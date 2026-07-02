"""Render preview PNGs of the STL parts (headless, via matplotlib).

Produces shaded isometric views so the design can be reviewed without a
GUI slicer. Rotates the assembly so the back plate is vertical (wall) and
the spindle is horizontal, matching how it is installed on a desk.

Usage:
    python render.py
"""

from __future__ import annotations

import os

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import trimesh  # noqa: E402
from mpl_toolkits.mplot3d.art3d import Poly3DCollection  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "output")


def _wall_orientation(mesh: trimesh.Trimesh) -> trimesh.Trimesh:
    """Rotate -90deg about X: spindle (+Z) -> horizontal, plate -> vertical."""
    m = mesh.copy()
    R = trimesh.transformations.rotation_matrix(-np.pi / 2, [1, 0, 0])
    m.apply_transform(R)
    return m


def render(stl_name: str, png_name: str, title: str, wall: bool = True,
           elev: float = 22, azim: float = -60, color: str = "#6f9ad6") -> str:
    path = os.path.join(OUT, stl_name)
    mesh = trimesh.load(path, force="mesh")
    if wall:
        mesh = _wall_orientation(mesh)

    fig = plt.figure(figsize=(8, 6))
    ax = fig.add_subplot(111, projection="3d")

    tris = mesh.vertices[mesh.faces]

    # Simple lambert-ish shading from face normals.
    normals = mesh.face_normals
    light = np.array([0.4, -0.5, 0.8])
    light = light / np.linalg.norm(light)
    shade = np.clip(normals @ light, 0.15, 1.0)
    base = np.array(matplotlib.colors.to_rgb(color))
    facecolors = np.clip(base[None, :] * shade[:, None], 0, 1)

    coll = Poly3DCollection(tris, facecolors=facecolors, edgecolors=(0, 0, 0, 0.06),
                            linewidths=0.15)
    ax.add_collection3d(coll)

    v = mesh.vertices
    mins, maxs = v.min(axis=0), v.max(axis=0)
    center = (mins + maxs) / 2
    span = (maxs - mins).max() / 2 * 1.05
    ax.set_xlim(center[0] - span, center[0] + span)
    ax.set_ylim(center[1] - span, center[1] + span)
    ax.set_zlim(center[2] - span, center[2] + span)
    ax.set_box_aspect((1, 1, 1))
    ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off()
    ax.set_title(title, fontsize=13)

    out = os.path.join(OUT, png_name)
    fig.tight_layout()
    fig.savefig(out, dpi=130, bbox_inches="tight")
    plt.close(fig)
    print(f"wrote {out}")
    return out


def main() -> None:
    render("assembly.stl", "preview_assembly.png",
           "Label roll holder - wall-mounted assembly", wall=True,
           azim=-60, color="#6f9ad6")
    render("bracket.stl", "preview_bracket.png",
           "Bracket + spindle (single print)", wall=True,
           azim=-60, color="#6f9ad6")
    render("separator.stl", "preview_separator.png",
           "Separator disc (print x2)", wall=False,
           elev=32, azim=-50, color="#d68e46")
    render("end_cap.stl", "preview_end_cap.png",
           "End cap", wall=False, elev=28, azim=-50, color="#c25151")


if __name__ == "__main__":
    main()
