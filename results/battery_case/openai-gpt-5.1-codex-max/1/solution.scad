// Olympus BLS-5 4-slot vertical case with snap-fit and finger holes
// Dimensions: battery 56 x 36 x 13 mm

// Parameters
battery = [56,36,13];
clearance = 0.6;           // general clearance around battery
slot_w = battery[1] + clearance;    // 36 + c (X direction)
slot_d = battery[2] + clearance;    // 13 + c (Y direction)
slot_h = battery[0] + 0.5;          // height allowance (Z direction)

wall = 2.0;                // outer wall thickness
divider = 1.5;             // between slots
base_thick = 2.2;          // bottom thickness
rim_thick = 2.0;           // top frame thickness
lip_over = 1.0;            // snap lip inward overhang
lip_drop = 1.5;            // lip depth downward
finger_r = 8;              // radius of main finger hole
finger_slot_offset = 6;    // spread for oval hull of finger hole

// Derived sizes
slots = 4;
outer_len = 2*wall + slots*slot_w + (slots-1)*divider;
outer_dep = 2*wall + slot_d;
outer_h   = base_thick + slot_h + rim_thick;

$fn=64;

module finger_hole(xc){
    // Oval-ish hole through base for finger push
    translate([xc, wall + slot_d/2, 0])
        hull(){
            translate([0, -finger_slot_offset/2, 0]) cylinder(r=finger_r, h=base_thick+1, center=false);
            translate([0,  finger_slot_offset/2, 0]) cylinder(r=finger_r, h=base_thick+1, center=false);
        }
}

module slot_cavity(i){
    translate([wall + i*(slot_w+divider), wall, base_thick])
        cube([slot_w, slot_d, slot_h + 0.2], center=false);
}

module snap_lips(i){
    x0 = wall + i*(slot_w+divider);
    z0 = base_thick + slot_h - lip_drop;
    // long lips along X on both Y sides
    translate([x0, wall - 0.01, z0])
        cube([slot_w, lip_over+0.02, lip_drop], center=false);
    translate([x0, wall + slot_d - lip_over +0.01, z0])
        cube([slot_w, lip_over+0.02, lip_drop], center=false);
    // small entry chamfer blocks (short bevels) at slot entrance
    translate([x0, wall, base_thick + slot_h - 0.5])
        cube([slot_w, 1.0, 0.5], center=false);
    translate([x0, wall + slot_d -1.0, base_thick + slot_h - 0.5])
        cube([slot_w, 1.0, 0.5], center=false);
}

module body(){
    difference(){
        // outer shell
        cube([outer_len, outer_dep, outer_h], center=false);
        // inner bulk removal
        translate([wall, wall, base_thick])
            cube([outer_len-2*wall, outer_dep-2*wall, slot_h + rim_thick], center=false);
        // individual cavities for walls/dividers crisp (optional)
        for(i=[0:slots-1]) slot_cavity(i);
        // finger holes
        for(i=[0:slots-1]) finger_hole(wall + slot_w/2 + i*(slot_w+divider));
    }
    // snap lips
    for(i=[0:slots-1]) snap_lips(i);
}

// add small feet chamfer
module chamfer_base(){
    linear_extrude(height=1)
        offset(delta=1) square([outer_len, outer_dep]);
}

union(){
    body();
    // optional chamfer skirt at bottom for easier printing
    translate([0,0,-1]) chamfer_base();
}
