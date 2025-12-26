// Olympus BLS-5 battery case (4x1) with snap-fit tabs and finger holes
battery_length = 56;
battery_width = 36;
battery_height = 13;

slot_clearance = 0.6;                    // small clearance for insertion
wall_thickness = 3;
base_thickness = 3;
top_clearance = 2;
slot_length_clearance = 1.0;
num_slots = 4;

inner_slot_width = battery_width + slot_clearance;
slot_length = battery_length + slot_length_clearance;
outer_length = num_slots*inner_slot_width + (num_slots + 1)*wall_thickness;
outer_width = slot_length + 2*wall_thickness;
outer_height = base_thickness + battery_height + top_clearance;

finger_hole_depth = 10;
finger_hole_length = 30;
finger_hole_width = 12;

// Snap-fit tab dimensions
tab_width = 12;
tab_length = 10;
tab_height = 6;
lip_thickness = 1.5;
lip_width = tab_width - 2;
lip_length = tab_length - 2;

module case_body() {
    difference() {
        // Outer shell
        cube([outer_length, outer_width, outer_height], center=false);

        // Battery cavities and finger holes
        for (slot_idx = [0 : num_slots - 1]) {
            let (slot_x = wall_thickness + slot_idx*(inner_slot_width + wall_thickness)) {
                // Slot cavity
                translate([slot_x, wall_thickness, base_thickness])
                    cube([inner_slot_width, slot_length, battery_height + top_clearance], center=false);

                // Finger hole from bottom
                translate([
                    slot_x + (inner_slot_width - finger_hole_width)/2,
                    wall_thickness + (slot_length - finger_hole_length)/2,
                    0
                ])
                    cube([finger_hole_width, finger_hole_length, finger_hole_depth], center=false);
            }
        }
    }
}

module snap_tab(slot_x, y_start) {
    let (tab_x = slot_x + (inner_slot_width - tab_width)/2,
         z_bottom = outer_height - tab_height) {
        union() {
            translate([tab_x, y_start, z_bottom])
                cube([tab_width, tab_length, tab_height], center=false);
            translate([
                tab_x + (tab_width - lip_width)/2,
                y_start + (tab_length - lip_length)/2,
                z_bottom - lip_thickness
            ])
                cube([lip_width, lip_length, lip_thickness], center=false);
        }
    }
}

module snap_tabs() {
    for (slot_idx = [0 : num_slots - 1]) {
        let (slot_x = wall_thickness + slot_idx*(inner_slot_width + wall_thickness)) {
            front_y = wall_thickness + 2;
            back_y = wall_thickness + slot_length - tab_length - 2;
            snap_tab(slot_x, front_y);
            snap_tab(slot_x, back_y);
        }
    }
}

// Final assembly
union() {
    case_body();
    snap_tabs();
}
