// Olympus BLS-5 Battery Case - 4x1 Linear Arrangement
// Battery: 56 x 36 x 13 mm
// Upright on 13x36mm face, largest faces (56x36) facing each other
// One-piece 3D printable, snap-fit retention, finger holes for removal

// ===== Parameters =====
bat_w = 36;    // width (X)
bat_d = 13;    // depth (Y) - batteries lined up along Y
bat_h = 56;    // height (Z) - standing upright

tol = 0.5;
wall = 2.5;
floor_t = 3.0;
divider_t = 2.0;

slot_w = bat_w + 2*tol;     // 37
slot_d = bat_d + 2*tol;     // 14
expose = 10;                 // battery protrudes above case for grip
slot_h = bat_h - expose;    // 46mm internal height

n_bat = 4;

// Snap-fit
snap_w = 10;
snap_protrude = 1.0;
snap_bump_h = 2.5;
snap_from_top = 4;

// Finger hole
finger_d = 16;

corner_r = 3;

// Overall
case_w = slot_w + 2*wall;
case_d = n_bat*slot_d + (n_bat-1)*divider_t + 2*wall;
case_h = slot_h + floor_t;

$fn = 48;

echo(str("Case: ", case_w, "x", case_d, "x", case_h, " mm"));

// ===== Helpers =====
module rcube(size, r) {
    hull() {
        for (x=[r, size[0]-r], y=[r, size[1]-r])
            translate([x, y, 0])
                cylinder(r=r, h=size[2]);
    }
}

function slot_y(i) = wall + i*(slot_d + divider_t);

// Snap bump on wall surface, protrudes in +Y
module snap_bump(z_base) {
    z = z_base;
    // Retention ledge (sharper bottom face for positive lock)
    hull() {
        translate([0, 0, z])
            cube([snap_w, 0.01, snap_bump_h*0.3]);
        translate([0, snap_protrude, z + snap_bump_h*0.3])
            cube([snap_w, 0.01, 0.01]);
    }
    // Ramp (gentler top face for push-in)
    hull() {
        translate([0, snap_protrude, z + snap_bump_h*0.3])
            cube([snap_w, 0.01, 0.01]);
        translate([0, 0.01, z + snap_bump_h])
            cube([snap_w, 0.01, 0.01]);
    }
    // Blend back to wall above
    hull() {
        translate([0, 0.01, z + snap_bump_h])
            cube([snap_w, 0.01, 0.01]);
        translate([0, 0, z + snap_bump_h + 2])
            cube([snap_w, 0.01, 0.01]);
    }
}

// ===== Main Case =====
module battery_case() {
    snap_z = slot_h - snap_from_top - snap_bump_h;
    
    difference() {
        union() {
            // --- Outer shell ---
            rcube([case_w, case_d, case_h], corner_r);
            
            // --- Snap tabs on X walls (left/right of each slot) ---
            for (i = [0:n_bat-1]) {
                sy = slot_y(i);
                // Left wall snaps
                translate([wall, sy + (slot_d-snap_w)/2, floor_t])
                    snap_bump(snap_z);
                // Right wall snaps
                translate([wall+slot_w, sy + (slot_d+snap_w)/2, floor_t])
                    rotate([0,0,180])
                        snap_bump(snap_z);
            }
            
            // --- Bottom grip ribs ---
            for (x = [5 : 6 : case_w-3]) {
                translate([x, corner_r, -0.8])
                    cube([1.2, case_d - 2*corner_r, 0.8]);
            }
        }
        
        // --- Slot cavities ---
        for (i = [0:n_bat-1]) {
            sy = slot_y(i);
            
            // Main cavity
            translate([wall, sy, floor_t])
                cube([slot_w, slot_d, slot_h + 10]);
            
            // Top entry chamfer for easy battery insertion
            hull() {
                translate([wall, sy, case_h - 2.5])
                    cube([slot_w, slot_d, 0.01]);
                translate([wall-1.2, sy-0.8, case_h + 0.01])
                    cube([slot_w+2.4, slot_d+1.6, 0.01]);
            }
            
            // Finger hole through floor
            translate([wall + slot_w/2, sy + slot_d/2, -2])
                cylinder(d=finger_d, h=floor_t + 4);
            
            // Finger hole chamfer on bottom for comfort
            translate([wall + slot_w/2, sy + slot_d/2, -0.01])
                mirror([0,0,1])
                    cylinder(d1=finger_d, d2=finger_d+4, h=1.5);
        }
        
        // --- Top outer edge chamfer ---
        difference() {
            translate([-1, -1, case_h - 1.2])
                cube([case_w+2, case_d+2, 1.7]);
            hull() {
                translate([0, 0, case_h - 1.2])
                    rcube([case_w, case_d, 0.01], corner_r);
                translate([0.8, 0.8, case_h + 0.01])
                    rcube([case_w-1.6, case_d-1.6, 0.01], max(corner_r-0.8, 0.5));
            }
        }
        
        // --- Engraved text on front face (Y=0 face) ---
        translate([case_w/2, 0.8, case_h*0.45])
            rotate([90, 0, 0])
                linear_extrude(height=0.8)
                    text("BLS-5", size=7, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
                         
        translate([case_w/2, 0.8, case_h*0.45 - 11])
            rotate([90, 0, 0])
                linear_extrude(height=0.8)
                    text("×4", size=5.5, halign="center", valign="center",
                         font="Liberation Sans");
    }
}

battery_case();
