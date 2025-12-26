// Chess Rook Model - Improved Proportions

$fn = 64;

module rook() {
    // --- Base Section ---
    // Bottom flange
    cylinder(h = 3, r1 = 15, r2 = 15);
    // Rounded transition
    translate([0, 0, 3]) cylinder(h = 2, r1 = 15, r2 = 13);
    // Secondary base tier
    translate([0, 0, 5]) cylinder(h = 2, r1 = 13, r2 = 11);
    
    // --- Shaft Section ---
    // Tapered column
    translate([0, 0, 7]) cylinder(h = 20, r1 = 10, r2 = 8.5);
    
    // --- Capital/Top Section ---
    // Collar
    translate([0, 0, 27]) cylinder(h = 2, r1 = 8.5, r2 = 11);
    translate([0, 0, 29]) cylinder(h = 2, r1 = 11, r2 = 12);
    
    // Battlements (The Crown)
    difference() {
        // Main cylindrical head
        translate([0, 0, 31]) cylinder(h = 9, r = 12);
        
        // Internal hollow (the well)
        translate([0, 0, 35]) cylinder(h = 6, r = 8.5);
        
        // Crenels (Slots) - Increased gap for clarity
        for (i = [0 : 3]) {
            rotate([0, 0, i * 45])
                translate([0, 0, 37.5])
                    cube([30, 4.5, 6], center = true);
        }
    }
}

// Center the model
translate([0, 0, 0]) rook();
