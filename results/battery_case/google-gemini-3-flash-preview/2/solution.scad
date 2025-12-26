// Case for 4 Olympus BLS-5 batteries (56 x 36 x 13 mm)
// Linear 4x1 arrangement, upright on thin edge (13x36)

batt_w = 36;
batt_t = 13;
batt_h = 56;

// Tolerances and wall thickness
clearance = 0.8; // Generous clearance for 3D printing
wall = 2.4;     // Stronger walls

// Slot dimensions (internal)
slot_w = batt_w + clearance;
slot_t = batt_t + clearance;
slot_h = 35; // Depth of the slot (batteries stick out for removal)

num_batt = 4;

// Case overall dimensions
case_w = slot_w + 2 * wall;
case_l = (num_batt * slot_t) + ((num_batt + 1) * wall);
case_h = slot_h + wall; // Add floor thickness

module battery_case() {
    difference() {
        // Main outer body
        cube([case_w, case_l, case_h]);

        // Cutouts for batteries and features
        for (i = [0 : num_batt - 1]) {
            y_pos = wall + i * (slot_t + wall);
            
            // 1. The battery slot
            translate([wall, y_pos, wall])
                cube([slot_w, slot_t, slot_h + 10]);
            
            // 2. Finger hole in the bottom for pushing batteries up
            translate([case_w / 2, y_pos + slot_t / 2, -1])
                cylinder(h = wall + 2, d = 14, $fn = 50);
                
            // 3. Side cutouts for easier grasping (U-shape)
            // Cutout through the sides of the case
            translate([-1, y_pos + (slot_t/2) - 8, case_h - 10])
                cube([case_w + 2, 16, 12]);
        }
    }
    
    // Snap-fit bumps
    // These are small hemispherical bumps inside the slots to provide friction/click
    for (i = [0 : num_batt - 1]) {
        y_pos = wall + i * (slot_t + wall);
        
        // Front and back face bumps (on the large faces of the battery)
        // Adjusting positions to be inside the slot
        
        // Bump on one side wall of slot
        translate([wall + slot_w/2, y_pos + 0.3, case_h - 4])
            sphere(d = 1.6, $fn = 20);
            
        // Bump on opposing side wall of slot
        translate([wall + slot_w/2, y_pos + slot_t - 0.3, case_h - 4])
            sphere(d = 1.6, $fn = 20);
    }
}

// Render the case
battery_case();
