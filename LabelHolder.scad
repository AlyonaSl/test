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
oval_len        = 120;
oval_w          = 10;

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
flange_t        = 3;      // flange thickness

// ---- edge clamp --------------------------------------------------
desk_min        = 10;
desk_max        = 40;
clamp_reach     = 40;     // how far the clamp reaches over/under the desk
clamp_arm_t     = 7;      // hook / jaw thickness
clamp_open      = 44;     // clear opening (> desk_max) ; screw takes up slack

// ---- clamp screw (recessed, tool-free) --------------------------
screw_dia       = 9;      // major diameter
screw_crest     = 0.9;    // rounded thread crest
screw_pitch     = 3;      // coarse (prints & self-taps well)
screw_len       = 42;
screw_head_dia  = 17;     // knurled head (sits recessed in the jaw)
screw_head_h    = 7;
screw_z         = -clamp_reach*0.62;   // screw position under the desk

// ---- bayonet -----------------------------------------------------
lug_w           = 5;      // lug axial width
lug_h           = 2.6;    // lug radial height
lug_span        = 40;     // lug angular width (deg)
bay_entry       = 10;     // axial entry-slot depth
bay_lock        = 95;     // lock groove sweep (deg)

// ---- lock / fixator ---------------------------------------------
lock_flange_dia = 84;     // outer roll stop (> core_id_max)
lock_flange_t   = 3;
lock_grip_dia   = 30;
lock_grip_h     = 15;

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
top_y       = stand_h - stand_w/2;
mid_y       = (hub_y + stand_h)/2;
bot_y       = hub_y;
jaw_top     = stand_h - clamp_arm_t - clamp_open;

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
        sphere(r=r, $fn=max(12, floor(FN/3)));
    }
}

// 2D blade silhouette: two hulled lobes with a gentle waist (organic bone).
module _sil2D() {
    union() {
        hull() {
            translate([0, top_y]) circle(d=stand_w);
            translate([0, mid_y]) circle(d=waist_w);
        }
        hull() {
            translate([0, mid_y]) circle(d=waist_w);
            translate([0, bot_y]) circle(d=hub_od+4);
        }
    }
}

// 2D long oval cutout.
module _oval2D() {
    hull() {
        translate([0, mid_y - oval_len/2 + oval_w/2]) circle(d=oval_w);
        translate([0, mid_y + oval_len/2 - oval_w/2]) circle(d=oval_w);
    }
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
        // reinforced spine (locally thick to full rib depth, big radii)
        translate([0, (jaw_top + stand_h)/2 - clamp_arm_t/2, -rib_depth/2])
            rbox([w, stand_h - jaw_top, rib_depth], 4);
        // top hook arm, reaching over the desk (-Z)
        translate([0, top_arm_y, -clamp_reach/2 + eps])
            rbox([w, clamp_arm_t, clamp_reach], 3);
        // small downward lip at the hook tip (positive grip on the top edge)
        translate([0, stand_h - clamp_arm_t, -clamp_reach + clamp_arm_t/2])
            rbox([w, clamp_arm_t*1.6, clamp_arm_t], 3);
        // bottom jaw arm, reaching under the desk (-Z)
        translate([0, jaw_arm_y, -clamp_reach/2 + eps])
            rbox([w, clamp_arm_t, clamp_reach], 3);
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
            // two roll-stop flanges at the blade edges (spool ends)
            for (sx = [-1, 1])
                translate([sx*hub_w/2, hub_y, 0]) rotate([0, 90, 0])
                    cylinder(h=flange_t, d=flange_dia, center=true);
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

// =============================================================================
//  LOCK  =  bayonet end fixator / outer roll stop  (print x2)
// =============================================================================
module Lock() {
    total = lock_flange_t + lock_grip_h;
    difference() {
        union() {
            cylinder(h=lock_flange_t, d=lock_flange_dia);          // roll stop
            translate([0, 0, lock_flange_t])                       // grip
                cylinder(h=lock_grip_h, d=lock_grip_dia);
            // soft grip flutes
            for (a=[0:24:359]) rotate([0,0,a])
                translate([lock_grip_dia/2, 0, lock_flange_t + lock_grip_h/2])
                    cylinder(h=lock_grip_h, d=1.6, center=true, $fn=8);
        }
        // socket + bayonet from the top (axle tip enters here)
        translate([0, 0, total - (bay_entry + lug_w + 4)])
            cylinder(h=bay_entry + lug_w + 5, d=bore_d);
        _bayonet_slots(total);
        // chamfer the mouth
        translate([0,0,total-1.2]) cylinder(h=1.3, d1=bore_d, d2=bore_d+2.4);
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

    // two end fixators, openings facing inward toward the axle
    color([0.75, 0.77, 0.82]) translate([ axle_total/2, hub_y, 0]) rotate([0,-90,0]) Lock();
    color([0.75, 0.77, 0.82]) translate([-axle_total/2, hub_y, 0]) rotate([0, 90, 0]) Lock();
}

// -----------------------------------------------------------------------------
//  DISPATCH
// -----------------------------------------------------------------------------
Parameters();

if      (PART == "stand")    Stand();
else if (PART == "clamp")    Clamp();
else if (PART == "axle")     Axle();
else if (PART == "lock")     Lock();
else                         Assembly();
