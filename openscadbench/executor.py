"""Executor implementations for running benchmarks."""

import json
import logging
import tempfile
from datetime import datetime
from fnmatch import fnmatch
from io import BytesIO
from pathlib import Path
from typing import Protocol, runtime_checkable

import llm
import llm_openrouter

from openscadbench import openscad
from openscadbench.benchmark import Benchmark
from openscadbench.result import Result


logger = logging.getLogger(__name__)

_patches_installed = False


def _install_patches():
    """Install all necessary monkey-patches for the llm library."""
    global _patches_installed
    if _patches_installed:
        return

    # Patch 1: Fix json.loads(None) crash for tools with no arguments
    # Some providers (Anthropic) return null for tool arguments when empty,
    # but the llm library calls json.loads() which crashes on None.
    import llm.default_plugins.openai_models as openai_models

    _original_json = openai_models.json

    class _SafeJson:
        @staticmethod
        def loads(s, **kwargs):
            if not s:
                return {}
            return _original_json.loads(s, **kwargs)

        @staticmethod
        def dumps(*args, **kwargs):
            return _original_json.dumps(*args, **kwargs)

    openai_models.json = _SafeJson

    # Patch 2: Preserve reasoning_details for Gemini 3 models
    _install_reasoning_patch()

    _patches_installed = True


def _install_reasoning_patch():
    """Monkey-patch llm_openrouter to preserve reasoning_details.

    Gemini 3 models require reasoning_details (thought signatures) to be
    preserved across conversation turns when using tool calling. The llm
    library doesn't do this by default, so we patch build_messages.

    The llm library splits API responses into separate assistant messages for
    content vs tool_calls, but reasoning_details must be attached to the
    message with tool_calls. We match tool_call IDs to find the right message.
    """
    original_build_messages = llm_openrouter.OpenRouterChat.build_messages

    def patched_build_messages(self, prompt, conversation):
        messages = original_build_messages(self, prompt, conversation)

        if not conversation:
            return messages

        # Build a map of tool_call_id -> reasoning_details from all responses
        reasoning_by_tool_call = {}
        for prev_response in conversation.responses:
            if not hasattr(prev_response, "response_json"):
                continue
            response_json = prev_response.response_json
            if not response_json:
                continue
            choices = response_json.get("choices", [])
            if not choices:
                continue
            message = choices[0].get("message", {})
            reasoning = message.get("reasoning_details")
            tool_calls = message.get("tool_calls", [])

            if not reasoning or not tool_calls:
                continue
            # Map each tool_call ID to this reasoning_details
            for tc in tool_calls:
                tc_id = tc.get("id")
                if tc_id:
                    reasoning_by_tool_call[tc_id] = reasoning

        if not reasoning_by_tool_call:
            return messages

        # Find assistant messages with tool_calls and inject reasoning_details
        for msg in messages:
            if msg.get("role") != "assistant":
                continue
            tool_calls = msg.get("tool_calls", [])
            if not tool_calls:
                continue
            # Get the first tool_call ID and look up its reasoning
            first_tc_id = tool_calls[0].get("id")
            if first_tc_id and first_tc_id in reasoning_by_tool_call:
                msg["reasoning_details"] = reasoning_by_tool_call[first_tc_id]

        return messages

    llm_openrouter.OpenRouterChat.build_messages = patched_build_messages


# Apply patches at module load time
_install_patches()


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

- submit(): Call this when you are satisfied with your model.

## Guidelines

1. Start by writing an initial version of the model, then render it to see the result.
2. Iterate: refine the code, re-render, until satisfied.
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

    def __init__(self, model: str, max_iterations: int = 50):
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

        def render_overview(_unused: str = "") -> llm.ToolOutput:
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

        def submit(_unused: str = "") -> str:
            """Signal that you are satisfied with the model.

            Call this when you believe the model meets the requirements.

            Returns:
                Confirmation message.
            """
            state["submitted"] = True
            return '{"success": true, "message": "Solution submitted"}'

        return [write_scad, render_png, render_overview, submit], state

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
        logger.debug("Starting run: benchmark=%s model=%s run=%s", benchmark.id, self.model_name, run_id)

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
            pending_tool_results = None

            while iteration < self.max_iterations and not state["submitted"]:
                iteration += 1
                logger.debug("Iteration %d/%d", iteration, self.max_iterations)

                # Get response from model
                # NOTE: stream=False is required because the llm library's
                # combine_chunks doesn't preserve reasoning_details, which
                # breaks Gemini 3 models that require thought signatures.
                if pending_tool_results:
                    # Continue with tool results from previous iteration
                    response = conversation.prompt(
                        tool_results=pending_tool_results,
                        tools=tools,
                        stream=False,
                    )
                    pending_tool_results = None
                elif iteration == 1:
                    # First iteration: include system prompt and user message
                    response = conversation.prompt(
                        benchmark.prompt,
                        system=SYSTEM_PROMPT,
                        tools=tools,
                        stream=False,
                    )
                else:
                    # No tool results and not first iteration - shouldn't happen normally
                    break

                # Consume the response text
                response_text = response.text()
                trace.append({"role": "assistant", "content": response_text})
                logger.debug("  Response: %d chars", len(response_text or ""))

                # Check for tool calls
                tool_calls = response.tool_calls()
                if not tool_calls:
                    logger.debug("  No tool calls, model finished")
                    break

                # Execute tool calls and record in trace
                pending_tool_results = response.execute_tool_calls()

                for tool_call, result in zip(tool_calls, pending_tool_results):
                    tool_name = tool_call.name
                    tool_args = tool_call.arguments
                    logger.debug("  Tool call: %s(%s)", tool_name, tool_args)

                    # Record tool call in trace
                    trace.append({
                        "role": "assistant",
                        "tool_calls": [{
                            "id": result.tool_call_id,
                            "type": "function",
                            "function": {
                                "name": tool_name,
                                "arguments": str(tool_args),
                            },
                        }],
                    })

                    # Record tool result in trace
                    if isinstance(result.output, llm.ToolOutput):
                        result_text = result.output.output
                    else:
                        result_text = str(result.output)

                    trace.append({
                        "role": "tool",
                        "tool_call_id": result.tool_call_id,
                        "content": result_text,
                    })

            if state["submitted"]:
                logger.debug("Agent submitted after %d iterations", iteration)
            elif iteration >= self.max_iterations:
                logger.debug("Agent hit max iterations (%d)", self.max_iterations)

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
    AgentExecutor("openrouter/google/gemini-3-flash-preview"),
    AgentExecutor("openrouter/google/gemini-3-pro-preview"),
    AgentExecutor("openrouter/anthropic/claude-sonnet-4.5"),
    AgentExecutor("openrouter/anthropic/claude-opus-4.5"),
    AgentExecutor("openrouter/anthropic/claude-opus-4.6"),
    AgentExecutor("openrouter/openai/gpt-5.1-codex-max"),
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
