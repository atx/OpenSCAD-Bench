"""Pure OpenSCAD utilities for rendering and analysis."""

import subprocess
import tempfile
from pathlib import Path
from typing import BinaryIO

from PIL import Image


class OpenSCADError(Exception):
    """Error from OpenSCAD execution."""


def check_syntax(scad_path: Path) -> tuple[bool, str]:
    """Check syntax of a SCAD file.

    Args:
        scad_path: Path to the .scad file.

    Returns:
        Tuple of (success, error_message). If success is True,
        error_message is empty.
    """
    result = subprocess.run(
        ["openscad", "--export-format=echo", "-o", "/dev/null", str(scad_path)],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        error_msg = result.stderr.strip() or result.stdout.strip()
        return False, error_msg

    return True, ""


def render_png(
    scad_path: Path,
    output: BinaryIO,
    distance: float,
    azimuth: float,
    elevation: float,
) -> None:
    """Render a SCAD file to PNG.

    Args:
        scad_path: Path to the .scad file.
        output: File-like object to write PNG data to.
        distance: Camera distance from origin.
        azimuth: Horizontal angle in degrees (0=front, 90=right).
        elevation: Vertical angle in degrees (0=horizon, 90=top-down).

    Raises:
        OpenSCADError: If rendering fails.
    """
    with tempfile.NamedTemporaryFile(suffix=".png", delete_on_close=False) as tmp:
        camera = f"0,0,0,{elevation},0,{azimuth},{distance}"
        result = subprocess.run(
            [
                "openscad",
                f"--camera={camera}",
                "--imgsize=800,600",
                "--render",
                "--autocenter",
                "--viewall",
                "--colorscheme=Tomorrow Night",
                "-o",
                tmp.name,
                str(scad_path),
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            error_msg = result.stderr.strip() or "Render failed"
            raise OpenSCADError(error_msg)

        output.write(Path(tmp.name).read_bytes())


def render_overview(scad_path: Path, output: BinaryIO) -> None:
    """Render four standard views as a 2x2 composite image.

    Views: front, back, top, isometric.

    Args:
        scad_path: Path to the .scad file.
        output: File-like object to write PNG data to.

    Raises:
        OpenSCADError: If rendering fails.
    """
    views = [
        ("front", 0, 0),
        ("back", 180, 0),
        ("top", 0, 90),
        ("isometric", 45, 35),
    ]

    images = []
    for name, azimuth, elevation in views:
        with tempfile.NamedTemporaryFile(suffix=".png", delete_on_close=False) as tmp:
            camera = f"0,0,0,{elevation},0,{azimuth},300"
            result = subprocess.run(
                [
                    "openscad",
                    f"--camera={camera}",
                    "--render",
                    "--autocenter",
                    "--viewall",
                    "--imgsize=400,300",
                    "--colorscheme=Tomorrow Night",
                    "-o",
                    tmp.name,
                    str(scad_path),
                ],
                capture_output=True,
                text=True,
            )

            if result.returncode != 0:
                error_msg = result.stderr.strip() or f"Failed to render {name} view"
                raise OpenSCADError(error_msg)

            images.append(Image.open(tmp.name).copy())

    # Create 2x2 composite
    composite = Image.new("RGB", (800, 600))
    composite.paste(images[0], (0, 0))  # front - top left
    composite.paste(images[1], (400, 0))  # back - top right
    composite.paste(images[2], (0, 300))  # top - bottom left
    composite.paste(images[3], (400, 300))  # isometric - bottom right

    # Write to output
    composite.save(output, format="PNG")


def get_dimensions(scad_path: Path) -> dict[str, float]:
    """Get the bounding box dimensions of a SCAD model.

    Args:
        scad_path: Path to the .scad file.

    Returns:
        Dictionary with "x", "y", "z" dimensions in mm.

    Raises:
        OpenSCADError: If export or parsing fails.
    """
    with tempfile.NamedTemporaryFile(suffix=".stl", delete_on_close=False) as tmp:
        result = subprocess.run(
            ["openscad", "-o", tmp.name, str(scad_path)],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            error_msg = result.stderr.strip() or "Failed to export for dimensions"
            raise OpenSCADError(error_msg)

        # Parse STL to find bounding box
        min_x = min_y = min_z = float("inf")
        max_x = max_y = max_z = float("-inf")

        with open(tmp.name, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("vertex"):
                    parts = line.split()
                    x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
                    min_x = min(min_x, x)
                    max_x = max(max_x, x)
                    min_y = min(min_y, y)
                    max_y = max(max_y, y)
                    min_z = min(min_z, z)
                    max_z = max(max_z, z)

        if min_x == float("inf"):
            raise OpenSCADError("No geometry found")

        return {
            "x": round(max_x - min_x, 2),
            "y": round(max_y - min_y, 2),
            "z": round(max_z - min_z, 2),
        }


def export_stl(scad_path: Path, output_path: Path) -> None:
    """Export a SCAD file to STL format.

    Args:
        scad_path: Path to the .scad file.
        output_path: Path to write the .stl file.

    Raises:
        OpenSCADError: If export fails.
    """
    result = subprocess.run(
        ["openscad", "-o", str(output_path), str(scad_path)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        error_msg = result.stderr.strip() or "STL export failed"
        raise OpenSCADError(error_msg)


def render_turntable_frames(
    scad_path: Path,
    output_dir: Path,
    num_frames: int = 36,
    elevation: float = 25.0,
    distance: float = 300.0,
) -> list[Path]:
    """Render turntable frames at evenly spaced azimuth angles.

    Args:
        scad_path: Path to the .scad file.
        output_dir: Directory to write frame PNGs.
        num_frames: Number of frames (default 36 = 10 degree increments).
        elevation: Camera elevation angle in degrees.
        distance: Camera distance from origin.

    Returns:
        List of paths to rendered frame PNGs in order.

    Raises:
        OpenSCADError: If any render fails.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    frame_paths = []

    for i in range(num_frames):
        azimuth = (360.0 / num_frames) * i
        frame_path = output_dir / f"frame_{i:04d}.png"

        camera = f"0,0,0,{elevation},0,{azimuth},{distance}"
        result = subprocess.run(
            [
                "openscad",
                f"--camera={camera}",
                "--autocenter",
                "--viewall",
                "--render",
                "--imgsize=400,300",
                "--colorscheme=Tomorrow Night",
                "-o",
                str(frame_path),
                str(scad_path),
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            error_msg = result.stderr.strip() or f"Failed to render frame {i}"
            raise OpenSCADError(error_msg)

        frame_paths.append(frame_path)

    return frame_paths


def stitch_frames_to_webm(
    frame_dir: Path,
    output_path: Path,
    fps: int = 12,
) -> None:
    """Stitch PNG frames into a WebM video using ffmpeg.

    Args:
        frame_dir: Directory containing frame_NNNN.png files.
        output_path: Path to write the .webm file.
        fps: Frames per second for the video.

    Raises:
        OpenSCADError: If ffmpeg fails.
    """
    pattern = frame_dir / "frame_%04d.png"

    result = subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-framerate",
            str(fps),
            "-i",
            str(pattern),
            "-c:v",
            "libvpx-vp9",
            "-crf",
            "30",
            "-b:v",
            "0",
            str(output_path),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        error_msg = result.stderr.strip() or "ffmpeg encoding failed"
        raise OpenSCADError(error_msg)
