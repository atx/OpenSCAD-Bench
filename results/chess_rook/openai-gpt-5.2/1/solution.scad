// Chess rook piece (parametric)
// Units: mm

$fn = 160;

// -------- Parameters --------
H = 45;                 // overall height
base_r = 18;
base_h = 6;
foot_r = 16.5;
waist_r = 10.5;
neck_r = 9.5;
shoulder_r = 13;

crown_z0 = 38;          // start of crown section (z)
crown_h = H - crown_z0; // height of crown
crown_r = 13.5;

crenels = 6;            // number of battlements
slot_w = 7;             // angular slot width implemented as chord width
slot_d = 7;             // radial depth of cut
slot_h = 5.2;           // vertical height of cut
slot_z = H - slot_h;    // bottom of slot

// Small bevels via short steps

// -------- Helpers --------
module rook_body(){
    // Profile in XZ plane for rotate_extrude (x=radius, z=height)
    // Keep x>=0. Last point should return near axis to avoid open surface.
    profile = [
        [0,0],
        [base_r,0],
        [base_r,1.5],
        [base_r-1.0,2.4],
        [foot_r,base_h],
        [foot_r-0.8,base_h+1.2],
        [12.8,12],
        [waist_r,18],
        [waist_r+1.2,23],
        [shoulder_r,28.5],
        [shoulder_r-0.8,31],
        [neck_r,34.5],
        [neck_r+1.5,36.5],
        [crown_r-0.8,crown_z0],
        [crown_r,crown_z0+0.8],
        [crown_r,H-0.8],
        [crown_r-0.8,H],
        [0,H]
    ];

    rotate_extrude(convexity=10)
        polygon(profile);
}

module rook_crenels(){
    // Ensure we only cut within the crown ring region.
    // Create a crown cylinder then subtract repeated rectangular slots.
    difference(){
        translate([0,0,crown_z0])
            cylinder(h=crown_h, r=crown_r);

        for(i=[0:crenels-1]){
            rotate([0,0, i*360/crenels])
                translate([crown_r - slot_d/2, -slot_w/2, slot_z])
                    cube([slot_d, slot_w, slot_h+0.4], center=false);
        }

        // Hollow out interior slightly to create a rim, like a traditional rook.
        translate([0,0,crown_z0+0.6])
            cylinder(h=crown_h, r=crown_r-3.2);
    }
}

module rook(){
    union(){
        rook_body();
        rook_crenels();

        // Add a subtle top lip
        translate([0,0,H-1.2])
            cylinder(h=1.2, r1=crown_r, r2=crown_r-0.8);
    }
}

// -------- Render --------
rook();
