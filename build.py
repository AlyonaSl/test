"""Build all printable files for the label-roll holder.

Generates, for every part:
  * an STL  (mesh, ready to slice)
  * a STEP  (parametric CAD, for editing in FreeCAD / Fusion / etc.)

and a combined STEP assembly for visualisation. Each exported STL is
validated with trimesh to confirm it is a watertight, positive-volume solid
(a hard requirement for reliable 3D printing).

Usage:
    python build.py
"""

from __future__ import annotations

import os
import sys

import cadquery as cq
import trimesh

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))
from label_roll_holder import DEFAULT, assembly, bracket, end_cap, separator  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "output")

PARTS = {
    "bracket": bracket,
    "separator": separator,
    "end_cap": end_cap,
}


def export_part(name: str, solid: cq.Workplane) -> str:
    stl_path = os.path.join(OUT, f"{name}.stl")
    step_path = os.path.join(OUT, f"{name}.step")
    cq.exporters.export(solid, stl_path, tolerance=0.05, angularTolerance=0.1)
    cq.exporters.export(solid, step_path)
    return stl_path


def validate_stl(name: str, stl_path: str) -> bool:
    mesh = trimesh.load(stl_path, force="mesh")
    watertight = bool(mesh.is_watertight)
    winding = bool(mesh.is_winding_consistent)
    volume_cm3 = mesh.volume / 1000.0
    bbox = mesh.bounding_box.extents
    status = "OK" if (watertight and winding and volume_cm3 > 0) else "FAIL"
    print(
        f"[{status:4}] {name:10} "
        f"watertight={watertight!s:5} winding_ok={winding!s:5} "
        f"vol={volume_cm3:7.2f} cm^3  "
        f"bbox={bbox[0]:.1f}x{bbox[1]:.1f}x{bbox[2]:.1f} mm  "
        f"tris={len(mesh.faces)}"
    )
    return watertight and winding and volume_cm3 > 0


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    p = DEFAULT
    print(
        f"Design: {p.num_rolls} rolls, width<= {p.roll_width:.0f} mm, "
        f"core ID {p.core_id_min:.0f}-{p.core_id_max:.0f} mm, "
        f"spindle Ø{p.spindle_dia:.0f} mm, reach {p.spindle_len + p.tip_len:.0f} mm\n"
    )

    ok = True
    for name, fn in PARTS.items():
        stl_path = export_part(name, fn(p))
        ok &= validate_stl(name, stl_path)

    # Combined assembly (visualisation / reference).
    compound = assembly(p).toCompound()
    cq.exporters.export(compound, os.path.join(OUT, "assembly.step"))
    cq.exporters.export(compound, os.path.join(OUT, "assembly.stl"),
                        tolerance=0.05, angularTolerance=0.1)
    print("\nWrote STL + STEP for every part and an assembly.step / assembly.stl")

    if not ok:
        print("\nERROR: at least one part is not a watertight solid.", file=sys.stderr)
        return 1
    print("All parts are watertight, printable solids.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
