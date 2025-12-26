// Olympus BLS-5 Battery Case
// Holds 4 batteries in a row
// Battery dimensions: 56mm (H) x 36mm (W) x 13mm (D)
// Standing on 36x13 face

/* [Parameters] */
bat_w = 36.0;   // Y dimension (Width)
bat_d = 13.0;   // X dimension (Thickness)
bat_h = 56.0;   // Z dimension (Height)

num_slots = 4;
wall = 1.6;        // Outer wall thickness
divider = 1.2;     // Inner divider thickness
floor_th = 2.0;    // Floor thickness
clearance = 0.5;   // Clearance around battery

// Feature Parameters
snap_zone = 2.0;       // Extra height for snap mechanism
snap_protrusion = 0.8; // Depth of snap nub
slit_depth = 15.0;     // Depth of flexure slits
hole_dia = 12.0;       // Finger hole diameter
tab_ratio = 0.6;       // Tab width ratio relative to slot depth

/* [Hidden] */
slot_w = bat_w + clearance;
slot_d = bat_d + clearance;
slot_h = bat_h;

// Total External Dimensions
// Layout: Wall | Slot | Divider | Slot ... | Wall
total_x = 2 * wall + num_slots * slot_d + (num_slots - 1) * divider;
total_y = slot_w + 2 * wall;
total_z = floor_th + slot_h + snap_zone;

$fn = 60;

module case() {
    union() {
        difference() {
            // Main solid block
            cube([total_x, total_y, total_z]);

            // Subtract Slots
            for (i = [0 : num_slots - 1]) {
                // X Position of this slot
                dx = wall + i * (slot_d + divider);
                
                translate([dx, wall, floor_th]) {
                    // Battery Slot cavity
                    // Extend above top
                    cube([slot_d, slot_w, total_z]);
                }
                
                // Finger hole (centered in slot)
                translate([dx + slot_d/2, total_y/2, -1]) {
                    cylinder(h = floor_th + 2, d = hole_dia);
                }
            }

            // Subtract Slits for Flex Tabs
            for (i = [0 : num_slots - 1]) {
                slit_w = 1.0;
                tab_w = slot_d * tab_ratio; // Tab width ~8mm
                
                cx = wall + i * (slot_d + divider) + slot_d/2;
                
                z_bot = total_z - slit_depth;
                
                // Front wall slits (Y near 0)
                translate([cx - tab_w/2 - slit_w, -1, z_bot])
                    cube([slit_w, wall + 2, slit_depth + 1]);
                translate([cx + tab_w/2, -1, z_bot])
                    cube([slit_w, wall + 2, slit_depth + 1]);

                // Back wall slits (Y near max)
                translate([cx - tab_w/2 - slit_w, total_y - wall - 1, z_bot])
                    cube([slit_w, wall + 2, slit_depth + 1]);
                translate([cx + tab_w/2, total_y - wall - 1, z_bot])
                    cube([slit_w, wall + 2, slit_depth + 1]);
            }
        }
        
        // Add Snap Nubs
        for (i = [0 : num_slots - 1]) {
            cx = wall + i * (slot_d + divider) + slot_d/2;
            tab_w = slot_d * tab_ratio;

            // Front Snap
            translate([cx, wall, floor_th + slot_h])
                snap_nub(tab_w, snap_protrusion);

            // Back Snap
            translate([cx, total_y - wall, floor_th + slot_h])
                rotate([0, 0, 180])
                snap_nub(tab_w, snap_protrusion);
        }
    }
}

module snap_nub(width, prot) {
    // Creates a nub centered at current [x,y,z]
    // Extrusion along X (width)
    // Profile in rotated space:
    // Poly X -> Global -Z
    // Poly Y -> Global Y
    
    translate([-width/2, 0, 0])
    rotate([0, 90, 0])
    linear_extrude(width)
    polygon(points=[
        [0, 0],           // Start at wall surface
        [-1.5, prot],     // Peak (Global Z+1.5, Y+prot)
        [-3.0, 0]         // End (Global Z+3.0, Y+0)
    ]);
}

case();
