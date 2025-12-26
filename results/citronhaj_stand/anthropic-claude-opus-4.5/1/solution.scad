// IKEA Citronhaj Spice Jar Stand - 3x3 Tiered Grid
// Jar dimensions: 40mm diameter, 120mm height
// 
// Features:
// - 3x3 grid of jar holders
// - Tiered design: front row lowest, back row highest (30mm steps)
// - Holds ~35mm of each jar for stability
// - Finger notches for easy jar removal
// - Drainage holes in base

// Jar Parameters
jar_diameter = 40;
jar_radius = jar_diameter / 2;
jar_height = 120;

// Stand parameters
wall_thickness = 3;
base_thickness = 3;
jar_spacing = 5;           // Space between jar holders
holder_height = 35;        // How much of jar is held
step_height = 30;          // Height between tiers (3cm)
jar_clearance = 0.5;       // Clearance for easy insertion

// Grid parameters
grid_cols = 3;
grid_rows = 3;

// Calculated dimensions
holder_outer_radius = jar_radius + wall_thickness + jar_clearance;
pitch_x = holder_outer_radius * 2 + jar_spacing;
pitch_y = holder_outer_radius * 2 + jar_spacing;
total_width = grid_cols * pitch_x - jar_spacing;
total_depth = grid_rows * pitch_y - jar_spacing;
max_height = base_thickness + holder_height + (grid_rows - 1) * step_height;

// Finger notch parameters
notch_radius = 10;
notch_height_ratio = 0.5; // Position of notch center relative to holder height

// Module for the complete stand
module spice_stand() {
    difference() {
        union() {
            // Create the tiered base platforms
            for (row = [0 : grid_rows - 1]) {
                tier_z = row * step_height;
                y_start = row * pitch_y;
                row_depth = pitch_y;
                
                // Add extra depth for last row to complete the back
                final_depth = (row == grid_rows - 1) ? row_depth - jar_spacing : row_depth;
                
                translate([0, y_start, 0])
                    cube([total_width, final_depth, base_thickness + tier_z]);
            }
            
            // Add the jar holder cylinders
            for (row = [0 : grid_rows - 1]) {
                for (col = [0 : grid_cols - 1]) {
                    x = holder_outer_radius + col * pitch_x - jar_spacing/2;
                    y = holder_outer_radius + row * pitch_y - jar_spacing/2;
                    z = row * step_height;
                    
                    translate([x, y, z])
                        cylinder(h = base_thickness + holder_height, r = holder_outer_radius, $fn = 64);
                }
            }
            
            // Add connecting ribs between holders in same row
            for (row = [0 : grid_rows - 1]) {
                for (col = [0 : grid_cols - 2]) {
                    x1 = holder_outer_radius + col * pitch_x - jar_spacing/2;
                    x2 = holder_outer_radius + (col + 1) * pitch_x - jar_spacing/2;
                    y = holder_outer_radius + row * pitch_y - jar_spacing/2;
                    z = row * step_height;
                    
                    translate([x1, y - wall_thickness/2, z])
                        cube([x2 - x1, wall_thickness, base_thickness + 5]);
                }
            }
        }
        
        // Cut out the jar cavities
        for (row = [0 : grid_rows - 1]) {
            for (col = [0 : grid_cols - 1]) {
                x = holder_outer_radius + col * pitch_x - jar_spacing/2;
                y = holder_outer_radius + row * pitch_y - jar_spacing/2;
                z = row * step_height + base_thickness;
                
                translate([x, y, z])
                    cylinder(h = holder_height + step_height + 1, r = jar_radius + jar_clearance, $fn = 64);
            }
        }
        
        // Drainage holes
        for (row = [0 : grid_rows - 1]) {
            for (col = [0 : grid_cols - 1]) {
                x = holder_outer_radius + col * pitch_x - jar_spacing/2;
                y = holder_outer_radius + row * pitch_y - jar_spacing/2;
                drain_depth = row * step_height + base_thickness;
                
                translate([x, y, -1])
                    cylinder(h = drain_depth + 2, r = jar_radius - 6, $fn = 64);
            }
        }
        
        // Finger notches for easy jar removal (on front of each holder)
        for (row = [0 : grid_rows - 1]) {
            for (col = [0 : grid_cols - 1]) {
                x = holder_outer_radius + col * pitch_x - jar_spacing/2;
                y = holder_outer_radius + row * pitch_y - jar_spacing/2;
                z = row * step_height + base_thickness + holder_height * notch_height_ratio;
                
                translate([x, y - holder_outer_radius - 1, z])
                    rotate([-90, 0, 0])
                        cylinder(h = wall_thickness + jar_clearance + 2, r = notch_radius, $fn = 32);
            }
        }
    }
}

// Render the stand
spice_stand();

// Print dimensions for reference
echo("Total Width: ", total_width, " mm");
echo("Total Depth: ", total_depth, " mm");
echo("Total Height: ", max_height, " mm");
