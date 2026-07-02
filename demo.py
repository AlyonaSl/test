"""Demonstration renders: the assembly holding 3 label rolls + a turntable.

Outputs:
    output/demo_rolls.png       still, assembly with 3 translucent rolls
    output/demo_turntable.mp4    rotating view (requires ffmpeg)
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import trimesh  # noqa: E402
from mpl_toolkits.mplot3d.art3d import Poly3DCollection  # noqa: E402

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))
from label_roll_holder import DEFAULT  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "output")


def _shade(mesh, base, light=(0.4, -0.5, 0.8)):
    n = mesh.face_normals
    lv = np.array(light) / np.linalg.norm(light)
    sh = np.clip(n @ lv, 0.18, 1.0)
    return np.clip(np.array(base)[None, :] * sh[:, None], 0, 1)


def _roll(center_y, width, od, core_id=None):
    """Translucent roll (solid cylinder) centred on the axle (+Y)."""
    roll = trimesh.creation.cylinder(radius=od / 2, height=width, sections=56)
    R = trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    roll.apply_transform(R)  # axis -> Y
    roll.apply_translation([0, center_y, DEFAULT.hub_z])
    return roll


def _add_mesh(ax, mesh, color, alpha=1.0, edge=(0, 0, 0, 0.06)):
    tris = mesh.vertices[mesh.faces]
    fc = _shade(mesh, matplotlib.colors.to_rgb(color))
    if alpha < 1.0:
        fc = np.hstack([fc, np.full((len(fc), 1), alpha)])
    ax.add_collection3d(
        Poly3DCollection(tris, facecolors=fc, edgecolors=edge, linewidths=0.1)
    )


def _scene():
    s = DEFAULT
    bracket = trimesh.load(os.path.join(OUT, "bracket.stl"), force="mesh")
    asm = trimesh.load(os.path.join(OUT, "assembly.stl"), force="mesh")
    ax_off = s.hub_len - 14
    span0 = ax_off + 22
    span1 = ax_off + s.axle_len - 6
    n = s.num_rolls
    width = (span1 - span0) / n - 4
    rolls = []
    for i in range(n):
        cy = span0 + width / 2 + i * (span1 - span0) / n + 2
        rolls.append(_roll(cy, width, od=75.0, core_id=66.0))
    return asm, rolls, (bracket, asm)


def _draw(ax, asm, rolls, azim, elev=18):
    ax.clear()
    _add_mesh(ax, asm, "#9aa7b6", alpha=1.0)
    for r in rolls:
        _add_mesh(ax, r, "#e7d8a6", alpha=0.45, edge=(0, 0, 0, 0.04))
    allv = np.vstack([asm.vertices] + [r.vertices for r in rolls])
    mn, mx = allv.min(0), allv.max(0)
    c = (mn + mx) / 2
    span = (mx - mn).max() / 2 * 1.02
    ax.set_xlim(c[0] - span, c[0] + span)
    ax.set_ylim(c[1] - span, c[1] + span)
    ax.set_zlim(c[2] - span, c[2] + span)
    ax.set_box_aspect((1, 1, 1))
    ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off()


def still():
    asm, rolls, _ = _scene()
    fig = plt.figure(figsize=(9, 6))
    ax = fig.add_subplot(111, projection="3d")
    _draw(ax, asm, rolls, azim=-62)
    ax.set_title("Holder with 3 rolls (Ø75 shown) on the Ø16 axle", fontsize=13)
    p = os.path.join(OUT, "demo_rolls.png")
    fig.tight_layout()
    fig.savefig(p, dpi=130, bbox_inches="tight")
    plt.close(fig)
    print("wrote", p)


def turntable(frames=48):
    asm, rolls, _ = _scene()
    tmp = tempfile.mkdtemp()
    for i in range(frames):
        fig = plt.figure(figsize=(7, 6))
        ax = fig.add_subplot(111, projection="3d")
        _draw(ax, asm, rolls, azim=-180 + 360 * i / frames)
        fig.savefig(os.path.join(tmp, f"f{i:03d}.png"), dpi=100,
                    bbox_inches="tight")
        plt.close(fig)
    out = os.path.join(OUT, "demo_turntable.mp4")
    subprocess.run(
        ["ffmpeg", "-y", "-framerate", "16", "-i", os.path.join(tmp, "f%03d.png"),
         "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", out],
        check=True, capture_output=True,
    )
    print("wrote", out)


if __name__ == "__main__":
    still()
    turntable()
