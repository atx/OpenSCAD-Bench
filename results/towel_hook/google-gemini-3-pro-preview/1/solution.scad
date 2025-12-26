$fn = 64;

// --- Dimensions ---
width = 16;           // Width of the hook (X axis)
thickness = 6;        // Base thickness (Y axis) and Profile Diameter
total_height = 55;    // Total height (Z axis)

// --- Screw Dimensions (M3 Flat Head) ---
screw_hole_diam = 3.4;    
screw_head_diam = 7.0;    
screw_head_depth = 2.4;   
screw_pos_z = total_height - 12; 

module sleek_hook() {
    
    // Path points [Y_offset_from_plate_front, Z_coord]
    // Z=0 is bottom of the J-curve
    // The Backplate bottom is roughly Z=8
    path = [
        [0, 10],   // P0: Buried in plate
        [4, 0],    // P1: Bottom of curve starts
        [20, 0],   // P2: Bottom flat area
        [32, 10],  // P3: Up
        [37, 24]   // P4: Tip
    ];
    
    // Thickness profile (Diameter of the arm at each point)
    // We taper slightly for elegance
    d_profile = [
        thickness + 1, // P0: Slightly thicker connection
        thickness,     // P1
        thickness,     // P2
        thickness * 0.9, // P3
        thickness * 0.9  // P4
    ];
    
    // --- 1. Backplate ---
    // A rounded rectangle
    difference() {
        hull() {
            // Main block
            translate([-width/2, 0, width/2])
                cube([width, thickness, total_height - width]);
            
            // Top Round
            translate([0, thickness/2, total_height - width/2])
                rotate([0, 90, 0])
                cylinder(d=thickness, h=width, center=true);

            // Bottom Round
            translate([0, thickness/2, width/2])
                rotate([0, 90, 0])
                cylinder(d=thickness, h=width, center=true);
        }
        // Screw hole is subtracted in final_assembly
    }
    
    // --- 2. Hook Arm ---
    // Hull chain
    
    // Transition from Backplate to P0
    // Backplate surface is Y=thickness. P0 is at Y=thickness.
    
    union() {
        for (i = [0 : len(path)-2]) {
            hull() {
                translate([0, thickness + path[i][0], path[i][1]])
                    rotate([0, 90, 0])
                    cylinder(d=d_profile[i], h=width, center=true);
                
                translate([0, thickness + path[i+1][0], path[i+1][1]])
                    rotate([0, 90, 0])
                    cylinder(d=d_profile[i+1], h=width, center=true);
            }
        }
    }
}

module final_assembly() {
    difference() {
        sleek_hook();
        
        // --- Screw Hole ---
        // Situated at screw_pos_z
        translate([0, thickness, screw_pos_z]) 
        rotate([90, 0, 0]) {
            // Drill through (Shaft)
            translate([0,0,-20]) cylinder(d=screw_hole_diam, h=50);
            
            // Countersink
            // Tip at -screw_head_depth, Rim at 0 (Flush with front face)
            translate([0,0,-screw_head_depth])
                cylinder(d1=screw_hole_diam, d2=screw_head_diam, h=screw_head_depth);
            
            // Entrance clearance (in case head sticks out or just air)
            cylinder(d=screw_head_diam, h=10);
        }
    }
}

final_assembly();

// Echo dimensions for user check
x_dim = width;
y_dim = thickness + 37; // Approx
z_dim = total_height;
echo("Approx Dimensions:", x_dim, y_dim, z_dim);
