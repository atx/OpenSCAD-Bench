// Towel Hook - Wall mounted with M3 flat head screw
// Designed for 3D printing with maximum strength
// Print orientation: wall plate flat on build plate (back side down)

$fn = 64;

// ================== PARAMETERS ==================

// Wall plate dimensions
wall_plate_width = 35;
wall_plate_height = 55;
wall_plate_thickness = 6;
wall_plate_corner_radius = 5;

// Hook dimensions
hook_thickness = 10;       // Thick for strength under load
hook_width = 30;           // Wide enough for heavy towels
hook_depth = 45;           // Projection from wall
hook_curve_radius = 12;    // Inner curve radius at bottom
hook_tip_length = 25;      // Upward tip prevents towel slipping

// Screw hole (M3 flat head countersunk)
screw_hole_diameter = 3.4;      // M3 clearance hole
screw_head_diameter = 6.5;      // Flat head diameter
screw_head_depth = 2.0;         // Countersink depth

// Reinforcement gusset
gusset_length = 20;

// ================== MODULES ==================

module rounded_rectangle(width, height, radius) {
    hull() {
        translate([radius, radius]) circle(r = radius);
        translate([width - radius, radius]) circle(r = radius);
        translate([radius, height - radius]) circle(r = radius);
        translate([width - radius, height - radius]) circle(r = radius);
    }
}

module wall_plate() {
    translate([-wall_plate_width/2, 0, 0])
    linear_extrude(height = wall_plate_thickness)
        rounded_rectangle(wall_plate_width, wall_plate_height, wall_plate_corner_radius);
}

module screw_hole() {
    // Positioned in upper portion of plate, above the hook attachment
    translate([0, wall_plate_height - 15, -0.1]) {
        // Through hole for M3 screw
        cylinder(d = screw_hole_diameter, h = wall_plate_thickness + 0.2);
        // Countersink from back side (Z=0 face against wall)
        cylinder(d1 = screw_head_diameter, d2 = screw_hole_diameter, h = screw_head_depth + 0.1);
    }
}

module hook_arm() {
    straight_length = hook_depth - hook_curve_radius - hook_thickness/2;
    
    // Main horizontal arm extending from plate
    translate([0, -hook_width/2, -hook_thickness])
    rotate([-90, 0, 90])
        linear_extrude(height = straight_length)
            rounded_rectangle(hook_width, hook_thickness, 2);
    
    // 180-degree curve at bottom
    translate([straight_length, 0, -hook_thickness - hook_curve_radius])
    rotate([90, 0, 0])
    translate([0, 0, -hook_width/2])
        rotate_extrude(angle = 180, convexity = 4)
            translate([hook_curve_radius, 0, 0])
                square([hook_thickness, hook_width]);
    
    // Upward return section
    upward_start_x = straight_length - hook_thickness - hook_curve_radius * 2;
    translate([upward_start_x, -hook_width/2, -hook_thickness - hook_curve_radius])
    rotate([-90, 0, 90])
        linear_extrude(height = hook_tip_length)
            rounded_rectangle(hook_width, hook_thickness, 2);
    
    // Rounded tip cap (dome shape)
    translate([upward_start_x + hook_tip_length, 0, -hook_curve_radius - hook_thickness/2])
        resize([hook_thickness * 0.8, hook_width * 0.9, hook_thickness * 0.8])
            sphere(d = 10);
}

module gusset_reinforcement() {
    // Triangular reinforcement fillet for strength
    translate([0, -hook_width/2, -gusset_length])
    rotate([0, -90, 0])
    linear_extrude(height = hook_width)
    polygon([
        [0, 0],
        [gusset_length, 0],
        [0, gusset_length]
    ]);
}

module towel_hook_assembly() {
    // Calculate hook vertical position on plate
    hook_y_center = 18;  // Hook attached in lower-middle area of plate
    
    difference() {
        union() {
            // Wall mounting plate
            wall_plate();
            
            // Hook arm with reinforcement
            translate([wall_plate_thickness, hook_y_center, wall_plate_thickness]) {
                hook_arm();
                gusset_reinforcement();
            }
        }
        
        // M3 countersunk screw hole
        screw_hole();
    }
}

// ================== RENDER ==================
towel_hook_assembly();
