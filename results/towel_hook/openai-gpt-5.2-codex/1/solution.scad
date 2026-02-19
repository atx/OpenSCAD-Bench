$fn=64;

// Parameters
plate_w = 50;
plate_h = 30;
plate_t = 6;

arm_len = 40;
arm_d = 12;
arm_w = 20;

hook_r = arm_d/2;

// Helper modules
module oval_cyl_y(len){
    // Cylinder along Y axis with oval cross-section (width in X, thickness in Z)
    scale([arm_w/arm_d,1,1])
        rotate([90,0,0])
            cylinder(h=len, r=hook_r, center=true);
}

module oval_cyl_z(len){
    // Cylinder along Z axis with oval cross-section (width in X, depth in Y)
    scale([arm_w/arm_d,1,1])
        cylinder(h=len, r=hook_r, center=true);
}

module base_plate(){
    difference(){
        translate([-plate_w/2,0,0])
            cube([plate_w, plate_t, plate_h]);
        // M3 countersunk screw hole
        translate([0, plate_t/2, plate_h/2])
            rotate([90,0,0])
                cylinder(h=plate_t+0.5, r=1.7, center=true);
        // Countersink (90 deg)
        translate([0, plate_t-1.5, plate_h/2])
            rotate([90,0,0])
                cylinder(h=3, r1=3.25, r2=1.7, center=true);
    }
}

module hook_body(){
    union(){
        // Horizontal arm
        translate([0, plate_t + arm_len/2, plate_h/2])
            oval_cyl_y(arm_len);
        // Vertical upturn at end
        translate([0, plate_t + arm_len, plate_h/2 + 12.5])
            oval_cyl_z(25);
        // Smooth bend between horizontal and vertical
        hull(){
            translate([0, plate_t + arm_len, plate_h/2])
                oval_cyl_y(2);
            translate([0, plate_t + arm_len, plate_h/2])
                oval_cyl_z(2);
        }
        // Reinforcing gusset under arm
        hull(){
            translate([-arm_w/2, plate_t, plate_h/2 - 6])
                cube([arm_w, 2, 12]);
            translate([-arm_w/2, plate_t + 18, plate_h/2 - 6])
                cube([arm_w, 2, 12]);
        }
    }
}

union(){
    base_plate();
    hook_body();
}
