// 4x Olympus BLS-5 battery case (single-piece, 3D printable)
// Battery: 56 x 36 x 13 mm
// Slots arranged linearly 4x1; batteries stand on smallest face (36x13 footprint)

$fn = 64;

// -------------------- Parameters --------------------
N = 4;

bat_h = 56;          // vertical (Z)
bat_w = 36;          // along X (row direction)
bat_d = 13;          // along Y (depth)

clear_xy = 0.50;     // clearance per side
clear_z  = 0.60;

inner_w = bat_w + 2*clear_xy;
inner_d = bat_d + 2*clear_xy;
inner_h = bat_h + clear_z;

wall    = 2.0;       // outer wall thickness
divider = 2.0;       // thickness between slots
floor_t = 2.2;       // floor thickness

top_extra = 2.0;     // extra height above battery
case_h = floor_t + inner_h + top_extra;

outer_r = 3.0;       // outer corner radius

// Finger hole (per slot)
finger_len = 22;     // along X
finger_w   = 8.5;    // along Y

// Snap tongue + nub (per slot, two sides)
clip_wx    = 10.0;   // tongue width along X
clip_gap   = 0.70;   // gap around tongue cuts
clip_baseZ = 2.2;    // uncut base height of tongue
clip_z0    = floor_t + 6.0;          // tongue start height
clip_h     = inner_h - 6.5;          // tongue height

nub_in     = 0.55;   // nub intrusion into cavity
nub_h      = 1.7;    // nub height
nub_wx     = 8.0;    // nub width along X
nub_z      = floor_t + inner_h - 7.0; // nub vertical placement

// -------------------- Derived dimensions --------------------
case_len = N*inner_w + (N-1)*divider + 2*wall;
case_dep = inner_d + 2*wall;

function slot_xc(i) = -case_len/2 + wall + inner_w/2 + i*(inner_w + divider);

// -------------------- Helpers --------------------
module rounded_box_xy(x, y, z, r){
    // Centered in X/Y, bottom at Z=0
    linear_extrude(height=z)
        offset(r=r)
            square([x-2*r, y-2*r], center=true);
}

module capsule2d(len, wid){
    // Centered capsule, major axis along X
    r = wid/2;
    hull(){
        translate([-(len/2-r),0]) circle(r=r);
        translate([ +(len/2-r),0]) circle(r=r);
    }
}

module nub_wedge_x(width_x, protrude_y, height_z){
    // Wedge whose base lies on Y=0 plane and protrudes +Y. Extruded along X.
    rotate([0,90,0])
        linear_extrude(height=width_x, center=true, convexity=5)
            polygon(points=[
                [0,0],
                [0,height_z],
                [protrude_y,height_z],
                [protrude_y,height_z*0.62]
            ]);
}

module clip_u_slot(xc, side){
    // side: -1 for front wall (y positive inner wall), +1 for back wall (y negative inner wall)
    // Cuts a through-wall U-slot leaving a tongue that can flex outward.
    y_wall_c = side*(inner_d/2 + wall/2);

    cut_h = max(0.1, clip_h - clip_baseZ);
    z_c = clip_z0 + clip_baseZ + cut_h/2;

    y_thru = wall + 0.8; // ensure cut goes fully through the wall

    // Side cuts (left/right)
    translate([xc - clip_wx/2 - clip_gap/2, y_wall_c, z_c])
        cube([clip_gap, y_thru, cut_h], center=true);
    translate([xc + clip_wx/2 + clip_gap/2, y_wall_c, z_c])
        cube([clip_gap, y_thru, cut_h], center=true);

    // Top cut (severs top connection; slight overlap trims tongue top)
    top_cut_h = 1.0;
    translate([xc, y_wall_c, clip_z0 + clip_h - top_cut_h/2])
        cube([clip_wx + 2*clip_gap, y_thru, top_cut_h], center=true);
}

module clip_nub(xc, side){
    // side: -1 => nub protrudes toward -Y (from front wall at y=+inner_d/2)
    // side: +1 => nub protrudes toward +Y (from back wall at y=-inner_d/2)
    y_inner = side*(inner_d/2);

    translate([xc, y_inner, nub_z]){
        if(side == 1) {
            nub_wedge_x(nub_wx, nub_in, nub_h);
        } else {
            mirror([0,1,0]) nub_wedge_x(nub_wx, nub_in, nub_h);
        }
    }
}

// -------------------- Model --------------------
module battery_case(){
    union(){
        difference(){
            // Outer body
            rounded_box_xy(case_len, case_dep, case_h, outer_r);

            // Cavities (4 slots)
            for(i=[0:N-1]){
                xc = slot_xc(i);
                translate([xc - inner_w/2, -inner_d/2, floor_t])
                    cube([inner_w, inner_d, case_h], center=false);
            }

            // Finger push holes (one per slot), through the floor
            for(i=[0:N-1]){
                xc = slot_xc(i);
                translate([xc, 0, 0])
                    linear_extrude(height=floor_t + 0.4)
                        capsule2d(finger_len, finger_w);
            }

            // U-slots that create the snap tongues (front/back wall per slot)
            for(i=[0:N-1]){
                xc = slot_xc(i);
                clip_u_slot(xc, -1);
                clip_u_slot(xc,  1);
            }
        }

        // Add snap nubs on both long sides of each slot
        for(i=[0:N-1]){
            xc = slot_xc(i);
            clip_nub(xc, -1);
            clip_nub(xc,  1);
        }
    }
}

battery_case();
