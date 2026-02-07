// 3D Printer Torture Test Model
// Compact design with multiple test features
// Size: 120mm x 85mm (fits most print beds)

$fn = 50; // Good resolution for circles

// Base dimensions
base_width = 120;
base_depth = 85;
base_height = 3;

module base_plate() {
    cube([base_width, base_depth, base_height]);
}

// Grid of holes (1-10mm diameter) - Tests print accuracy for holes
module hole_test() {
    hole_sizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    spacing = 11;
    
    for (i = [0:9]) {
        translate([10 + i * spacing, 10, -1])
            cylinder(d = hole_sizes[i], h = base_height + 2);
        
        // Size markers below holes
        translate([10 + i * spacing - 1.5, 3, base_height])
            linear_extrude(0.4)
            text(str(hole_sizes[i]), size=2.5, font="Liberation Sans:style=Bold");
    }
}

// Grid of circular pins (1-10mm diameter, heights 1-5mm cycling)
// Tests dimensional accuracy and small feature printing
module pin_test() {
    pin_sizes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    pin_heights = [1, 2, 3, 4, 5, 2, 3, 4, 5, 5]; // Heights vary for testing
    spacing = 11;
    
    for (i = [0:9]) {
        translate([10 + i * spacing, 26, base_height])
            cylinder(d = pin_sizes[i], h = pin_heights[i]);
        
        // Size markers for pins
        translate([10 + i * spacing - 1.5, 19, base_height])
            linear_extrude(0.4)
            text(str(pin_sizes[i]), size=2.5, font="Liberation Sans:style=Bold");
    }
}

// Thin walls test (0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0mm)
// Tests minimum wall thickness capability
module thin_walls_test() {
    wall_thicknesses = [0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0];
    wall_labels = ["0.2", "0.4", "0.6", "0.8", "1.0", "1.5", "2.0"];
    wall_height = 10;
    wall_length = 8;
    spacing = 3.5;
    
    for (i = [0:len(wall_thicknesses)-1]) {
        x_pos = 10 + i * (wall_length + spacing);
        translate([x_pos, 41, base_height])
            cube([wall_thicknesses[i], wall_length, wall_height]);
        
        // Labels
        translate([x_pos - 1, 51, base_height])
            linear_extrude(0.4)
            text(wall_labels[i], size=2, font="Liberation Sans:style=Bold");
    }
}

// Bridge test (5, 10, 20, 30, 40, 50mm lengths)
// Tests bridging capability without support
module bridge_test() {
    bridge_lengths = [5, 10, 20, 30, 40, 50];
    bridge_labels = ["5", "10", "20", "30", "40", "50"];
    bridge_width = 5;
    bridge_thickness = 0.8;
    pillar_height = 10;
    
    y_start = 60;
    
    for (i = [0:len(bridge_lengths)-1]) {
        length = bridge_lengths[i];
        x_pos = 10;
        y_pos = y_start + i * 4;
        
        // Left pillar
        translate([x_pos, y_pos, base_height])
            cube([bridge_width, bridge_width, pillar_height]);
        
        // Right pillar
        translate([x_pos + length + bridge_width, y_pos, base_height])
            cube([bridge_width, bridge_width, pillar_height]);
        
        // Bridge span - the actual test feature
        translate([x_pos + bridge_width, y_pos, base_height + pillar_height])
            cube([length, bridge_width, bridge_thickness]);
        
        // Label
        translate([x_pos + 60, y_pos + 1, base_height])
            linear_extrude(0.4)
            text(str(bridge_labels[i], "mm"), size=2.5, font="Liberation Sans:style=Bold");
    }
}

// Overhang test (10, 20, 30, 40, 50, 60, 70 degrees)
// Tests overhang capability without support
module overhang_test() {
    angles = [10, 20, 30, 40, 50, 60, 70];
    angle_labels = ["10", "20", "30", "40", "50", "60", "70"];
    overhang_height = 12;
    overhang_base = 8;
    base_width_overhang = 4;
    
    x_start = 78;
    
    for (i = [0:len(angles)-1]) {
        angle = angles[i];
        x_pos = x_start + i * 5.5;
        
        // Base support for overhang
        translate([x_pos, 60, base_height])
            cube([base_width_overhang, 5, 2]);
        
        // Overhanging part - angled from vertical
        translate([x_pos, 60, base_height + 2])
        rotate([0, -angle, 0])
            cube([overhang_base, 5, overhang_height]);
        
        // Angle label
        translate([x_pos - 0.5, 66, base_height])
            linear_extrude(0.4)
            text(str(angle_labels[i], "°"), size=2, font="Liberation Sans:style=Bold");
    }
}

// Main section labels for easy identification
module labels() {
    // Holes label
    translate([35, 15, base_height])
        linear_extrude(0.6)
        text("HOLES (mm)", size=3.5, font="Liberation Sans:style=Bold");
    
    // Pins label
    translate([35, 31, base_height])
        linear_extrude(0.6)
        text("PINS (mm)", size=3.5, font="Liberation Sans:style=Bold");
    
    // Walls label
    translate([22, 56, base_height])
        linear_extrude(0.6)
        text("THIN WALLS (mm)", size=3.5, font="Liberation Sans:style=Bold");
    
    // Bridge label
    translate([15, 80, base_height])
        linear_extrude(0.6)
        text("BRIDGES", size=3.5, font="Liberation Sans:style=Bold");
    
    // Overhang label
    translate([83, 75, base_height])
        linear_extrude(0.6)
        text("OVERHANG", size=3, font="Liberation Sans:style=Bold");
    
    // Title on base
    translate([2, base_depth - 5, base_height])
        linear_extrude(0.6)
        text("3D PRINTER TORTURE TEST", size=4, font="Liberation Sans:style=Bold");
}

// Assemble the complete model
module torture_test() {
    difference() {
        union() {
            base_plate();
            pin_test();
            thin_walls_test();
            bridge_test();
            overhang_test();
            labels();
        }
        hole_test();
    }
}

// Render the model
torture_test();
