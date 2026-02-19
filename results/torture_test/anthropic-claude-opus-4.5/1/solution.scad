// 3D Printer Torture Test Model
// Tests: holes, pins, thin walls, bridges, overhangs, stringing, dimensional accuracy

$fn = 64;

// Base dimensions
base_thickness = 3;
base_width = 150;
base_depth = 95;

// ==================== BASE PLATE ====================
module base_plate() {
    cube([base_width, base_depth, base_thickness]);
}

// ==================== HOLES GRID (1-10mm) ====================
module holes_section() {
    hole_sizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    section_height = 5;
    
    translate([3, 3, base_thickness]) {
        difference() {
            // Block for holes
            cube([62, 16, section_height]);
            
            // Create holes - evenly spaced
            for (i = [0:9]) {
                translate([4 + i * 6, 9, -1])
                    cylinder(d = hole_sizes[i], h = section_height + 2);
            }
            
            // Label engraved
            translate([31, 2, section_height - 0.3])
                linear_extrude(0.5)
                    text("HOLES 1-10mm", size = 2.5, halign = "center", valign = "center");
        }
        
        // Size labels on top
        for (i = [0:9]) {
            translate([4 + i * 6, 15, section_height])
                linear_extrude(0.4)
                    text(str(i+1), size = 2, halign = "center", valign = "center");
        }
    }
}

// ==================== PINS GRID (1-10mm diameter, varying heights) ====================
module pins_section() {
    pin_diameters = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    pin_heights = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5];
    
    translate([72, 3, base_thickness]) {
        // Base platform with label
        difference() {
            cube([62, 16, 1]);
            translate([31, 2, 0.5])
                linear_extrude(0.7)
                    text("PINS 1-10mm", size = 2.5, halign = "center", valign = "center");
        }
        
        // Create pins - evenly spaced
        for (i = [0:9]) {
            translate([4 + i * 6, 9, 1])
                cylinder(d = pin_diameters[i], h = pin_heights[i]);
        }
        
        // Size labels
        for (i = [0:9]) {
            translate([4 + i * 6, 15, 1])
                linear_extrude(0.4)
                    text(str(i+1), size = 2, halign = "center", valign = "center");
        }
    }
}

// ==================== THIN WALLS (0.4-2mm) ====================
module thin_walls_section() {
    wall_thicknesses = [0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0];
    wall_height = 12;
    wall_length = 8;
    
    translate([3, 24, base_thickness]) {
        // Base for walls with label
        difference() {
            cube([50, 13, 1]);
            translate([25, 11, 0.5])
                linear_extrude(0.7)
                    text("WALLS", size = 2.5, halign = "center", valign = "center");
        }
        
        // Create thin walls
        x_pos = 3;
        for (i = [0:6]) {
            translate([x_pos, 1, 1])
                cube([wall_thicknesses[i], wall_length, wall_height]);
            x_pos = x_pos + 7;
        }
        
        // Wall thickness labels on top
        x_pos = 3;
        for (i = [0:6]) {
            translate([x_pos + wall_thicknesses[i]/2, wall_length/2 + 1, wall_height + 1])
                linear_extrude(0.4)
                    text(str(wall_thicknesses[i]), size = 2, halign = "center", valign = "center");
            x_pos = x_pos + 7;
        }
    }
}

// ==================== OVERHANGS (15-75 degrees) ====================
module overhangs_section() {
    overhang_angles = [15, 25, 35, 45, 55, 65, 75];
    overhang_width = 8;
    overhang_height = 12;
    
    translate([58, 24, base_thickness]) {
        // Base label
        translate([82, 6.5, 0])
            linear_extrude(0.5)
                text("OVERHANG", size = 2.5, halign = "center", valign = "center", direction = "ttb");
        
        for (i = [0:6]) {
            x_offset = i * 10;
            angle = overhang_angles[i];
            
            translate([x_offset, 0, 0]) {
                // Vertical support
                cube([3, overhang_width, overhang_height]);
                
                // Angled overhang
                overhang_length = 7;
                translate([3, 0, 0])
                    rotate([0, -angle, 0])
                        cube([overhang_length, overhang_width, 1.5]);
                
                // Angle label on top
                translate([1.5, overhang_width/2, overhang_height])
                    linear_extrude(0.4)
                        text(str(angle), size = 2, halign = "center", valign = "center");
            }
        }
    }
}

// ==================== BRIDGES (5-50mm, select lengths) ====================
module bridges_section() {
    bridge_lengths = [5, 10, 15, 20, 30, 40, 50];
    bridge_width = 4;
    bridge_thickness = 1.5;
    pillar_height = 8;
    pillar_width = 3;
    
    translate([3, 43, base_thickness]) {
        // Label
        translate([0, 44, 0])
            linear_extrude(0.5)
                text("BRIDGES", size = 3, halign = "left", valign = "center");
        
        for (i = [0:6]) {
            y_offset = i * 6;
            
            // Left pillar
            translate([0, y_offset, 0])
                cube([pillar_width, bridge_width, pillar_height]);
            
            // Right pillar
            translate([pillar_width + bridge_lengths[i], y_offset, 0])
                cube([pillar_width, bridge_width, pillar_height]);
            
            // Bridge span
            translate([pillar_width, y_offset, pillar_height - bridge_thickness])
                cube([bridge_lengths[i], bridge_width, bridge_thickness]);
            
            // Length label on right side
            translate([pillar_width + bridge_lengths[i] + pillar_width + 1, y_offset + bridge_width/2, pillar_height/2])
                linear_extrude(0.4)
                    text(str(bridge_lengths[i]), size = 2.5, halign = "left", valign = "center");
        }
    }
}

// ==================== STRINGING TEST (cone array) ====================
module stringing_test() {
    translate([68, 43, base_thickness]) {
        // Base with label
        difference() {
            cube([28, 42, 1]);
            translate([14, 40, 0.5])
                linear_extrude(0.7)
                    text("STRINGING", size = 2.5, halign = "center", valign = "center");
        }
        
        // Array of cones/spires for stringing test
        for (x = [0:4]) {
            for (y = [0:6]) {
                translate([3 + x * 5, 3 + y * 5, 1])
                    cylinder(d1 = 3, d2 = 0.5, h = 10);
            }
        }
    }
}

// ==================== DIMENSIONAL ACCURACY TEST ====================
module dimensional_test() {
    translate([102, 43, base_thickness]) {
        // Base platform
        difference() {
            cube([45, 45, 1]);
            translate([22.5, 43, 0.5])
                linear_extrude(0.7)
                    text("ACCURACY", size = 2.5, halign = "center", valign = "center");
        }
        
        // 20mm x 20mm x 10mm calibration cube
        translate([0, 5, 1]) {
            difference() {
                cube([20, 20, 10]);
                
                // X mark on top
                translate([10, 10, 9.5])
                    linear_extrude(1)
                        text("X", size = 6, halign = "center", valign = "center");
                
                // Y mark on right side
                translate([19.5, 10, 5])
                    rotate([90, 0, 90])
                        linear_extrude(1)
                            text("Y", size = 6, halign = "center", valign = "center");
                
                // Z mark on front
                translate([10, 0.5, 5])
                    rotate([90, 0, 0])
                        linear_extrude(1)
                            text("Z", size = 6, halign = "center", valign = "center");
            }
        }
        
        // Small cylinder for roundness test
        translate([32, 17, 1])
            cylinder(d = 15, h = 8);
        
        // Labels
        translate([10, 1, 1])
            linear_extrude(0.5)
                text("20x20", size = 2.5, halign = "center", valign = "center");
        
        translate([32, 1, 1])
            linear_extrude(0.5)
                text("D15", size = 2.5, halign = "center", valign = "center");
    }
}

// ==================== TITLE ====================
module title() {
    translate([75, 91, base_thickness])
        linear_extrude(0.6)
            text("3D PRINTER TORTURE TEST", size = 4, halign = "center", valign = "center");
}

// ==================== MAIN ASSEMBLY ====================
module torture_test() {
    base_plate();
    title();
    holes_section();
    pins_section();
    thin_walls_section();
    overhangs_section();
    bridges_section();
    stringing_test();
    dimensional_test();
}

torture_test();
