# OpenSCAD-Bench
OpenSCAD benchmark for LLMs. An experiment in spatio-textual reasoning capability.

<p align="center">
  <a href="https://atx.github.io/OpenSCAD-Bench/">
<img width="847" height="440" alt="image" src="https://github.com/user-attachments/assets/4c0142db-8fdb-42c1-b1b5-5b5cc256accd" />
  </a>
</p>

**[View Latest Results →](https://atx.github.io/OpenSCAD-Bench/)**


AI agents receive a text prompt describing an object to model, use tools to iteratively write and render OpenSCAD code, and submit a final solution. There is no grading system in place, conclusions are left to the reader.


### The setup

Each agent gets:

- `write_scad(content)` — write/overwrite the .scad file (returns syntax errors if any)
- `render_png(distance, azimuth, elevation)` — render the current model from a camera angle
- `render_overview()` — render front/back/top/isometric as a composite image
- `submit()` — declare the solution final

The agent loops until it calls `submit()` or hits the iteration limit (20 calls). There is no automated scoring — evaluation is purely visual via the results page.
