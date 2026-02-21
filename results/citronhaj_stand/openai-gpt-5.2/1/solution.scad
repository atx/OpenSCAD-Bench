// IKEA Citronhaj 9-jar tiered stand (3x3)
// Units: mm
// Designed to be easy to 3D print: solid stair body (let your slicer handle infill).

$fn = 96;

// --- Jar / fit parameters ---
jar_d = 40;
jar_h = 120;
clearance_d = 2.0;            // total diameter clearance (increase if tight)
cup_id = jar_d + clearance_d; // inner diameter of holder

cup_wall = 3.0;               // holder wall thickness
cup_od = cup_id + 2*cup_wall;

cup_h = 48;                    // how much of the jar is enveloped

// Opening to make removal easier
notch_w = 18;                  // width of front access notch in the ring

// --- Layout parameters ---
cols = 3;
rows = 3;

spacing_x = 55; // center-to-center
spacing_y = 60; // center-to-center

margin = 8; // outer margin from holder OD to outer edge

// --- Tier parameters ---
base_th = 8;        // top surface height for front row
step_h = 30;        // ~3 cm per level

// Derived overall size
W = (cols-1)*spacing_x + cup_od + 2*margin;
D = (rows-1)*spacing_y + cup_od + 2*margin;

// Row center positions (front->back) and column centers (left->right)
function x_center(c) = margin + cup_od/2 + c*spacing_x;
function y_center(r) = margin + cup_od/2 + r*spacing_y;

// Step boundaries at midpoints between row centers
front_y = 0;
y1 = (y_center(0) + y_center(1))/2;  // boundary between row 0 and 1
n2 = (y_center(1) + y_center(2))/2;  // boundary between row 1 and 2
back_y = D;

front_depth = y1 - front_y;
mid_depth   = n2 - y1;
back_depth  = back_y - n2;

z1 = base_th;
z2 = base_th + step_h;
z3 = base_th + 2*step_h;

module cup_ring(h=cup_h, id=cup_id, od=cup_od, cham=1.2, cham_h=3) {
    // Ring with a small internal lead-in chamfer and a front notch for easier grabbing.
    difference() {
        cylinder(h=h, d=od);

        // straight bore
        translate([0,0,-0.1])
            cylinder(h=h-cham_h+0.2, d=id);

        // lead-in at top (slightly wider)
        translate([0,0,h-cham_h-0.01])
            cylinder(h=cham_h+0.2, d1=id, d2=id+2*cham);

        // front access notch (faces negative Y, i.e., towards the front of the stand)
        translate([-notch_w/2, -od, -0.5])
            cube([notch_w, od, h+1]);
    }
}

module staircase_body() {
    // Solid staircase. Print with normal infill to save material.
    union() {
        // front (lowest)
        translate([0, 0, 0])
            cube([W, front_depth, z1]);

        // middle
        translate([0, front_depth, 0])
            cube([W, mid_depth, z2]);

        // back (highest)
        translate([0, front_depth+mid_depth, 0])
            cube([W, back_depth, z3]);
    }
}

module holders() {
    // Place 3x3 rings on the three tier top surfaces.
    for (r=[0:rows-1]) {
        zt = (r==0) ? z1 : (r==1 ? z2 : z3);
        for (c=[0:cols-1]) {
            translate([x_center(c), y_center(r), zt])
                cup_ring();
        }
    }
}

// --- Model ---
union() {
    staircase_body();
    holders();
}
