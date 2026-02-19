$fn=64;

// Base plate
base_thickness = 4;
base_size = [140, 120, base_thickness];

module holes_grid() {
    // 10 holes 1-10mm in 2 rows of 5
    start = [10, 10];
    spacing = [12, 12];
    for (i=[0:9]) {
        d = i+1;
        x = start[0] + (i%5)*spacing[0];
        y = start[1] + floor(i/5)*spacing[1];
        translate([x,y,0]) cylinder(h=base_thickness+1, d=d, center=false);
    }
}

module pins_grid() {
    // 10 pins 1-10mm dia, heights 1-5mm
    start = [10, 50];
    spacing = [12, 12];
    for (i=[0:9]) {
        d = i+1;
        h = 1 + (i%5); // 1-5mm
        x = start[0] + (i%5)*spacing[0];
        y = start[1] + floor(i/5)*spacing[1];
        translate([x,y,base_thickness]) cylinder(h=h, d=d, center=false);
    }
}

module thin_walls() {
    // walls of 0.2-2mm thickness
    start = [80, 10];
    lengths = 30;
    heights = 20;
    for (i=[0:9]) {
        t = 0.2 + i*0.2; // 0.2 to 2.0
        x = start[0] + i*3;
        translate([x, start[1], base_thickness]) cube([t, lengths, heights], center=false);
    }
}

module bridges() {
    // bridges lengths 5-50mm
    start = [80, 60];
    for (i=[0:9]) {
        len = 5 + i*5; // 5 to 50
        x = start[0];
        y = start[1] + i*5;
        // two pillars with bridge
        translate([x, y, base_thickness]) cube([3,3,20], center=false);
        translate([x+len, y, base_thickness]) cube([3,3,20], center=false);
        translate([x, y, base_thickness+20]) cube([len+3,3,2], center=false);
    }
}

module overhangs() {
    // overhang angles 10-70 degrees
    start = [10, 90];
    for (i=[0:6]) {
        ang = 10 + i*10; // 10 to 70
        x = start[0] + i*18;
        // create a wedge by rotating a rectangular roof
        translate([x, start[1], base_thickness]) {
            // support block
            cube([10, 20, 20], center=false);
            // overhang roof
            rotate([0, -ang, 0])
                translate([0,0,20]) cube([20,20,2], center=false);
        }
    }
}

difference() {
    // base
    cube(base_size, center=false);
    // subtract holes
    holes_grid();
}

// add features
pins_grid();
thin_walls();
bridges();
overhangs();
