"""Parametric 3D-printable label-roll holder — "elegant centre-mount" design.

Reproduces the reference product sheet:
  * Elegant clamp-on-edge bracket (hooks over the desktop, tightened from
    below with a printed knurled screw), with an oval lightening cutout and a
    stiffening rim.
  * Removable Ø16 mm axle ("ось") that twist-locks into the bracket hub
    (bayonet) and carries up to 3 rolls (cores Ø50-80 mm).
  * Printed knurled clamp screw (tool-free), for desktops 10-40 mm thick.
  * Bayonet end fixator ("фиксатор оси", printed x2) that twist-locks onto the
    axle end and retains the rolls.

Everything is parametric — edit :class:`Spec` and re-run ``build.py``.

Modelling convention
--------------------
X = width, Y = depth (+Y points away from the wall, into the room),
Z = height. The desktop top surface is at Z = 0; the strut hangs down toward
negative Z, and the axle hub sits near the bottom pointing +Y.

Round "axial" parts (axle, hub socket, fixator) are modelled along +Z where
CadQuery is best behaved, then rotated into place for the assembly.
"""

from __future__ import annotations

from dataclasses import dataclass
from math import cos, pi, sin

import cadquery as cq


# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class Spec:
    # ---- rolls / axle ------------------------------------------------------
    num_rolls: int = 3
    core_id_min: float = 50.0
    core_id_max: float = 80.0
    axle_dia: float = 16.0
    axle_len: float = 286.0
    axle_working: float = 276.0

    # ---- strut / decorative panel -----------------------------------------
    strut_h: float = 220.0
    strut_top_w: float = 56.0
    strut_bottom_w: float = 26.0
    wall_t: float = 2.2
    rim_h: float = 6.0
    rim_w: float = 5.0
    oval_w: float = 12.0
    oval_h: float = 70.0

    # ---- edge clamp --------------------------------------------------------
    hook_depth: float = 18.0
    clamp_w: float = 44.0
    top_plate_t: float = 6.0
    desk_gap: float = 45.0
    jaw_t: float = 8.0
    jaw_depth: float = 24.0

    # ---- axle hub (bayonet socket) ----------------------------------------
    hub_od: float = 34.0
    hub_len: float = 30.0
    hub_z: float = 22.0
    fit_clr: float = 0.4

    # ---- bayonet -----------------------------------------------------------
    lug_w: float = 5.0
    lug_h: float = 2.5
    lug_pos: float = 8.0
    bay_entry: float = 11.0

    # ---- clamp screw -------------------------------------------------------
    screw_root_r: float = 5.0
    screw_crest: float = 1.6
    screw_pitch: float = 4.0
    screw_len: float = 52.0
    screw_facets: int = 44
    knob_dia: float = 30.0
    knob_h: float = 12.0
    knob_facets: int = 24

    # ---- fixator (end cap) -------------------------------------------------
    fix_flange_dia: float = 84.0
    fix_flange_t: float = 3.0
    fix_hub_dia: float = 30.0
    fix_hub_len: float = 14.0
    fix_facets: int = 22

    @property
    def bore_r(self) -> float:
        return self.axle_dia / 2 + self.fit_clr


DEFAULT = Spec()


# ---------------------------------------------------------------------------
# Thread helpers (robust single-op twistExtrude — meshes cleanly)
# ---------------------------------------------------------------------------
def _thread_profile(r_minor: float, crest: float, crest_ang_deg: float, n: int):
    from math import radians

    half = radians(crest_ang_deg) / 2.0
    pts = []
    for i in range(n):
        a = 2 * pi * i / n
        d = ((a + pi) % (2 * pi)) - pi
        bump = crest * (1 - abs(d) / half) if abs(d) < half else 0.0
        r = r_minor + bump
        pts.append((r * cos(a), r * sin(a)))
    return pts


def _threaded_solid(r_minor, crest, pitch, height, crest_ang=150.0, n=44):
    prof = _thread_profile(r_minor, crest, crest_ang, n)
    twist = 360.0 * height / pitch
    return cq.Workplane("XY").polyline(prof).close().twistExtrude(height, twist)


# ---------------------------------------------------------------------------
# Bayonet socket / lugs (all modelled along +Z, opening at the top face)
# ---------------------------------------------------------------------------
def _cut_bayonet_socket(part: cq.Workplane, s: Spec, face_z: float, depth: float):
    """Cut a Ø(bore) blind socket with two J-slots, opening at Z = face_z."""
    bore = s.bore_r
    slot_r = bore + s.lug_h + 0.4
    w = s.lug_w + 0.6
    part = part.cut(
        cq.Workplane("XY", origin=(0, 0, face_z)).circle(bore).extrude(-depth)
    )
    for ang in (0.0, 180.0):
        entry = (
            cq.Workplane("XY", origin=(0, 0, face_z))
            .transformed(rotate=(0, 0, ang))
            .center(bore - 0.2, 0)
            .rect(s.lug_h + 0.6, w, centered=(False, True))
            .extrude(-s.bay_entry)
        )
        part = part.cut(entry)
        try:
            groove = (
                cq.Workplane("XZ", origin=(0, 0, face_z - s.bay_entry + w / 2))
                .center(bore - 0.2, 0)
                .rect(s.lug_h + 0.6, w, centered=(False, True))
                .revolve(90.0, (0, 0, 0), (0, 0, 1))
                .rotate((0, 0, 0), (0, 0, 1), ang)
            )
            part = part.cut(groove)
        except Exception:
            pass
    return part


def _add_lugs(part: cq.Workplane, s: Spec, z_end: float, direction: int):
    """Add two radial bayonet lugs near an axle end (axle modelled along +Z)."""
    r = s.axle_dia / 2
    z_center = z_end + direction * s.lug_pos
    for ang in (0.0, 180.0):
        lug = (
            cq.Workplane("XY", origin=(0, 0, z_center - s.lug_w / 2))
            .transformed(rotate=(0, 0, ang))
            .center(r - 0.6, 0)
            .rect(s.lug_h + 0.6, s.lug_w, centered=(False, True))
            .extrude(s.lug_w)
        )
        part = part.union(lug)
    return part


# ---------------------------------------------------------------------------
# Parts
# ---------------------------------------------------------------------------
def _strut_silhouette(s: Spec):
    ht = s.strut_h
    # Reinforced (wider, solid) foot around the hub, slender neck, wide top.
    keys = [
        (0.0, 20.0),
        (0.18 * ht, 20.0),
        (0.34 * ht, 13.0),
        (0.52 * ht, 13.0),
        (0.74 * ht, 19.0),
        (0.92 * ht, 25.0),
        (ht, s.strut_top_w / 2),
    ]
    right = [(hw, z) for (z, hw) in keys]
    left = [(-hw, z) for (z, hw) in reversed(keys)]
    return cq.Workplane("XZ").spline(right + left).close()


def strut(s: Spec = DEFAULT) -> cq.Workplane:
    """Decorative shell panel with a stiffening rim and an oval cutout.

    Modelled in the XZ plane; note CadQuery extrudes "XZ" toward -Y, so the
    panel occupies Y in [-total_t, 0] and its flat back is at Y = 0.
    """
    total_t = s.wall_t + s.rim_h
    panel = _strut_silhouette(s).extrude(total_t)  # -> Y in [-total_t, 0]

    inner = _strut_silhouette(s).wires().toPending().offset2D(-s.rim_w)
    try:
        pocket = inner.extrude(s.rim_h)  # -> Y in [-rim_h, 0]
        # Keep the foot and the top solid; only lighten the mid region.
        z0, z1 = 0.26 * s.strut_h, 0.90 * s.strut_h
        limiter = cq.Workplane("XY").box(400, 400, z1 - z0).translate(
            (0, 0, (z0 + z1) / 2)
        )
        pocket = pocket.intersect(limiter)
        panel = panel.cut(pocket)
    except Exception:
        pass

    oval = (
        cq.Workplane("XZ", origin=(0, 0, s.strut_h * 0.52))
        .ellipse(s.oval_w / 2, s.oval_h / 2)
        .extrude(total_t + 2)
    )
    panel = panel.cut(oval)
    # Flip so the shell grows in +Y (front = room), flat back at Y = 0.
    return panel.mirror("XZ")


def clamp(s: Spec = DEFAULT) -> cq.Workplane:
    """Edge-clamp: top plate (hook) + lower jaw with a self-tap pilot hole."""
    top = s.strut_h
    cw = s.clamp_w
    top_plate = (
        cq.Workplane("XY")
        .box(cw, s.hook_depth + s.wall_t, s.top_plate_t, centered=(True, False, False))
        .translate((0, -s.hook_depth, top))
    )
    jaw_z = top - s.desk_gap
    jaw = (
        cq.Workplane("XY")
        .box(cw, s.jaw_depth + s.wall_t, s.jaw_t, centered=(True, False, False))
        .translate((0, -s.jaw_depth, jaw_z - s.jaw_t))
    )
    boss_r = s.screw_root_r + s.screw_crest + 4
    boss = (
        cq.Workplane("XY", origin=(0, -s.jaw_depth / 2, jaw_z - s.jaw_t))
        .circle(boss_r)
        .extrude(-14)
    )
    body = top_plate.union(jaw).union(boss)

    pilot_r = s.screw_root_r + s.screw_crest * 0.35
    hole = (
        cq.Workplane("XY", origin=(0, -s.jaw_depth / 2, jaw_z - s.jaw_t - 14 - 1))
        .circle(pilot_r)
        .extrude(s.jaw_t + 16 + 3)
    )
    return body.cut(hole)


def _hub_z(s: Spec) -> cq.Workplane:
    """Hub cylinder with a bayonet socket, modelled along +Z (opening at top)."""
    h = cq.Workplane("XY").circle(s.hub_od / 2).extrude(s.hub_len)
    return _cut_bayonet_socket(h, s, face_z=s.hub_len, depth=s.bay_entry + s.lug_w + 6)


def hub(s: Spec = DEFAULT) -> cq.Workplane:
    """Hub oriented for the bracket: pointing +Y at height ``hub_z``."""
    return (
        _hub_z(s)
        .rotate((0, 0, 0), (1, 0, 0), -90)  # +Z -> +Y
        .translate((0, 1.0, s.hub_z))  # embed 1 mm into the solid foot
    )


def bracket(s: Spec = DEFAULT) -> cq.Workplane:
    """Full bracket = strut + edge clamp + axle hub (single print)."""
    return strut(s).union(clamp(s)).union(hub(s))


def axle(s: Spec = DEFAULT) -> cq.Workplane:
    """Ø16 axle (along +Z): inner shoulder (roll stop) + bayonet lugs each end."""
    rod = cq.Workplane("XY").circle(s.axle_dia / 2).extrude(s.axle_len)
    shoulder = (
        cq.Workplane("XY", origin=(0, 0, 18))
        .circle(s.fix_flange_dia / 2)
        .extrude(s.fix_flange_t)
    )
    part = rod.union(shoulder)
    part = _add_lugs(part, s, z_end=0.0, direction=+1)
    part = _add_lugs(part, s, z_end=s.axle_len, direction=-1)
    try:
        part = part.faces(">Z").chamfer(1.2)
        part = part.faces("<Z").chamfer(1.2)
    except Exception:
        pass
    return part


def clamp_screw(s: Spec = DEFAULT) -> cq.Workplane:
    """Printed knurled thumb-screw for the edge clamp."""
    shaft = _threaded_solid(
        s.screw_root_r, s.screw_crest, s.screw_pitch, s.screw_len, n=s.screw_facets
    )
    knob = (
        cq.Workplane("XY", origin=(0, 0, s.screw_len))
        .polygon(s.knob_facets, s.knob_dia)
        .extrude(s.knob_h)
    )
    pad = cq.Workplane("XY").circle(s.screw_root_r).extrude(-3)
    part = shaft.union(knob).union(pad)
    try:
        part = part.faces(">Z").fillet(2.0)
    except Exception:
        pass
    return part


def fixator(s: Spec = DEFAULT) -> cq.Workplane:
    """Bayonet end cap (along +Z): flange (roll stop) + hub with bayonet socket."""
    flange = (
        cq.Workplane("XY").polygon(s.fix_facets, s.fix_flange_dia).extrude(s.fix_flange_t)
    )
    hub_cap = (
        cq.Workplane("XY", origin=(0, 0, s.fix_flange_t))
        .circle(s.fix_hub_dia / 2)
        .extrude(s.fix_hub_len)
    )
    cap = flange.union(hub_cap)
    total = s.fix_flange_t + s.fix_hub_len
    return _cut_bayonet_socket(cap, s, face_z=total, depth=s.bay_entry + s.lug_w + 3)


# ---------------------------------------------------------------------------
def assembly(s: Spec = DEFAULT) -> cq.Assembly:
    asm = cq.Assembly()
    asm.add(bracket(s), name="bracket", color=cq.Color(0.90, 0.90, 0.92))

    ax_off = s.hub_len - 14
    axle_p = axle(s).rotate((0, 0, 0), (1, 0, 0), -90)  # +Z -> +Y
    asm.add(
        axle_p,
        name="axle",
        loc=cq.Location(cq.Vector(0, ax_off, s.hub_z)),
        color=cq.Color(0.82, 0.82, 0.86),
    )

    tip_y = ax_off + s.axle_len
    fix_p = fixator(s).rotate((0, 0, 0), (1, 0, 0), 90)  # opening faces -Y
    asm.add(
        fix_p,
        name="fixator",
        loc=cq.Location(cq.Vector(0, tip_y, s.hub_z)),
        color=cq.Color(0.72, 0.74, 0.80),
    )
    return asm
