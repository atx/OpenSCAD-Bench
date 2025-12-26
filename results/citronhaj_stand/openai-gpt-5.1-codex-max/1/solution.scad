// IKEA Citronhaj spice jar stand - 3x3 tiered holder
// Jar dimensions: 40mm diameter, height 120mm
// Stand: 3 tiers with ~30mm step height

$fn = 96;

// Parameters
jar_d = 40;
jar_r = jar_d/2;
clearance = 1.5;          // radial clearance
wall = 3;                 // cup wall thickness
cup_h = 25;               // height of holder wall (kept low to clear next tier)
lip_drop = 15;            // front opening drop for easy removal
spacing = 55;             // center-to-center spacing of jars
step_h = 30;              // tier height difference
plate_thick = 5;          // thickness of each tier platform
plate_depth = 60;         // depth of each tier plate
plate_width = spacing*3 + 10; // total width with margin

module cup(){
    outer_r = jar_r + wall + clearance;
    inner_r = jar_r + clearance;
    difference(){
        cylinder(r=outer_r, h=cup_h);
        translate([0,0,1]) cylinder(r=inner_r, h=cup_h); // leave 1mm floor
        // front notch for easier access
        translate([-outer_r, -outer_r, 0]) cube([outer_r*2, outer_r, lip_drop]);
    }
}

module tier(row){
    // row index 0 front, 1 middle, 2 back
    x_start = -((spacing*2)/2);
    z = row*step_h;
    y = row*(plate_depth-5); // slight overlap for stability
    // platform
    translate([0,y,z]) cube([plate_width, plate_depth, plate_thick], center=true);
    // cups
    for(i=[0:2]){
        translate([x_start + i*spacing, y, z + plate_thick]) cup();
    }
}

// Assemble all tiers
union(){
    for(r=[0:2]) tier(r);
}
