// Chess Rook Piece
// Classic design with crenellated top (battlements)

$fn = 80; // Smooth curves

// Parameters
total_height = 65;
base_radius = 16;

module rook() {
    // Base platform
    cylinder(h = 3, r1 = base_radius, r2 = base_radius);
    
    // Base molding (curved profile)
    translate([0, 0, 3])
        cylinder(h = 4, r1 = base_radius, r2 = 13);
    
    // Lower collar
    translate([0, 0, 7])
        cylinder(h = 2, r = 13);
    
    translate([0, 0, 9])
        cylinder(h = 2, r1 = 13, r2 = 11);
    
    // Main body (tapered column)
    translate([0, 0, 11])
        cylinder(h = 30, r1 = 11, r2 = 9);
    
    // Upper collar / neck area
    translate([0, 0, 41])
        cylinder(h = 3, r1 = 9, r2 = 7);
    
    translate([0, 0, 44])
        cylinder(h = 2, r = 7);
    
    // Flare out to crown
    translate([0, 0, 46])
        cylinder(h = 3, r1 = 7, r2 = 11);
    
    // Crown with battlements
    translate([0, 0, 49])
        crown();
    
    // Decorative rings on body
    for (z = [18, 28, 38]) {
        body_r = 11 - (11 - 9) * ((z - 11) / 30);
        translate([0, 0, z])
            torus_ring(body_r + 0.5, 0.8);
    }
}

module crown() {
    crown_radius = 11;
    crown_height = 16;
    wall_thickness = 3;
    merlon_count = 4;
    merlon_height = 7;
    crenel_angle = 35; // Angle width of each gap
    
    difference() {
        // Outer crown cylinder with slight taper
        cylinder(h = crown_height, r1 = crown_radius, r2 = crown_radius + 1);
        
        // Hollow interior (deeper cut for chess piece look)
        translate([0, 0, 3])
            cylinder(h = crown_height, r = crown_radius - wall_thickness);
        
        // Cut out the crenels (gaps between merlons)
        for (i = [0 : merlon_count - 1]) {
            rotate([0, 0, i * 90 + 45])
                translate([0, 0, crown_height - merlon_height])
                    linear_extrude(height = merlon_height + 1)
                        polygon(points = [
                            [0, 0],
                            [(crown_radius + 2) * cos(crenel_angle/2), (crown_radius + 2) * sin(crenel_angle/2)],
                            [(crown_radius + 2) * cos(-crenel_angle/2), (crown_radius + 2) * sin(-crenel_angle/2)]
                        ]);
        }
    }
    
    // Add small details on top of merlons
    for (i = [0 : merlon_count - 1]) {
        rotate([0, 0, i * 90])
            translate([crown_radius - 1, 0, crown_height])
                cylinder(h = 1, r = 2.5);
    }
}

module torus_ring(r_major, r_minor) {
    rotate_extrude()
        translate([r_major, 0, 0])
            circle(r = r_minor);
}

// Generate the rook
rook();
