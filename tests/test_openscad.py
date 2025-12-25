"""Tests for OpenSCAD utility functions."""

from io import BytesIO

import pytest
from PIL import Image

from openscadbench import openscad


@pytest.fixture
def valid_scad(tmp_path):
    """Create a valid SCAD file."""
    scad_file = tmp_path / "valid.scad"
    scad_file.write_text("cube([10, 20, 30]);")
    return scad_file


@pytest.fixture
def invalid_scad(tmp_path):
    """Create an invalid SCAD file with syntax error."""
    scad_file = tmp_path / "invalid.scad"
    scad_file.write_text("cube([10, 20, 30")  # Missing closing bracket
    return scad_file


def test_check_syntax_valid(valid_scad):
    """Valid SCAD code should return (True, '')."""
    success, error = openscad.check_syntax(valid_scad)
    assert success is True
    assert error == ""


def test_check_syntax_invalid(invalid_scad):
    """Invalid SCAD code should return (False, ...)."""
    success, _ = openscad.check_syntax(invalid_scad)
    assert success is False


def test_render_png(valid_scad):
    """render_png should produce a valid 800x600 PNG."""
    buf = BytesIO()
    openscad.render_png(valid_scad, buf, distance=200, azimuth=45, elevation=30)

    buf.seek(0)
    img = Image.open(buf)
    assert img.format == "PNG"
    assert img.size == (800, 600)


def test_render_overview(valid_scad):
    """render_overview should produce a valid 800x600 composite PNG."""
    buf = BytesIO()
    openscad.render_overview(valid_scad, buf)

    buf.seek(0)
    img = Image.open(buf)
    assert img.format == "PNG"
    assert img.size == (800, 600)


def test_get_dimensions(valid_scad):
    """get_dimensions should return correct bounding box for cube([10, 20, 30])."""
    dims = openscad.get_dimensions(valid_scad)

    assert dims["x"] == 10.0
    assert dims["y"] == 20.0
    assert dims["z"] == 30.0
