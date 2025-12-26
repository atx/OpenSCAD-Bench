// Towel Hook for M3 Flat Head Screw
// Designed for 3D printing (Recommended: print on side for max strength)
$fn = 64;

// Global dimensions
W = 18;      // Width of the hook
H = 65;      // Total height
D = 45;      // Total depth
T = 10;      // Thickness of the arm/hook
BT = 8;      // Base plate thickness

// Screw dimensions (M3 Flat Head)
SCREW_D = 3.6;
HEAD_D = 6.8;
HEAD_H = 3.2;

module towel_hook_v3() {
    difference() {
        union() {
            // Main structure extruded from the side profile
            // This ensures a clean look and easy fillets
            rotate([90, 0, 90])
            linear_extrude(height = W)
            polygon(points=[
                [0, 0],             // Bottom back
                [D, 0],             // Bottom front
                [D, T + 18],        // Tip top
                [D - T, T + 18],    // Tip inner top
                [D - T, T],         // Arm top
                [BT, T],            // Above gusset
                [BT, H],            // Back top front
                [0, H]              // Back top back
            ]);
            
            // Large structural gusset for heavy towels
            rotate([90, 0, 90])
            linear_extrude(height = W)
            polygon(points=[
                [BT, T],
                [D - T - 5, T],
                [BT, H - 15]
            ]);
        }

        // M3 Flat Head Screw Hole
        // Positioned high to handle the leverage of a heavy towel
        translate([W/2, -0.1, H - 10])
        rotate([-90, 0, 0]) {
            // Shaft
            cylinder(d = SCREW_D, h = BT + 0.2);
            // Countersink (y increases into the part)
            // d1 is at y=0, d2 is at y=HEAD_H
            cylinder(d1 = HEAD_D, d2 = SCREW_D, h = HEAD_H);
        }

        // Aesthetic / Safety Rounding
        // Round the very front of the hook
        translate([-1, D, T+18]) rotate([45, 0, 0]) cube([W+2, 10, 10]);
        // Round the back top
        translate([-1, 0, H]) rotate([0, 90, 0]) cylinder(r=2, h=W+2);
    }
}

towel_hook_v3();
