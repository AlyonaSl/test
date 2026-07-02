"""Render preview PNGs of the OpenSCAD-exported STL parts (headless)."""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import trimesh
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

SC = os.path.join("output", "scad")


def shade(mesh, base):
    n = mesh.face_normals
    lv = np.array([0.4, -0.5, 0.8]); lv = lv/np.linalg.norm(lv)
    s = np.clip(n @ lv, 0.18, 1.0)
    return np.clip(np.array(base)[None, :]*s[:, None], 0, 1)


def render(stl, png, title, color="#aab2bd", elev=20, azim=-60, upify=True):
    m = trimesh.load(os.path.join(SC, stl), force="mesh")
    if upify:  # Y(height) -> Z(up)
        m.apply_transform(trimesh.transformations.rotation_matrix(np.pi/2, [1, 0, 0]))
    fig = plt.figure(figsize=(8, 6)); ax = fig.add_subplot(111, projection="3d")
    ax.add_collection3d(Poly3DCollection(m.vertices[m.faces],
                        facecolors=shade(m, matplotlib.colors.to_rgb(color)),
                        edgecolors=(0, 0, 0, 0.05), linewidths=0.1))
    v = m.vertices; c = (v.min(0)+v.max(0))/2; sp = (v.max(0)-v.min(0)).max()/2*1.03
    ax.set_xlim(c[0]-sp, c[0]+sp); ax.set_ylim(c[1]-sp, c[1]+sp); ax.set_zlim(c[2]-sp, c[2]+sp)
    ax.set_box_aspect((1, 1, 1)); ax.view_init(elev=elev, azim=azim); ax.set_axis_off()
    ax.set_title(title, fontsize=13)
    fig.tight_layout(); fig.savefig(os.path.join(SC, png), dpi=130, bbox_inches="tight")
    plt.close(fig); print("wrote", png)


render("assembly.stl", "preview_assembly.png", "LabelHolder - assembly (3 rolls)", azim=-58)
render("stand.stl", "preview_stand.png", "Stand: blade + hidden rib + clamp + hub", azim=-58)
render("axle.stl", "preview_axle.png", "Axle Ø16 (inner flange + bayonet)", azim=-52)
render("clamp.stl", "preview_clamp.png", "Clamp thumb-screw", color="#b79b53", azim=-52)
render("lock.stl", "preview_lock.png", "Lock: bayonet fixator (x2)", color="#b06a6a", azim=-52)
