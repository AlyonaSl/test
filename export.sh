#!/usr/bin/env bash
# Export every part of LabelHolder.scad to STL + 3MF (print masters) and STEP.
#
# STEP note: OpenSCAD is a mesh modeller and cannot emit analytic BREP STEP, so
# STEP files are tessellated (via OpenCASCADE/OCP). To keep them a sensible size
# we feed a coarser mesh into the STEP writer; the screw STEP uses a smooth
# shaft (THREADED=false) while the STL/3MF keep the full printable thread.
#
# Requires: openscad, xvfb-run, python3 (with cadquery/OCP + trimesh).
set -euo pipefail
cd "$(dirname "$0")"
OUT=output/scad
mkdir -p "$OUT"
PARTS=(stand clamp axle lock)

echo ">> STL + 3MF (print masters)"
for p in "${PARTS[@]}"; do
    xvfb-run -a openscad -q -D "PART=\"$p\"" -o "$OUT/$p.stl"  LabelHolder.scad
    xvfb-run -a openscad -q -D "PART=\"$p\"" -o "$OUT/$p.3mf" LabelHolder.scad
done
xvfb-run -a openscad -q -D 'PART="assembly"' -o "$OUT/assembly.stl" LabelHolder.scad

echo ">> coarse meshes for compact STEP"
xvfb-run -a openscad -q -D FN=16               -D 'PART="stand"' -o "$OUT/stand_coarse.stl" LabelHolder.scad
xvfb-run -a openscad -q -D FN=18               -D 'PART="axle"'  -o "$OUT/axle_coarse.stl"  LabelHolder.scad
xvfb-run -a openscad -q -D FN=16               -D 'PART="lock"'  -o "$OUT/lock_coarse.stl"  LabelHolder.scad
xvfb-run -a openscad -q -D FN=28 -D THREADED=false -D 'PART="clamp"' -o "$OUT/clamp_coarse.stl" LabelHolder.scad

echo ">> STEP"
python3 step_export.py
rm -f "$OUT"/*_coarse.stl
echo ">> done"
