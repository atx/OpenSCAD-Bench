// Battery dimensions: 56 x 36 x 13
// Arrangement: 4x1 linear, standing on 36x13 face, largest faces (56x36) facing each other.

battery_w = 36.8; // Width (slightly oversized for fit)
battery_d = 13.8; // Depth (slightly oversized for fit)
battery_h = 56.0; // Total battery height

wall = 2.0;       // Wall thickness
base_h = 3.0;     // Base thickness
holder_h = 30;    // Height of the case walls

finger_hole_r = 8;
snap_r = 1.0;     // Small bump for snap fit

num_batteries = 4;

module battery_slot() {
    // Main cavity
    translate([-battery_w/2, -battery_d/2, 0.01])
        cube([battery_w, battery_d, holder_h + 1]);
    
    // Finger hole through the bottom
    translate([0, 0, -base_h - 1])
        cylinder(h = base_h + 2, r = finger_hole_r, $fn=32);
        
    // Snap bumps (on the large faces: battery_w x battery_h faces)
    // We place them near the top edge of the holder to grip the side of the battery
    bump_offset_y = battery_d/2;
    bump_z = holder_h - 5;
    
    translate([0, bump_offset_y, bump_z])
        scale([1, 0.6, 1]) sphere(r = snap_r, $fn=16);
    translate([0, -bump_offset_y, bump_z])
        scale([1, 0.6, 1]) sphere(r = snap_r, $fn=16);
}

module battery_case() {
    total_w = battery_w + 2 * wall;
    // Arrangement: wall - batt1 - wall - batt2 - wall - batt3 - wall - batt4 - wall
    total_d = (battery_d * num_batteries) + (wall * (num_batteries + 1));
    total_h = holder_h;

    difference() {
        // Main block
        translate([-total_w/2, -total_d/2, -base_h])
            cube([total_w, total_d, total_h + base_h]);
        
        // Subtract slots
        for (i = [0 : num_batteries - 1]) {
            y_pos = -total_d/2 + wall + battery_d/2 + i * (battery_d + wall);
            translate([0, y_pos, 0])
                battery_slot();
        }
        
        // Side cutouts for weight reduction and better grip on the battery
        for (i = [0 : num_batteries - 1]) {
             y_pos = -total_d/2 + wall + battery_d/2 + i * (battery_d + wall);
             // Cutout on left and right walls
             translate([-total_w/2 - 1, y_pos, holder_h + 2])
                rotate([0, 90, 0])
                cylinder(h = total_w + 2, r = 12, $fn=64);
        }
    }
}

// Ensure the battery case is centered for better viewing
battery_case();
