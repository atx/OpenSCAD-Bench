// Chess Rook Model
// Parametric simple rook with crenellations

$fn = 96;

module rook(
    base_d=40,
    base_h=8,
    body_d=30,
    body_h=35,
    taper=2,
    neck_d=24,
    neck_h=6,
    head_d=32,
    head_h=10,
    crenel_count=6,
    crenel_gap=6,
    wall_thickness=3
){
    union(){
        // Base
        cylinder(d=base_d, h=base_h);
        // Body tapered
        translate([0,0,base_h])
            cylinder(h=body_h, d1=body_d+taper*2, d2=body_d-taper*2);
        // Neck
        translate([0,0,base_h+body_h])
            cylinder(d=neck_d, h=neck_h);
        // Head ring with crenellations cut out
        translate([0,0,base_h+body_h+neck_h])
            head_with_crenels(head_d, head_h, crenel_count, crenel_gap, wall_thickness);
    }
}

module head_with_crenels(d, h, count, gap, thickness){
    difference(){
        // outer head
        cylinder(d=d, h=h);
        // hollow core to create wall thickness
        translate([0,0,0])
            cylinder(d=d-2*thickness, h=h);
        // crenel cutouts
        for(i=[0:count-1]){
            rotate([0,0,360/count * i])
                translate([d/2 - gap/2, 0, h/2])
                    cube([gap, d, h+2], center=true);
        }
    }
}

rook();
