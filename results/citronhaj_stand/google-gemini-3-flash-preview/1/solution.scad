// IKEA Citronhaj Spice Jar Stand
// 3x3 Grid, Tiered Levels (30mm steps)
// Designed for easy printing and jar accessibility

jar_diameter = 40;
tolerance = 1.8; // Tolerance for a smooth fit
wall = 3.2; // Wall thickness (approx 8 perimeters with 0.4 nozzle or 4 with 0.8)
cell_size = jar_diameter + tolerance + wall;
hole_diameter = jar_diameter + tolerance;

tier_step = 30;
bottom_thickness = 3;
front_height = 25; // Height of the front pocket

module spice_jar_stand() {
    difference() {
        // Solid body with 3 steps
        union() {
            for (row = [0:2]) {
                h = front_height + (row * tier_step);
                translate([0, row * cell_size, 0])
                    cube([3 * cell_size, cell_size, h]);
            }
        }

        // Holes for jars
        for (row = [0:2]) {
            for (col = [0:2]) {
                cx = col * cell_size + cell_size/2;
                cy = row * cell_size + cell_size/2;
                h_total = front_height + (row * tier_step) + 5;
                
                translate([cx, cy, bottom_thickness])
                    cylinder(h = h_total, d = hole_diameter, $fn=100);
            }
        }
        
        // Large rounded cutouts on the front and between rows for visibility and weight reduction
        for (row = [0:2]) {
            for (col = [0:2]) {
                cx = col * cell_size + cell_size/2;
                cy = row * cell_size;
                h_cut = front_height + (row * tier_step);
                
                // Frontal arched cutouts
                translate([cx, cy - 0.1, h_cut])
                    rotate([-90, 0, 0])
                        cylinder(h = wall + 0.2, d = hole_diameter, $fn=80);
            }
        }
        
        // Side cut-outs for aesthetics
        for (row = [0:2]) {
            h_side = (front_height + row * tier_step) / 1.5;
            // Left
            translate([-1, row * cell_size + cell_size/2, h_side])
                rotate([0, 90, 0])
                    cylinder(h = wall + 2, d = h_side * 1.2, $fn=60);
            // Right
            translate([3 * cell_size - wall + 1, row * cell_size + cell_size/2, h_side])
                rotate([0, 90, 0])
                    cylinder(h = wall + 2, d = h_side * 1.2, $fn=60);
        }
    }
}

spice_jar_stand();

// Visualization of jars
%for (row = [0:2]) {
    for (col = [0:2]) {
        translate([col * cell_size + cell_size/2, row * cell_size + cell_size/2, bottom_thickness])
            cylinder(h = 120, d = 40, $fn=60);
    }
}
