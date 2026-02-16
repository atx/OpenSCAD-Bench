// Chess Rook Piece
// Dimensions in mm

$fn = 80;

module rook() {
    union() {
        // Base
        base();
        
        // Body
        translate([0, 0, 9])
            body();
        
        // Top crown with battlements
        translate([0, 0, 58])
            crown();
    }
}

module base() {
    // Bottom wide base with slight bevel
    cylinder(h = 1, r1 = 18, r2 = 18);
    translate([0, 0, 1])
        cylinder(h = 2, r1 = 18, r2 = 15.5);
    
    // Base torus detail
    translate([0, 0, 3])
        rotate_extrude()
            translate([14.5, 1.5, 0])
                circle(r = 1.5);
    
    // Tapered section above base
    translate([0, 0, 3])
        cylinder(h = 3, r1 = 15.5, r2 = 13);
    
    // Second ring detail
    translate([0, 0, 6])
        rotate_extrude()
            translate([12.5, 1.2, 0])
                circle(r = 1.2);
    
    // Transition to body
    translate([0, 0, 6])
        cylinder(h = 3, r1 = 13, r2 = 10.5);
}

module body() {
    // Main tapered shaft
    cylinder(h = 36, r1 = 10.5, r2 = 8.5);
    
    // Subtle grooves / rings on the shaft for visual interest
    for (z = [5, 7]) {
        translate([0, 0, z])
            rotate_extrude()
                translate([10.2 - z*0.04, 0, 0])
                    scale([0.7, 1.2])
                        circle(r = 0.5);
    }
    
    // Upper collar area - flaring out for the crown
    translate([0, 0, 36])
        cylinder(h = 2, r1 = 8.5, r2 = 9.5);
    
    translate([0, 0, 38])
        rotate_extrude()
            translate([9.5, 1, 0])
                circle(r = 1);
    
    translate([0, 0, 39])
        cylinder(h = 2, r1 = 10, r2 = 11);
    
    translate([0, 0, 41])
        cylinder(h = 4, r1 = 11, r2 = 12);
    
    // Upper ring detail before crown
    translate([0, 0, 45])
        rotate_extrude()
            translate([12, 1, 0])
                circle(r = 1);
    
    translate([0, 0, 46])
        cylinder(h = 3, r1 = 12.5, r2 = 13.5);
}

module crown() {
    num_merlons = 5;
    merlon_angular = 360 / num_merlons; // 72 degrees per segment
    crenel_ratio = 0.42; // portion of each segment that is a gap
    
    outer_r = 14;
    inner_r = 10;
    wall_height = 10;
    crenel_depth = 5.5; // how much of the top is cut away for crenels
    
    difference() {
        union() {
            // Base platform of crown - slight flare
            cylinder(h = 2, r1 = 13.5, r2 = outer_r);
            
            // Crown wall
            translate([0, 0, 2])
            difference() {
                cylinder(h = wall_height, r = outer_r);
                translate([0, 0, -1])
                    cylinder(h = wall_height + 2, r = inner_r);
            }
            
            // Small bevel on top of each merlon
            for (i = [0 : num_merlons - 1]) {
                angle = i * merlon_angular;
                rotate([0, 0, angle])
                    translate([0, 0, wall_height + 2])
                        merlon_cap(outer_r, inner_r, merlon_angular * (1 - crenel_ratio));
            }
        }
        
        // Cut crenels (the gaps between merlons)
        for (i = [0 : num_merlons - 1]) {
            angle = i * merlon_angular + merlon_angular * (1 - crenel_ratio) / 2;
            rotate([0, 0, angle])
                translate([0, 0, 2 + wall_height - crenel_depth])
                    crenel_cut(outer_r + 1, inner_r - 1, crenel_depth + 3, merlon_angular * crenel_ratio);
        }
        
        // Inner bowl depression
        translate([0, 0, 1])
            cylinder(h = 2, r1 = 7, r2 = inner_r);
    }
}

module merlon_cap(outer_r, inner_r, angle_span) {
    // Small rounded cap on top of each merlon
    linear_extrude(height = 0.8, scale = 0.92)
        difference() {
            pie_slice(outer_r, angle_span);
            circle(r = inner_r);
        }
}

module crenel_cut(outer_r, inner_r, h, angle_span) {
    // Wedge-shaped cut through the wall
    linear_extrude(height = h)
        difference() {
            pie_slice(outer_r, angle_span);
            circle(r = inner_r);
        }
}

module pie_slice(r, angle) {
    if (angle < 180) {
        intersection() {
            circle(r = r);
            polygon(points = [
                [0, 0],
                [r * 1.5, 0],
                [r * 1.5 * cos(angle), r * 1.5 * sin(angle)],
                [0, 0]
            ]);
        }
    }
}

// Render the rook
rook();
