// Solid Towel Hook for M3 Flat Head Screw
// Designed for strength and support-free printing

$fn = 64;

// Dimensions
base_width = 20;
base_height = 50;
base_thickness = 6;
hook_projection = 35; // Total depth from wall
hook_thickness = 12;
screw_pos_y = 15; // From center

module hook() {
    difference() {
        union() {
            // Rounded Base Plate
            hull() {
                translate([0, base_height/2 - base_width/2, 0]) cylinder(d=base_width, h=base_thickness);
                translate([0, -(base_height/2 - base_width/2), 0]) cylinder(d=base_width, h=base_thickness);
            }

            // Hook Body - Strong triangular/curved profile
            // Sweeping from the bottom of the base up to the tip
            hull() {
                // Large attachment area at the bottom for leverage resistance
                translate([-base_width/2, -base_height/2, 0]) 
                    cube([base_width, 25, base_thickness]);
                
                // The outer "nose" of the hook
                translate([0, 0, hook_projection - hook_thickness/2])
                    rotate([-90, 0, 0])
                    cylinder(d=hook_thickness, h=2);
            }
            
            // The Upward Tip to catch the towel
            hull() {
                translate([0, 0, hook_projection - hook_thickness/2])
                    rotate([-90, 0, 0])
                    cylinder(d=hook_thickness, h=2);
                
                translate([0, 15, hook_projection])
                    sphere(d=hook_thickness);
            }
        }

        // M3 Screw Hole with Countersink (Upper portion)
        translate([0, screw_pos_y, -1]) {
            // Through hole
            cylinder(d=3.5, h=base_thickness + 2);
            // Countersink for M3 flat head (approx 6-6.5mm)
            cylinder(d1=6.8, d2=3.5, h=3.3);
        }
        
        // Ensure absolutely flat back
        translate([-50, -50, -10]) cube([100, 100, 10]);
    }
}

// Orientation: Print on side for max strength (layers spanning the curve)
rotate([0, -90, 0])
hook();
