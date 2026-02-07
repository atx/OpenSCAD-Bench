// 3D Printer Torture Test
// Features: 
// - Hole diameters: 1 to 10mm
// - Pin diameters: 1 to 10mm (heights 1 to 5mm)
// - Thin walls: 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.6, 2.0 mm
// - Bridges: 5, 10, 15, 20, 30, 40, 50 mm
// - Overhangs: 10, 20, 30, 45, 60, 70 degrees (from vertical)

$fn = 32;

module torture_test() {
    base_size_x = 110;
    base_size_y = 100;
    base_h = 3;

    difference() {
        union() {
            // Base plate
            cube([base_size_x, base_size_y, base_h]);
            
            // --- Circular Pins (1mm to 10mm wide, 1-5mm height) ---
            for(i=[1:10]) {
                h_val = ((i-1) % 5) + 1;
                translate([10 + (i-1)*10, 25, base_h]) 
                    cylinder(h=h_val, d=i);
            }
            
            // --- Thin Walls (0.2mm to 2.0mm) ---
            walls = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.6, 2.0];
            for(i=[0:len(walls)-1]) {
                translate([10 + i*13, 40, base_h]) 
                    cube([10, walls[i], 10]);
            }
            
            // --- Bridges (5mm to 50mm) ---
            bridges = [5, 10, 15, 20, 30, 40, 50];
            for(i=[0:len(bridges)-1]) {
                y_off = 55 + i*6;
                pillar_w = 4;
                translate([10, y_off, base_h]) cube([pillar_w, 4, 15]); // Pillar 1
                translate([10 + bridges[i] + pillar_w, y_off, base_h]) cube([pillar_w, 4, 15]); // Pillar 2
                translate([10, y_off, base_h + 15]) 
                    cube([bridges[i] + pillar_w*2, 4, 2]); // Bridge span
            }
            
            // --- Overhang Angles (10-70 degrees from vertical) ---
            o_angles = [10, 20, 30, 45, 60, 70];
            for(i=[0:len(o_angles)-1]) {
                translate([85, 10 + i*13, base_h]) {
                    cube([6, 8, 8]); // Foundation
                    translate([0, 0, 8])
                    rotate([0, o_angles[i], 0])
                        mirror([1,0,0]) cube([20, 8, 2]); // Overhang beam
                }
            }
        }
        
        // --- Grid of Holes (1mm to 10mm) ---
        // Subtracted from base
        for(i=[1:10]) {
            translate([10 + (i-1)*10, 10, -1]) 
                cylinder(h=base_h + 2, d=i);
        }
    }
}

torture_test();
