$fn = 120; // High resolution for final model

// Dimensions
base_r = 16;
turret_r = 14;
neck_r = 10;
height = 55;

difference() {
    // 1. MAIN BODY: ROTATIONAL EXTRUSION
    rotate_extrude()
    polygon(points=[
        // Center Bottom
        [0, 0],
        
        // Base Section
        [base_r, 0],
        [base_r, 4],            // Vertical base foot
        [base_r - 1.5, 6],      // Angle in
        [base_r - 1.5, 9],      // Step vertical
        [base_r - 3, 11],       // Transition to column
        
        // Column / Neck
        [neck_r, 32],           // Tapering up to neck
        
        // Collar Ring (Decorative ring below turret)
        [neck_r + 2.5, 34],     // Ring bulge
        [neck_r + 2.5, 36],     // Ring vertical
        [neck_r + 0.5, 37],     // Ring undercut
        
        // Turret / Head
        [turret_r, 40],         // Turret flare bottom
        [turret_r, height],     // Turret side
        [0, height]             // Top center
    ]);

    // 2. TOP SCOOP (Concave top)
    translate([0, 0, height + 2]) // Lifted slightly so sphere cuts a shallow bowl
    sphere(r = turret_r * 0.85);

    // 3. CRENELLATIONS (Castle Slots)
    // 6 cuts creates 6 merlons.
    // Iterating 0, 60, 120 cuts through the diameter, creating 2 slots per cut.
    for (angle = [0 : 60 : 179]) { 
        rotate([0, 0, angle])
        translate([0, 0, height])
        cube([5, turret_r * 3, 6], center=true);
    }
}
