"""Static site generator for benchmark results."""

import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, select_autoescape

from openscadbench import openscad
from openscadbench.catalog import get_benchmark
from openscadbench.result import Result


@dataclass
class RunInfo:
    """Info about a single run for template rendering."""

    run_id: str
    started_at: str
    completed_at: str


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

        Generates:
        - overview.png (2x2 composite)
        - solution.stl
        - turntable.webm

        Args:
            result: The Result to generate artifacts for.

        Returns:
            True if all artifacts exist (generated or cached).
        """
        result_dir = result.get_result_dir(self.results_dir)
        scad_path = result_dir / "solution.scad"

        overview_png = result_dir / "overview.png"
        solution_stl = result_dir / "solution.stl"
        turntable_webm = result_dir / "turntable.webm"

        # Check if all artifacts already exist
        if overview_png.exists() and solution_stl.exists() and turntable_webm.exists():
            return True

        # Check if SCAD has any content worth rendering
        if not result.scad_content.strip() or result.scad_content.strip() == "// Empty solution":
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
            return False

    def render(self) -> None:
        """Generate the complete static site."""
        print(f"Discovering results in {self.results_dir}...")
        results = self.discover_results()
        print(f"Found {len(results)} results")

        # Generate artifacts for each result
        valid_results: list[Result] = []
        for result in results:
            print(f"Processing {result.benchmark_id}/{result.agent_id}/{result.run_id}...")
            if self.generate_artifacts(result):
                valid_results.append(result)
            else:
                print(f"  Skipping (empty or invalid)")

        # Build matrix data structure
        agents = sorted(set(r.agent_id for r in valid_results))
        benchmark_ids = sorted(set(r.benchmark_id for r in valid_results))

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

        for result in valid_results:
            key = (result.agent_id, result.benchmark_id)
            cells[key].append(RunInfo(
                run_id=result.run_id,
                started_at=result.started_at.isoformat(),
                completed_at=result.completed_at.isoformat(),
            ))

        # Sort runs within each cell by run_id
        for key in cells:
            cells[key].sort(key=lambda r: int(r.run_id))

        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        assets_dir = self.output_dir / "assets"

        # Copy artifacts to site/assets/
        print("Copying assets...")
        for result in valid_results:
            result_dir = result.get_result_dir(self.results_dir)
            dest_dir = assets_dir / result.benchmark_id / result.agent_id / result.run_id
            dest_dir.mkdir(parents=True, exist_ok=True)

            for filename in ["overview.png", "turntable.webm", "solution.stl",
                             "solution.scad", "trace.json", "metadata.json"]:
                src = result_dir / filename
                if src.exists():
                    shutil.copy2(src, dest_dir / filename)

        # Render index.html
        print("Rendering index.html...")
        template = self.env.get_template("index.html")
        html = template.render(
            benchmarks=benchmarks,
            agents=agents,
            cells=cells,
        )
        (self.output_dir / "index.html").write_text(html)

        print(f"Site generated at {self.output_dir}/")
