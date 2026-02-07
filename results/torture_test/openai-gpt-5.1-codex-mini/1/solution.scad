$fn = 64;

module base_plate() {
    cube([180, 140, 4], center = false);
}

module hole_grid() {
    // Grid of holes from 1-10mm diameter (2 rows of 5)
    for (row = [0, 1]) {
        for (col = [0 : 4]) {
            diam = row * 5 + col + 1;
            x = 12 + col * 12;
            y = 12 + row * 18;
            translate([x, y, -1])
                cylinder(h = 6, d = diam, center = false);
        }
    }
}

module pin_grid() {
    // Circular pins with diameters from 1-10mm and heights from 1-5mm
    diam_rows = [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9, 10]
    ];
    for (row = [0, 1]) {
        for (col = [0 : 4]) {
            diam = diam_rows[row][col];
            height = 1 + col;
            translate([90 + col * 12, 10 + row * 18, 4])
                cylinder(h = height, d = diam, center = false);
        }
    }
}

module thin_wall_array() {
    thicknesses = [0.2, 0.6, 1.0, 1.4, 1.8, 2.0];
    for (i = [0 : 5]) {
        thickness = thicknesses[i];
        preceding = [for (j = [0 : i - 1]) thicknesses[j] + 4];
        x_offset = 10 + sum(preceding);
        translate([x_offset, 25, 4])
            cube([thickness, 30, 25], center = false);
    }
}

module bridge_tests() {
    lengths = [5, 15, 25, 35, 45, 50];
    base_x = 100;
    bridge_spacing = 4;
    post_width = 5;
    post_depth = 12;
    post_height = 12;
    beam_thickness = 2;

    for (i = [0 : 5]) {
        len_bridge = lengths[i];
        y = 70 + i * bridge_spacing;
        translate([base_x, y, 4])
            cube([post_width, post_depth, post_height], center = false);
        translate([base_x + post_width + len_bridge, y, 4])
            cube([post_width, post_depth, post_height], center = false);
        translate([base_x + post_width, y + 2, 4 + post_height - beam_thickness])
            cube([len_bridge, post_depth - 4, beam_thickness], center = false);
    }
}

module overhang_prism(len_angle, height, depth) {
    polyhedron(
        points = [
            [0, 0, 4],
            [len_angle, 0, 4],
            [0, 0, 4 + height],
            [0, depth, 4],
            [len_angle, depth, 4],
            [0, depth, 4 + height]
        ],
        faces = [
            [0, 1, 2],
            [3, 5, 4],
            [0, 3, 4, 1],
            [1, 4, 5, 2],
            [2, 5, 3, 0]
        ]
    );
}

module overhang_array() {
    angles = [10, 20, 30, 40, 50, 60, 70];
    height = 10;
    depth = 25;
    for (idx = [0 : 6]) {
        angle = angles[idx];
        length = height / tan(angle * PI / 180);
        preceding_lengths = [for (j = [0 : idx - 1]) height / tan(angles[j] * PI / 180)];
        x_offset = 5 + sum(preceding_lengths) + idx * 5;
        translate([x_offset, 110, 0])
            overhang_prism(length, height, depth);
    }
}

module torture_test() {
    difference() {
        union() {
            base_plate();
            pin_grid();
            thin_wall_array();
            bridge_tests();
            overhang_array();
        }
        hole_grid();
    }
}


torture_test();
