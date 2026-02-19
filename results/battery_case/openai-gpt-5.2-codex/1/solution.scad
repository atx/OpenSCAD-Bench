// Battery case for 4 Olympus BLS-5 batteries
$fn = 64;

// Battery dimensions
battery_w = 36;   // width (mm)
battery_t = 13;   // thickness (mm)
battery_h = 56;   // height (mm)

// Clearances
clearance = 0.6;  // total clearance

// Slot footprint oriented so batteries face each other with largest face
slot_x = battery_t + clearance; // along row (thickness)
slot_y = battery_w + clearance; // across (width)
slot_h = battery_h + 1;         // extra headroom

// Case parameters
wall = 2;
bottom = 2;

// Snap bump parameters
bump_w = slot_x - 3;  // width of bump along X
bump_t = 1;           // protrusion into cavity
bump_h = 2;
bump_offset = 1.5;    // below top

// Finger hole
finger_r = 6;

// Overall case dimensions
case_len = 4*slot_x + 5*wall;  // along X
case_dep = slot_y + 2*wall;    // along Y
case_hgt = bottom + slot_h;    // along Z

module slot_cavity(x0) {
    translate([x0, wall, bottom])
        cube([slot_x, slot_y, slot_h], center=false);
}

module finger_hole(x0) {
    translate([x0 + slot_x/2, wall + slot_y/2, 0])
        cylinder(h = bottom + 0.5, r = finger_r, center=false);
}

module snap_bumps(x0) {
    // two bumps on long sides (along Y)
    z0 = bottom + slot_h - bump_h - bump_offset;
    x_center = x0 + slot_x/2 - bump_w/2;
    // front side
    translate([x_center, wall, z0])
        cube([bump_w, bump_t, bump_h], center=false);
    // back side
    translate([x_center, wall + slot_y - bump_t, z0])
        cube([bump_w, bump_t, bump_h], center=false);
}

// Build the case
union() {
    difference() {
        // outer shell
        cube([case_len, case_dep, case_hgt], center=false);
        // cavities and finger holes
        for (i = [0:3]) {
            x0 = wall + i*(slot_x + wall);
            slot_cavity(x0);
            finger_hole(x0);
        }
    }
    // add snap bumps
    for (i = [0:3]) {
        x0 = wall + i*(slot_x + wall);
        snap_bumps(x0);
    }
}
