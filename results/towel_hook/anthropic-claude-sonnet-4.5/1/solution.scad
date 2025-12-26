// 3D Printable Towel Hook with M3 Flat Head Screw Mount
// Designed to be printed flat and screwed to a wall

$fn = 100;

module towel_hook() {
    difference() {
        union() {
            // Mounting plate - thick and reinforced with rounded edges
            hull() {
                translate([0, 0, 0])
                    cylinder(d = 22, h = 4);
                translate([12, 0, 0])
                    cylinder(d = 18, h = 4);
            }
            
            // Transition from plate to hook arm with better support
            hull() {
                translate([12, 0, 0])
                    cylinder(d = 18, h = 4);
                translate([22, 0, 2])
                    rotate([0, 90, 0])
                    cylinder(d = 14, h = 3);
            }
            
            // Main hook arm - extends outward from wall (50mm projection)
            translate([22, 0, 2])
                rotate([0, 90, 0])
                cylinder(d = 14, h = 48);
            
            // Hook curve - the part that holds the towel (180 degree bend)
            translate([70, 0, 2])
                rotate([0, 0, 0])
                rotate_extrude(angle = 180)
                translate([14, 0, 0])
                circle(d = 14);
            
            // Hook tip - extends upward (20mm height)
            translate([70, 28, 2])
                rotate([0, 90, 0])
                cylinder(d = 14, h = 12);
            
            // Rounded end cap
            translate([82, 28, 2])
                sphere(d = 14);
            
            // Large reinforcement gusset - triangular support
            hull() {
                translate([25, 0, 2])
                    rotate([0, 90, 0])
                    cylinder(d = 14, h = 1);
                translate([25, -7, -4])
                    cube([1, 14, 0.5]);
                translate([12, -9, 0])
                    cylinder(d = 18, h = 4);
            }
            
            // Second reinforcement gusset
            hull() {
                translate([45, 0, 2])
                    rotate([0, 90, 0])
                    cylinder(d = 14, h = 1);
                translate([45, -7, -4])
                    cube([1, 14, 0.5]);
                translate([25, -7, -3])
                    cube([1, 14, 0.5]);
            }
            
            // Extended base for more stability
            hull() {
                translate([0, 0, 0])
                    cylinder(d = 22, h = 1);
                translate([30, -10, -4])
                    cube([1, 20, 1]);
            }
        }
        
        // M3 flat head screw hole (countersunk)
        // M3 clearance hole: 3.4mm diameter
        translate([0, 0, -5])
            cylinder(d = 3.4, h = 15);
        
        // Countersink for M3 flat head screw
        // Standard M3 flat head: 6-6.5mm diameter head, ~1.8mm countersink depth
        translate([0, 0, 4 - 1.9])
            cylinder(d1 = 3.4, d2 = 7, h = 2);
    }
}

towel_hook();
