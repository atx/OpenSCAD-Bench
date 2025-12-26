// Chess Rook Piece
$fn = 100; // Smooth circles

module rook() {
    union() {
        // Base (wide circular platform)
        translate([0, 0, 0])
            cylinder(h = 3, r = 20, center = false);
        
        // Base ring (decorative)
        translate([0, 0, 3])
            cylinder(h = 2, r1 = 20, r2 = 18, center = false);
        
        // Lower body (tapered)
        translate([0, 0, 5])
            cylinder(h = 15, r1 = 18, r2 = 12, center = false);
        
        // Middle section
        translate([0, 0, 20])
            cylinder(h = 10, r = 12, center = false);
        
        // Upper taper
        translate([0, 0, 30])
            cylinder(h = 5, r1 = 12, r2 = 14, center = false);
        
        // Top platform (castle top)
        translate([0, 0, 35])
            cylinder(h = 4, r = 14, center = false);
        
        // Battlements (crenellations)
        translate([0, 0, 39])
            difference() {
                cylinder(h = 8, r = 14, center = false);
                
                // Cut out the notches to create battlements
                for (angle = [0:45:315]) {
                    rotate([0, 0, angle])
                        translate([0, 10, 2])
                            cube([8, 10, 10], center = true);
                }
            }
    }
}

rook();
