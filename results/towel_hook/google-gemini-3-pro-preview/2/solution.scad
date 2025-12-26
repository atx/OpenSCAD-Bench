// 3D Printable Towel Hook
// Designed for a single M3 flat head screw
// Print orientation: Flat on side (XY plane) for maximum strength

$fn = 64;

// --- Dimenions ---
hook_width = 16;       // Thickness of the hook (extrusion height)
wall_height = 45;      // Height of the back plate
stick_out = 32;        // How far it sticks out from wall
stem_thickness = 11;   // Thickness of the vertical arm
screw_y_pos = 28;      // Height of screw hole from bottom

// M3 Screw dimensions
screw_shaft_d = 3.5;
screw_head_d = 6.8;    // Clearance for head
screw_cone_h = (screw_head_d - screw_shaft_d) / 2; // Approx 1.65mm

// --- Modules ---

module teardrop_shape_2d(r) {
    // Defines a teardrop logic where the 'point' is aimed at Global Z
    // AFTER rotation of [0, 90, 0].
    // RotY(90) maps Local X to Global -Z.
    // So to point Global +Z, we need Local -X.
    hull() {
        circle(r=r);
        // Point at -X
        translate([-r/sin(45), 0]) square([0.1, 0.1], center=true); 
    }
}

// Actually, calculating the point offset is annoying.
// Let's just define it standard (Point +Y) and rotate properly.
// Standard Teardrop (Point +Y):
// If Rotated [0, 90, 0]: Y stays Y. Point stays Horizontal. Bad.
// If Rotated [0, 90, 0] * [0, 0, 90]?
// Rotate Z(90) first: X->Y, Y->-X.
// Then Y(90): ...
// Let's just construct the polygon manually in the loop.

module horizontal_teardrop(d, h) {
    r = d/2;
    // We want a hole along X axis.
    // We want the peak in +Z axis.
    // Let's construct it directly in 3D using linear_extrude along X (using rotation).
    
    rotate([0, 90, 0]) // Extrude becomes X axis
    linear_extrude(height=h, center=false)
    polygon([
        [0, r],                   // Top of circle (Global Y+)
        [r * cos(45), r * sin(45)],
        [r * 1.414, 0],           // Peak (Global Z+ ... wait, check mapping)
        [r * cos(45), -r * sin(45)],
        [0, -r],
        [-r * cos(45), -r * sin(45)],
        [-r * 1.414, 0],          // Bottom Peak?
        [-r * cos(45), r * sin(45)]
    ]);
    // The Matrix check again:
    // Cylinder along Z. Profile in XY.
    // Rotate [0, 90, 0].
    // New X = Old Z.
    // New Y = Old Y.
    // New Z = -Old X.
    
    // We want Peak at New Z (+).
    // So we need Peak at Old X (-).
    // So the point in the 2D polygon must be at x < 0.
    
    // Correct Polygon for Z-extrusion before rotation:
    // Circle at origin.
    // Point at [-r, 0] or further negative.
    
}

module teardrop_x_aligned(d, h) {
    r = d/2;
    rotate([0, 90, 0])
    linear_extrude(height=h)
    hull() {
        circle(r=r);
        // Peak at Local -X (which maps to Global +Z)
        polygon([
            [0, r * sin(45)],
            [-r * 1.5, 0], // The tip
            [0, -r * sin(45)]
        ]);
    }
}

module screw_hole_cutout() {
    seat_x = 4; // Thickness of wall behind screw
    
    translate([-1, screw_y_pos, hook_width/2]) {
        // 1. Shaft Passage (Teardrop)
        teardrop_x_aligned(d=screw_shaft_d, h=seat_x + 2);
    }
    
    translate([seat_x, screw_y_pos, hook_width/2]) {
        // 2. Head Countersink (Cone)
        // Since we can't easily teardrop a cone, and it's short,
        // we use a standard cylinder cone.
        // It's inside the body, bridging is minimal.
        rotate([0, 90, 0])
            cylinder(d1=screw_shaft_d, d2=screw_head_d, h=screw_cone_h);
        
        // 3. Head Access (Teardrop)
        // Starts after cone.
        translate([screw_cone_h, 0, 0])
            teardrop_x_aligned(d=screw_head_d, h=30);
    }
}


module hook_shape() {
    difference() {
        hull() {
            // Top of wall mount
            translate([stem_thickness/2, wall_height - stem_thickness/2]) 
                circle(d=stem_thickness);
            
            // Bottom "Heel"
            translate([stem_thickness/2, stem_thickness/2]) 
                circle(d=stem_thickness);
            
            // Curve bottom 
            translate([stick_out - 6, 8]) 
                circle(d=9);
            
            // Tip
            translate([stick_out, 24]) 
                circle(d=6);
        }
        
        // Flatten the back
        translate([-stem_thickness, -10]) 
            square([stem_thickness, wall_height + 20]);
    }
}

difference() {
    linear_extrude(height=hook_width, convexity=10)
        hook_shape();
        
    screw_hole_cutout();
}
