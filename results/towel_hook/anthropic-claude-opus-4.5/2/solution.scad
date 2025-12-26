// Towel Hook - Wall mounted with M3 flat head screw
// Designed for 3D printing - sturdy construction for heavy towels

$fn = 80;

// Main parameters
wall_plate_width = 35;
wall_plate_height = 50;
wall_plate_thickness = 6;

// Hook parameters
hook_thickness = 10;         // Extra thick for strength
hook_width = 28;             // Wide hook for stability
hook_extension = 45;         // How far hook extends from wall
hook_curve_radius = 14;      // Radius of the J-curve
hook_upturn_angle = 150;     // How far around the J curves (degrees)

// M3 flat head screw hole parameters
m3_shaft_diameter = 3.4;     // Slightly oversized for easy fit
m3_head_diameter = 6.5;      // M3 flat head is ~6mm
m3_head_depth = 3.2;         // Countersink depth for flush fit

// Reinforcement/gusset parameters
gusset_size = 25;
gusset_thickness = 5;

module wall_plate() {
    // Rounded rectangle plate that mounts to wall
    corner_r = 6;
    hull() {
        translate([wall_plate_width/2 - corner_r, corner_r, 0])
            cylinder(r=corner_r, h=wall_plate_thickness);
        translate([-(wall_plate_width/2 - corner_r), corner_r, 0])
            cylinder(r=corner_r, h=wall_plate_thickness);
        translate([wall_plate_width/2 - corner_r, wall_plate_height - corner_r, 0])
            cylinder(r=corner_r, h=wall_plate_thickness);
        translate([-(wall_plate_width/2 - corner_r), wall_plate_height - corner_r, 0])
            cylinder(r=corner_r, h=wall_plate_thickness);
    }
}

module screw_hole() {
    // M3 countersunk hole - positioned in upper portion of plate
    // Screw goes from back (wall side, z=0) through to front
    // Countersink on back so head is flush with wall
    translate([0, wall_plate_height - 15, 0]) {
        // Countersink for flat head on back/wall side (z=0)
        translate([0, 0, -0.1])
            cylinder(d1=m3_head_diameter, d2=m3_shaft_diameter, h=m3_head_depth + 0.1);
        
        // Shaft hole through rest of plate
        translate([0, 0, -0.1])
            cylinder(d=m3_shaft_diameter, h=wall_plate_thickness + 0.2);
    }
}

module hook_arm() {
    // Straight portion of hook extending from wall with rounded top edges
    arm_length = hook_extension - hook_curve_radius;
    edge_r = 2;
    
    translate([0, -arm_length/2 + 4, wall_plate_thickness + hook_thickness/2]) {
        // Main arm body
        hull() {
            // Front edge rounded
            translate([hook_width/2 - edge_r, -arm_length/2 - 4, hook_thickness/2 - edge_r])
                rotate([0, 90, 0])
                    cylinder(r=edge_r, h=0.1, center=true);
            translate([-(hook_width/2 - edge_r), -arm_length/2 - 4, hook_thickness/2 - edge_r])
                rotate([0, 90, 0])
                    cylinder(r=edge_r, h=0.1, center=true);
            // Back corners
            translate([hook_width/2 - edge_r, arm_length/2 + 4, hook_thickness/2 - edge_r])
                sphere(r=edge_r);
            translate([-(hook_width/2 - edge_r), arm_length/2 + 4, hook_thickness/2 - edge_r])
                sphere(r=edge_r);
            // Bottom is flat
            translate([0, 0, -hook_thickness/2])
                cube([hook_width, arm_length + 8, 0.1], center=true);
        }
    }
}

module hook_j_curve() {
    // The J-shaped curved end using rotate_extrude
    arm_length = hook_extension - hook_curve_radius;
    
    // Position at end of arm, centered on the curve
    translate([0, -arm_length, wall_plate_thickness + hook_curve_radius]) {
        rotate([0, 90, 0])
            rotate([0, 0, 90])  // Start from the "up" position
                rotate_extrude(angle=hook_upturn_angle, convexity=10)
                    translate([hook_curve_radius, 0, 0])
                        square([hook_thickness, hook_width], center=true);
    }
}

module gusset_profile_2d() {
    // Curved gusset profile for smoother stress distribution
    gusset_points = [
        [0, 0],
        [0, gusset_size],
        [-gusset_size * 0.3, gusset_size * 0.5],
        [-gusset_size * 0.8, 0]
    ];
    polygon(gusset_points);
}

module gussets() {
    // Curved reinforcement gussets for strength at the joint
    translate([0, 0, wall_plate_thickness]) {
        // Left gusset
        translate([-hook_width/2 + 0.1, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(height=gusset_thickness)
                    gusset_profile_2d();
        
        // Right gusset  
        translate([hook_width/2 - gusset_thickness - 0.1, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(height=gusset_thickness)
                    gusset_profile_2d();
        
        // Center gusset for extra strength
        translate([-gusset_thickness/2, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(height=gusset_thickness)
                    gusset_profile_2d();
    }
}

module connection_block() {
    // Solid block connecting plate to hook arm
    translate([-hook_width/2, -8, wall_plate_thickness])
        cube([hook_width, 16, hook_thickness]);
}

module hook_tip_cap() {
    // Rounded cap at the end of the J-curve
    arm_length = hook_extension - hook_curve_radius;
    
    // Calculate position of hook tip
    tip_angle = hook_upturn_angle;
    tip_x = 0;
    tip_y = -arm_length + hook_curve_radius * sin(tip_angle - 90);
    tip_z = wall_plate_thickness + hook_curve_radius - hook_curve_radius * cos(tip_angle - 90);
    
    translate([0, tip_y, tip_z])
        rotate([-(tip_angle - 90), 0, 0])
            scale([1, 1, 0.5])
                rotate([90, 0, 0])
                    cylinder(d=hook_thickness, h=hook_width, center=true);
}

module towel_hook() {
    difference() {
        union() {
            // Wall mounting plate
            wall_plate();
            
            // Solid connection between plate and hook
            connection_block();
            
            // Main hook arm
            hook_arm();
            
            // J-curve at the end
            hook_j_curve();
            
            // Reinforcement gussets
            gussets();
        }
        
        // Subtract screw hole with countersink
        screw_hole();
    }
}

// Render the hook - oriented for 3D printing (plate flat on bed)
towel_hook();
