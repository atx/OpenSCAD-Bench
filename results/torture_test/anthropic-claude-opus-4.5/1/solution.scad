// 3D Printer Torture Test Model
// Tests: holes, pins, thin walls, bridges, overhangs
// Size: approximately 100mm x 140mm x 20mm

$fn = 64;

// ==================== HOLES SECTION ====================
// 10 holes from 1mm to 10mm diameter
module holes_section() {
    hole_diameters = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    hole_block_height = 5;
    
    difference() {
        // Block for holes
        cube([28, 32, hole_block_height]);
        
        // Create holes in 2 rows of 5
        for (i = [0:4]) {
            // First row (1-5mm)
            translate([4 + i*5, 7, -1])
                cylinder(d = hole_diameters[i], h = hole_block_height + 2);
            
            // Second row (6-10mm)
            translate([4 + i*5, 21, -1])
                cylinder(d = hole_diameters[i + 5], h = hole_block_height + 2);
        }
    }
    
    // Size indicators on top
    translate([2, 1, hole_block_height])
        linear_extrude(0.5)
            text("1 2 3 4 5", size = 2, spacing = 1.8);
    translate([0, 27, hole_block_height])
        linear_extrude(0.5)
            text("6 7 8 9 10", size = 2, spacing = 1.3);
}

// ==================== PINS SECTION ====================
// 10 pins from 1mm to 10mm diameter, heights 1-5mm  
module pins_section() {
    pin_diameters = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    pin_heights = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5];
    base_h = 2;
    
    // Base for pins
    cube([28, 32, base_h]);
    
    // Create pins in 2 rows of 5
    for (i = [0:4]) {
        // First row (1-5mm diameter)
        translate([4 + i*5, 7, base_h])
            cylinder(d = pin_diameters[i], h = pin_heights[i]);
        
        // Second row (6-10mm diameter)
        translate([4 + i*5, 21, base_h])
            cylinder(d = pin_diameters[i + 5], h = pin_heights[i + 5]);
    }
    
    // Size indicators
    translate([2, 1, base_h])
        linear_extrude(0.5)
            text("1 2 3 4 5", size = 2, spacing = 1.8);
    translate([0, 27, base_h])
        linear_extrude(0.5)
            text("6 7 8 9 10", size = 2, spacing = 1.3);
}

// ==================== THIN WALLS SECTION ====================
// Walls from 0.2mm to 2mm thickness
module thin_walls_section() {
    wall_thicknesses = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0];
    wall_height = 15;
    wall_depth = 10;
    base_h = 2;
    spacing = 3;
    
    total_width = 2;
    for (t = wall_thicknesses) total_width = total_width + t + spacing;
    
    // Base
    cube([total_width, wall_depth + 6, base_h]);
    
    // Create walls with increasing thickness
    x_pos = 2;
    for (i = [0:len(wall_thicknesses)-1]) {
        translate([x_pos, 3, base_h])
            cube([wall_thicknesses[i], wall_depth, wall_height]);
        x_pos = x_pos + wall_thicknesses[i] + spacing;
    }
}

// ==================== BRIDGES SECTION ====================
// Bridges from 5mm to 50mm length
module bridges_section() {
    bridge_lengths = [5, 10, 15, 20, 30, 40, 50];
    bridge_width = 4;
    pillar_height = 8;
    bridge_thickness = 1.2;
    pillar_width = 3;
    spacing = 1.5;
    
    for (i = [0:len(bridge_lengths)-1]) {
        bridge_len = bridge_lengths[i];
        y_pos = i * (bridge_width + spacing);
        
        // Left pillar
        translate([0, y_pos, 0])
            cube([pillar_width, bridge_width, pillar_height]);
        
        // Right pillar  
        translate([pillar_width + bridge_len, y_pos, 0])
            cube([pillar_width, bridge_width, pillar_height]);
        
        // Bridge span (the actual unsupported bridge)
        translate([pillar_width, y_pos, pillar_height - bridge_thickness])
            cube([bridge_len, bridge_width, bridge_thickness]);
    }
}

// ==================== OVERHANGS SECTION ====================
// Overhangs from 10 to 70 degrees (angle from vertical)
module overhangs_section() {
    overhang_angles = [10, 20, 30, 40, 50, 60, 70];
    overhang_width = 8;
    support_height = 18;
    overhang_length = 12;
    thickness = 2;
    spacing = 2;
    
    for (i = [0:len(overhang_angles)-1]) {
        angle = overhang_angles[i];
        y_pos = i * (overhang_width + spacing);
        
        // Vertical support pillar
        translate([0, y_pos, 0])
            cube([thickness, overhang_width, support_height]);
        
        // Angled overhang - created by rotating a block
        translate([thickness, y_pos + overhang_width/2, support_height]) {
            rotate([0, angle, 0])
            translate([0, -overhang_width/2, -thickness])
                cube([overhang_length, overhang_width, thickness]);
        }
    }
}

// ==================== MAIN BASE AND ASSEMBLY ====================
module torture_test() {
    base_height = 3;
    
    // Total base dimensions
    base_width = 100;
    base_depth = 140;
    
    // Main base plate
    cube([base_width, base_depth, base_height]);
    
    // Title at top
    translate([5, base_depth - 9, base_height])
        linear_extrude(0.6)
            text("3D PRINTER TORTURE TEST", size = 4);
    
    // Row positions
    row1_y = 5;      // Bridges and overhangs at bottom
    row2_y = 55;     // Thin walls in middle
    row3_y = 90;     // Holes and pins near top
    
    // ===== Section 1: Holes (upper left) =====
    translate([5, row3_y, base_height]) {
        holes_section();
    }
    translate([5, row3_y + 33, base_height])
        linear_extrude(0.6)
            text("HOLES mm", size = 3);
    
    // ===== Section 2: Pins (upper right) =====
    translate([50, row3_y, base_height]) {
        pins_section();
    }
    translate([50, row3_y + 33, base_height])
        linear_extrude(0.6)
            text("PINS mm", size = 3);
    
    // ===== Section 3: Thin walls (middle) =====
    translate([5, row2_y, base_height]) {
        thin_walls_section();
    }
    translate([5, row2_y + 20, base_height])
        linear_extrude(0.6)
            text("THIN WALLS 0.2-2.0mm", size = 2.5);
    
    // ===== Section 4: Overhangs (right side) =====
    translate([55, row1_y, base_height]) {
        overhangs_section();
    }
    translate([75, row1_y + 72, base_height])
        linear_extrude(0.6)
            text("OVERHANG", size = 2.5);
    translate([75, row1_y + 67, base_height])
        linear_extrude(0.6)
            text("10-70 deg", size = 2.5);
    
    // ===== Section 5: Bridges (bottom left) =====
    translate([5, row1_y, base_height]) {
        bridges_section();
    }
    translate([5, row1_y + 40, base_height])
        linear_extrude(0.6)
            text("BRIDGES 5-50mm", size = 2.5);
        
    // Corner chamfers for easier removal from build plate
    // (small triangles at corners)
}

torture_test();
