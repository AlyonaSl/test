# Label roll holder — elegant centre-mount (3D-printable)

A slim, elegant desk-edge holder for **3 label rolls**, reproduced as a fully
parametric CAD model from the reference product sheet. Re-running the build
regenerates every printable file (`STL`) and editable CAD file (`STEP`).

![Holder with 3 rolls](output/demo_rolls.png)

## Specification (from the reference)

| Item | Value |
|---|---|
| Rolls | 3, on one axle |
| Roll core inner diameter (втулка) | 50–80 mm |
| Axle (ось) | Ø16 mm, length 286 mm |
| Strut height | 220 mm (56 mm wide at top) |
| Mount | Clamp over the desk edge, desktops 10–40 mm |
| Clamp screw | Printed knurled thumb-screw (tool-free) |
| Axle lock / roll stop | Bayonet fixator (quarter-turn) |

## Parts (in `output/`)

| Part | Print qty | Notes |
|---|---|---|
| `bracket` | 1 | Strut + oval cutout + stiffening rim + edge clamp + axle hub |
| `axle` | 1 | Ø16 mm rod, inner roll-stop flange, bayonet lugs both ends |
| `clamp_screw` | 1 | Knurled thumb-screw, self-taps into the clamp jaw |
| `fixator` | 2 | Bayonet end cap; twist-locks on the axle tip, stops the rolls |

Each part is provided as `.stl` (slice & print) and `.step` (edit in FreeCAD /
Fusion / SolidWorks). `assembly.step` / `assembly.stl` show everything together.

![Bracket](output/preview_bracket.png)

## How it goes together

1. Hook the `bracket` over the desk edge; tighten the `clamp_screw` from below
   against the desktop underside (fits 10–40 mm tops).
2. Slide up to 3 rolls onto the `axle` (they rest against the inner flange).
3. Twist a `fixator` onto the axle tip to retain the rolls.
4. Insert the axle inner end into the bracket hub and twist 90° to lock.

## Regenerating the files

Dependencies are in `requirements.txt` (CadQuery + trimesh + matplotlib).

```bash
python3 build.py     # export STL + STEP for every part; validate watertightness
python3 render.py    # per-part preview PNGs
python3 demo.py      # demo_rolls.png + demo_turntable.mp4 (needs ffmpeg)
```

`build.py` exits non-zero if any part is not a watertight, positive-volume
solid — a hard requirement for reliable printing.

## Customising

All dimensions live in the `Spec` dataclass in
[`src/label_roll_holder.py`](src/label_roll_holder.py). Change `num_rolls`,
`axle_len`, `strut_h`, `desk_gap`, etc. and re-run `build.py`.

## Recommended print settings (per the reference sheet)

- **Material:** PLA or PETG.
- **Layer height:** 0.2 mm, **4 perimeters**, **~35 % gyroid** infill.
- **Bracket:** print on its flat back; no supports needed.
- **Clamp screw / fixator:** flat on the bed.
- **Axle:** print upright if the printer is tall enough, otherwise lay it flat.

## Design notes / interpretation

The reference infographic mixes a few inconsistent numbers (e.g. side-view
"110 mm" vs. axle length 286 mm, and core Ø50–80 vs. roll Ø75). This model
follows the explicit part callouts (axle Ø16 × 286 mm; strut 56 × 220 mm; clamp
10–40 mm) and implements a **cantilever axle** with a bayonet mount + a bayonet
end fixator, which is the most functional and print-friendly reading. The clamp
screw self-taps into a plain pilot hole (robust FDM approach) rather than a
modelled internal thread. Everything is parametric, so any of these choices are
one edit away from changing.
