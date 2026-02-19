$fn=160;

module rook() {
    union() {
        // base
        cylinder(h=5, r=20);
        translate([0, 0, 5])
            cylinder(h=2, r=18);
        
        // body
        translate([0, 0, 7])
            cylinder(h=25, r1=16, r2=14);
        translate([0, 0, 32])
            cylinder(h=3, r=18);
        
        // turret with crenellations
        translate([0, 0, 35])
            difference() {
                cylinder(h=13, r=17);
                for (angle = [0, 90, 180, 270]) {
                    rotate([0, 0, angle])
                        translate([10, -8, 0])
                            cube([8, 16, 14], center=false);
                }
            }
    }
}

rook();