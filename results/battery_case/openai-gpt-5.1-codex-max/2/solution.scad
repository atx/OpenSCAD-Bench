// Olympus BLS-5 4x1 upright case with snap-fit and finger holes
// Battery: 56 x 36 x 13 mm (H x W x T)

// Parameters
cell_depth = 14;      // along X (battery thickness + clearance)
cell_width = 37;      // along Y (battery width + clearance)
cell_height = 58;     // along Z (battery height + clearance)
wall = 2;             // wall thickness and inter-cell wall
floor = 2;            // bottom thickness
fillet = 1.2;         // small top edge softening
snap_thickness = 1.5;
snap_length = 8;
snap_inset = 1.2;     // inward lip
snap_gap = 0.6;       // gap above battery for flex
finger_r = 8;         // finger push hole radius

cells = 4;

// Derived
case_length = cells*cell_depth + (cells+1)*wall; // X
case_width  = cell_width + 2*wall;               // Y
case_height = floor + cell_height + snap_thickness + 1; // Z

module battery_slot(ix){
    translate([wall + ix*(cell_depth+wall), wall, floor])
        cube([cell_depth, cell_width, cell_height]);
    // finger hole
    translate([wall + ix*(cell_depth+wall) + cell_depth/2,
               wall + cell_width/2,
               0])
        cylinder(h=floor+0.1, r=finger_r, $fn=40);
}

module snap_tabs(){
    for(ix=[0:cells-1]){
        x0 = wall + ix*(cell_depth+wall);
        y_left = wall - 0.01;
        y_right = wall + cell_width - snap_thickness + 0.01;
        z0 = floor + cell_height + snap_gap;
        translate([x0 + (cell_depth - snap_length)/2, y_left, z0])
            snap_tab();
        translate([x0 + (cell_depth - snap_length)/2, y_right, z0])
            mirror([0,1,0]) snap_tab();
    }
}

module snap_tab(){
    // simple cantilever with small inward hook
    union(){
        cube([snap_length, snap_thickness, snap_thickness + 2]);
        translate([0, snap_thickness, snap_thickness])
            cube([snap_length, snap_inset, snap_thickness]);
    }
}

module case_body(){
    difference(){
        // Outer box with softened top via minkowski
        union(){
            cube([case_length, case_width, case_height]);
            translate([0,0,case_height])
                minkowski(){
                    cube([case_length, case_width, fillet]);
                    cube([fillet, fillet, 0.01]);
                }
        }
        // Four cavities and finger holes
        for(ix=[0:cells-1]) battery_slot(ix);
        // Front/back small through-holes for ventilation
        for(ix=[0:cells-1]){
            translate([wall + ix*(cell_depth+wall) + cell_depth/2, -0.1, floor + cell_height/2])
                rotate([90,0,0]) cylinder(h=case_width+0.2, r=1.5, $fn=20);
        }
    }
}

// Assembly
union(){
    case_body();
    snap_tabs();
}
