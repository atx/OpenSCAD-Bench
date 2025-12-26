$fn = 120;

module base_plate(){
    difference(){
        // Mounting plate thick enough to distribute stress
        cylinder(h=5, d=40);
        // Countersink for M3 flat head screw (approx. 120°)
        translate([0,0,5])
            cylinder(h=4, r1=12, r2=2, center=false);
        // Screw hole through the plate
        translate([0,0,-1])
            cylinder(h=8, d=3);
    }
}

module hook_arm(){
    union(){
        // Vertical stem rising from the plate
        translate([0,0,5])
            cylinder(h=25, r=5);
        // Outward arm to support towels
        translate([0,2.5,30])
            rotate([90,0,0])
                cylinder(h=45, r=4, center=false);
        // Upward lip at the tip to keep towels from sliding off
        translate([0,47,32])
            cylinder(h=18, r=3.8, center=false);
        // Triangular gusset to stiffen the arm
        translate([0,5,15])
            rotate([90,0,0])
                linear_extrude(height=5)
                    polygon(points=[[0,0],[25,6],[25,9],[0,3]]);
    }
}

module towel_hook(){
    union(){
        base_plate();
        hook_arm();
    }
}

// Build the hook
translate([0,0,0])
    towel_hook();
