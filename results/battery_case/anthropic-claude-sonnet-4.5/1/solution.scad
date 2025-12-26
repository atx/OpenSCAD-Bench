// Battery Case for 4x Olympus BLS-5 batteries
// Battery dimensions: 56mm x 36mm x 13mm
// Arrangement: 4x1 linear, standing on 36x13mm face
// Batteries face each other with their largest (56mm x 13mm) face

// Battery dimensions
battery_length = 56;  // longest dimension (faces each other)
battery_width = 36;   // medium dimension (runs along the row)
battery_height = 13;  // smallest dimension (standing height)

// Case parameters
wall_thickness = 2.5;
base_thickness = 2.0;
clearance = 0.5;  // clearance around battery

// Slot dimensions (with clearance)
slot_length = battery_length + clearance * 2;
slot_width = battery_width + clearance * 2;
slot_height = battery_height + clearance;

// Finger hole for removal
finger_hole_diameter = 18;

// Snap-fit parameters
snap_height = 3.5;  // how much the snap protrudes above slot
snap_depth = 1.0;   // how deep the snap hook is
snap_flex_width = 16;  // width of flexible snap arm
snap_thickness = 1.3;  // thickness of snap arm for flexibility

num_batteries = 4;

// Total case dimensions
case_inner_length = slot_length;
case_inner_width = slot_width * num_batteries + wall_thickness * (num_batteries - 1);
case_outer_length = case_inner_length + wall_thickness * 2;
case_outer_width = case_inner_width + wall_thickness * 2;
case_height = slot_height + snap_height;

echo("Case outer dimensions (LxWxH):", case_outer_length, "x", case_outer_width, "x", case_height, "mm");

module complete_case() {
    difference() {
        union() {
            // Base plate
            cube([case_outer_length, case_outer_width, base_thickness]);
            
            // Outer walls
            difference() {
                cube([case_outer_length, case_outer_width, case_height]);
                translate([wall_thickness, wall_thickness, base_thickness])
                    cube([case_inner_length, case_inner_width, case_height]);
            }
            
            // Internal dividers between battery slots
            for (i = [1:num_batteries - 1]) {
                translate([wall_thickness, 
                          wall_thickness + i * slot_width + (i - 1) * wall_thickness, 
                          base_thickness])
                    cube([slot_length, wall_thickness, slot_height]);
            }
            
            // Snap-fit retention system for each slot
            for (i = [0:num_batteries - 1]) {
                translate([wall_thickness, 
                          wall_thickness + i * (slot_width + wall_thickness), 
                          base_thickness]) {
                    
                    // Snap tabs on the LONG sides (left and right)
                    // These hold the 56mm face of the battery
                    for (side = [0, 1]) {
                        translate([side * slot_length - (side == 0 ? snap_thickness : 0), 
                                  slot_width / 2 - snap_flex_width / 2,
                                  slot_height]) {
                            
                            difference() {
                                union() {
                                    // Vertical flexible arm
                                    cube([snap_thickness, snap_flex_width, snap_height]);
                                    
                                    // Inward-facing hook lip
                                    translate([side == 0 ? -snap_depth : snap_thickness, 
                                              0, 
                                              snap_height * 0.35])
                                        cube([snap_depth, snap_flex_width, snap_height * 0.45]);
                                }
                                
                                // Entry chamfer for easy insertion
                                translate([side == 0 ? -snap_depth - 0.5 : snap_thickness + snap_depth + 0.5, 
                                          snap_flex_width / 2, 
                                          snap_height + 0.5])
                                    rotate([0, side == 0 ? -38 : 38, 0])
                                    translate([-3, -snap_flex_width, -1])
                                    cube([6, snap_flex_width * 2, 4]);
                            }
                        }
                    }
                    
                    // Snap tabs on the SHORT sides (front and back)
                    // These hold the 36mm face of the battery
                    for (side = [0, 1]) {
                        translate([slot_length / 2 - snap_flex_width / 2,
                                  side * slot_width - (side == 0 ? snap_thickness : 0),
                                  slot_height]) {
                            
                            difference() {
                                union() {
                                    // Vertical flexible arm
                                    cube([snap_flex_width, snap_thickness, snap_height]);
                                    
                                    // Inward-facing hook lip
                                    translate([0,
                                              side == 0 ? -snap_depth : snap_thickness, 
                                              snap_height * 0.35])
                                        cube([snap_flex_width, snap_depth, snap_height * 0.45]);
                                }
                                
                                // Entry chamfer for easy insertion
                                translate([snap_flex_width / 2,
                                          side == 0 ? -snap_depth - 0.5 : snap_thickness + snap_depth + 0.5, 
                                          snap_height + 0.5])
                                    rotate([side == 0 ? 38 : -38, 0, 0])
                                    translate([-snap_flex_width, -3, -1])
                                    cube([snap_flex_width * 2, 6, 4]);
                            }
                        }
                    }
                }
            }
        }
        
        // Finger holes for battery removal (one per slot)
        for (i = [0:num_batteries - 1]) {
            translate([wall_thickness + slot_length / 2, 
                      wall_thickness + slot_width / 2 + i * (slot_width + wall_thickness), 
                      -0.1])
                cylinder(d = finger_hole_diameter, h = base_thickness + 0.2, $fn = 40);
        }
    }
}

complete_case();
