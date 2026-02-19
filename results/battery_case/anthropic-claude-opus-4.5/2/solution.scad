// Battery Case for 4x Olympus BLS-5 Batteries
// Battery dimensions: 56mm x 36mm x 13mm
// Arrangement: 4x1 linear, batteries upright on smallest face (13x36mm base)
// Batteries face each other with largest face (56x36mm)
// Designed to print upright (open end up) without supports

$fn = 50;

// Battery dimensions
bat_length = 56;  // height when upright
bat_width = 36;   // depth  
bat_thick = 13;   // thickness (side by side)

// Case parameters
wall = 2.5;           // wall thickness
floor_thick = 3;      // floor thickness
clearance = 0.5;      // clearance around battery
snap_protrude = 1.5;  // how far snap protrudes into slot
snap_height = 5;      // height of snap ridge
snap_from_top = 10;   // distance from top to snap top
finger_hole_dia = 16; // diameter of finger hole

// Calculated dimensions
slot_width = bat_thick + clearance * 2;  // width per slot ~14mm
slot_depth = bat_width + clearance * 2;  // depth ~37mm
slot_height = bat_length + 4;            // height ~60mm (extra for grip)

num_batteries = 4;
divider_thick = 2.5;  // thickness between slots

// Total case dimensions
case_width = num_batteries * slot_width + (num_batteries - 1) * divider_thick + 2 * wall;
case_depth = slot_depth + 2 * wall;
case_height = slot_height + floor_thick;

echo("===== Case Dimensions =====");
echo("Width:", case_width, "mm");
echo("Depth:", case_depth, "mm");  
echo("Height:", case_height, "mm");
echo("Slot size (WxD):", slot_width, "x", slot_depth, "mm");

// Snap-fit ridge module - flexible lip for retention
module snap_ridge(length) {
    // Creates a snap lip that flexes during insertion
    // Ramp on top for easy insertion, ridge for retention
    
    linear_extrude(height = length)
    polygon([
        [0, 0],
        [0, snap_height],
        [snap_protrude * 0.3, snap_height],           // flat top section
        [snap_protrude, snap_height * 0.55],          // ramp for insertion
        [snap_protrude, snap_height * 0.45],          // retention ridge
        [snap_protrude * 0.35, snap_height * 0.15],   // undercut
        [snap_protrude * 0.35, 0]                     // base
    ]);
}

// Single battery slot cavity
module battery_slot() {
    // Main cavity
    cube([slot_width, slot_depth, slot_height + 1]);
    
    // Entry chamfer at top for easier battery insertion
    chamfer = 2;
    translate([slot_width/2, slot_depth/2, slot_height])
        cylinder(h = chamfer + 1, d1 = 0, d2 = max(slot_width, slot_depth) + chamfer * 2);
}

// Finger hole that goes through the floor
module finger_hole() {
    // Oval-shaped finger hole centered in slot
    hull() {
        translate([slot_width/2, slot_depth/2 - 5, -1])
            cylinder(h = floor_thick + 2, d = finger_hole_dia);
        translate([slot_width/2, slot_depth/2 + 5, -1])
            cylinder(h = floor_thick + 2, d = finger_hole_dia);
    }
    
    // Chamfer the finger hole edges for comfort
    hull() {
        translate([slot_width/2, slot_depth/2 - 5, -1])
            cylinder(h = 2, d1 = finger_hole_dia + 3, d2 = finger_hole_dia);
        translate([slot_width/2, slot_depth/2 + 5, -1])
            cylinder(h = 2, d1 = finger_hole_dia + 3, d2 = finger_hole_dia);
    }
}

// Relief slot behind snap to allow flexing
module snap_relief(slot_x, front) {
    relief_depth = 1.2;
    relief_height = snap_height + 8;
    relief_width = slot_width - 3;
    snap_z = floor_thick + slot_height - snap_from_top - snap_height - 2;
    
    if (front) {
        translate([slot_x + 1.5, 0.3, snap_z])
            cube([relief_width, relief_depth, relief_height]);
    } else {
        translate([slot_x + 1.5, case_depth - 0.3 - relief_depth, snap_z])
            cube([relief_width, relief_depth, relief_height]);
    }
}

// Snap ridges for one slot (on front and back walls)
module slot_snaps(slot_x) {
    snap_z = floor_thick + slot_height - snap_from_top - snap_height;
    snap_length = slot_width - 3;  // slightly narrower than slot
    
    // Front wall snap (protrudes backward into slot)
    translate([slot_x + 1.5, wall, snap_z])
        rotate([90, 0, 90])
            snap_ridge(snap_length);
    
    // Back wall snap (protrudes forward into slot)  
    translate([slot_x + slot_width - 1.5, case_depth - wall, snap_z])
        rotate([90, 0, -90])
            snap_ridge(snap_length);
}

// Main case body
module case_body() {
    difference() {
        // Outer shell with rounded corners
        hull() {
            r = 2;
            translate([r, r, 0]) cylinder(r = r, h = case_height);
            translate([case_width - r, r, 0]) cylinder(r = r, h = case_height);
            translate([r, case_depth - r, 0]) cylinder(r = r, h = case_height);
            translate([case_width - r, case_depth - r, 0]) cylinder(r = r, h = case_height);
        }
        
        // Carve out battery slots
        for (i = [0:num_batteries - 1]) {
            slot_x = wall + i * (slot_width + divider_thick);
            
            // Main slot
            translate([slot_x, wall, floor_thick])
                battery_slot();
            
            // Finger hole through floor
            translate([slot_x, wall, 0])
                finger_hole();
            
            // Relief cuts for snap flexibility
            snap_relief(slot_x, true);
            snap_relief(slot_x, false);
        }
        
        // Top edge chamfers for comfort
        chamfer_size = 1.5;
        translate([-1, -chamfer_size, case_height - chamfer_size])
            rotate([45, 0, 0])
                cube([case_width + 2, chamfer_size * 2, chamfer_size * 2]);
        translate([-1, case_depth + chamfer_size, case_height - chamfer_size])
            rotate([45, 0, 0])
                cube([case_width + 2, chamfer_size * 2, chamfer_size * 2]);
        translate([-chamfer_size, -1, case_height - chamfer_size])
            rotate([0, -45, 0])
                cube([chamfer_size * 2, case_depth + 2, chamfer_size * 2]);
        translate([case_width + chamfer_size, -1, case_height - chamfer_size])
            rotate([0, -45, 0])
                cube([chamfer_size * 2, case_depth + 2, chamfer_size * 2]);
    }
}

// Add slot numbers on front face
module labels() {
    label_depth = 0.8;
    label_size = 7;
    
    for (i = [0:num_batteries - 1]) {
        slot_center_x = wall + i * (slot_width + divider_thick) + slot_width/2;
        translate([slot_center_x, 0.01, case_height - 14])
            rotate([90, 0, 0])
                linear_extrude(height = label_depth)
                    text(str(i + 1), size = label_size, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
    }
}

// Grip indents on sides  
module grip_indents() {
    indent_depth = 1;
    indent_length = case_depth - 16;
    indent_height = 2;
    indent_spacing = 5;
    
    for (z = [18 : indent_spacing : case_height - 18]) {
        // Left side
        translate([-0.1, 8, z - indent_height/2])
            cube([indent_depth + 0.1, indent_length, indent_height]);
        // Right side
        translate([case_width - indent_depth, 8, z - indent_height/2])
            cube([indent_depth + 0.1, indent_length, indent_height]);
    }
}

// Complete battery case
module battery_case() {
    difference() {
        union() {
            case_body();
            
            // Add snap ridges to each slot
            for (i = [0:num_batteries - 1]) {
                slot_x = wall + i * (slot_width + divider_thick);
                slot_snaps(slot_x);
            }
        }
        
        // Add labels (engraved)
        labels();
        
        // Grip indents on sides
        grip_indents();
    }
}

// Render the case
battery_case();
