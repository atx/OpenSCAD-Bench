"""Catalog of benchmark definitions."""

from fnmatch import fnmatch

from openscadbench.benchmark import Benchmark

BENCHMARKS: list[Benchmark] = [
    Benchmark(
        id="towel_hook",
        name="Towel Hook",
        prompt="""
Make a 3D printable towel hook. The hook should be designed to be screwed onto a
wall with a single M3 flat head screw.

The hook should be capable of holding a large towel without bending or breaking.
        """
    ),
    Benchmark(
        id="citronhaj_stand",
        name="Citronhaj Stand",
        prompt="""
Make a 3D printable stand for the IKEA Citronhaj spice jar.

A Citronhaj spice jar is a cylinder with a diameter of 40 mm and a height of 120 mm.

Your job is to create a stand that can hold 9 jars in a 3x3 grid. The stand should
have "tiered" levels, so that the front row is the lowest, the middle row is a bit higher, and the last row is highest. The step size should be about 3cm per level.

The stand should envelop enough of each jar to hold it securely, preventing it
from tiping over. However, it should still be easy to remove the jars
from the stand.
"""
    ),
    Benchmark(
        id="battery_case",
        name="Battery Case",
        prompt="""
Create a 3D printable case for holding four Olympus BLS-5 batteries.

The dimensions of a battery is 56 mm x 36 mm x 13 mm.

This case should hold the batteries in a linear 4 x 1 arrangement, with the
batteries standing 'upright' on their smallest face. They should face each
other with their largest face.

The case should be 3D printable in one single piece.

There should be a 'snap-fit' mechanism to hold the batteries in place,
while allowing easy removal by a finger hole from the bottom of each battery slot.
""",
    ),
    Benchmark(
        id="chess_rook",
        name="Chess Rook",
        prompt="""Create a 3D model of a chess rook piece."""
    )
]


def get_benchmark(benchmark_id: str) -> Benchmark | None:
    """Get a benchmark by its ID.

    Args:
        benchmark_id: The unique identifier of the benchmark.

    Returns:
        The matching Benchmark, or None if not found.
    """
    for benchmark in BENCHMARKS:
        if benchmark.id == benchmark_id:
            return benchmark
    return None


def match_benchmarks(pattern: str) -> list[Benchmark]:
    """Match benchmarks by glob pattern.

    Args:
        pattern: A glob pattern to match against benchmark IDs.
                 Use "*" to match all benchmarks.

    Returns:
        List of matching Benchmark objects.
    """
    return [b for b in BENCHMARKS if fnmatch(b.id, pattern)]
