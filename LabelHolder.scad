// =============================================================================
//  LabelHolder.scad  —  Compact 3-roll label holder (desk-edge clamp)
//  Parametric, FDM-oriented (PETG / PLA), support-free.
//
//  Frame convention:  X = width, Y = height (0 = bottom .. stand_h = top),
//                     Z = depth (front face at Z = 0, +Z = room/rolls,
//                     -Z = behind = desk side / hidden ribs).
//
//  Printable parts (each independent, print separately):
//     Stand()  - blade + hidden rear rib + edge clamp head + axle hub  (x1)
//     Clamp()  - recessed knurled clamp thumb-screw                    (x1)
//     Axle()   - Ø16 axle, inner roll-stop flange, bayonet ends        (x1)
//     Lock()   - bayonet end fixator / roll stop                       (x2)
//
//  Select what to render/export with the PART variable (see bottom), e.g.:
//     openscad -D 'PART="stand"' -o stand.stl LabelHolder.scad
// =============================================================================

PART = "assembly";   // "assembly" | "stand" | "clamp" | "axle" | "lock"

// -----------------------------------------------------------------------------
//  PARAMETERS  (all dimensions in mm)
// -----------------------------------------------------------------------------

// ---- rolls -------------------------------------------------------
roll_count      = 3;
roll_od_max     = 75;     // max roll outer diameter
core_id_min     = 50;     // min core (втулка) inner diameter
core_id_max     = 80;     // max core inner diameter

// ---- stand (blade) ----------------------------------------------
stand_h         = 220;    // total height
face_t          = 2.2;    // front face plate thickness (stays thin)
stand_w         = 26;     // width at the wide lobes
waist_w         = 18;     // width at the mid waist (gentle taper)

// ---- hidden rear rib (channel stiffener) ------------------------
rib_depth       = 14;     // how far the rib stands off the back
rib_w           = 2.6;    // rib wall thickness

// ---- long oval lightening cutout --------------------------------
oval_len        = 112;    // large leaf-shaped lightening cutout
oval_w          = 24;

// ---- split axle (for smaller print beds) ------------------------
// The 350 mm axle is longer than most beds; print it as two halves that
// join with a centre pin/socket inside the hub. Each half is ~180 mm.
coupler_d       = 9;      // centre coupling pin diameter
coupler_len     = 14;     // pin length / socket depth
coupler_clr     = 0.35;   // pin-in-socket clearance

// ---- axle + CENTRAL hub  (mount is at the CENTRE of the axle) -----
// The stand carries the axle at its mid-point; rolls sit on BOTH sides.
// This turns one 290 mm cantilever into two ~145 mm ones (deflection ~1/16).
axle_dia        = 16;     // spec: Ø16 (raise to reduce deflection)
axle_work       = 290;    // total clear roll span (both sides combined)
axle_end        = 14;     // spare axle past each end lug
bore_clr        = 0.6;    // radial fit clearance (bore vs axle)
hub_od          = 30;     // central hub outer diameter
hub_w           = 26;     // central hub length along the axle (X)
hub_y           = 46;     // axle height above the stand bottom
flange_dia      = core_id_max + 4;  // central roll-stop flanges (> max core)
flange_t        = 4;      // flange thickness (lens rim -> looks thin)

// ---- edge clamp --------------------------------------------------
desk_min        = 10;
desk_max        = 40;
clamp_reach     = 40;     // how far the clamp reaches over/under the desk
clamp_arm_t     = 6;      // hook / jaw thickness (slim)
clamp_open      = 44;     // clear opening (> desk_max) ; screw takes up slack

// ---- clamp screw (recessed, tool-free) --------------------------
screw_dia       = 9;      // major diameter
screw_crest     = 0.9;    // rounded thread crest
screw_pitch     = 3;      // coarse (prints & self-taps well)
screw_len       = 42;
screw_head_dia  = 17;     // knurled head (sits recessed in the jaw)
screw_head_h    = 7;
screw_z         = -clamp_reach*0.62;   // screw position under the desk

// ---- bayonet (compact, so the end caps can be small) -------------
lug_w           = 4;      // lug axial width
lug_h           = 2.2;    // lug radial height
lug_span        = 40;     // lug angular width (deg)
bay_entry       = 7;      // axial entry-slot depth
bay_lock        = 95;     // lock groove sweep (deg)

// ---- lock / fixator (small, elegant domed end knob) -------------
lock_knob_dia   = 26;     // small end-knob diameter (just caps the axle)
lock_knob_h     = 20;     // knob height (houses the compact bayonet socket)
end_stop_dia    = 0;      // 0 = no roll-stop flange (most elegant look).
                          // Set > core (e.g. 84) to positively retain rolls.
end_stop_t      = 3;

// ---- quality -----------------------------------------------------
FN              = 72;     // circle resolution (lower for a light STEP mesh)
screw_slice_mul = 12;     // helical slices per thread turn
THREADED        = true;   // false -> smooth shaft (used for a compact STEP)
$fn             = FN;
eps             = 0.05;

// ---- derived -----------------------------------------------------
each_side   = axle_work/2;                                  // roll span per side
axle_total  = hub_w + 2*flange_t + axle_work + 2*axle_end;  // full axle length
bore_d      = axle_dia + bore_clr;
bot_y       = hub_y;
strut_span  = stand_h - bot_y;
mid_y       = bot_y + 0.5*strut_span;                       // oval / body centre
top_y       = stand_h - stand_w/2;
jaw_top     = stand_h - clamp_arm_t - clamp_open;
clamp_head_w = 56;        // wide rounded head at the clamp (front view)

// -----------------------------------------------------------------------------
//  Parameters()  —  engineering summary (echoed to the console)
// -----------------------------------------------------------------------------
module Parameters() {
    I    = PI*pow(axle_dia,4)/64;                 // 2nd moment of area
    w    = 15/axle_work;                          // 1.5 kg UDL (N/mm)
    // centre mount -> each side is a ~each_side cantilever (balanced load)
    dPET = w*pow(each_side,4)/(8*2100*I);         // PETG per-side deflection
    dPLA = w*pow(each_side,4)/(8*3600*I);         // PLA  per-side deflection
    echo(str("[LabelHolder] axle I = ", round(I), " mm^4"));
    echo(str("[LabelHolder] centre-mount: 2 x ", each_side, " mm spans"));
    echo(str("[LabelHolder] per-side deflection @1.5kg : PETG ~", round(dPET*10)/10,
             " mm, PLA ~", round(dPLA*10)/10, " mm"));
    echo(str("[LabelHolder] axle total length = ", axle_total, " mm"));
}

// -----------------------------------------------------------------------------
//  Small helpers
// -----------------------------------------------------------------------------

// Rounded box (organic, large-radius) via minkowski.
module rbox(sz, r=3) {
    minkowski() {
        cube([max(sz[0]-2*r,0.01), max(sz[1]-2*r,0.01), max(sz[2]-2*r,0.01)],
             center=true);
        sphere(r=r, $fn=max(8, floor(FN/3)));
    }
}

// Disc with a fully rounded rim (elegant "lens" flange), centred on Z.
module rdisc(d, h, r) {
    minkowski() {
        cylinder(d=max(d-2*r, 0.1), h=max(h-2*r, 0.1), center=true);
        sphere(r=r, $fn=max(10, floor(FN/2)));
    }
}

// Smooth spherical-cap dome of base diameter d and height h, base at z=0.
module _dome(d, h) {
    r = d/2;
    scale([1, 1, h/r])
        intersection() {
            sphere(r=r, $fn=FN);
            translate([0, 0, 0]) cylinder(r=r, h=r);
        }
}

// 2D blade silhouette: a graceful organic "wishbone" — narrow foot, gentle
// body swell around the oval, wide rounded head at the clamp. Built by hulling
// a chain of control circles for smooth, large-radius transitions.
module _sil2D() {
    k = [
        [bot_y,                        hub_od + 2],   // foot (blends into hub)
        [bot_y + 0.22*strut_span,      30],
        [bot_y + 0.52*strut_span,      46],           // body swell (flanks oval)
        [bot_y + 0.80*strut_span,      40],
        [stand_h - clamp_head_w/2,     clamp_head_w], // rounded head, top=stand_h
    ];
    for (i = [0 : len(k) - 2])
        hull() {
            translate([0, k[i][0]])     circle(d = k[i][1]);
            translate([0, k[i+1][0]])   circle(d = k[i+1][1]);
        }
}

// Large leaf-shaped (elliptical) lightening cutout, centred on the body.
module _oval2D() {
    translate([0, mid_y]) resize([oval_w, oval_len]) circle(d = oval_len, $fn = 120);
}

// -----------------------------------------------------------------------------
//  Bayonet socket slots (axis = Z, opening at z = z_top).  Cut from a bored hub.
// -----------------------------------------------------------------------------
module _bayonet_slots(z_top) {
    br = bore_d/2;
    for (a = [0, 180]) rotate([0, 0, a]) {
        // axial entry channel
        translate([0, 0, z_top - bay_entry])
            rotate([0, 0, -lug_span/2])
            rotate_extrude(angle = lug_span)
                translate([br - 0.4, 0]) square([lug_h + 0.8, bay_entry + eps]);
        // circumferential locking groove
        translate([0, 0, z_top - bay_entry])
            rotate([0, 0, -bay_lock + lug_span/2])
            rotate_extrude(angle = bay_lock)
                translate([br - 0.4, 0]) square([lug_h + 0.8, lug_w + 0.8]);
    }
}

// Two bayonet lugs on an axle (axis = Z), centred at height z.
module _axle_lugs(z) {
    ar = axle_dia/2;
    for (a = [0, 180]) rotate([0, 0, a])
        translate([0, 0, z - lug_w/2])
            rotate([0, 0, -lug_span/2])
            rotate_extrude(angle = lug_span)
                translate([ar - 0.4, 0]) square([lug_h, lug_w]);
}

// =============================================================================
//  STAND  (blade + hidden rib + clamp head + hub)  — printed as one part
// =============================================================================

// Flat front face plate.
module _blade_face() {
    translate([0, 0, -face_t]) linear_extrude(face_t) _sil2D();
}

// Hidden rear perimeter rib (channel section) — the main stiffener.
module _blade_rib() {
    translate([0, 0, -rib_depth])
        linear_extrude(rib_depth - face_t)
            difference() { _sil2D(); offset(-rib_w) _sil2D(); }
}

// Edge-clamp head: top hook (over desk) + bottom jaw (under desk), blended.
module _clamp_head() {
    w = stand_w;
    top_arm_y = stand_h - clamp_arm_t/2;
    jaw_arm_y = jaw_top - clamp_arm_t/2;
    union() {
        // reinforced spine, blended into the blade with a large-radius flare
        hull() {
            translate([0, (jaw_top + stand_h)/2 - clamp_arm_t/2, -rib_depth/2])
                rbox([w, stand_h - jaw_top, rib_depth], 5);
            translate([0, jaw_top - 24, -rib_depth/2])
                rbox([waist_w + 6, 6, rib_depth], 5);
        }
        // top hook arm (over the desk), softly rounded
        hull() {
            translate([0, top_arm_y, -eps]) rbox([w, clamp_arm_t, 2], 3);
            translate([0, top_arm_y, -clamp_reach + clamp_arm_t])
                rbox([w, clamp_arm_t, 2], 3);
        }
        // gentle downturned lip at the hook tip (positive grip), rounded
        translate([0, stand_h - clamp_arm_t*0.9, -clamp_reach + clamp_arm_t/2])
            rbox([w, clamp_arm_t*1.8, clamp_arm_t], 3);
        // bottom jaw arm (under the desk), softly rounded
        hull() {
            translate([0, jaw_arm_y, -eps]) rbox([w, clamp_arm_t, 2], 3);
            translate([0, jaw_arm_y, -clamp_reach + clamp_arm_t])
                rbox([w, clamp_arm_t, 2], 3);
        }
    }
}

// CENTRAL hub: through-bore along X + two roll-stop flanges at the blade edges.
// The axle passes through and rolls sit on both sides against the flanges.
module _hub() {
    span = hub_w + 2*flange_t + 4;
    difference() {
        union() {
            // hub barrel (axis = X)
            translate([0, hub_y, 0]) rotate([0, 90, 0])
                cylinder(h=hub_w, d=hub_od, center=true);
            // two lens-rim roll-stop flanges at the blade edges (spool ends)
            for (sx = [-1, 1])
                translate([sx*hub_w/2, hub_y, 0]) rotate([0, 90, 0])
                    rdisc(flange_dia, flange_t, min(flange_t/2 - 0.2, 1.6));
            // large-radius blend from the barrel up into the blade
            hull() {
                translate([0, hub_y, -rib_depth/2 + eps])
                    rbox([stand_w, hub_od, rib_depth], 4);
                translate([0, hub_y + 30, -rib_depth/2 + eps])
                    rbox([waist_w + 4, 10, rib_depth], 4);
            }
        }
        // axle through-bore
        translate([0, hub_y, 0]) rotate([0, 90, 0])
            cylinder(h=span, d=bore_d, center=true);
    }
}

// Solid reinforced foot: fills the base so the hub joins the blade with no
// trapped voids (and stiffens the most-loaded region).
module _foot() {
    foot_top = hub_y + 30;
    translate([0, 0, -rib_depth]) linear_extrude(rib_depth)
        intersection() {
            _sil2D();
            translate([-200, -500]) square([400, 500 + foot_top]);
        }
}

module Stand() {
    difference() {
        union() {
            _blade_face();
            _blade_rib();
            _clamp_head();
            _foot();
            _hub();
        }
        // long oval lightening cutout (through the blade)
        translate([0, 0, -rib_depth - 1])
            linear_extrude(rib_depth + 2) _oval2D();
        // recessed clamp-screw pilot hole (self-tapping), axis = Y, in the jaw
        translate([0, jaw_top + 1, screw_z]) rotate([90, 0, 0])
            cylinder(h=clamp_arm_t + 2, d=screw_dia - 2*screw_crest);
        // hidden head recess on the underside of the jaw
        translate([0, jaw_top - clamp_arm_t + screw_head_h, screw_z])
            rotate([90, 0, 0])
            cylinder(h=screw_head_h + 1, d=screw_head_dia + 1);
    }
}

// =============================================================================
//  CLAMP  =  recessed knurled clamp thumb-screw  (printed separately)
// =============================================================================

// 2D thread profile: minor circle + rounded crest bump (single start).
module _screw_profile() {
    rminor = screw_dia/2 - screw_crest;
    union() {
        circle(r = rminor);
        translate([rminor, 0]) circle(r = screw_crest);
    }
}

module Clamp() {
    turns = screw_len/screw_pitch;
    union() {
        // helical rounded thread (twisted extrude — cheap, prints self-tapping).
        // THREADED=false gives a smooth shaft (used only for a compact STEP).
        if (THREADED)
            linear_extrude(height=screw_len, twist=-360*turns,
                           slices=ceil(turns)*screw_slice_mul, convexity=8)
                _screw_profile($fn=min(FN, 48));
        else
            cylinder(h=screw_len, d=screw_dia - screw_crest);
        // pressure pad tip
        translate([0, 0, -2]) cylinder(h=2.5, d=screw_dia - 2*screw_crest);
        // low-profile knurled head (stays recessed / barely visible)
        translate([0, 0, screw_len])
            union() {
                cylinder(h=screw_head_h, d=screw_head_dia);
                // shallow knurl flutes
                for (a=[0:20:359]) rotate([0,0,a])
                    translate([screw_head_dia/2, 0, screw_head_h/2])
                        cylinder(h=screw_head_h+eps, d=1.6, center=true, $fn=8);
            }
    }
}

// =============================================================================
//  AXLE  (Ø16 plain rod, bayonet lugs at BOTH ends for the two end fixators)
//  Passes through the central hub; rolls load on both sides.
// =============================================================================
module Axle() {
    lug_z = bay_entry - lug_w/2 + 2;      // lug position matching the fixator
    difference() {
        union() {
            cylinder(h=axle_total, d=axle_dia);          // rod
            _axle_lugs(lug_z);                           // one end
            _axle_lugs(axle_total - lug_z);              // other end
        }
        // 45deg lead-in chamfers at both ends (print + easy insertion)
        translate([0,0,-eps])
            cylinder(h=axle_dia/2, d1=axle_dia+2, d2=0);
        translate([0,0,axle_total+eps]) mirror([0,0,1])
            cylinder(h=axle_dia/2, d1=axle_dia+2, d2=0);
    }
}

// One split-axle half (axis = Z): outer end (z=0) takes a pebble cap; the
// centre end (z=L) has either a coupling pin (pin=true) or socket (pin=false).
axle_half_len = hub_w/2 + each_side + axle_end;   // centre -> outer end

module _axle_half(pin=true) {
    L = axle_half_len;
    lug_z = bay_entry - lug_w/2 + 2;              // outer-end lugs (for the cap)
    difference() {
        union() {
            cylinder(h=L, d=axle_dia);
            _axle_lugs(lug_z);
            if (pin) translate([0, 0, L - eps]) cylinder(h=coupler_len, d=coupler_d);
        }
        // centre socket (the non-pin half)
        if (!pin)
            translate([0, 0, L - coupler_len - coupler_clr])
                cylinder(h=coupler_len + coupler_clr + eps, d=coupler_d + coupler_clr);
        // outer-end lead-in chamfer
        translate([0, 0, -eps]) cylinder(h=3, d1=axle_dia + 2, d2=axle_dia - 3);
        // coupling lead-in chamfers
        if (pin)
            translate([0, 0, L + coupler_len + eps]) mirror([0,0,1])
                cylinder(h=1.6, d1=coupler_d + 1.4, d2=coupler_d - 0.8);
    }
}

module AxleA() { _axle_half(true);  }   // half with the coupling pin
module AxleB() { _axle_half(false); }   // half with the coupling socket

// =============================================================================
//  LOCK  =  bayonet end fixator / outer roll stop  (print x2)
// =============================================================================
// Smooth domed knob: Ø d, height h, flat base at z = 0 (a soft "pebble" cap).
module _knob(d, h) {
    cyl_h = max(h - d/2, 0.1);
    union() {
        cylinder(d=d, h=cyl_h);
        translate([0, 0, cyl_h]) _dome(d, d/2);   // hemispherical cap on top
    }
}

module Lock() {
    socket = bay_entry + lug_w + 1;          // compact bayonet socket
    has_stop = end_stop_dia > lock_knob_dia;
    knob_z   = has_stop ? end_stop_t - 1.2 : 0;
    difference() {
        union() {
            // optional thin roll-stop flange (inward face) — off by default
            if (has_stop)
                translate([0, 0, end_stop_t/2])
                    rdisc(end_stop_dia, end_stop_t, min(end_stop_t/2 - 0.2, 1.4));
            // small smooth domed knob (the elegant end cap)
            translate([0, 0, knob_z]) _knob(lock_knob_dia, lock_knob_h);
        }
        // bayonet socket, opening on the inward face (z = 0)
        translate([0, 0, -eps]) cylinder(h=socket + eps, d=bore_d);
        translate([0, 0, socket]) mirror([0, 0, 1]) _bayonet_slots(socket);
        // chamfer the mouth for easy engagement
        translate([0, 0, -eps]) cylinder(h=1.2, d1=bore_d + 2.0, d2=bore_d);
    }
}

// =============================================================================
//  ASSEMBLY  (for preview only; parts still print separately)
// =============================================================================
// Roll ghost (cylinder along X) at centre xc, width w.
module _roll_ghost_x(xc, w) {
    color([0.85, 0.8, 0.6, 0.25])
        translate([xc, hub_y, 0]) rotate([0, 90, 0])
            translate([0, 0, -w/2]) cylinder(h=w, d=roll_od_max);
}

module Assembly() {
    Stand();

    // axle through the central hub, centred on the stand (axis = X)
    color([0.8, 0.82, 0.85])
        translate([-axle_total/2, hub_y, 0]) rotate([0, 90, 0]) Axle();

    // roll ghosts filling BOTH sides of the centre flanges evenly
    // (example split of 3 rolls: one wide roll left, two rolls right)
    gap = hub_w/2 + flange_t + 2;
    _roll_ghost_x(-(gap + each_side/2), each_side - 8);   // left side (1 roll)
    rw = (each_side - 12)/2;                              // right side (2 rolls)
    _roll_ghost_x( gap + rw/2,           rw);
    _roll_ghost_x( gap + rw + 4 + rw/2,  rw);

    // two end fixators: domes face outward, openings toward the axle
    color([0.75, 0.77, 0.82]) translate([ axle_total/2, hub_y, 0]) rotate([0, 90, 0]) Lock();
    color([0.75, 0.77, 0.82]) translate([-axle_total/2, hub_y, 0]) rotate([0,-90,0]) Lock();
}

// Small-parts print plate: clamp screw + two pebble caps, laid out flat on one
// small bed and ready to slice (screw head down; caps dome-up).
module Accessories() {
    translate([-30, 0, screw_len + screw_head_h]) rotate([180, 0, 0]) Clamp();
    translate([ 16, -24, 0]) Lock();
    translate([ 16,  24, 0]) Lock();
}

// -----------------------------------------------------------------------------
//  DISPATCH
// -----------------------------------------------------------------------------
Parameters();

if      (PART == "stand")        Stand();
else if (PART == "clamp")        Clamp();
else if (PART == "axle")         Axle();        // full one-piece axle (~350 mm)
else if (PART == "axle_a")       AxleA();        // split half (pin)  — small beds
else if (PART == "axle_b")       AxleB();        // split half (socket)
else if (PART == "lock")         Lock();
else if (PART == "accessories")  Accessories();  // clamp + 2 caps on one plate
else                             Assembly();
