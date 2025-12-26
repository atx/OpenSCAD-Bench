"""CLI entry point for OpenSCAD Bench."""

import argparse
import itertools
import json
import sys
from pathlib import Path

from dotenv import load_dotenv
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

from openscadbench import openscad
from openscadbench.catalog import BENCHMARKS, match_benchmarks
from openscadbench.executor import EXECUTORS, match_executors
from openscadbench.result import Result

# Load environment variables from .env file
load_dotenv()


def cmd_list_benchmarks(args: argparse.Namespace) -> int:
    """List all available benchmarks."""

    print(f"{'ID'} {'Name'}")
    print("-" * 50)
    for benchmark in BENCHMARKS:
        print(f"{benchmark.id} {benchmark.name}")

    print(f"\nTotal: {len(BENCHMARKS)} benchmark(s)")
    return 0


def cmd_run(args: argparse.Namespace) -> int:
    """Run benchmarks with specified models."""
    # Match benchmarks
    benchmarks = match_benchmarks(args.benchmark)
    if not benchmarks:
        print(f"No benchmarks matching pattern: {args.benchmark}", file=sys.stderr)
        return 1

    # Match executors
    executors = match_executors(args.model)
    if not executors:
        print(f"No executors matching pattern: {args.model}", file=sys.stderr)
        return 1

    # Parse runs
    runs = [r.strip() for r in args.runs.split(",")]

    # Results directory
    results_dir = Path("results")

    # Run all combinations
    combinations = list(itertools.product(benchmarks, executors, runs))
    completed = 0
    skipped = 0

    for i, (benchmark, executor, run_id) in enumerate(combinations, 1):
        result_dir = Result.make_path_for_base_dir(
            results_dir, benchmark.id, executor.id, run_id
        )
        if result_dir.exists() and not args.force_overwrite:
            print(f"Skipping {benchmark.id} with {executor.id} (run {run_id}): already exists")
            skipped += 1
            continue

        print(f"Running {benchmark.id} with {executor.id} (run {run_id})...")
        result = executor.run(benchmark, run_id)
        result_path = result.save(results_dir)
        print(f"  Saved to {result_path}")
        completed += 1

    print(f"\nCompleted {completed} runs, skipped {skipped} existing.")
    return 0


def cmd_render_site(args: argparse.Namespace) -> int:
    """Generate the static results site."""
    from openscadbench.renderer import SiteRenderer

    results_dir = Path(args.results_dir)
    output_dir = Path(args.output_dir)

    if not results_dir.exists():
        print(f"Error: Results directory not found: {results_dir}", file=sys.stderr)
        return 1

    renderer = SiteRenderer(results_dir, output_dir)
    renderer.render()
    return 0


def cmd_render_overview(args: argparse.Namespace) -> int:
    """Render a 4-view overview of an OpenSCAD file."""
    scad_path = Path(args.scad_file)
    output_path = Path(args.output)

    with open(output_path, "wb") as f:
        openscad.render_overview(scad_path, f)

    print(f"Rendered overview to {output_path}")
    return 0


def cmd_render_trace(args: argparse.Namespace) -> int:
    """Pretty-print a trace.json file."""
    trace_path = Path(args.trace_file)

    with open(trace_path) as f:
        trace = json.load(f)

    console = Console()
    role_styles = {
        "system": "dim",
        "user": "green",
        "assistant": "blue",
        "tool": "yellow",
    }

    for msg in trace:
        role = msg.get("role", "unknown")
        style = role_styles.get(role, "white")

        # Handle tool calls
        if "tool_calls" in msg:
            for tc in msg["tool_calls"]:
                func = tc.get("function", {})
                name = func.get("name", "?")
                args_str = func.get("arguments", "{}")
                console.print(Panel(
                    f"[bold]{name}[/bold]({args_str})",
                    title=f"[{style}]assistant → tool call[/{style}]",
                    border_style=style,
                ))
            continue

        # Skip empty content
        content = msg.get("content", "")
        if not content:
            continue

        # Format tool results more nicely
        if role == "tool":
            title = f"[{style}]tool result[/{style}]"
        else:
            title = f"[{style}]{role}[/{style}]"

        console.print(Panel(content, title=title, border_style=style))

    return 0


def main() -> int:
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        prog="openscadbench",
        description="OpenSCAD benchmark for evaluating LLM 3D modeling capabilities",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # list-benchmarks command
    subparsers.add_parser(
        "list-benchmarks",
        help="List all available benchmarks",
    )

    # run command
    run_parser = subparsers.add_parser(
        "run",
        help="Run benchmark(s) with specified model(s)",
    )
    run_parser.add_argument(
        "--benchmark",
        required=True,
        help='Benchmark ID or glob pattern (e.g., "raspberry_*" or "*" for all)',
    )
    run_parser.add_argument(
        "--model",
        required=True,
        help='Model name or glob pattern (e.g., "claude-*")',
    )
    run_parser.add_argument(
        "--runs",
        default="1",
        help='Comma-separated run IDs (default: "1")',
    )
    run_parser.add_argument(
        "--force-overwrite",
        action="store_true",
        help="Overwrite existing results (default: skip existing)",
    )

    # render-site command
    render_site_parser = subparsers.add_parser(
        "render-site",
        help="Generate the static results website",
    )
    render_site_parser.add_argument(
        "--results-dir",
        dest="results_dir",
        default="results",
        help="Path to results directory (default: results/)",
    )
    render_site_parser.add_argument(
        "--output-dir",
        dest="output_dir",
        default="site",
        help="Path to output directory (default: site/)",
    )

    # render-overview command
    overview_parser = subparsers.add_parser(
        "render-overview",
        help="Render a 4-view overview of an OpenSCAD file",
    )
    overview_parser.add_argument(
        "scad_file",
        help="Path to the OpenSCAD file",
    )
    overview_parser.add_argument(
        "output",
        help="Output PNG path",
    )

    # render-trace command
    trace_parser = subparsers.add_parser(
        "render-trace",
        help="Pretty-print a trace.json file",
    )
    trace_parser.add_argument(
        "trace_file",
        help="Path to the trace.json file",
    )

    args = parser.parse_args()

    match args.command:
        case "list-benchmarks":
            return cmd_list_benchmarks(args)
        case "run":
            return cmd_run(args)
        case "render-site":
            return cmd_render_site(args)
        case "render-overview":
            return cmd_render_overview(args)
        case "render-trace":
            return cmd_render_trace(args)
        case _:
            return 1


if __name__ == "__main__":
    sys.exit(main())
