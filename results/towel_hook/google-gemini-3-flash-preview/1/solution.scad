// Heavy duty Towel Hook with M3 Screw hole
// Optimized for strength and easy 3D printing
$fn = 64;

// Parameters
back_plate_height = 55;
back_plate_width = 22;
back_plate_thickness = 5;

hook_reach = 32;
hook_width = 14;
hook_thickness = 10;
hook_up_turn = 28;

screw_hole_dia = 3.5;
screw_head_dia = 6.4;
screw_head_depth = 3.0;

module towel_hook() {
    difference() {
        union() {
            // Main Body: Back plate and Arm unioned for strength
            // Back Plate with rounded edges for better aesthetics
            hull() {
                translate([0, 0, back_plate_width/2])
                    rotate([-90, 0, 0]) cylinder(h=back_plate_thickness, d=back_plate_width);
                translate([0, 0, back_plate_height - back_plate_width/2])
                    rotate([-90, 0, 0]) cylinder(h=back_plate_thickness, d=back_plate_width);
            }
            
            // Large Support Gusset / Arm
            // Triangular profile provides maximum strength against bending
            hull() {
                // Large attachment area on backplate
                translate([-back_plate_width/2 + 2, back_plate_thickness - 0.1, 8])
                    cube([back_plate_width - 4, 0.1, 35]);
                
                // Extension to the hook base
                translate([-hook_width/2, back_plate_thickness + hook_reach - hook_thickness, 12])
                    cube([hook_width, hook_thickness, 8]);
            }
            
            // The Hook Tip (Upward part)
            translate([0, back_plate_thickness + hook_reach - hook_thickness/2, 12 + hook_thickness/2]) {
                // Corner joint
                sphere(d=hook_width);
                
                // Vertical rise, slightly flared for grip
                hull() {
                    sphere(d=hook_width);
                    translate([0, -3, hook_up_turn])
                        sphere(d=hook_width + 1);
                }
                
                // Decorative / Safety Ball at the top
                translate([0, -3, hook_up_turn])
                    sphere(d=hook_width + 4);
            }
        }
        
        // M3 Screw Hole (Counter-sunk)
        // Positioned in the upper half of the backplate
        translate([0, -0.1, back_plate_height - 12]) {
            rotate([-90, 0, 0]) {
                cylinder(h=back_plate_thickness + 0.5, d=screw_hole_dia);
                // Countersink for flat head screw (standard 90 deg)
                cylinder(h=screw_head_depth + 0.1, d1=screw_head_dia, d2=screw_hole_dia);
            }
        }
        
        // Ensure the back surface is perfectly flat for wall mounting
        translate([-50, -10, -50]) cube([100, 10, 200]);
    }
}

// Center the model for easier viewing
translate([0, 0, 0]) towel_hook();
