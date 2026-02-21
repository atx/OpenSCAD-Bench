// 3D printable towel hook for a single M3 flat head (countersunk) screw
// Units: mm

$fn = 96;

// ---------------- Parameters ----------------
plate_w = 44;
plate_h = 44;
plate_t = 7;
plate_corner_r = 7;

// Place screw above the hook so a screwdriver can access it
hole_y = 12;          // +Y is up

// M3 flat head screw (90°) allowances for printing
m3_clear_d = 3.4;     // clearance hole
cs_head_d  = 6.5;     // countersink major diameter
cs_depth   = 2.3;     // countersink depth from front face

// Hook geometry (robust, prints without support on most printers)
arm_d    = 16;        // main arm thickness
arm_out  = 56;        // reach from wall
arm_drop = 20;        // downward drop at the end
lip_up   = 10;        // upturn to retain towel

// Reinforcement web
web_w = 18;           // web thickness in X (centered)
web_taper = 0.58;     // fraction of arm reach where web ends

// Back friction ribs (helps resist rotation with a single screw)
add_back_ribs = true;
rib_h = 0.7;
rib_w = 1.2;

// ---------------- Helpers ----------------
module rounded_plate_2d(w,h,r){
    offset(r=r) square([w-2*r, h-2*r], center=true);
}

module plate(){
    linear_extrude(height=plate_t)
        rounded_plate_2d(plate_w, plate_h, plate_corner_r);
}

module countersunk_hole(){
    // Through hole
    translate([0,hole_y,-0.5])
        cylinder(h=plate_t+1.0, d=m3_clear_d);

    // Countersink from front face (z=plate_t)
    translate([0,hole_y,plate_t-cs_depth])
        cylinder(h=cs_depth+0.6, d1=cs_head_d, d2=m3_clear_d);
}

module back_ribs(){
    if(add_back_ribs){
        // Small ribs on the wall-facing side (z=0..rib_h)
        // to increase friction and reduce tendency to rotate.
        for(xpos=[-12, 12]){
            translate([xpos,0,0])
                linear_extrude(height=rib_h)
                    square([rib_w, plate_h*0.72], center=true);
        }
    }
}

module arm_capsule(p0, p1, d){
    hull(){
        translate(p0) sphere(d=d);
        translate(p1) sphere(d=d);
    }
}

module hook_arm(){
    // wall plane is z=0, hook extends +z

    root_y = 0;

    // Path points
    p0 = [0, root_y, plate_t];
    p1 = [0, root_y-5, plate_t + arm_out*0.42];
    p2 = [0, root_y-arm_drop, plate_t + arm_out];
    p3 = [0, root_y-arm_drop + lip_up, plate_t + arm_out + 6];

    web_end_z = plate_t + arm_out*web_taper;

    union(){
        // Root boss spreads stress into the plate
        translate([0,root_y,0])
            cylinder(h=plate_t, d=arm_d+14);

        // Main arm
        arm_capsule(p0, p1, arm_d);
        arm_capsule(p1, p2, arm_d);
        arm_capsule(p2, p3, arm_d*0.92);

        // End knob to keep towel on the hook
        translate(p3) sphere(d=arm_d*1.08);

        // Reinforcement web (a fin in the YZ plane, extruded along X)
        rotate([0,90,0])
            linear_extrude(height=web_w, center=true)
                polygon(points=[
                    [plate_t,   8],
                    [plate_t,  -6],
                    [web_end_z,-20],
                    [web_end_z, -8]
                ]);

        // Local blend near root
        translate([0,root_y,plate_t])
            sphere(d=arm_d+6);
    }
}

module towel_hook_raw(){
    difference(){
        union(){
            plate();
            back_ribs();
            hook_arm();
        }
        countersunk_hole();
    }
}

// Clip anything behind the wall plane (keeps the back face flat)
intersection(){
    towel_hook_raw();
    translate([-1000,-1000,0]) cube([2000,2000,2000]);
}
