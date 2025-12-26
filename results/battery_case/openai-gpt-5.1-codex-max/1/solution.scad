// Olympus BLS-5 4x1 battery case
// Batteries stand on 36x13 face; height 56

$fn = 80;

// Parameters
battery_w = 36;    // along Y (width of largest face)
battery_t = 13;    // along X (thickness / row direction)
battery_h = 56;    // vertical height
clear_xy = 0.6;    // clearance on X/Y
clear_z = 2;       // clearance on Z
wall = 2;          // outer and divider wall thickness
base_th = 2;       // bottom thickness
rim_th = 2;        // top rim thickness

// Derived inner sizes
slot_x = battery_t + clear_xy; // along row
slot_y = battery_w + clear_xy; // depth
slot_h = battery_h + clear_z;  // usable height

slots = 4;

total_x = slots * slot_x + (slots + 1) * wall;
total_y = slot_y + 2 * wall;
total_z = base_th + slot_h + rim_th;

finger_r_x = 9; // finger hole radius along X (oval)
finger_r_y = 6; // radius along Y (oval)
finger_hole_depth = base_th + 16; // how high the hole pushes up into slot

nib_inset = 0.8; // inward overhang depth
nib_height = 1.6;

module body_block(){
    cube([total_x, total_y, total_z], center=false);
}

module slot_cavity(index){
    x0 = wall + index * (slot_x + wall);
    translate([x0, wall, base_th])
        cube([slot_x, slot_y, slot_h], center=false);
}

module finger_hole(index){
    x_center = wall + slot_x/2 + index * (slot_x + wall);
    y_center = total_y/2;
    translate([x_center, y_center, 0])
        linear_extrude(height=finger_hole_depth, center=false)
            offset(r=0)
                square([finger_r_x*2, finger_r_y*2], center=true);
}

module nibs(index){
    // small inward lips on both long sides near the rim
    x0 = wall + index * (slot_x + wall);
    z0 = total_z - rim_th - nib_height + 0.2;
    nib_len = slot_x - 2; // leave clearance near dividers
    // front nib (y at wall)
    translate([x0 + 1, wall - 0.01, z0])
        cube([nib_len, nib_inset, nib_height]);
    // back nib (y at wall + slot_y)
    translate([x0 + 1, wall + slot_y - nib_inset + 0.01, z0])
        cube([nib_len, nib_inset, nib_height]);
}

module case_model(){
    difference(){
        body_block();
        // cavities
        for(i=[0:slots-1]) slot_cavity(i);
        // finger holes
        for(i=[0:slots-1]) finger_hole(i);
    }
    // add nibs after subtraction
    for(i=[0:slots-1]) nibs(i);
}

case_model();
