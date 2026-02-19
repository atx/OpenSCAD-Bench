$fn=64;

// Parameters
plate_w = 50;
plate_h = 30;
plate_t = 6;

hook_th = 8;
hook_w = 20;
hook_len = 25;

// Countersunk M3 flat head screw dimensions
screw_clear = 3.4; // clearance hole
cs_d = 6.5;        // countersink diameter

module countersunk_hole(){
    cylinder(d=screw_clear,h=plate_t+2,center=false);
    translate([0,0,plate_t-0.01])
        cylinder(d1=cs_d,d2=screw_clear,h=(cs_d-screw_clear)/2,center=false);
}

module hook(){
    stem_h = 30;
    stem_t = hook_th;
    stem_w = hook_w;

    translate([0,0,plate_t])
    union(){
        // stem
        translate([plate_w/2-stem_w/2,plate_h- stem_t,0])
            cube([stem_w,stem_t,stem_h]);

        // arm body
        translate([plate_w/2-hook_w/2,plate_h-stem_t/2,stem_h-hook_th/2])
            cube([hook_w,hook_len,hook_th]);

        // rounded transitions for arm
        hull(){
            translate([plate_w/2,plate_h-stem_t/2,stem_h-hook_th/2])
                cylinder(d=hook_th,h=hook_th);
            translate([plate_w/2,plate_h-stem_t/2+hook_len,stem_h-hook_th/2])
                cylinder(d=hook_th,h=hook_th);
        }

        // end knob
        translate([plate_w/2,plate_h-stem_t/2+hook_len,stem_h-hook_th/2])
            sphere(d=hook_th*1.2);

        // gusset for strength
        hull(){
            translate([plate_w/2-stem_w/2,plate_h-stem_t,0])
                cube([stem_w,stem_t,1]);
            translate([plate_w/2-hook_w/2,plate_h-stem_t/2,stem_h/2])
                cube([hook_w,hook_th,1]);
        }
    }
}

union(){
    difference(){
        hull(){
            translate([5,5,0]) cylinder(r=5,h=plate_t);
            translate([plate_w-5,5,0]) cylinder(r=5,h=plate_t);
            translate([5,plate_h-5,0]) cylinder(r=5,h=plate_t);
            translate([plate_w-5,plate_h-5,0]) cylinder(r=5,h=plate_t);
        }
        translate([plate_w/2,plate_h/2,-1]) countersunk_hole();
    }
    hook();
}
