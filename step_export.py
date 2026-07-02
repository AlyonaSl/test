"""Convert the OpenSCAD-exported STL meshes to STEP (tessellated BREP).

OpenSCAD is a mesh modeller and cannot emit a native parametric STEP, so we
wrap each printable mesh as a STEP shell via OpenCASCADE (OCP). The result is a
valid, widely-importable STEP file (faceted, not analytic surfaces).
"""
import os
import time

from OCP.IFSelect import IFSelect_RetDone
from OCP.STEPControl import STEPControl_AsIs, STEPControl_Writer
from OCP.StlAPI import StlAPI_Reader
from OCP.TopoDS import TopoDS_Shape

SC = os.path.join("output", "scad")
PARTS = ["stand", "axle", "clamp", "lock"]

for name in PARTS:
    t0 = time.time()
    shape = TopoDS_Shape()
    src = os.path.join(SC, f"{name}_coarse.stl")
    if not os.path.exists(src):
        src = os.path.join(SC, f"{name}.stl")
    ok = StlAPI_Reader().Read(shape, src)
    w = STEPControl_Writer()
    w.Transfer(shape, STEPControl_AsIs)
    status = w.Write(os.path.join(SC, f"{name}.step"))
    sz = os.path.getsize(os.path.join(SC, f"{name}.step")) // 1024
    print(f"{name:8} read={ok!s:5} write_ok={status == IFSelect_RetDone!s:5} "
          f"{sz} KiB  {time.time()-t0:.1f}s")
