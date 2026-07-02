# AGENTS.md

## Project overview

Parametric CAD project (Python + CadQuery) that generates 3D-printable files
for a desk-mounted label-roll holder. The single source of truth for geometry
is `src/label_roll_holder.py`; `build.py` exports/validates the files and
`render.py` produces preview images. Generated output lives in `output/`.

## Cursor Cloud specific instructions

- Python deps are defined in `requirements.txt` and are installed into the
  **system** Python via the startup update script (this VM's Python is
  PEP-668 "externally managed", so installs use `--break-system-packages`).
  Run scripts directly with `python3` — no virtualenv is required or expected.
- Regenerate everything with `python3 build.py` (exports `STL` + `STEP` and
  validates each part is watertight; it exits non-zero if not) and
  `python3 render.py` (writes preview PNGs). See `README.md` for details.
- Rendering is headless: `render.py` forces the matplotlib `Agg` backend. The
  matplotlib 3D previews can show dark triangular "z-fighting" artifacts — these
  are a painter's-algorithm rendering limitation, not geometry defects. Trust
  `build.py`'s trimesh watertight/winding check for actual mesh validity, or
  open the `STEP` files in a real CAD viewer.
- There is no long-running service to start; this repo is a file generator.
