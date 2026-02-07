// 3D Printer Torture Test Model
// Units in mm

$fn=80;

module base_plate(size=[120,120,4]) {
    cube(size, center=false);
}

// Grid of holes 1-10mm diameter, spaced 12mm
module hole_grid(origin=[0,0,0]) {
    translate(origin)
    for(i=[0:9]) {
        for(j=[0:4]) {
            d = i+1; // 1..10 mm
            translate([i*12 + 6, j*12 + 6, 0])
                cylinder(h=10, d=d, center=false);
        }
    }
}

// Compact grid of pins covering 1-10mm diameters, heights 1-5mm, spaced 12mm
module pin_grid(origin=[0,0,0]) {
    translate(origin)
    for(row=[0:1]) { // two rows
        for(col=[0:4]) { // five columns
            idx = row*5 + col; // 0..9
            d = idx + 1;      // 1..10 mm diameters
            h = (col + row) % 5 + 1; // 1..5 mm heights
            translate([col*12 + 6, row*12 + 6, 4])
                cylinder(h=h, d=d, center=false);
        }
    }
}

// Thin walls between 0.2-2mm thickness, 20mm long, 15mm tall
module thin_wall_array(origin=[0,0,0]) {
    translate(origin)
    for(k=[0:9]) {
        t = 0.2 + k*0.2; // 0.2 to 2.0
        translate([k*6,0,4])
            cube([t,20,15], center=false);
    }
}

// Bridges of 5-50mm length in 5mm increments, 1mm thick and 5mm wide bar
module bridge_array(origin=[0,0,0]) {
    translate(origin)
    for(n=[1:10]) {
        gap = n*5; // 5..50mm
        y = (n-1)*10;
        // supports
        translate([0,y,4]) cube([5,5,10], center=false);
        translate([gap+5,y,4]) cube([5,5,10], center=false);
        // bridge bar across
        translate([5,y,14]) cube([gap,5,1], center=false);
    }
}

// Overhang angles between 10-70 degrees in 10 deg steps using wedges
module overhang_ramp(origin=[0,0,0]) {
    translate(origin)
    for(a=[10:10:70]) {
        idx = a/10 -1;
        xoff = idx*9; // compact spacing
        len = 20;
        h = 20;
        translate([xoff,0,4]) rotate([0,90,0]) linear_extrude(height=len)
            polygon(points=[[0,0],[h*tan(a),0],[0,h]]);
        // small base strip for stability
        translate([xoff,0,4]) cube([2, len, 2], center=false);
    }
}

// Assemble model
module torture_test_model(){
    difference(){
        base_plate();
        // holes cut into base in left-lower section
        hole_grid(origin=[5,5,0]);
    }
    // pins in left-mid area
    pin_grid(origin=[5,65,0]);
    // thin walls along upper-left edge
    thin_wall_array(origin=[5,95,0]);
    // bridges along bottom-right area
    bridge_array(origin=[60,5,0]);
    // overhang ramps along upper-right area
    overhang_ramp(origin=[65,100,0]);
}

torture_test_model();
