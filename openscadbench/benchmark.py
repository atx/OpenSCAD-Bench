"""Benchmark dataclass representing a modeling task."""

from dataclasses import dataclass


@dataclass
class Benchmark:
    """A benchmark task for the OpenSCAD modeling challenge.

    Attributes:
        id: Unique identifier, e.g., "raspberry_pi_case"
        name: Human-readable name, e.g., "Raspberry Pi 4 Case"
        prompt: Full instruction text given to the agent
    """

    id: str
    name: str
    prompt: str

    def __post_init__(self):
        self.prompt = self.prompt.strip()
