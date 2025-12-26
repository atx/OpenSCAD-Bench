// Sturdy 3D-printable towel hook with single M3 flat head screw
// Default units: millimeters

// Parameters
plate_width = 30;
plate_height = 40;
plate_thickness = 6;
hook_width = 20; // along X

arm_height = 20;   // Y dimension of main arm
arm_length = 26;   // Z dimension from plate face to near tip
lip_height = 14;   // extra height at tip for retention
lip_depth = 8;     // thickness of lip in Z

screw_shaft_r = 1.6; // M3 clearance
countersink_r = 3.2; // for flat head
countersink_depth = 3;

$fn = 80;

module rounded_rect_xy(w,h,r){
    offset(r) offset(-r) square([w,h], center=true);
}

module plate(){
    linear_extrude(height=plate_thickness)
        rounded_rect_xy(plate_width, plate_height, 4);
}

module screw_hole(){
    translate([0,0,-1]) union(){
        cylinder(h=plate_thickness+2, r=screw_shaft_r);
        translate([0,0,plate_thickness-countersink_depth])
            cylinder(h=countersink_depth+1, r1=countersink_r, r2=screw_shaft_r);
    }
}

module hook_arm(){
    // Main arm: thick block protruding from plate
    translate([0,0,plate_thickness + arm_length/2])
        cube([hook_width, arm_height, arm_length], center=true);
}

module hook_lip(){
    // Upward lip near the end, overlapping well with the arm
    translate([0, arm_height/2, plate_thickness + arm_length - lip_depth/2])
        cube([hook_width, lip_height, lip_depth], center=true);
}

module hook_wedge(){
    // Strengthening/ramping wedge to ease printing under the lip
    hull(){
        translate([0, arm_height/2 - 2, plate_thickness + arm_length - lip_depth])
            cube([hook_width, 4, 4], center=true);
        translate([0, arm_height/2 - 2, plate_thickness + arm_length/2])
            cube([hook_width, 4, 4], center=true);
    }
}

module hook_root(){
    // Extra beef at root to spread load into plate
    hull(){
        translate([0, -arm_height/2 + 2, plate_thickness/2])
            cube([hook_width, 6, plate_thickness], center=true);
        translate([0, -arm_height/2 + 2, plate_thickness + 6])
            cube([hook_width, 8, 6], center=true);
    }
}

module model(){
    difference(){
        union(){
            plate();
            hook_arm();
            hook_lip();
            hook_wedge();
            hook_root();
        }
        screw_hole();
    }
}

model();