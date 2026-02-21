// 3D printable towel hook with a single countersunk M3 screw
// Units: mm

$fn = 80;

// ---------------- Parameters ----------------
plate_L = 50;          // X
plate_W = 30;          // Y
plate_T = 9;           // Z
plate_R = 4;           // plate corner radius (XY)

// Root pad (adds material near the arm, kept clear of the screw head area)
root_pad_h = 4;
root_pad_L = 18;
root_pad_W = 24;
root_pad_R = 6;
root_pad_x = 16;       // pad center X; chosen to avoid overlapping the countersink

// M3 flat head screw (typical)
hole_d = 3.4;          // clearance for M3
csink_top_d = 6.6;     // countersink diameter at surface
csink_depth = 3.0;     // depth of countersink cone

// Hook body
arm_r = 7.2;           // base radius for the arm (before scaling)
arm_sy = 1.25;         // widen in Y
arm_sz = 0.95;         // slightly flatter in Z

// Arm path points (printing orientation: plate on bed, hook on top)
arm_pts = [
    [-9,  0, plate_T-2],
    [ 0,  0, plate_T+4],
    [18,  0, plate_T+20],
    [41,  0, plate_T+14],
    [58,  0, plate_T+6],
    [52,  0, plate_T+2],   // ramp down (helps print without support)
    [42,  0, plate_T+2],
    [42,  0, plate_T+12]   // upturned lip
];

// ---------------- Helpers ----------------
module rounded_rect_2d(L, W, r){
    offset(r=r) square([L-2*r, W-2*r], center=true);
}

module plate_solid(){
    linear_extrude(height=plate_T)
        rounded_rect_2d(plate_L, plate_W, plate_R);
}

module root_pad(){
    translate([root_pad_x, 0, plate_T])
        linear_extrude(height=root_pad_h)
            rounded_rect_2d(root_pad_L, root_pad_W, root_pad_R);
}

module arm_node(p){
    translate(p)
        scale([1, arm_sy, arm_sz])
            sphere(r=arm_r);
}

module arm_sweep(points){
    union(){
        for(i=[0:len(points)-2])
            hull(){
                arm_node(points[i]);
                arm_node(points[i+1]);
            }
    }
}

module gusset(){
    // Reinforcing web between plate and arm (kept wide at the root)
    hull(){
        translate([6,0,plate_T+0.02])
            linear_extrude(height=0.9)
                offset(r=2)
                    square([30, 22], center=true);

        translate([14,0,plate_T+12])
            scale([1, 1.2, 0.8])
                sphere(r=arm_r*0.95);
    }
}

module countersunk_m3(){
    // Through-hole
    translate([0,0,-0.2])
        cylinder(h=plate_T + root_pad_h + 2.4, d=hole_d);

    // Countersink from the top surface of the base plate (flat-head screw)
    translate([0,0,plate_T-csink_depth])
        cylinder(h=csink_depth+0.3, d1=csink_top_d, d2=hole_d);

    // Anti-elephant-foot relief ring at the surface
    translate([0,0,plate_T-0.35])
        cylinder(h=0.6, d=csink_top_d+0.4);
}

// ---------------- Model ----------------
module towel_hook(){
    difference(){
        union(){
            plate_solid();
            root_pad();
            arm_sweep(arm_pts);
            gusset();
        }
        countersunk_m3();
    }
}

towel_hook();
