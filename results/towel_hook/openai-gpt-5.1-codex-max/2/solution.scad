// Towel hook with single M3 flat head screw mount
// Units: mm

plate_w = 40;   // width (X)
plate_h = 40;   // height (Y)
plate_t = 6;    // thickness (Z)

hook_depth = 45; // total projection from wall (mm)
hook_thick = 12;
hook_width = 18;
hook_rise = 18;

// Screw hole placed above hook center
screw_center = [0, plate_h/4]; // [x,y] on plate
screw_clear = 3.4;
countersink_top_d = 7;
countersink_angle = 90; // degrees
countersink_h = (countersink_top_d - screw_clear) / 2 / tan(countersink_angle/2 * PI/180);

module cone(d1=10, d2=5, h=5){
    cylinder(h=h, d1=d1, d2=d2, $fn=60);
}

module backplate(){
    // Plate lies in XY plane, thickness along +Z; back at Z=0, front at Z=plate_t
    translate([-plate_w/2, -plate_h/2, 0])
        cube([plate_w, plate_h, plate_t], center=false);
}

module countersunk_hole(){
    cylinder(h=plate_t+0.5, d=screw_clear, $fn=40);
    translate([0,0,plate_t])
        rotate([180,0,0])
            cone(d1=countersink_top_d, d2=screw_clear, h=countersink_h);
}

module hook_arm(){
    base_len = 14;
    // choose arm length so total projection ~ hook_depth
    arm_len = max(hook_depth - (hook_thick*2 + base_len), hook_thick/2);
    z0 = hook_thick/2; // bottom at z=0

    union(){
        hull(){
            translate([0,0,z0]) cube([hook_thick, hook_thick, hook_thick], center=true);
            translate([hook_thick/2 + base_len/2,0,z0]) cube([base_len, hook_thick, hook_thick], center=true);
        }
        hull(){
            translate([hook_thick/2 + base_len/2,0,z0]) cube([base_len, hook_thick, hook_thick], center=true);
            translate([hook_thick/2 + base_len + arm_len/2,0,z0]) cube([arm_len, hook_thick, hook_thick], center=true);
        }
        hull(){
            translate([hook_thick/2 + base_len + arm_len/2,0,z0]) cube([arm_len, hook_thick, hook_thick], center=true);
            translate([hook_thick/2 + base_len + arm_len + hook_thick/2,0,z0 + hook_rise]) cube([hook_thick, hook_width, hook_thick], center=true);
        }
        hull(){
            translate([hook_thick/2 + base_len + arm_len + hook_thick/2,0,z0 + hook_rise]) cube([hook_thick, hook_width, hook_thick], center=true);
            translate([hook_thick/2 + base_len + arm_len + hook_thick/2,0,z0 + hook_rise + hook_thick]) cube([hook_thick, hook_width, hook_thick], center=true);
        }
    }
}

module towel_hook(){
    difference(){
        union(){
            backplate();
            // Rotate hook so it protrudes out from the wall (+Z), keep centered on plate
            base_len = 14;
            arm_len_local = max(hook_depth - (hook_thick*2 + base_len), hook_thick/2);
            hook_extent = hook_thick*2 + base_len + arm_len_local; // approximate front-to-back reach
            translate([hook_extent/2, 0, plate_t])
                rotate([0,-90,0])
                    translate([hook_thick/2, 0, 0]) hook_arm();
        }
        translate([screw_center[0], screw_center[1], 0]) countersunk_hole();
    }
}

towel_hook();
