// Battery Case for 4x Olympus BLS-5 Batteries
// Battery dimensions: 56mm x 36mm x 13mm
// Arrangement: 4x1 linear, batteries upright on smallest face (13x36)
// Batteries face each other with largest face (56x36)
// Printable in one piece, lying flat (open side up)

// Battery dimensions
bat_length = 56;  // height when upright (Z)
bat_width = 36;   // depth (Y direction)
bat_thickness = 13;  // side-to-side when arranged (X direction)

// Tolerances and wall parameters
tolerance = 0.8;  // clearance around battery
wall = 2.5;       // outer wall thickness
base_height = 4;  // bottom thickness
divider_wall = 2.0; // dividers between slots

// Snap-fit parameters
snap_protrusion = 1.8; // how far snap protrudes into slot
snap_width = 12;  // width of snap bump
snap_z_pos = 42;  // Z position of snap (from base top)

// Finger hole parameters
finger_hole_diameter = 18;

// Slot dimensions (with tolerance)
slot_length = bat_length + tolerance;  // Z height
slot_width = bat_width + tolerance;    // Y depth  
slot_thickness = bat_thickness + tolerance;  // X width

// Number of batteries
num_batteries = 4;

// Overall case dimensions
case_width = num_batteries * slot_thickness + 2 * wall + (num_batteries - 1) * divider_wall;
case_depth = slot_width + 2 * wall;
case_height = slot_length + base_height;

$fn = 48;

// Calculate slot X position
function get_slot_x(i) = wall + i * (slot_thickness + divider_wall);

// Main module
module battery_case() {
    difference() {
        union() {
            // Main shell
            outer_shell();
            
            // Snap ridges
            snap_ridges();
        }
        
        // Battery slots (cut out)
        for (i = [0:num_batteries-1]) {
            translate([get_slot_x(i), wall, base_height])
                battery_slot();
        }
        
        // Finger holes from bottom
        for (i = [0:num_batteries-1]) {
            slot_center_x = get_slot_x(i) + slot_thickness/2;
            translate([slot_center_x, wall + slot_width/2, -0.1])
                finger_hole();
        }
        
        // Top edge chamfer
        translate([0, 0, case_height - 1.5])
            top_chamfer();
    }
}

module outer_shell() {
    r = 3;
    
    // Main body with rounded corners
    linear_extrude(height = case_height) {
        hull() {
            translate([r, r]) circle(r=r);
            translate([case_width - r, r]) circle(r=r);
            translate([r, case_depth - r]) circle(r=r);
            translate([case_width - r, case_depth - r]) circle(r=r);
        }
    }
}

module snap_ridges() {
    // Add snap bumps inside each slot (on front and back walls)
    for (i = [0:num_batteries-1]) {
        slot_center_x = get_slot_x(i) + slot_thickness/2;
        
        // Front wall snap (protrudes in +Y direction)
        translate([slot_center_x, wall, base_height + snap_z_pos])
            snap_ridge();
        
        // Back wall snap (protrudes in -Y direction)
        translate([slot_center_x, case_depth - wall, base_height + snap_z_pos])
            mirror([0, 1, 0])
                snap_ridge();
    }
}

module snap_ridge() {
    // Snap retention ridge
    // Profile: ramped top for insertion, steeper bottom for retention
    
    ridge_height = 6;
    
    translate([-snap_width/2, 0, -ridge_height/2]) {
        linear_extrude(height = snap_width) {
            polygon([
                [0, 0],                              // top at wall surface
                [3, 0],                              // ramp start
                [0, snap_protrusion],                // tip
                [-ridge_height + 1, snap_protrusion * 0.3],  // retention angle
                [-ridge_height, 0],                  // bottom at wall
            ]);
        }
    }
}

module battery_slot() {
    // Main slot cavity
    cube([slot_thickness, slot_width, slot_length + 1]);
    
    // Entry chamfer at top for easier battery insertion
    translate([-0.5, -0.5, slot_length - 1])
        linear_extrude(height = 3, scale = [1 + 3/slot_thickness, 1 + 3/slot_width])
            square([slot_thickness + 1, slot_width + 1]);
}

module finger_hole() {
    // Main hole for finger access
    cylinder(d=finger_hole_diameter, h=base_height + 0.2);
    
    // Chamfer at bottom (print bed side) - helps with bridging
    translate([0, 0, -0.1])
        cylinder(d1=finger_hole_diameter + 4, d2=finger_hole_diameter, h=2);
    
    // Generous chamfer at top for finger comfort
    translate([0, 0, base_height - 1])
        cylinder(d1=finger_hole_diameter, d2=finger_hole_diameter + 8, h=5);
}

module top_chamfer() {
    // External chamfer around top edge for comfort
    r = 3;
    chamfer = 1.5;
    
    difference() {
        translate([-0.1, -0.1, 0])
            cube([case_width + 0.2, case_depth + 0.2, chamfer + 0.1]);
        
        linear_extrude(height = chamfer + 0.2) {
            offset(r = -chamfer)
            hull() {
                translate([r, r]) circle(r=r);
                translate([case_width - r, r]) circle(r=r);
                translate([r, case_depth - r]) circle(r=r);
                translate([case_width - r, case_depth - r]) circle(r=r);
            }
        }
    }
}

// Render the case
battery_case();

// Output dimensions for reference
echo("=== BATTERY CASE DIMENSIONS ===");
echo("Case outer:", case_width, "x", case_depth, "x", case_height, "mm");
echo("Slot inner:", slot_thickness, "x", slot_width, "x", slot_length, "mm");
echo("Print orientation: Open side up (no supports needed)");
