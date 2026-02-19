$fn=64;
// Parameters
batt_h=56; // height
batt_w=36; // width (along length)
batt_d=13; // depth
clearance=0.6;
slot_w=batt_w+clearance;
slot_d=batt_d+clearance;
wall=2;
divider=1.5;
base=2;
inner_h=batt_h+1; // clearance above
case_h=base+inner_h;
slots=4;

length = wall*2 + slots*slot_w + (slots-1)*divider;
depth = wall*2 + slot_d;

module case_shell(){
    cube([length, depth, case_h], center=false);
}

module slot_cut(i){
    x = wall + i*(slot_w+divider);
    y = wall;
    translate([x, y, base])
        cube([slot_w, slot_d, inner_h+1], center=false);
}

module finger_hole(i){
    x = wall + i*(slot_w+divider) + slot_w/2;
    y = wall + slot_d/2;
    translate([x, y, 0])
        cylinder(d=18, h=base+10, center=false);
}

module snap_tabs(){
    tab_depth=0.8;
    tab_height=2;
    tab_len=8;
    zpos=base+inner_h-10;
    for(i=[0:slots-1]){
        x0 = wall + i*(slot_w+divider) + (slot_w-tab_len)/2;
        // front wall tab
        translate([x0, wall-0.01, zpos])
            cube([tab_len, tab_depth, tab_height], center=false);
        // back wall tab
        translate([x0, wall+slot_d-tab_depth+0.01, zpos])
            cube([tab_len, tab_depth, tab_height], center=false);
    }
}

difference(){
    union(){
        case_shell();
        snap_tabs();
    }
    // cut slots
    for(i=[0:slots-1]) slot_cut(i);
    // finger holes
    for(i=[0:slots-1]) finger_hole(i);
}
