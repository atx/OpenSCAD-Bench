// Stand for IKEA Citronhaj spice jars (Ø40mm x 120mm)
// 3x3 grid, tiered levels (30mm step)

// Parameters
jar_diameter = 40;
jar_clearance = 1.5; // added to diameter for easy fit
holder_wall = 2;
holder_height = 40; // amount of jar height enclosed
step_height = 30;   // tier step between rows
base_thickness = 3;
col_spacing = 52; // center-to-center spacing in X
row_spacing = 52; // center-to-center spacing in Y
rows = 3;
cols = 3;

inner_d = jar_diameter + jar_clearance; // inner diameter of cup
outer_d = inner_d + 2*holder_wall;

// Single cup with notch
module holder_cup() {
    difference() {
        cylinder(d=outer_d, h=holder_height, $fn=80);
        translate([0,0,-0.1]) cylinder(d=inner_d, h=holder_height+0.2, $fn=80);
        // front notch for thumb access
        translate([0, outer_d/2, holder_height/2]) rotate([90,0,0]) cylinder(d=inner_d*0.8, h=outer_d, center=true, $fn=60);
    }
}

// Riser under a cup
module riser(h) {
    cylinder(d=outer_d+8, h=h, $fn=60);
}

module holder_with_riser(z_level){
    union(){
        translate([0,0,base_thickness]) holder_cup();
        riser(z_level);
    }
}

module stand(){
    union(){
        // base plate
        base_size_x = (cols-1)*col_spacing + outer_d + 16;
        base_size_y = (rows-1)*row_spacing + outer_d + 16;
        translate([-base_size_x/2, -base_size_y/2, 0]) cube([base_size_x, base_size_y, base_thickness]);
        // holders on tiers
        for(r=[0:rows-1])
            for(c=[0:cols-1]){
                x = (c-(cols-1)/2)*col_spacing;
                y = (r-(rows-1)/2)*row_spacing;
                z_riser = r*step_height;
                translate([x,y,z_riser]) holder_with_riser(base_thickness);
            }
        // simple gusset ramps between rows to reduce overhangs
        for(r=[0:rows-2]){
            z0 = r*step_height;
            z1 = (r+1)*step_height;
            y_center = (r-(rows-1)/2)*row_spacing + row_spacing/2;
            ramp_width = (cols-1)*col_spacing + outer_d + 10;
            ramp_depth = row_spacing*0.5;
            translate([-ramp_width/2, y_center - ramp_depth/2, base_thickness])
                hull(){
                    translate([0,0,0]) cube([ramp_width, ramp_depth, 2]);
                    translate([0,0,z1-z0]) cube([ramp_width, ramp_depth, 2]);
                }
        }
    }
}

stand();
