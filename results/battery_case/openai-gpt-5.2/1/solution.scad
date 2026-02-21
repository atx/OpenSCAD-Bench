// Olympus BLS-5 (generic) 4x1 battery case
// 3D-printable, single piece, open-top with bottom finger holes and simple snap lips.
// Units: mm

$fn = 64;

// --- Battery nominal dimensions ---
batt_h = 56;   // standing height
batt_w = 36;   // wide face width
batt_t = 13;   // thickness

// --- Fit / print parameters ---
clear_x = 0.6;   // total clearance in thickness direction
clear_y = 0.9;   // total clearance in width direction
clear_z = 1.2;   // extra height clearance

wall = 2.2;       // outer wall thickness
divider = 1.6;    // internal walls between slots
bottom_th = 2.2;  // bottom thickness

// Snap lips (small compliant lips on front/back walls)
lip_depth = 0.50; // protrusion into slot (each side)
lip_h = 2.2;      // vertical height of lip
lip_ramp_h = 1.2; // underside ramp height to ease insertion
lip_z_from_bottom = bottom_th + batt_h - 0.8; // start just below battery top

// Finger hole (through bottom) as rounded rectangle
finger_x = 10;
finger_y = 26;
finger_r = 5;

// Derived slot size (internal cavity)
slot_x = batt_t + clear_x;
slot_y = batt_w + clear_y;
slot_h = batt_h + clear_z;

// Overall case size
case_x = 2*wall + 4*slot_x + 3*divider;
case_y = 2*wall + slot_y;
case_z = bottom_th + slot_h + 3.0; // extra rim height above battery

// -------------------- Helpers --------------------
module rounded_rect_2d(x, y, r) {
    r2 = min(r, x/2, y/2);
    hull() {
        for (sx=[-1,1]) for (sy=[-1,1])
            translate([sx*(x/2 - r2), sy*(y/2 - r2)]) circle(r=r2);
    }
}

module finger_hole_3d(h) {
    linear_extrude(height=h)
        rounded_rect_2d(finger_x, finger_y, finger_r);
}

module slot_cavity() {
    // Tall cube to ensure we cut fully to the top
    translate([0, 0, bottom_th]) cube([slot_x, slot_y, case_z], center=false);
}

module slot_finger_cut() {
    // Through-hole from underside, centered in the slot
    translate([slot_x/2, slot_y/2, -0.1])
        finger_hole_3d(bottom_th + 0.35);
}

module wedge_prism_x(len_x, depth_y, height_z) {
    // Triangular prism whose cross-section in YZ is:
    // (0,0) -> (depth_y,0) -> (depth_y,height_z)
    polyhedron(
        points=[
            [0,      0,        0],
            [len_x,  0,        0],
            [len_x,  depth_y,  0],
            [0,      depth_y,  0],
            [0,      depth_y,  height_z],
            [len_x,  depth_y,  height_z]
        ],
        faces=[
            [0,1,2,3],   // bottom
            [0,1,5,4],   // slanted
            [3,2,5,4],   // back rectangle
            [0,3,4],     // x=0 triangle
            [1,2,5]      // x=len triangle
        ]
    );
}

module lip_with_ramp(front=true) {
    // Local coordinates: x along slot, y across lip depth (towards cavity), z up.
    // For front lip: wall at y=0, cavity towards +y => ramp high at y=lip_depth.
    // For back  lip: cavity at y=0, wall towards +y => ramp high at y=0.

    difference() {
        cube([slot_x, lip_depth, lip_h], center=false);
        if (front) {
            // remove wedge to create underside ramp rising toward y=lip_depth
            wedge_prism_x(slot_x, lip_depth, lip_ramp_h);
        } else {
            // mirrored ramp: high at y=0
            translate([0, lip_depth, 0]) mirror([0,1,0])
                wedge_prism_x(slot_x, lip_depth, lip_ramp_h);
        }
    }
}

module slot_lips() {
    // Two opposing lips (front/back) near the top of the slot.
    translate([0, 0, lip_z_from_bottom])
        lip_with_ramp(front=true);

    translate([0, slot_y - lip_depth, lip_z_from_bottom])
        lip_with_ramp(front=false);
}

module one_slot_cuts(i) {
    x0 = wall + i*(slot_x + divider);
    y0 = wall;

    translate([x0, y0, 0]) slot_cavity();
    translate([x0, y0, 0]) slot_finger_cut();
}

module one_slot_lips(i) {
    x0 = wall + i*(slot_x + divider);
    y0 = wall;
    translate([x0, y0, 0]) slot_lips();
}

// -------------------- Model --------------------

union() {
    difference() {
        // Outer solid
        cube([case_x, case_y, case_z], center=false);

        // Remove 4 slot cavities and bottom finger holes
        for (i=[0:3]) one_slot_cuts(i);

        // Simple top relief to ease insertion / reduce sharp rim
        chamfer_h = 2.0;
        chamfer_out = 0.8;
        translate([wall - chamfer_out, wall - chamfer_out, case_z - chamfer_h])
            cube([case_x - 2*(wall - chamfer_out), case_y - 2*(wall - chamfer_out), chamfer_h + 0.2], center=false);
    }

    // Add snap lips back in
    for (i=[0:3]) one_slot_lips(i);
}
