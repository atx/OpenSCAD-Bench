"""Static site generator for benchmark results."""

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

        print(f"Site generated at {self.output_dir}/")
