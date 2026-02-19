// 3D Printer Torture Test Model
// Units: mm

$fn = 64;

// Parameters
base_size = [180, 130, 4];
margin = 5;

module base_plate() {
    cube(base_size, center=false);
}

// Hole grid: diameters 1-10mm
module hole_grid() {
    diameters = [1,2,3,4,5,6,7,8,9,10];
    spacing = 11; // compact spacing while avoiding overlap
    rows = 2;
    for (r = [0:rows-1])
        for (i = [0:len(diameters)-1])
            translate([margin + i*spacing, margin + 10 + r*spacing, 0])
                cylinder(d=diameters[i], h=base_size[2]+0.5, center=false);
}

// Pins grid: diameters 1-10mm, heights 1-5mm
module pin_grid() {
    diameters = [1,2,3,4,5,6,7,8,9,10];
    spacing = 11;
    rows = 2;
    base_height = base_size[2];
    for (r = [0:rows-1])
        for (i = [0:len(diameters)-1]) {
            h = 1 + (i % 5); // cycle 1-5mm heights
            translate([margin + i*spacing, 45 + r*spacing, base_height])
                cylinder(d=diameters[i], h=h, center=false);
        }
}

// Thin walls from 0.2-2mm thickness
module thin_walls() {
    thicknesses = [0.2,0.4,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0];
    wall_height = 20;
    spacing = 5;
    start_x = margin;
    start_y = 80;
    for (i = [0:len(thicknesses)-1])
        translate([start_x + i*spacing, start_y, base_size[2]])
            cube([thicknesses[i], 18, wall_height], center=false);
}

// Bridges of 5-50mm length
module bridges() {
    spans = [5,10,20,30,40,50];
    support_size = [6,6,10];
    deck_thickness = 1;
    gap = 0; // gap between supports and deck bottom (0 => rests on supports)
    start_x = 118; // fits within 180mm base with max span 50
    start_y = margin;
    offset_y = 20;
    for (i = [0:len(spans)-1]) {
        span = spans[i];
        x0 = start_x;
        y0 = start_y + i*offset_y;
        // left and right supports
        translate([x0, y0, base_size[2]]) cube(support_size, center=false);
        translate([x0 + span + support_size[0], y0, base_size[2]]) cube(support_size, center=false);
        // bridge deck (anchored to supports)
        translate([x0 + support_size[0], y0, base_size[2] + support_size[2] + gap])
            cube([span, support_size[1], deck_thickness], center=false);
    }
}

// Overhang angles 10-70 degrees
module overhangs() {
    angles = [10,20,30,40,50,60,70];
    arm_len = 22;
    arm_thick = 3;
    arm_width = 12;
    start_x = 20;
    start_y = 105;
    column_size = [14,14,20];
    // column
    translate([start_x, start_y, base_size[2]]) cube(column_size, center=false);
    // arms
    for (i = [0:len(angles)-1]) {
        ang = angles[i];
        // attach at increasing heights
        h0 = base_size[2] + 5 + i*2;
        translate([start_x + column_size[0], start_y, h0])
            rotate([0, -ang, 0]) // negative rotates downward for overhang
                cube([arm_len, arm_width, arm_thick], center=false);
    }
}

module model() {
    difference() {
        union() {
            base_plate();
            pin_grid();
            thin_walls();
            bridges();
            overhangs();
        }
        // subtract holes through base
        hole_grid();
    }
}

model();
