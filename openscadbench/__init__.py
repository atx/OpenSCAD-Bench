"""OpenSCAD Bench - LLM benchmark for 3D modeling via OpenSCAD."""

from openscadbench.benchmark import Benchmark
from openscadbench.result import Result
from openscadbench.catalog import BENCHMARKS, get_benchmark, match_benchmarks
from openscadbench.executor import (
    AgentExecutor,
    BaseExecutor,
    DummyExecutor,
    EXECUTORS,
    get_executor,
    match_executors,
)
from openscadbench.openscad import (
    OpenSCADError,
    check_syntax,
    get_dimensions,
    render_overview,
    render_png,
)

__all__ = [
    "Benchmark",
    "Result",
    "BENCHMARKS",
    "get_benchmark",
    "match_benchmarks",
    "AgentExecutor",
    "BaseExecutor",
    "DummyExecutor",
    "EXECUTORS",
    "get_executor",
    "match_executors",
    "OpenSCADError",
    "check_syntax",
    "get_dimensions",
    "render_overview",
    "render_png",
]
