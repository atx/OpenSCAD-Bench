// =============================================
// Wall-mounted Towel Hook
// M3 flat head screw mounting
// Robust design for heavy towels
// Print: plate flat on bed, hook up
// =============================================

$fn = 100;

// === Dimensions ===
// Mounting plate
plate_w    = 34;
plate_h    = 55;
plate_t    = 5;
plate_r    = 5;

// Hook body
hook_w     = 22;       // Width of the hook arm
hook_len   = 32;       // Arm extension from wall
hook_t     = 8;        // Arm thickness (strong)
curve_r    = 13;       // Inner radius of J-curve
tip_len    = 20;       // Anti-slip tip length
tip_angle  = 12;       // Tip lean-back angle (degrees)
arm_z      = 5;        // Bottom of arm above plate bottom

// Structural reinforcement
gusset_along = 18;     // Gusset extent along arm
gusset_up    = 22;     // Gusset extent up the plate

// M3 Flat head screw
m3_shaft_d  = 3.4;     // Clearance
m3_head_d   = 6.8;     // Head diameter
m3_sink     = 2.0;     // Countersink depth
screw_z     = plate_h - 15;

// === Wall Plate ===
module wall_plate() {
    translate([0, plate_t/2, plate_h/2])
    rotate([90, 0, 0])
    linear_extrude(plate_t, center=true)
        offset(plate_r) offset(-plate_r)
            square([plate_w, plate_h], center=true);
}

// === Screw Hole with Countersink ===
module screw_hole() {
    translate([0, 0, screw_z]) {
        // Shaft through-hole
        rotate([-90, 0, 0])
            translate([0, 0, -0.5])
                cylinder(d=m3_shaft_d, h=plate_t + 1);
        // Countersink on back (y=0 face)
        rotate([-90, 0, 0])
            translate([0, 0, -0.01])
                cylinder(d1=m3_head_d, d2=m3_shaft_d, h=m3_sink);
    }
}

// === J-Hook 2D Profile (YZ plane) ===
module hook_2d() {
    ro = curve_r + hook_t/2;
    ri = curve_r - hook_t/2;
    cy = plate_t + hook_len;       // Curve center Y
    cz = arm_z + hook_t/2;        // Curve center Z

    // Straight arm
    translate([plate_t, arm_z])
        square([hook_len, hook_t]);

    // 180° curve
    translate([cy, cz])
    difference() {
        circle(r=ro);
        circle(r=ri);
        translate([-ro-1, 0]) square([2*ro+2, ro+1]);
    }

    // Anti-slip tip curving upward
    ty = cy;
    tz = cz - ro;
    translate([ty, tz])
    rotate(180 + tip_angle) {
        translate([-hook_t/2, 0])
            square([hook_t, tip_len]);
        translate([0, tip_len])
            circle(d=hook_t);
    }
}

module hook_body() {
    rotate([90, 0, 90])
    translate([0, 0, -hook_w/2])
    linear_extrude(hook_w)
        hook_2d();
}

// === Reinforcement ===
module reinforcement() {
    at = arm_z + hook_t;
    flare = (plate_w - hook_w) / 2;

    // Upper gusset triangle (full hook width)
    translate([-hook_w/2, plate_t, at])
    rotate([0, 90, 0])
    linear_extrude(hook_w)
        polygon([[0,0], [0, gusset_along], [-gusset_up, 0]]);

    // Lower fill + mini gusset
    translate([-hook_w/2, plate_t, 0])
        cube([hook_w, 5, arm_z]);

    translate([-hook_w/2, plate_t, 0])
    rotate([0, 90, 0])
    linear_extrude(hook_w)
        polygon([[0,0], [0, 5], [arm_z, 0]]);

    // Side flare wings (blend hook width to plate width)
    for (s = [-1, 1]) {
        mirror_x = s > 0 ? 0 : 1;
        mirror([mirror_x, 0, 0])
        hull() {
            // At hook edge, goes up most of gusset
            translate([hook_w/2, plate_t, 0])
                cube([0.01, gusset_along * 0.35, at + gusset_up * 0.5]);
            // At plate edge, tall but thin
            translate([plate_w/2 - 1.5, plate_t/2, 0])
                cube([1.5, plate_t/2 + 0.01, at + gusset_up * 0.65]);
        }
    }
}

// === Final Assembly ===
difference() {
    union() {
        wall_plate();
        hook_body();
        reinforcement();
    }
    screw_hole();

    // Trim behind wall (y < 0)
    translate([-60, -60, -10])
        cube([120, 60, 100]);
}
