// Towel Hook - Wall mounted with single M3 flat head (countersunk) screw
// Designed for 3D printing - robust enough for a large towel
// Print orientation: wall plate flat on print bed (back face down)

$fn = 100;

// === Wall Plate Parameters ===
plate_w = 36;           // Width of wall plate
plate_h = 50;           // Height of wall plate  
plate_t = 5;            // Thickness of wall plate
plate_corner_r = 5;     // Corner rounding radius

// === Hook Parameters ===
hook_w = 24;            // Width of the hook body
hook_bar_r = 5;         // Radius of hook bar cross-section (10mm thick)
hook_reach = 35;        // How far hook tip extends from wall
hook_inner_r = 14;      // Inner radius of the hook curve

// === M3 Countersunk Screw ===
m3_clear = 3.4;         // M3 clearance hole
m3_head_d = 7.0;        // Countersunk head outer diameter
m3_cs_depth = 2.0;      // Countersink depth

// === Derived ===
screw_z = plate_h/2 - 13;
arm_bottom_z = -plate_h/2 + 6;
arm_t = hook_bar_r * 2;

// --- 2D hook side profile (in YZ plane) ---
module hook_side_profile() {
    arm_y_end = hook_reach - hook_inner_r;
    
    // Straight arm from wall to curve
    hull() {
        translate([0, arm_bottom_z + hook_bar_r])
            circle(r=hook_bar_r);
        translate([arm_y_end, arm_bottom_z + hook_bar_r])
            circle(r=hook_bar_r);
    }
    
    // J-curve
    curve_cx = arm_y_end;
    curve_cz = arm_bottom_z + hook_bar_r + hook_inner_r + hook_bar_r;
    
    steps = 64;
    start_a = -90;
    end_a = 145;
    
    for (i = [0:steps-1]) {
        a1 = start_a + i * (end_a - start_a) / steps;
        a2 = start_a + (i+1) * (end_a - start_a) / steps;
        hull() {
            translate([curve_cx + hook_inner_r * cos(a1), 
                       curve_cz + hook_inner_r * sin(a1)])
                circle(r=hook_bar_r);
            translate([curve_cx + hook_inner_r * cos(a2), 
                       curve_cz + hook_inner_r * sin(a2)])
                circle(r=hook_bar_r);
        }
    }
}

// Gusset profile
module gusset_profile() {
    gusset_h = 22;
    gusset_l = 18;
    
    // Curved gusset - approximate with polygon
    steps = 20;
    points = [
        for (i = [0:steps]) 
            let(t = i/steps)
            [gusset_l * (1-t*t), arm_bottom_z + arm_t + gusset_h * t]
    ];
    // Close the polygon
    all_points = concat(
        [[0, arm_bottom_z + arm_t]],
        [for (i = [1:steps]) 
            let(t = i/steps)
            [gusset_l * (1-t) * (1-t), arm_bottom_z + arm_t + gusset_h * t]
        ],
        [[0, arm_bottom_z + arm_t + gusset_h]]
    );
    polygon(all_points);
}

// === Main modules ===

module wall_plate() {
    translate([0, plate_t/2, 0])
        rotate([90, 0, 0])
            linear_extrude(height=plate_t, center=true)
                offset(r=plate_corner_r)
                    square([plate_w - 2*plate_corner_r, 
                            plate_h - 2*plate_corner_r], center=true);
}

module screw_hole() {
    translate([0, plate_t + 0.01, screw_z])
        rotate([90, 0, 0]) {
            cylinder(d=m3_clear, h=plate_t + 0.02);
            cylinder(d1=m3_head_d, d2=m3_clear, h=m3_cs_depth + 0.01);
        }
}

module hook_body() {
    translate([-hook_w/2, 0, 0])
        rotate([0, 90, 0])
            rotate([0, 0, 90])
                linear_extrude(height=hook_w)
                    hook_side_profile();
}

module gusset() {
    translate([-hook_w/2, 0, 0])
        rotate([0, 90, 0])
            rotate([0, 0, 90])
                linear_extrude(height=hook_w)
                    gusset_profile();
}

// Chamfer/fillet on bottom edge of arm for aesthetics
module arm_bottom_chamfer() {
    ch = 2;
    translate([-hook_w/2, plate_t, arm_bottom_z - hook_bar_r])
        rotate([0, 90, 0])
            rotate([0, 0, 90])
                linear_extrude(height=hook_w)
                    polygon([[0, 0], [ch, 0], [0, ch]]);
}

// Smooth wing transitions from hook body width to plate width
module wing_fillets() {
    fillet_h = arm_t + 22;
    
    for (side = [-1, 1]) {
        hull() {
            // At hook body edge
            translate([side * hook_w/2 - (side > 0 ? 0 : 0.01), 
                       plate_t, arm_bottom_z])
                cube([0.01, 4, fillet_h]);
            // At plate edge (slightly inset)
            translate([side * (plate_w/2 - plate_corner_r - 1) - (side > 0 ? 0 : 0.01), 
                       0.5, arm_bottom_z])
                cube([0.01, plate_t - 0.5, fillet_h]);
        }
    }
}

module towel_hook() {
    difference() {
        union() {
            wall_plate();
            translate([0, plate_t, 0]) {
                hook_body();
                gusset();
            }
            wing_fillets();
        }
        screw_hole();
    }
}

towel_hook();
