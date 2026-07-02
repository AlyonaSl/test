"""Parametric 3D-printable label-roll holder.

Desk-side-mounted holder for 3 label rolls.

Design goals (from the spec):
  * Holds up to 3 rolls, each up to 50 mm wide.
  * Fits roll cores (inner sleeve / "втулка") of 50-80 mm inner diameter.
  * Mounts to the vertical side wall of a desk (flat plate + countersunk screws).
  * Compact and clean-looking.

The whole model is parametric: tweak the values in ``Params`` and re-run
``build.py`` to regenerate every STL / STEP file.

Coordinate convention used while modelling
------------------------------------------
The spindle is modelled pointing along +Z (easy to revolve / extrude).
The back plate lies in the XY plane just below z = 0.
For a wall installation, rotate the assembly -90 deg about X so the plate
becomes vertical (against the wall) and the spindle points horizontally.
Slicers re-orient parts anyway, so exported part files keep this simple
modelling orientation; recommended print orientation is documented in the
project README / AGENTS.md.
"""

from __future__ import annotations

from dataclasses import dataclass

import cadquery as cq


@dataclass(frozen=True)
class Params:
    # ---- rolls -------------------------------------------------------------
    num_rolls: int = 3
    roll_width: float = 50.0          # max width of one roll (mm)
    roll_width_clearance: float = 4.0  # axial slack per roll (mm)
    core_id_min: float = 50.0         # smallest core inner diameter (mm)
    core_id_max: float = 80.0         # largest core inner diameter (mm)

    # ---- spindle -----------------------------------------------------------
    spindle_dia: float = 30.0         # must be < core_id_min so rolls spin freely
    end_margin: float = 8.0           # spare spindle length past the last roll
    base_fillet: float = 8.0          # fillet at the spindle root (strength)

    # ---- reinforcement boss at the spindle root ----------------------------
    boss_dia: float = 44.0            # < core_id_min so a core still slides over it
    boss_len: float = 30.0

    # ---- tip boss (receives the end cap) -----------------------------------
    tip_dia: float = 16.0
    tip_len: float = 12.0

    # ---- back plate (screws to the desk side wall) -------------------------
    plate_w: float = 90.0
    plate_h: float = 90.0
    plate_t: float = 8.0
    screw_pitch: float = 58.0         # vertical spacing between the 2 screws
    screw_hole_dia: float = 4.6       # clearance for a #8 / 4.5 mm wood screw
    screw_head_dia: float = 9.0       # countersink major diameter
    csk_angle: float = 90.0

    # ---- separator discs (printed x (num_rolls - 1)) -----------------------
    # Must be larger than core_id_max so even an 80 mm core cannot ride over it.
    sep_dia: float = 86.0
    sep_thickness: float = 6.0
    fit_clearance: float = 1.0        # radial slack so parts slide on the spindle

    # ---- end cap (spool-end style: large flange + central hub/socket) ------
    cap_flange_dia: float = 88.0      # > core_id_max: stops the outer roll
    cap_flange_t: float = 4.0
    cap_hub_dia: float = 28.0
    cap_hub_len: float = 12.0
    cap_wall: float = 3.0

    @property
    def bay(self) -> float:
        return self.roll_width + self.roll_width_clearance

    @property
    def usable_len(self) -> float:
        """Spindle length occupied by rolls + separators."""
        return self.num_rolls * self.bay + (self.num_rolls - 1) * self.sep_thickness

    @property
    def spindle_len(self) -> float:
        """Straight spindle body length, from plate face to tip boss."""
        return self.usable_len + self.end_margin


DEFAULT = Params()


# ---------------------------------------------------------------------------
# Parts
# ---------------------------------------------------------------------------
def bracket(p: Params = DEFAULT) -> cq.Workplane:
    """Back plate + reinforcement boss + cantilever spindle (single print)."""
    # Back plate, top face at z = 0, growing downward.
    plate = (
        cq.Workplane("XY")
        .box(p.plate_w, p.plate_h, p.plate_t, centered=(True, True, False))
        .translate((0, 0, -p.plate_t))
    )

    # Two countersunk screw holes, heads on the room-facing (+Z) side.
    plate = (
        plate.faces(">Z")
        .workplane()
        .pushPoints([(0, p.screw_pitch / 2), (0, -p.screw_pitch / 2)])
        .cskHole(p.screw_hole_dia, p.screw_head_dia, p.csk_angle)
    )

    # Reinforcement boss around the spindle root.
    boss = cq.Workplane("XY").circle(p.boss_dia / 2).extrude(p.boss_len)

    # Straight spindle body.
    spindle = cq.Workplane("XY").circle(p.spindle_dia / 2).extrude(p.spindle_len)

    # Tip boss that the end cap grips.
    tip = (
        cq.Workplane("XY")
        .workplane(offset=p.spindle_len)
        .circle(p.tip_dia / 2)
        .extrude(p.tip_len)
    )

    part = plate.union(boss).union(spindle).union(tip)

    # Fillet the boss root against the plate for strength (best-effort).
    try:
        root_edges = part.edges(
            cq.selectors.BoxSelector((-100, -100, -0.5), (100, 100, 0.5))
        )
        part = root_edges.fillet(p.base_fillet)
    except Exception:
        pass

    # Chamfer the very tip so the end cap slides on easily (best-effort).
    try:
        part = part.faces(">Z").chamfer(1.2)
    except Exception:
        pass
    return part


def separator(p: Params = DEFAULT) -> cq.Workplane:
    """Disc that slides on the spindle to keep neighbouring rolls apart."""
    bore = p.spindle_dia + p.fit_clearance
    disc = (
        cq.Workplane("XY")
        .circle(p.sep_dia / 2)
        .circle(bore / 2)
        .extrude(p.sep_thickness)
    )
    # Light chamfer on the outer top/bottom edges for a clean look (best-effort).
    try:
        disc = disc.edges("%CIRCLE").chamfer(0.8)
    except Exception:
        pass
    return disc


def end_cap(p: Params = DEFAULT) -> cq.Workplane:
    """Spool-end push-on cap: a large flange (roll stop) + a central hub.

    The hub has a socket that friction-fits over the spindle tip boss.
    """
    socket_dia = p.tip_dia + 0.4  # friction fit over the tip boss
    flange = cq.Workplane("XY").circle(p.cap_flange_dia / 2).extrude(p.cap_flange_t)
    hub = (
        cq.Workplane("XY")
        .workplane(offset=p.cap_flange_t)
        .circle(p.cap_hub_dia / 2)
        .extrude(p.cap_hub_len)
    )
    cap = flange.union(hub)
    total = p.cap_flange_t + p.cap_hub_len
    # Socket bored up from the bottom (the face that goes onto the spindle).
    cap = (
        cap.faces("<Z")
        .workplane()
        .circle(socket_dia / 2)
        .cutBlind(total - p.cap_wall)
    )
    # Soften outer edges for a finished look (best-effort).
    try:
        cap = cap.faces(">Z").edges().fillet(2.5)
        cap = cap.edges("%CIRCLE").edges(">Z").chamfer(0.8)
    except Exception:
        pass
    return cap


def assembly(p: Params = DEFAULT) -> cq.Assembly:
    """Positioned assembly for visualisation (bracket + separators + cap)."""
    asm = cq.Assembly()
    asm.add(bracket(p), name="bracket", color=cq.Color(0.30, 0.45, 0.75))

    # Separators sit after each roll bay (except the last).
    z = 0.0
    for i in range(p.num_rolls - 1):
        z += p.bay
        asm.add(
            separator(p),
            name=f"separator_{i + 1}",
            loc=cq.Location(cq.Vector(0, 0, z)),
            color=cq.Color(0.85, 0.55, 0.20),
        )
        z += p.sep_thickness

    asm.add(
        end_cap(p),
        name="end_cap",
        loc=cq.Location(cq.Vector(0, 0, p.spindle_len)),
        color=cq.Color(0.75, 0.30, 0.30),
    )
    return asm
