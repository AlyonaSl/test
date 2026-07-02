# Printing guide — LabelHolder

Ready-to-slice files are in [`output/scad/`](output/scad/). Use the **`.3mf`**
files (they embed millimetre units and open in Bambu Studio / OrcaSlicer /
PrusaSlicer / Cura); `.stl` is provided as well. `.step` is for CAD editing only,
not for printing.

## What to print (quantities)

| Part | File | Qty |
|---|---|---|
| Stand (wishbone bracket) | `stand.3mf` | 1 |
| Clamp thumb-screw + 2 end caps (one small plate) | `accessories.3mf` | 1 |

…plus the **axle**, choose ONE option depending on your bed size:

| Bed size | Axle files | Qty |
|---|---|---|
| **≥ 360 mm** (or ~256 mm printed diagonally) | `axle.3mf` (one piece, ~350 mm) | 1 |
| **Standard (≤ 300 mm)** — recommended | `axle_a.3mf` + `axle_b.3mf` (two halves) | 1 each |

The two axle halves join with a **centre pin/socket** that seats inside the hub,
so the split is invisible in use and needs no glue (add a drop of glue if you
want it permanent).

> Why: the one-piece axle is ~350 mm — longer than most FDM beds. The split
> halves are ~180 mm and fit any common printer.

## Orientation & supports (print without supports)

- **accessories.3mf** — already laid out: screw **head-down**, caps **dome-up**.
  No supports.
- **axle / axle_a / axle_b** — lay the rod **flat/horizontal** on the bed; add a
  **brim** for adhesion. No supports.
- **stand.3mf** — print on its **back** (flat face up, rear ribs on the bed).
  No supports needed for the blade, oval or hook thanks to the ≥45° geometry; if
  your slicer flags the clamp jaw underside, enable minimal/tree supports there
  only.

## Recommended slicer settings (from the design sheet)

- Material: **PETG** (preferred for the 1.5 kg load) or **PLA**
- Layer height: **0.2 mm**
- Walls / perimeters: **4**
- Infill: **~35 % gyroid**
- Supports: **off** (see stand note above)
- Colour: white matte looks best (any colour works)

## Assembly

1. Hook the **stand** over the desk edge; tighten the **clamp screw** from
   below until snug (tool-free knurled head; fits 10–40 mm desktops).
2. Load rolls onto the axle. For the split axle: put rolls on each half, then
   push the halves together (pin → socket) through the central hub. For the
   one-piece axle: slide it through the hub and add rolls on both sides.
3. Twist a **pebble end cap** onto each axle end (bayonet, 90°).

## Re-generating the files

Edit parameters at the top of [`LabelHolder.scad`](LabelHolder.scad) and run
`./export.sh` (needs `openscad` + `xvfb`). Useful parameters:

- `end_stop_dia` — set to `84` to add a positive roll-retention flange to the
  end caps (default `0` = small elegant caps).
- `axle_work`, `roll_od_max`, `core_id_max` — size to your rolls.
