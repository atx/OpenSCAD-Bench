// Battery Case for 4x Olympus BLS-5 Batteries
// Battery dimensions: 56mm x 36mm x 13mm
// Arrangement: 4x1 linear, standing upright on smallest face (13x36)
// Batteries face each other with largest face (56x36)
// Print orientation: upright (open end up), no supports needed

$fn = 50;

// Battery dimensions
bat_length = 56;     // height when standing
bat_width = 36;      // depth (front to back)
bat_thickness = 13;  // width of each slot (left to right)

// Tolerances and case parameters
tolerance = 0.6;     // clearance around battery
wall = 2.5;          // wall thickness
floor_thick = 3;     // floor thickness
num_batteries = 4;

// Slot dimensions (with tolerance)
slot_height = bat_length + tolerance + 3; // extra height for easy removal
slot_width = bat_thickness + tolerance;
slot_depth = bat_width + tolerance;

// Snap-fit parameters - cantilever design
snap_cantilever_length = 15;  // length of flexible arm
snap_thick = 1.2;             // thickness of cantilever (for flexibility)
snap_tab_width = 10;          // width of snap tab
snap_bump_depth = 2.0;        // how far bump protrudes into slot
snap_bump_height = 4;         // height of the bump
snap_start_z = 42;            // height from floor where cantilever starts

// Finger hole parameters
finger_hole_dia = 18;  // diameter of finger access hole

// Divider parameters
divider_thick = wall;

// Overall case dimensions
case_width = num_batteries * slot_width + (num_batteries + 1) * divider_thick;
case_depth = slot_depth + 2 * wall;
case_height = slot_height + floor_thick;

echo("=== Battery Case for 4x BLS-5 ===");
echo("Case dimensions (WxDxH):", case_width, "x", case_depth, "x", case_height, "mm");
echo("Slot dimensions:", slot_width, "x", slot_depth, "x", slot_height, "mm");

// Main module
module battery_case() {
    difference() {
        union() {
            // Main case body
            case_body();
            // Add snap bumps
            snap_bumps();
        }
        
        // Cut out battery slots
        battery_slots();
        
        // Cut out finger holes
        finger_holes();
        
        // Create flexible cantilever cuts
        cantilever_cuts();
    }
}

// Main case body with rounded corners
module case_body() {
    r = 3;
    linear_extrude(case_height) {
        offset(r) offset(-r) {
            square([case_width, case_depth]);
        }
    }
}

// Battery slot cutouts
module battery_slots() {
    for (i = [0:num_batteries-1]) {
        slot_x = divider_thick + i * (slot_width + divider_thick);
        
        translate([slot_x, wall, floor_thick]) {
            // Main slot
            cube([slot_width, slot_depth, slot_height + 1]);
            
            // Entry chamfer at top for easier insertion
            translate([-1.5, -1.5, slot_height - 5])
                linear_extrude(7, scale=[1.3, 1.15])
                    square([slot_width + 3, slot_depth + 3]);
        }
    }
}

// Finger holes from bottom for battery removal
module finger_holes() {
    for (i = [0:num_batteries-1]) {
        slot_x = divider_thick + i * (slot_width + divider_thick);
        hole_x = slot_x + slot_width/2;
        hole_y = wall + slot_depth/2;
        
        // Main finger hole
        translate([hole_x, hole_y, -1])
            cylinder(d=finger_hole_dia, h=floor_thick + 2);
        
        // Chamfer on bottom (outside) for comfort and printability
        translate([hole_x, hole_y, -0.1])
            cylinder(d1=finger_hole_dia + 4, d2=finger_hole_dia, h=2);
        
        // Chamfer on top (inside) for smooth edge
        translate([hole_x, hole_y, floor_thick - 0.5])
            cylinder(d1=finger_hole_dia, d2=finger_hole_dia + 3, h=2);
    }
}

// Cuts to create flexible cantilever snaps
module cantilever_cuts() {
    for (i = [0:num_batteries-1]) {
        slot_x = divider_thick + i * (slot_width + divider_thick);
        slot_center_x = slot_x + slot_width/2;
        
        // Front wall cantilevers
        cantilever_cut_set(slot_center_x, 0, "front");
        
        // Back wall cantilevers
        cantilever_cut_set(slot_center_x, case_depth - wall, "back");
    }
}

module cantilever_cut_set(center_x, wall_y, side) {
    gap = 1.2;  // gap around cantilever for flexibility
    
    // Vertical cuts on sides of cantilever (creates the free edges)
    for (dx = [-1, 1]) {
        x_pos = center_x + dx * (snap_tab_width/2 + gap/2);
        
        translate([x_pos - gap/2, wall_y - 1, floor_thick + snap_start_z])
            cube([gap, wall + 2, snap_cantilever_length + 10]);
    }
    
    // Horizontal cut at bottom of cantilever (creates the hinge)
    translate([center_x - snap_tab_width/2 - gap, wall_y - 1, floor_thick + snap_start_z])
        cube([snap_tab_width + gap*2, wall + 2, gap]);
    
    // Cut behind cantilever to allow flex (hollows out behind the snap)
    behind_depth = wall - snap_thick;
    if (side == "front") {
        translate([center_x - snap_tab_width/2 + 0.5, snap_thick, floor_thick + snap_start_z + gap])
            cube([snap_tab_width - 1, behind_depth + 0.1, snap_cantilever_length + 8]);
    } else {
        translate([center_x - snap_tab_width/2 + 0.5, case_depth - wall, floor_thick + snap_start_z + gap])
            cube([snap_tab_width - 1, behind_depth + 0.1, snap_cantilever_length + 8]);
    }
}

// Generate snap bumps
module snap_bumps() {
    for (i = [0:num_batteries-1]) {
        slot_x = divider_thick + i * (slot_width + divider_thick);
        slot_center_x = slot_x + slot_width/2;
        bump_z = floor_thick + snap_start_z + snap_cantilever_length - snap_bump_height - 1;
        
        // Front snap bump
        translate([slot_center_x, wall, bump_z])
            snap_bump("front");
        
        // Back snap bump
        translate([slot_center_x, case_depth - wall, bump_z])
            snap_bump("back");
    }
}

module snap_bump(side) {
    // Ramp-style snap bump for easy insertion, retention on exit
    y_dir = (side == "front") ? 1 : -1;
    
    translate([-snap_tab_width/2, 0, 0]) {
        // Entry ramp (gradual slope for easy battery insertion)
        hull() {
            cube([snap_tab_width, 0.01, 0.01]);
            translate([0, y_dir * snap_bump_depth, snap_bump_height * 0.65])
                cube([snap_tab_width, 0.01, 0.01]);
        }
        // Retention face (steeper - holds battery in place)
        hull() {
            translate([0, y_dir * snap_bump_depth, snap_bump_height * 0.65])
                cube([snap_tab_width, 0.01, 0.01]);
            translate([0, y_dir * 0.2, snap_bump_height])
                cube([snap_tab_width, 0.01, 0.01]);
        }
    }
}

// Add small ridges on the bottom for grip and stability
module grip_ridges() {
    ridge_height = 0.8;
    ridge_width = 1.5;
    
    for (y = [6, case_depth - 6]) {
        translate([4, y - ridge_width/2, 0])
            cube([case_width - 8, ridge_width, ridge_height]);
    }
}

// Optional: Add label text embossed on front
module label_text() {
    translate([case_width/2, 0.3, case_height * 0.4])
        rotate([90, 0, 0])
            linear_extrude(0.8)
                text("BLS-5", size=7, halign="center", valign="center", 
                     font="Liberation Sans:style=Bold");
}

// Render everything
union() {
    difference() {
        battery_case();
        label_text();
    }
    grip_ridges();
}
