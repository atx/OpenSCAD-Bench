$fn=96;

module rook(){
    // base
    base_h=8;
    base_r=18;
    mid_h=20;
    mid_r=13;
    top_h=6;
    top_r=16;
    crenel_h=6;
    crenel_r=16;
    crenel_count=6;

    union(){
        // base pedestal
        cylinder(h=base_h, r=base_r);
        translate([0,0,base_h]) cylinder(h=3, r1=base_r, r2=mid_r+2);
        // shaft
        translate([0,0,base_h+3]) cylinder(h=mid_h, r=mid_r);
        // top flare
        translate([0,0,base_h+3+mid_h]) cylinder(h=top_h, r1=mid_r, r2=top_r);
        // battlement ring
        translate([0,0,base_h+3+mid_h+top_h]) difference(){
            cylinder(h=crenel_h, r=crenel_r);
            cylinder(h=crenel_h, r=crenel_r-4);
        }
        // crenellations (blocks)
        for(i=[0:crenel_count-1]){
            angle = 360/crenel_count*i;
            translate([0,0,base_h+3+mid_h+top_h+crenel_h-2])
                rotate([0,0,angle])
                    translate([crenel_r-3,0,0])
                        cube([6,6,4], center=true);
        }
    }
}

rook();
