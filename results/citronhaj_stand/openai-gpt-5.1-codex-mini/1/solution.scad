$fn = 64;

// Dimension parameters
jar_diameter = 40;
clearance = 1;
inner_radius = jar_diameter / 2 + clearance;
wall_thickness = 5;
outer_radius = inner_radius + wall_thickness;
spacing_x = 55;
spacing_y = 60;
width_x = 2 * spacing_x + jar_diameter + 20;
depth_y = 2 * spacing_y + jar_diameter + 20;
base_plate_height = 3;
row_depth = 60;
row_tops = [30, 60, 90];
row_centers = [-spacing_y, 0, spacing_y];
col_positions = [-spacing_x, 0, spacing_x];
ring_height = 95;
embed_depth = 3;
pocket_depth_target = 25;
cavity_extra = 5;

module base_plate() {
    translate([-width_x / 2, -depth_y / 2, 0])
        cube([width_x, depth_y, base_plate_height]);
}

module row_step(row_center_y, row_top) {
    block_height = row_top - base_plate_height;
    if (block_height > 2) {
        pocket_depth = min(pocket_depth_target, max(block_height - 3, 2));
        translate([-width_x / 2, row_center_y - row_depth / 2, base_plate_height])
            difference() {
                cube([width_x, row_depth, block_height]);
                for (col_x = col_positions)
                    translate([col_x, row_center_y, row_top - pocket_depth])
                        cylinder(h = pocket_depth + cavity_extra, r = inner_radius);
            }
    }
}

module jar_ring(x_pos, y_pos, row_top) {
    translate([x_pos, y_pos, row_top - embed_depth])
        difference() {
            cylinder(h = ring_height, r = outer_radius);
            translate([0, 0, -1])
                cylinder(h = ring_height + 2, r = inner_radius);
        }
}

union() {
    base_plate();
    for (idx = [0 : 2])
        row_step(row_centers[idx], row_tops[idx]);
    for (row_idx = [0 : 2])
        for (col_idx = [0 : 2])
            jar_ring(col_positions[col_idx], row_centers[row_idx], row_tops[row_idx]);
}
