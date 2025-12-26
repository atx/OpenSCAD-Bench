// 3D Printable Towel Hook
// Designed for wall mounting with M3 flat head screw

$fn = 100;

module towel_hook() {
    difference() {
        union() {
            // Base plate that mounts to wall - larger for better support
            translate([0, 0, 0])
                cylinder(d = 25, h = 5);
            
            // Reinforcement/transition from base to arm - stronger design
            hull() {
                translate([0, 0, 0])
                    cylinder(d = 25, h = 5);
                translate([8, 0, 10])
                    rotate([0, 90, 0])
                    cylinder(d = 14, h = 8);
            }
            
            // Main horizontal arm extending from wall - thicker for strength
            translate([8, 0, 10])
                rotate([0, 90, 0])
                cylinder(d = 14, h = 45);
            
            // Reinforcement rib on top of arm for extra strength
            hull() {
                translate([8, 0, 10 + 7])
                    rotate([0, 90, 0])
                    cylinder(d = 3, h = 40);
                translate([0, 0, 5])
                    cylinder(d = 10, h = 0.1);
            }
            
            // Curved hook portion - 200 degree curve for better grip
            translate([53, 0, 10])
                rotate([0, 0, 0])
                rotate_extrude(angle = 200)
                translate([14, 0, 0])
                circle(d = 14);
            
            // Downward portion of hook
            translate([53 + 14*cos(200), 14*sin(200), 10])
                rotate([0, 0, 0])
                cylinder(d = 14, h = 30, center = false);
            
            // Rounded end tip for smooth finish
            translate([53 + 14*cos(200), 14*sin(200), 10])
                sphere(d = 14);
        }
        
        // M3 flat head screw countersink hole
        // M3 clearance hole (3.2mm diameter)
        translate([0, 0, -0.1])
            cylinder(d = 3.4, h = 10);
        
        // Countersink for M3 flat head screw
        // Standard M3 flat head: 6-6.5mm diameter, ~1.8mm depth
        translate([0, 0, 5 - 2])
            cylinder(d1 = 3.4, d2 = 7, h = 2.2);
    }
}

towel_hook();
