"""Result dataclass and serialization for benchmark runs."""

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


@dataclass
class Result:
    """Captures everything from a single benchmark run.

    Attributes:
        benchmark_id: ID of the benchmark that was run.
        agent_id: Model name, e.g., "claude-sonnet-4-20250514".
        run_id: Run number as string, e.g., "1", "2", "3".
        scad_content: Final OpenSCAD code (solution.scad contents).
        trace: Full message history (OpenAI-style messages).
        started_at: When the benchmark run started.
        completed_at: When the benchmark run completed.
    """

    benchmark_id: str
    agent_id: str
    run_id: str
    scad_content: str
    trace: list[dict]
    started_at: datetime
    completed_at: datetime

    @staticmethod
    def make_path_for_base_dir(
        base_path: Path, benchmark_id: str, agent_id: str, run_id: str
    ) -> Path:
        """Construct the result directory path from components.

        Args:
            base_path: Base results directory.
            benchmark_id: ID of the benchmark.
            agent_id: ID of the agent/model.
            run_id: Run identifier.

        Returns:
            Path to results/{benchmark_id}/{agent_id}/{run_id}/
        """
        return base_path / benchmark_id / agent_id / run_id

    def get_result_dir(self, base_path: Path) -> Path:
        """Get the directory path for this result.

        Args:
            base_path: Base results directory.

        Returns:
            Path to results/{benchmark_id}/{agent_id}/{run_id}/
        """
        return self.make_path_for_base_dir(
            base_path, self.benchmark_id, self.agent_id, self.run_id
        )

    def save(self, base_path: Path) -> Path:
        """Save all artifacts to disk.

        Writes:
        - solution.scad: The SCAD content
        - trace.json: The message trace
        - metadata.json: Timing info

        Note: STL/render generation is not implemented yet.

        Args:
            base_path: Base results directory.

        Returns:
            Path to the result directory.
        """
        result_dir = self.get_result_dir(base_path)
        result_dir.mkdir(parents=True, exist_ok=True)

        # Write solution.scad
        (result_dir / "solution.scad").write_text(self.scad_content)

        # Write trace.json
        with open(result_dir / "trace.json", "w") as f:
            json.dump(self.trace, f, indent=2)

        # Write metadata.json
        metadata = {
            "started_at": self.started_at.isoformat(),
            "completed_at": self.completed_at.isoformat(),
        }
        with open(result_dir / "metadata.json", "w") as f:
            json.dump(metadata, f, indent=2)

        return result_dir

    @classmethod
    def load(cls, result_dir: Path) -> "Result":
        """Load a result from disk.

        Args:
            result_dir: Path to the result directory
                        (e.g., results/benchmark_id/agent_id/run_id/).

        Returns:
            The loaded Result object.

        Raises:
            FileNotFoundError: If required files are missing.
        """
        # Parse IDs from path
        run_id = result_dir.name
        agent_id = result_dir.parent.name
        benchmark_id = result_dir.parent.parent.name

        # Read solution.scad
        scad_content = (result_dir / "solution.scad").read_text()

        # Read trace.json
        with open(result_dir / "trace.json") as f:
            trace = json.load(f)

        # Read metadata.json
        with open(result_dir / "metadata.json") as f:
            metadata = json.load(f)

        return cls(
            benchmark_id=benchmark_id,
            agent_id=agent_id,
            run_id=run_id,
            scad_content=scad_content,
            trace=trace,
            started_at=datetime.fromisoformat(metadata["started_at"]),
            completed_at=datetime.fromisoformat(metadata["completed_at"]),
        )
