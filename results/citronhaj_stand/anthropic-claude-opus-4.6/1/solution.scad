// =====================================================
// IKEA Citronhaj Spice Jar Stand - 3x3 Tiered
// Jar: 40mm diameter, 120mm height (cylindrical)
// 3D printable - prints flat (no supports needed)
// =====================================================

$fn = 72;

// === Jar parameters ===
jar_d = 40;                     // Jar diameter
jar_r = jar_d / 2;             // Jar radius

// === Stand design parameters ===
wall = 2.5;                     // Wall thickness around jars
base_t = 3;                     // Bottom plate thickness
step_h = 30;                    // Height increase per tier (3cm)
cup_h = 35;                     // Depth each cup holds the jar
gap = 0.5;                      // Clearance for easy jar fit
scoop_ang = 70;                 // Angular width of removal scoop

// === Derived dimensions ===
hole_r = jar_r + gap;           // Cup inner radius (20.5mm)
pitch = jar_d + 2*gap + wall;   // Center-to-center spacing (43.5mm)
cols = 3;
rows = 3;
total_w = cols * pitch + wall;  // Total width  (~133mm)
total_d = rows * pitch + wall;  // Total depth  (~133mm)
max_h = base_t + cup_h + (rows-1) * step_h;  // Max height (~98mm)

echo(str("Stand: ", total_w, " x ", total_d, " x ", max_h, " mm"));

module stand() {
    difference() {
        // ==========================================
        // POSITIVE: Solid stepped body
        // ==========================================
        union() {
            for (row = [0 : rows-1]) {
                h = base_t + cup_h + row * step_h;
                y_start = row * pitch;
                depth = pitch + (row == rows-1 ? wall : 0);
                translate([0, y_start, 0])
                    cube([total_w, depth, h]);
            }
        }
        
        // ==========================================
        // NEGATIVE: All cut-outs
        // ==========================================
        
        for (row = [0 : rows-1]) {
            for (col = [0 : cols-1]) {
                cx = wall + hole_r + col * pitch;
                cy = wall + hole_r + row * pitch;
                floor_z = base_t + row * step_h;
                top_z = floor_z + cup_h;
                
                // --- Jar cavity (cylinder) ---
                translate([cx, cy, floor_z])
                    cylinder(r = hole_r, h = max_h - floor_z + 10);
                
                // --- Top chamfer for easy jar insertion ---
                translate([cx, cy, top_z - 1.5])
                    cylinder(r1 = hole_r, r2 = hole_r + wall + 0.5, h = 2);
                
                // --- Bottom chamfer inside cup (printability) ---
                translate([cx, cy, floor_z - 0.01])
                    cylinder(r1 = hole_r + 0.5, r2 = hole_r, h = 0.8);
                
                // --- Front scoop for easy jar removal ---
                // Removes a wedge-shaped section of the front cup wall
                scoop_h = cup_h * 0.55;
                translate([cx, cy, top_z - scoop_h])
                    linear_extrude(height = scoop_h + 10)
                    intersection() {
                        // The cup wall ring
                        difference() {
                            circle(r = hole_r + wall + 1);
                            circle(r = hole_r - 0.1);
                        }
                        // Front-pointing wedge
                        rotate([0, 0, -90])
                        polygon([
                            [0, 0],
                            [60*cos(-scoop_ang/2), 60*sin(-scoop_ang/2)],
                            [60*cos(scoop_ang/2), 60*sin(scoop_ang/2)]
                        ]);
                    }
                
                // --- Drainage / weight-saving hole at bottom ---
                translate([cx, cy, -0.1])
                    cylinder(r = 5, h = floor_z + 0.2);
            }
        }
        
        // --- Step face chamfers (aesthetic) ---
        for (row = [1 : rows-1]) {
            sz = base_t + cup_h + (row-1) * step_h;
            sy = row * pitch;
            translate([-0.5, sy + 2.5, sz])
                rotate([0, 90, 0])
                linear_extrude(height = total_w + 1)
                polygon([
                    [0.1, 0.1],
                    [0.1, -2.6],
                    [-2.5, 0.1]
                ]);
        }
        
        // --- Front bottom edge chamfer ---
        translate([-0.5, 1.5, 0])
            rotate([0, 90, 0])
            linear_extrude(height = total_w + 1)
            polygon([
                [0.1, 0.1],
                [0.1, -1.6],
                [-1.5, 0.1]
            ]);
        
        // --- Weight reduction: hollow out thick rear tiers ---
        for (row = [2 : rows-1]) {
            margin = wall + 4;
            y0 = row * pitch + margin;
            h_block = row * step_h - base_t - 2;
            if (h_block > 3) {
                translate([margin, y0, base_t])
                    cube([
                        total_w - 2*margin, 
                        pitch - 2*margin, 
                        h_block
                    ]);
            }
        }
        
        // Middle row - lighter weight reduction
        mid_margin = wall + 5;
        mid_h = step_h - base_t - 2;
        if (mid_h > 3) {
            translate([mid_margin, pitch + mid_margin, base_t])
                cube([
                    total_w - 2*mid_margin,
                    pitch - 2*mid_margin,
                    mid_h
                ]);
        }
    }
}

stand();
