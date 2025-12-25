"""Executor implementations for running benchmarks."""

import tempfile
from datetime import datetime
from fnmatch import fnmatch
from io import BytesIO
from pathlib import Path
from typing import Protocol, runtime_checkable

import llm

from openscadbench import openscad
from openscadbench.benchmark import Benchmark
from openscadbench.result import Result


SYSTEM_PROMPT = """\
You are an expert OpenSCAD programmer. Your task is to create a 3D model based on the
user's description.

You have access to the following tools:

- write_scad(content): Write OpenSCAD code to the model file. Returns syntax errors if
  any. Always provide the complete file contents—this overwrites the previous version.

- render_png(distance, azimuth, elevation): Render the current model from a specific
  camera angle. Returns a PNG image.
  - distance: Camera distance from origin (try 200-500 for typical models)
  - azimuth: Horizontal angle in degrees (0=front, 90=right, 180=back, 270=left)
  - elevation: Vertical angle in degrees (0=horizon, 90=top-down)

- render_overview(): Render four standard views (front, back, top, isometric) as a
  single composite image. Use this to quickly check your model from all angles.

- get_dimensions(): Get the bounding box dimensions of the current model. Returns
  {x, y, z} in mm.

- submit(): Call this when you are satisfied with your model.

## Guidelines

1. Start by writing an initial version of the model, then render it to see the result.
2. Iterate: refine the code, re-render, check dimensions, until satisfied.
3. Use render_overview() periodically to verify the model looks correct from all angles.
4. OpenSCAD uses millimeters as the default unit.
5. When you believe the model meets the requirements, call submit().

Common OpenSCAD patterns:
- Difference for subtracting shapes: difference() { base(); cutout(); }
- Union for combining: union() { part1(); part2(); }
- Linear extrude for 2D→3D: linear_extrude(height) square([x,y]);
- Translate/rotate for positioning: translate([x,y,z]) rotate([rx,ry,rz]) shape();
"""


@runtime_checkable
class BaseExecutor(Protocol):
    """Protocol for benchmark executors.

    Executors take a benchmark and produce a result by running an agent
    (or in the case of DummyExecutor, returning a placeholder).
    """

    id: str

    def run(self, benchmark: Benchmark, run_id: str) -> Result:
        """Execute a benchmark and return the result.

        Args:
            benchmark: The benchmark to run.
            run_id: The run identifier (e.g., "1", "2", "3").

        Returns:
            The result of the benchmark run.
        """
        ...


class DummyExecutor:
    """Executor that returns an empty SCAD file (for testing)."""

    id: str = "dummy"

    def run(self, benchmark: Benchmark, run_id: str) -> Result:
        """Return an empty result for testing purposes."""
        now = datetime.now()
        return Result(
            benchmark_id=benchmark.id,
            agent_id=self.id,
            run_id=run_id,
            scad_content="// Empty solution\n",
            trace=[
                {"role": "system", "content": "You are an OpenSCAD expert."},
                {"role": "user", "content": benchmark.prompt},
                {"role": "assistant", "content": "// Empty solution"},
            ],
            started_at=now,
            completed_at=now,
        )


class AgentExecutor:
    """Executor that uses an LLM agent to solve benchmarks.

    Uses the llm library with OpenRouter to run an agentic loop where the
    model can use tools to write, render, and iterate on OpenSCAD code.
    """

    def __init__(self, model: str, max_iterations: int = 20):
        """Initialize the agent executor.

        Args:
            model: Model identifier for the llm library
                   (e.g., "openrouter/google/gemini-2.5-flash-lite:free").
            max_iterations: Maximum number of LLM calls before stopping.
        """
        self.model_name = model
        self.max_iterations = max_iterations
        self.id = model.replace("openrouter/", "").replace("/", "-").replace(":", "_")

    def _make_tools(self, scad_path: Path) -> tuple[list, dict]:
        """Create LLM tool functions bound to a SCAD file.

        Args:
            scad_path: Path to the .scad file to operate on.

        Returns:
            Tuple of (tools_list, state_dict) where state_dict contains
            mutable state like {"submitted": False}.
        """
        state = {"submitted": False}

        def write_scad(content: str) -> str:
            """Write OpenSCAD code to the model file.

            Writes the content to model.scad and runs a syntax check.
            Returns syntax errors if any. Always provide the complete file
            contents - this overwrites the previous version.

            Args:
                content: Complete OpenSCAD code to write.

            Returns:
                JSON with success status and any syntax errors.
            """
            scad_path.write_text(content)
            success, error = openscad.check_syntax(scad_path)
            if not success:
                return f'{{"success": false, "error": "{error}"}}'
            return '{"success": true}'

        def render_png(distance: float, azimuth: float, elevation: float) -> llm.ToolOutput:
            """Render the current model from a specific camera angle.

            Args:
                distance: Camera distance from origin (try 200-500 for typical models).
                azimuth: Horizontal angle in degrees (0=front, 90=right, 180=back, 270=left).
                elevation: Vertical angle in degrees (0=horizon, 90=top-down).

            Returns:
                PNG image of the rendered model.
            """
            buf = BytesIO()
            try:
                openscad.render_png(scad_path, buf, distance, azimuth, elevation)
            except openscad.OpenSCADError as e:
                return llm.ToolOutput(output=f'{{"success": false, "error": "{e}"}}')
            return llm.ToolOutput(
                output='{"success": true}',
                attachments=[llm.Attachment(content=buf.getvalue(), type="image/png")],
            )

        def render_overview() -> llm.ToolOutput:
            """Render four standard views as a single composite image.

            Renders front, back, top, and isometric views in a 2x2 grid.
            Use this to quickly check your model from all angles.

            Returns:
                Composite PNG image with four views.
            """
            buf = BytesIO()
            try:
                openscad.render_overview(scad_path, buf)
            except openscad.OpenSCADError as e:
                return llm.ToolOutput(output=f'{{"success": false, "error": "{e}"}}')
            return llm.ToolOutput(
                output='{"success": true}',
                attachments=[llm.Attachment(content=buf.getvalue(), type="image/png")],
            )

        def get_dimensions() -> str:
            """Get the bounding box dimensions of the current model.

            Returns:
                JSON with x, y, z dimensions in mm.
            """
            try:
                dims = openscad.get_dimensions(scad_path)
            except openscad.OpenSCADError as e:
                return f'{{"success": false, "error": "{e}"}}'
            return f'{{"x": {dims["x"]}, "y": {dims["y"]}, "z": {dims["z"]}}}'

        def submit() -> str:
            """Signal that you are satisfied with the model.

            Call this when you believe the model meets the requirements.

            Returns:
                Confirmation message.
            """
            state["submitted"] = True
            return '{"success": true, "message": "Solution submitted"}'

        return [write_scad, render_png, render_overview, get_dimensions, submit], state

    def run(self, benchmark: Benchmark, run_id: str) -> Result:
        """Execute a benchmark using the LLM agent.

        Args:
            benchmark: The benchmark to run.
            run_id: The run identifier (e.g., "1", "2", "3").

        Returns:
            The result of the benchmark run.
        """
        started_at = datetime.now()
        trace: list[dict] = []

        # Create temporary working directory
        with tempfile.TemporaryDirectory() as tmpdir:
            working_dir = Path(tmpdir)
            scad_path = working_dir / "model.scad"

            # Initialize an empty scad file
            scad_path.write_text("// Initial empty model\n")

            # Create tools bound to this scad file
            tools, state = self._make_tools(scad_path)

            # Get the model
            model = llm.get_model(self.model_name)

            # Build initial messages
            trace.append({"role": "system", "content": SYSTEM_PROMPT})
            trace.append({"role": "user", "content": benchmark.prompt})

            # Start conversation
            conversation = model.conversation()

            # Run agent loop
            iteration = 0
            prompt = benchmark.prompt
            include_system = True  # Only include system prompt on first call

            while iteration < self.max_iterations and not state["submitted"]:
                iteration += 1

                # Get response from model
                if include_system:
                    response = conversation.prompt(prompt, system=SYSTEM_PROMPT, tools=tools)
                    include_system = False
                else:
                    response = conversation.prompt(prompt, tools=tools)

                # Consume the response text
                response_text = response.text()
                trace.append({"role": "assistant", "content": response_text})

                # Check for tool calls
                tool_calls = response.tool_calls()
                if not tool_calls:
                    # No tool calls, model is done talking
                    break

                # Execute tool calls
                tool_results = response.execute_tool_calls()

                # Build the next prompt with tool results
                tool_messages = []
                for tool_call, result in zip(tool_calls, tool_results):
                    tool_name = tool_call.name
                    tool_args = tool_call.arguments

                    # Record tool call in trace
                    trace.append({
                        "role": "assistant",
                        "tool_calls": [{
                            "id": f"call_{iteration}_{tool_name}",
                            "type": "function",
                            "function": {
                                "name": tool_name,
                                "arguments": str(tool_args),
                            },
                        }],
                    })

                    # Record tool result in trace
                    if isinstance(result, llm.ToolOutput):
                        result_text = result.output
                    else:
                        result_text = str(result)

                    trace.append({
                        "role": "tool",
                        "tool_call_id": f"call_{iteration}_{tool_name}",
                        "content": result_text,
                    })

                    tool_messages.append(f"Tool {tool_name} returned: {result_text}")

                # Continue with tool results as the next prompt
                prompt = "\n".join(tool_messages) if tool_messages else "Continue."

            # Get final SCAD content
            scad_content = ""
            if scad_path.exists():
                scad_content = scad_path.read_text()

        completed_at = datetime.now()

        return Result(
            benchmark_id=benchmark.id,
            agent_id=self.id,
            run_id=run_id,
            scad_content=scad_content,
            trace=trace,
            started_at=started_at,
            completed_at=completed_at,
        )


EXECUTORS: list[BaseExecutor] = [
    #AgentExecutor("openrouter/google/gemini-3-flash-preview"),
    #AgentExecutor("openrouter/google/gemini-3-pro-preview"),
    #AgentExecutor("openrouter/anthropic/claude-sonnet-4.5"),
    #AgentExecutor("openrouter/anthropic/claude-opus-4.5"),
    #AgentExecutor("openrouter/openai/gpt-5.1-codex-max"),
    AgentExecutor("openrouter/openai/gpt-5.1-codex-mini"),
]


def get_executor(executor_id: str) -> BaseExecutor | None:
    """Get an executor by its ID.

    Args:
        executor_id: The unique identifier of the executor.

    Returns:
        The matching executor, or None if not found.
    """
    for executor in EXECUTORS:
        if executor.id == executor_id:
            return executor
    return None


def match_executors(pattern: str) -> list[BaseExecutor]:
    """Match executors by glob pattern.

    Args:
        pattern: A glob pattern to match against executor IDs.
                 Use "*" to match all executors.

    Returns:
        List of matching executors.
    """
    return [e for e in EXECUTORS if fnmatch(e.id, pattern)]
