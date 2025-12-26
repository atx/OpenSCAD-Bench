// Olympus BLS-5 Battery Case
// 4-slot linear holder with snap-fit tabs and finger holes for removal

// Battery dimensions (mm)
battery_height = 56;
battery_width = 36;
battery_thickness = 13;

// Design parameters
clearance_x = 0.8;         // side-to-side clearance
clearance_y = 0.8;         // front-back clearance between batteries
wall_thickness = 2.8;      // outer wall thickness
partition_thickness = 1.6; // walls between slots
base_thickness = 3;        // bottom thickness
top_clearance = 3;         // space above battery for snap-fit area

// Derived dimensions
slot_width = battery_width + 2 * clearance_x;
slot_length = battery_thickness + clearance_y;
case_height = base_thickness + battery_height + top_clearance;
outer_x = slot_width + 2 * wall_thickness;
outer_y = 4 * slot_length + 3 * partition_thickness + 2 * wall_thickness;
slot_height = case_height - base_thickness; // extends up to open top (no lid)

module battery_slots() {
    for (i = [0:3]) {
        translate([
            wall_thickness,
            wall_thickness + i * (slot_length + partition_thickness),
            base_thickness
        ])
        cube([slot_width, slot_length, slot_height], center = false);
    }
}

module finger_holes() {
    hole_width = slot_width - 3;
    hole_length = slot_length - 3;
    hole_height = base_thickness;

    for (i = [0:3]) {
        slot_y = wall_thickness + i * (slot_length + partition_thickness);
        translate([
            wall_thickness + (slot_width - hole_width) / 2,
            slot_y + (slot_length - hole_length) / 2,
            0
        ])
        cube([hole_width, hole_length, hole_height], center = false);
    }
}

module snap_tabs() {
    tab_protrusion = 1.6;
    tab_overlap = 0.5;
    tab_length = max(slot_length - 3, 6);
    tab_height = 6;
    tab_z = base_thickness + slot_height - tab_height - 0.7;

    for (i = [0:3]) {
        slot_y = wall_thickness + i * (slot_length + partition_thickness);
        tab_y = slot_y + (slot_length - tab_length) / 2;

        // Left tab
        translate([
            wall_thickness - tab_overlap,
            tab_y,
            tab_z
        ])
        cube([tab_protrusion + tab_overlap, tab_length, tab_height], center = false);

        // Right tab
        translate([
            wall_thickness + slot_width - tab_protrusion,
            tab_y,
            tab_z
        ])
        cube([tab_protrusion + tab_overlap, tab_length, tab_height], center = false);
    }
}

// Main case geometry
difference() {
    // Outer shell
    cube([outer_x, outer_y, case_height], center = false);
    // Subtract the battery cavities
    battery_slots();
    // Subtract finger holes at the bottom for removal
    finger_holes();
}

// Add the snap-fit tabs after the subtraction so they remain
snap_tabs();
