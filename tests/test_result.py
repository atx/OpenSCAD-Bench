"""Tests for Result serialization and deserialization."""

import json
from datetime import datetime

import pytest

from openscadbench.result import Result


@pytest.fixture
def sample_result() -> Result:
    """Create a sample Result for testing."""
    return Result(
        benchmark_id="test_benchmark",
        agent_id="test_agent",
        run_id="1",
        scad_content="cube([10, 20, 30]);",
        trace=[
            {"role": "system", "content": "You are an OpenSCAD expert."},
            {"role": "user", "content": "Create a cube."},
            {"role": "assistant", "content": "cube([10, 20, 30]);"},
        ],
        started_at=datetime(2025, 1, 15, 10, 0, 0),
        completed_at=datetime(2025, 1, 15, 10, 5, 30),
    )


def test_save_load_roundtrip(tmp_path, sample_result):
    """Save a Result and load it back, verifying all fields match."""
    result_dir = sample_result.save(tmp_path)
    loaded = Result.load(result_dir)

    assert loaded.benchmark_id == sample_result.benchmark_id
    assert loaded.agent_id == sample_result.agent_id
    assert loaded.run_id == sample_result.run_id
    assert loaded.scad_content == sample_result.scad_content
    assert loaded.trace == sample_result.trace
    assert loaded.started_at == sample_result.started_at
    assert loaded.completed_at == sample_result.completed_at


def test_save_creates_correct_directory_structure(tmp_path, sample_result):
    """Verify the correct directory structure is created."""
    result_dir = sample_result.save(tmp_path)

    expected_dir = tmp_path / "test_benchmark" / "test_agent" / "1"
    assert result_dir == expected_dir
    assert result_dir.is_dir()


def test_save_creates_correct_files(tmp_path, sample_result):
    """Verify all expected files are created with correct content."""
    result_dir = sample_result.save(tmp_path)

    # Check solution.scad
    scad_file = result_dir / "solution.scad"
    assert scad_file.exists()
    assert scad_file.read_text() == "cube([10, 20, 30]);"

    # Check trace.json
    trace_file = result_dir / "trace.json"
    assert trace_file.exists()
    with open(trace_file) as f:
        trace_data = json.load(f)
    assert trace_data == sample_result.trace

    # Check metadata.json
    metadata_file = result_dir / "metadata.json"
    assert metadata_file.exists()
    with open(metadata_file) as f:
        metadata = json.load(f)
    assert metadata["started_at"] == "2025-01-15T10:00:00"
    assert metadata["completed_at"] == "2025-01-15T10:05:30"
