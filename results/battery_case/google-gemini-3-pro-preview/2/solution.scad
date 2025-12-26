// Olympus BLS-5 Battery Holder
// Battery dims: 56 x 36 x 13
// Orientation: Standing on 13x36 face.
// Stacked along 13mm dimension (linear 4x1).

// --- Parameters ---
bat_w = 36.5; // Battery Width (Y-axis in slot)
bat_t = 13.5; // Battery Thickness (X-axis in slot)
bat_h = 56.0; // Battery Height

slot_count = 4;

wall_thickness = 1.6;
divider_thickness = 1.2;
floor_thickness = 2.0;
slot_radius = 2.0; // Corner radius for the slot

// Derived Outer Dims
total_len = slot_count * bat_t + (slot_count - 1) * divider_thickness + 2 * wall_thickness;
total_wid = bat_w + 2 * wall_thickness;
total_high = bat_h + floor_thickness;

// Finger hole
hole_dia = 16.0;

// Snap fit parameters
bump_depth = 0.5; // Depth of the snap nub
bump_height = 4.0; // Height of the snap nub
tab_width = 8.0; 
tab_len = 20.0; // Length of the flex cut
slits_w = 1.0; 

$fn = 60;

module rounded_slot(t, w, h, r) {
    // Extrudes a rounded rectangle
    linear_extrude(height = h)
        hull() {
            translate([r, r]) circle(r=r);
            translate([t-r, r]) circle(r=r);
            translate([r, w-r]) circle(r=r);
            translate([t-r, w-r]) circle(r=r);
        }
}

module snap_nub() {
    w = tab_width - 1.5; // Slightly narrower than tab to avoid slit edges
    d = bump_depth;
    h = bump_height; 
    
    // A prism on the inner face
    // Points into the slot (Local +Y from wall surface)
    // Centered horizontally on the tab
    // Vertically spans from top (0) down to (-h)
    
    translate([-w/2, 0, -h])
    rotate([90, 0, 90]) // Rotate to place along X (width) and Y (depth)
    linear_extrude(w)
        polygon([[0, 0], [d, h/2], [0, h]]); 
}

module battery_case() {
    difference() {
        // Main Body Box
        cube([total_len, total_wid, total_high]);
        
        // Remove Slots
        for (i = [0 : slot_count - 1]) {
            translate([wall_thickness + i * (bat_t + divider_thickness), wall_thickness, floor_thickness]) {
                // Rounded Slot Cavity
                rounded_slot(bat_t, bat_w, bat_h + 1, slot_radius);
                
                // Finger Hole
                translate([bat_t / 2, bat_w / 2, -floor_thickness - 1])
                    cylinder(d = hole_dia, h = floor_thickness + 5);
            }
        }
        
        // Relief Cuts for Tabs
        for (i = [0 : slot_count - 1]) {
            current_x_start = wall_thickness + i * (bat_t + divider_thickness);
            center_x = current_x_start + bat_t / 2;
            
            // Front Wall Cuts
            translate([center_x - tab_width/2 - slits_w, -1, total_high - tab_len])
                cube([slits_w, wall_thickness + 2, tab_len + 1]);
            translate([center_x + tab_width/2, -1, total_high - tab_len])
                cube([slits_w, wall_thickness + 2, tab_len + 1]);
                
            // Back Wall Cuts
            translate([center_x - tab_width/2 - slits_w, total_wid - wall_thickness - 1, total_high - tab_len])
                cube([slits_w, wall_thickness + 2, tab_len + 1]);
            translate([center_x + tab_width/2, total_wid - wall_thickness - 1, total_high - tab_len])
                cube([slits_w, wall_thickness + 2, tab_len + 1]);
        }
    }
    
    // Add Snap Nubs
    for (i = [0 : slot_count - 1]) {
        center_x = wall_thickness + i * (bat_t + divider_thickness) + bat_t / 2;
        
        // Front Nub
        translate([center_x, wall_thickness, total_high])
            snap_nub();
            
        // Back Nub
        translate([center_x, total_wid - wall_thickness, total_high])
            rotate([0, 0, 180])
            snap_nub();
    }
}

battery_case();
