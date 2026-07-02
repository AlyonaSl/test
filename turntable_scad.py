"""Turntable MP4 of the OpenSCAD assembly (output/scad/assembly.stl)."""
import os
import subprocess
import tempfile

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import trimesh
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

SC = os.path.join("output", "scad")
m = trimesh.load(os.path.join(SC, "assembly.stl"), force="mesh")
m.apply_transform(trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0]))

lv = np.array([0.35, -0.45, 0.82]); lv = lv / np.linalg.norm(lv)
base = np.array(matplotlib.colors.to_rgb("#fbfbfd"))   # white matte
v = m.vertices
c = (v.min(0) + v.max(0)) / 2
sp = (v.max(0) - v.min(0)).max() / 2 * 1.02

tmp = tempfile.mkdtemp()
FR = 48
for i in range(FR):
    fig = plt.figure(figsize=(7, 6)); ax = fig.add_subplot(111, projection="3d")
    sh = np.clip(m.face_normals @ lv, 0.66, 1.0)
    ax.add_collection3d(Poly3DCollection(
        m.vertices[m.faces], facecolors=np.clip(base[None, :] * sh[:, None], 0, 1),
        edgecolors=(0.35, 0.37, 0.4, 0.16), linewidths=0.12))
    ax.set_xlim(c[0]-sp, c[0]+sp); ax.set_ylim(c[1]-sp, c[1]+sp); ax.set_zlim(c[2]-sp, c[2]+sp)
    ax.set_box_aspect((1, 1, 1)); ax.view_init(elev=16, azim=-180 + 360 * i / FR)
    ax.set_axis_off(); ax.set_facecolor("#dfe2e7"); fig.patch.set_facecolor("#dfe2e7")
    fig.savefig(os.path.join(tmp, f"f{i:03d}.png"), dpi=100, bbox_inches="tight",
                facecolor="#dfe2e7")
    plt.close(fig)

out = os.path.join(SC, "demo_turntable.mp4")
subprocess.run(["ffmpeg", "-y", "-framerate", "16", "-i", os.path.join(tmp, "f%03d.png"),
                "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", out],
               check=True, capture_output=True)
print("wrote", out)
