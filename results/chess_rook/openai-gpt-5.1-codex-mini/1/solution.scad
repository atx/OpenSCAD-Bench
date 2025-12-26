$fn=120;

module rook(){
    base();
    body();
    crown();
}

module base(){
    union(){
        translate([0,0,0])
            cylinder(h=5, r=20);
        translate([0,0,5])
            cylinder(h=3, r=18);
        translate([0,0,8])
            cylinder(h=2, r=17);
    }
}

module body(){
    union(){
        translate([0,0,10])
            cylinder(h=22, r1=16, r2=14);
        translate([0,0,32])
            cylinder(h=4, r=13);
        translate([0,0,36])
            cylinder(h=4, r1=13, r2=12);
        translate([0,0,40])
            cylinder(h=4, r=12);
    }
}

module crown(){
    union(){
        translate([0,0,44])
            cylinder(h=6, r=16);
        translate([0,0,50])
            cylinder(h=8, r=15);
        translate([0,0,58])
            cylinder(h=3, r=14);
        crown_notches();
    }
}

module crown_notches(){
    difference(){
        translate([0,0,50])
            cylinder(h=11, r=15);
        for (i=[0:5]){
            rotate([0,0,i*60])
                translate([0,12,51])
                    cube([12,6,12], center=true);
        }
    }
}

rotate([0,0,0])
    rook();