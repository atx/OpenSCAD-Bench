// Battery Case for 4x Olympus BLS-5 Batteries
// Battery dimensions: 56mm x 36mm x 13mm
// Arrangement: 4x1 linear, standing upright on 36x13mm face

// Parameters
battery_length = 56;  // tallest dimension (vertical when upright)
battery_width = 36;   // medium dimension
battery_depth = 13;   // smallest dimension (base when upright)

wall_thickness = 2.5;
base_thickness = 2;
clearance = 0.5;  // clearance around battery for easy fit

// Snap-fit parameters
snap_overhang = 1.5;  // how far the snap protrudes inward
snap_height = 5;      // height of snap from top of battery
snap_width = 12;      // width of each snap tab
snap_flex_gap = 1.2;  // gap to allow flexibility

// Finger hole parameters
finger_hole_diameter = 14;

num_batteries = 4;

// Calculated dimensions
slot_width = battery_width + 2 * clearance;
slot_depth = battery_depth + 2 * clearance;
slot_height = battery_length + clearance;

inner_width = slot_width * num_batteries + wall_thickness * (num_batteries - 1);
outer_width = inner_width + 2 * wall_thickness;
outer_depth = slot_depth + 2 * wall_thickness;
outer_height = slot_height + snap_height;

module complete_case() {
    difference() {
        union() {
            // Main base and walls
            cube([outer_width, outer_depth, base_thickness]);
            
            // Outer walls
            difference() {
                cube([outer_width, outer_depth, slot_height]);
                translate([wall_thickness, wall_thickness, base_thickness])
                    cube([inner_width, slot_depth, slot_height]);
            }
            
            // Interior dividing walls
            for (i = [1:num_batteries-1]) {
                translate([wall_thickness + i * (slot_width + wall_thickness) - wall_thickness, 
                          wall_thickness, base_thickness])
                    cube([wall_thickness, slot_depth, slot_height]);
            }
            
            // Snap-fit tabs at the top
            for (i = [0:num_batteries-1]) {
                x_offset = wall_thickness + i * (slot_width + wall_thickness);
                
                // Front snap tab
                translate([x_offset + slot_width/2 - snap_width/2, 
                          0, 
                          slot_height - snap_height])
                    difference() {
                        cube([snap_width, wall_thickness + snap_overhang, snap_height]);
                        // Chamfer for easy insertion (angled entry)
                        translate([0, wall_thickness + snap_overhang, 0])
                            rotate([30, 0, 0])
                                translate([-0.1, -0.5, -0.1])
                                    cube([snap_width + 0.2, 2, 2]);
                    }
                
                // Back snap tab
                translate([x_offset + slot_width/2 - snap_width/2, 
                          outer_depth - wall_thickness - snap_overhang, 
                          slot_height - snap_height])
                    difference() {
                        cube([snap_width, wall_thickness + snap_overhang, snap_height]);
                        // Chamfer for easy insertion (angled entry)
                        translate([0, -0.5, 0])
                            rotate([-30, 0, 0])
                                translate([-0.1, 0, -0.1])
                                    cube([snap_width + 0.2, 2, 2]);
                    }
            }
        }
        
        // Finger holes from bottom
        for (i = [0:num_batteries-1]) {
            translate([wall_thickness + i * (slot_width + wall_thickness) + slot_width/2, 
                      wall_thickness + slot_depth/2, 
                      -0.1])
                cylinder(d=finger_hole_diameter, h=base_thickness + 0.2, $fn=40);
        }
        
        // Flexibility cuts for snap tabs
        for (i = [0:num_batteries-1]) {
            x_offset = wall_thickness + i * (slot_width + wall_thickness);
            
            // Front flexibility cuts (left side)
            translate([x_offset + slot_width/2 - snap_width/2 - snap_flex_gap, 
                      -0.1, 
                      slot_height - snap_height - 3])
                cube([snap_flex_gap, wall_thickness + snap_overhang + 0.2, snap_height + 3.1]);
                
            // Front flexibility cuts (right side)
            translate([x_offset + slot_width/2 + snap_width/2, 
                      -0.1, 
                      slot_height - snap_height - 3])
                cube([snap_flex_gap, wall_thickness + snap_overhang + 0.2, snap_height + 3.1]);
            
            // Back flexibility cuts (left side)
            translate([x_offset + slot_width/2 - snap_width/2 - snap_flex_gap, 
                      outer_depth - wall_thickness - snap_overhang - 0.1, 
                      slot_height - snap_height - 3])
                cube([snap_flex_gap, wall_thickness + snap_overhang + 0.2, snap_height + 3.1]);
                
            // Back flexibility cuts (right side)
            translate([x_offset + slot_width/2 + snap_width/2, 
                      outer_depth - wall_thickness - snap_overhang - 0.1, 
                      slot_height - snap_height - 3])
                cube([snap_flex_gap, wall_thickness + snap_overhang + 0.2, snap_height + 3.1]);
        }
        
        // Add small chamfer to top edges for better printability
        translate([-0.1, -0.1, slot_height])
            rotate([0, 0, 0])
                cube([outer_width + 0.2, outer_depth + 0.2, 0.3]);
    }
    
    // Add text label (optional)
    translate([outer_width/2 - 20, outer_depth - wall_thickness - 0.5, base_thickness - 0.6])
        linear_extrude(0.7)
            text("BLS-5", size=5, halign="center", font="Liberation Sans:style=Bold");
}

complete_case();
