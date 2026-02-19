"""Static site generator for benchmark results."""

import ast
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape
from PIL import Image, ImageDraw

from openscadbench import openscad
from openscadbench.catalog import get_benchmark
from openscadbench.result import Result


def generate_invalid_placeholder(output_path: Path) -> None:
    """Generate a placeholder image for invalid results.

    Creates a subdued dark image with "INVALID" text centered.

    Args:
        output_path: Path to write the PNG file.
    """
    from PIL import ImageFont

    # Subdued dark gray background (similar to the site's bg-gray-900)
    img = Image.new("RGB", (400, 300), color=(17, 24, 39))
    draw = ImageDraw.Draw(img)

    text = "invalid"

    # Try to load a larger font, fall back to default if unavailable
    font = None
    for font_size in [72, 60, 48]:
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
            break
        except OSError:
            continue

    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (400 - text_width) // 2
    y = (300 - text_height) // 2

    # Muted gray text
    draw.text((x, y), text, fill=(75, 85, 99), font=font)

    img.save(output_path, format="PNG")


@dataclass
class RunInfo:
    """Info about a single run for template rendering."""

    run_id: str
    started_at: str
    completed_at: str
    valid: bool


def _parse_tool_args(args_str: str) -> dict:
    """Parse tool arguments from trace format.

    Arguments in traces are Python dict repr strings (with single quotes).

    Args:
        args_str: The raw arguments string from the trace.

    Returns:
        Parsed arguments as a dict.
    """
    if not args_str or not args_str.strip():
        return {}
    result = ast.literal_eval(args_str)
    if isinstance(result, dict):
        return result
    return {}


class SiteRenderer:
    """Generates a static HTML site from benchmark results."""

    def __init__(
        self,
        results_dir: Path,
        output_dir: Path,
        templates_dir: Path | None = None,
    ):
        """Initialize the renderer.

        Args:
            results_dir: Path to the results/ directory.
            output_dir: Path to output site/ directory.
            templates_dir: Path to templates/ directory.
        """
        self.results_dir = results_dir
        self.output_dir = output_dir

        if templates_dir is None:
            templates_dir = Path(__file__).parent.parent / "templates"
        self.templates_dir = templates_dir

        self.env = Environment(
            loader=FileSystemLoader(str(templates_dir)),
            autoescape=select_autoescape(["html"]),
        )

    def discover_results(self) -> list[Result]:
        """Find all result directories and load them.

        Returns:
            List of loaded Result objects.
        """
        results = []

        for benchmark_dir in sorted(self.results_dir.iterdir()):
            if not benchmark_dir.is_dir():
                continue

            for agent_dir in sorted(benchmark_dir.iterdir()):
                if not agent_dir.is_dir():
                    continue

                for run_dir in sorted(agent_dir.iterdir()):
                    if not run_dir.is_dir():
                        continue

                    if not (run_dir / "solution.scad").exists():
                        continue

                    results.append(Result.load(run_dir))

        return results

    def generate_artifacts(self, result: Result) -> bool:
        """Generate artifacts for a result if they don't exist.

        For valid results, generates:
        - overview.png (2x2 composite)
        - solution.stl
        - turntable.webm

        For invalid results (empty SCAD or OpenSCAD errors), generates:
        - invalid.png (placeholder image)

        Args:
            result: The Result to generate artifacts for.

        Returns:
            True if result is valid (artifacts generated or cached).
            False if result is invalid (invalid.png generated).
        """
        result_dir = result.get_result_dir(self.results_dir)
        scad_path = result_dir / "solution.scad"

        overview_png = result_dir / "overview.png"
        solution_stl = result_dir / "solution.stl"
        turntable_webm = result_dir / "turntable.webm"
        invalid_png = result_dir / "invalid.png"

        # Check if already processed as invalid
        if invalid_png.exists():
            return False

        # Check if all valid artifacts already exist
        if overview_png.exists() and solution_stl.exists() and turntable_webm.exists():
            return True

        # Check if SCAD has any content worth rendering
        if not result.scad_content.strip() or result.scad_content.strip() == "// Empty solution":
            print(f"  Generating invalid.png (empty SCAD)...")
            generate_invalid_placeholder(invalid_png)
            return False

        # Generate artifacts, catching errors for invalid geometry
        try:
            # Generate overview.png
            if not overview_png.exists():
                print(f"  Generating overview.png...")
                with open(overview_png, "wb") as f:
                    openscad.render_overview(scad_path, f)

            # Generate solution.stl
            if not solution_stl.exists():
                print(f"  Generating solution.stl...")
                openscad.export_stl(scad_path, solution_stl)

            # Generate turntable.webm
            if not turntable_webm.exists():
                print(f"  Generating turntable.webm...")
                with tempfile.TemporaryDirectory() as tmpdir:
                    frames_dir = Path(tmpdir)
                    openscad.render_turntable_frames(scad_path, frames_dir)
                    openscad.stitch_frames_to_webm(frames_dir, turntable_webm)

            return True
        except openscad.OpenSCADError as e:
            print(f"  Error: {e}")
            print(f"  Generating invalid.png...")
            generate_invalid_placeholder(invalid_png)
            return False

    def generate_trace_renders(self, result: Result) -> None:
        """Pre-render images for render_png/render_overview tool calls in the trace.

        Walks the trace sequentially, tracking the current SCAD content from
        write_scad calls. For each render_png or render_overview tool call,
        re-renders the image using the SCAD state at that point.

        Images are stored in {result_dir}/trace/{index}.png where index is the
        trace array index of the assistant message containing the tool_calls.

        Args:
            result: The Result to generate trace renders for.
        """
        result_dir = result.get_result_dir(self.results_dir)
        trace_dir = result_dir / "trace"

        # First pass: find which indices need rendering (for cache check)
        current_scad: str | None = None
        render_indices: list[int] = []

        for i, msg in enumerate(result.trace):
            if msg.get("role") != "assistant" or not msg.get("tool_calls"):
                continue
            for tc in msg["tool_calls"]:
                name = tc.get("function", {}).get("name", "")
                if name == "write_scad":
                    args = _parse_tool_args(tc["function"].get("arguments", "{}"))
                    current_scad = args.get("content")
                elif name in ("render_png", "render_overview") and current_scad is not None:
                    render_indices.append(i)

        if not render_indices:
            return

        # Cache check: skip if all expected files exist
        if trace_dir.is_dir() and all(
            (trace_dir / f"{idx}.png").exists() for idx in render_indices
        ):
            return

        trace_dir.mkdir(parents=True, exist_ok=True)

        # Second pass: replay and render
        current_scad = None
        with tempfile.TemporaryDirectory() as tmpdir:
            scad_path = Path(tmpdir) / "model.scad"

            for i, msg in enumerate(result.trace):
                if msg.get("role") != "assistant" or not msg.get("tool_calls"):
                    continue

                for tc in msg["tool_calls"]:
                    func = tc.get("function", {})
                    name = func.get("name", "")
                    args_str = func.get("arguments", "{}")

                    if name == "write_scad":
                        args = _parse_tool_args(args_str)
                        current_scad = args.get("content")
                        if current_scad is not None:
                            scad_path.write_text(current_scad)

                if i not in render_indices:
                    continue

                output_path = trace_dir / f"{i}.png"
                if output_path.exists():
                    continue

                # Re-render the tool call from this message
                for tc in msg["tool_calls"]:
                    func = tc.get("function", {})
                    name = func.get("name", "")
                    if name not in ("render_png", "render_overview"):
                        continue

                    args = _parse_tool_args(func.get("arguments", "{}"))
                    try:
                        with open(output_path, "wb") as f:
                            if name == "render_overview":
                                openscad.render_overview(scad_path, f)
                            else:
                                openscad.render_png(
                                    scad_path,
                                    f,
                                    distance=float(args.get("distance", 300)),
                                    azimuth=float(args.get("azimuth", 45)),
                                    elevation=float(args.get("elevation", 25)),
                                )
                    except openscad.OpenSCADError as e:
                        print(f"    Trace render {i} failed: {e}")
                        generate_invalid_placeholder(output_path)

    def render(self) -> None:
        """Generate the complete static site."""
        print(f"Discovering results in {self.results_dir}...")
        results = self.discover_results()
        print(f"Found {len(results)} results")

        # Generate artifacts for each result, tracking validity
        result_validity: dict[str, bool] = {}
        for result in results:
            key = f"{result.benchmark_id}/{result.agent_id}/{result.run_id}"
            print(f"Processing {key}...")
            valid = self.generate_artifacts(result)
            result_validity[key] = valid
            if not valid:
                print(f"  Marked as invalid")
            print(f"  Generating trace renders...")
            self.generate_trace_renders(result)

        # Build matrix data structure from ALL results
        agents = sorted(set(r.agent_id for r in results))
        benchmark_ids = sorted(set(r.benchmark_id for r in results))

        benchmarks = []
        for bid in benchmark_ids:
            b = get_benchmark(bid)
            benchmarks.append({
                "id": bid,
                "name": b.name if b else bid,
                "prompt": b.prompt.strip() if b else "",
            })

        # Build cells: (agent_id, benchmark_id) -> list of RunInfo
        cells: dict[tuple[str, str], list[RunInfo]] = {}
        for agent in agents:
            for bid in benchmark_ids:
                cells[(agent, bid)] = []

        for result in results:
            key = f"{result.benchmark_id}/{result.agent_id}/{result.run_id}"
            valid = result_validity[key]
            cell_key = (result.agent_id, result.benchmark_id)
            cells[cell_key].append(RunInfo(
                run_id=result.run_id,
                started_at=result.started_at.isoformat(),
                completed_at=result.completed_at.isoformat(),
                valid=valid,
            ))

        # Sort runs within each cell by run_id
        for key in cells:
            cells[key].sort(key=lambda r: int(r.run_id))

        # Compute max runs per benchmark (for column width weighting)
        benchmark_max_runs = {}
        for bid in benchmark_ids:
            benchmark_max_runs[bid] = max(
                (len(cells[(agent, bid)]) for agent in agents),
                default=1,
            )

        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        assets_dir = self.output_dir / "assets"

        # Copy artifacts to site/assets/
        print("Copying assets...")
        for result in results:
            result_dir = result.get_result_dir(self.results_dir)
            dest_dir = assets_dir / result.benchmark_id / result.agent_id / result.run_id
            dest_dir.mkdir(parents=True, exist_ok=True)

            key = f"{result.benchmark_id}/{result.agent_id}/{result.run_id}"
            valid = result_validity[key]

            # Always copy SCAD, trace, and metadata
            for filename in ["solution.scad", "trace.json", "metadata.json"]:
                src = result_dir / filename
                if src.exists():
                    shutil.copy2(src, dest_dir / filename)

            if valid:
                # Copy valid result artifacts
                for filename in ["overview.png", "turntable.webm", "solution.stl"]:
                    src = result_dir / filename
                    if src.exists():
                        shutil.copy2(src, dest_dir / filename)
            else:
                # Copy invalid placeholder
                src = result_dir / "invalid.png"
                if src.exists():
                    shutil.copy2(src, dest_dir / "invalid.png")

            # Copy trace render images
            trace_src = result_dir / "trace"
            if trace_src.is_dir():
                trace_dest = dest_dir / "trace"
                trace_dest.mkdir(parents=True, exist_ok=True)
                for png_file in trace_src.glob("*.png"):
                    shutil.copy2(png_file, trace_dest / png_file.name)

        # Render index.html
        print("Rendering index.html...")
        template = self.env.get_template("index.html")
        html = template.render(
            benchmarks=benchmarks,
            agents=agents,
            cells=cells,
            benchmark_max_runs=benchmark_max_runs,
        )
        (self.output_dir / "index.html").write_text(html)

        # Copy trace.html (static file, no Jinja rendering needed)
        print("Copying trace.html...")
        shutil.copy2(self.templates_dir / "trace.html", self.output_dir / "trace.html")

        print(f"Site generated at {self.output_dir}/")
