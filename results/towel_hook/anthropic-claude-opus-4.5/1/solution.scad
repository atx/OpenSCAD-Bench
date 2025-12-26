// Towel Hook - Wall mounted with M3 flat head screw
// Designed for 3D printing - sturdy construction for heavy towels
// Print orientation: lay flat with wall plate on print bed

$fn = 64;

// Main parameters
wall_plate_width = 32;
wall_plate_height = 50;
wall_plate_thickness = 5;

// Screw hole parameters (M3 flat head)
screw_hole_diameter = 3.4;  // Clearance for M3 screw
screw_head_diameter = 6.5;  // M3 flat head countersink diameter
screw_head_depth = 2.5;     // Countersink depth

// Hook parameters
hook_thickness = 10;        // Thick for strength (good layer adhesion)
hook_width = 24;            // Width of the hook arm
hook_length = 45;           // How far hook extends from wall
hook_curve_radius = 14;     // Inner radius of the hook curve
hook_tip_length = 28;       // Length of upward tip to prevent towel sliding off

// Reinforcement gusset
gusset_length = 18;
gusset_height = 18;

// Position of hook on plate (lower portion)
hook_y_offset = -10;

module rounded_rect(w, h, r) {
    hull() {
        for (x = [-1, 1]) {
            for (y = [-1, 1]) {
                translate([x * (w/2 - r), y * (h/2 - r)])
                    circle(r = r);
            }
        }
    }
}

module wall_plate() {
    difference() {
        // Rounded rectangle plate
        linear_extrude(height = wall_plate_thickness)
            rounded_rect(wall_plate_width, wall_plate_height, 5);
        
        // Countersunk screw hole - positioned in upper portion
        translate([0, wall_plate_height/4, -0.1]) {
            // Through hole
            cylinder(d = screw_hole_diameter, h = wall_plate_thickness + 0.2);
            // Countersink from back for flat head screw (cone on mounting surface)
            translate([0, 0, -0.1])
                cylinder(d1 = screw_head_diameter, d2 = screw_hole_diameter, h = screw_head_depth + 0.1);
        }
    }
}

module hook_2d_profile() {
    // 2D profile that will be extruded
    outer_r = hook_curve_radius + hook_thickness;
    inner_r = hook_curve_radius;
    
    union() {
        // Horizontal arm
        translate([0, -hook_thickness/2])
            square([hook_length - hook_curve_radius + 0.1, hook_thickness]);
        
        // Curved section (180 degrees, going down)
        translate([hook_length - hook_curve_radius, -hook_curve_radius - hook_thickness/2])
            difference() {
                circle(r = outer_r);
                circle(r = inner_r);
                // Keep only left half (the curve going down and back)
                translate([0, -outer_r - 1])
                    square([outer_r + 1, 2 * outer_r + 2]);
            }
        
        // Upward tip
        translate([hook_length - 2*hook_curve_radius - hook_thickness, -2*hook_curve_radius - hook_thickness + 0.1])
            square([hook_thickness, hook_tip_length + 2*hook_curve_radius + hook_thickness - hook_thickness/2]);
        
        // Rounded tip top
        translate([hook_length - 2*hook_curve_radius - hook_thickness/2, hook_tip_length - hook_thickness/2])
            circle(d = hook_thickness);
    }
}

module hook_body() {
    // Extrude the 2D hook profile
    translate([0, -hook_width/2, 0])
        rotate([90, 0, 0])
            rotate([0, 0, -90])
                linear_extrude(height = hook_width)
                    hook_2d_profile();
}

module gusset_2d() {
    // 2D triangular gusset profile with rounded corners
    hull() {
        translate([hook_thickness/2, hook_thickness/2])
            circle(d = hook_thickness);
        translate([gusset_length - hook_thickness/2, hook_thickness/2])
            circle(d = hook_thickness);
        translate([hook_thickness/2, gusset_height - hook_thickness/2])
            circle(d = hook_thickness);
    }
}

module gussets() {
    // Two side gussets
    gusset_offset = hook_width/2 - hook_thickness/2;
    
    translate([0, gusset_offset, -hook_thickness/2])
        rotate([90, 0, 0])
            linear_extrude(height = hook_thickness)
                gusset_2d();
    
    translate([0, -gusset_offset + hook_thickness, -hook_thickness/2])
        rotate([90, 0, 0])
            linear_extrude(height = hook_thickness)
                gusset_2d();
    
    // Connecting bar between gussets at the base
    translate([0, -hook_width/2 + hook_thickness/2, -hook_thickness/2])
        cube([hook_thickness, hook_width - hook_thickness, gusset_height]);
}

module towel_hook() {
    union() {
        // Wall mounting plate
        wall_plate();
        
        // Hook body positioned on lower part of plate
        translate([0, hook_y_offset, wall_plate_thickness + hook_thickness/2])
            hook_body();
        
        // Reinforcement gussets
        translate([0, hook_y_offset, wall_plate_thickness + hook_thickness/2])
            gussets();
    }
}

// Render the hook
towel_hook();
