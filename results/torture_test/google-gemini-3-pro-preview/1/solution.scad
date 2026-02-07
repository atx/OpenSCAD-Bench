// 3D Printer Torture Test Final
// Features: Holes, Pins, Walls, Bridges, Overhangs
// Compact design

$fn = 60;

// Dimensions
base_w = 130;
base_d = 100;
base_h = 2;

module main() {
    difference() {
        union() {
            // Base
            rounded_cube([base_w, base_d, base_h], 3);
            
            // Feature: Pins (Front Left)
            translate([5, 5, base_h]) feature_pins();
            
            // Feature: Walls (Front Right)
            translate([75, 5, base_h]) feature_walls();
            
            // Feature: Overhangs (Middle Left)
            translate([5, 45, base_h]) feature_overhangs();
            
            // Feature: Bridges (Back)
            translate([2, 85, base_h]) feature_bridges();
            
            // Labels for Holes (Middle Right)
            translate([60, 45, base_h]) feature_hole_labels();
            
            // Main Label
            translate([base_w/2, 2, base_h]) 
                linear_extrude(0.6) 
                text("TEST BOARD", size=4, halign="center");
        }
        
        // Subtract Holes (Middle Right)
        translate([60, 45, -1]) feature_holes_cutout();
    }
}

// 1. PINS
module feature_pins() {
    diams = [2, 3, 4, 6, 8, 10];
    translate([0, -2, 0]) label("PINS");
    
    // 2 Rows of 3
    for (i = [0:len(diams)-1]) {
        d = diams[i];
        row = floor(i/3);
        col = i % 3;
        
        px = col * 15 + 5;
        py = row * 15 + 5;
        h = d < 4 ? 4 : (d/2 + 3);
        
        translate([px, py, 0]) {
            cylinder(d=d, h=h);
            translate([0, -d/2 - 2, 0]) label(str(d), 1.5);
        }
    }
}

// 2. WALLS
module feature_walls() {
    thicks = [0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0];
    translate([0, -2, 0]) label("WALLS");
    
    for(i=[0:len(thicks)-1]) {
        t = thicks[i];
        translate([i * 6, 5, 0]) {
            cube([t, 8, 10]);
            translate([t/2, -2, 0]) label(str(t), 1.2);
        }
    }
}

// 3. OVERHANGS
module feature_overhangs() {
    angles = [15, 30, 45, 60, 70];
    step_h = 6;
    pillar_d = 10;
    pillar_w = 10;
    
    translate([0, -2, 0]) label("OVERHANG");
    
    // Central Pillar
    cube([pillar_w, pillar_d, len(angles)*step_h + 2]);
    
    z = 0;
    for(a = angles) {
        // dx = how much it sticks out
        dx = step_h * tan(a);
        
        translate([0, 0, z]) {
            
            // Attach to Right Side
            translate([pillar_w - 0.01, pillar_d, 0]) 
            rotate([90, 0, 0]) // Extrude along Y
            linear_extrude(pillar_d)
            polygon([[0,0], [dx, step_h], [0, step_h]]);
            
            // Label
            translate([pillar_w/2, pillar_d/2, step_h/2])
            rotate([90, 0, 0])
             label(str(a), 2.5);
        }
        z = z + step_h;
    }
}

// 4. HOLES
module feature_holes_cutout() {
    r1 = [2, 3, 4, 5];
    r2 = [6, 8, 10];
    
    // Row 1
    for(i=[0:len(r1)-1]) {
        d = r1[i];
        translate([i*10 + 5, 5, 0]) cylinder(d=d, h=10);
    }
    // Row 2
    for(i=[0:len(r2)-1]) {
        d = r2[i];
        translate([i*15 + 5, 22, 0]) cylinder(d=d, h=10);
    }
}

module feature_hole_labels() {
    translate([0, -2, 0]) label("HOLES");
    r1 = [2, 3, 4, 5];
    r2 = [6, 8, 10];
    
    for(i=[0:len(r1)-1]) {
        d = r1[i];
        translate([i*10 + 5, 11, 0]) label(str(d), 1.5);
    }
    for(i=[0:len(r2)-1]) {
        d = r2[i];
        translate([i*15 + 5, 30, 0]) label(str(d), 1.5);
    }
}

// 5. BRIDGES
module feature_bridges() {
    spans = [10, 20, 30, 40];
    pillar = 5;
    depth = 8;
    h = 10;
    
    translate([0, -2, 0]) label("BRIDGES");
    
    x = 0;
    for(s = spans) {
        // Pillar
        translate([x, 0, 0]) cube([pillar, depth, h]);
        // Bridge
        translate([x+pillar, 0, h-1.5]) cube([s, depth, 1.5]);
        // Label
        translate([x+pillar+s/2, -1, 0]) label(str(s), 2.5);
        
        x = x + pillar + s;
    }
    translate([x, 0, 0]) cube([pillar, depth, h]);
}

// Helpers
module label(txt, sz=3) {
    linear_extrude(0.6) text(txt, size=sz, halign="center");
}

module rounded_cube(size, r) {
    hull() {
        translate([r, r, 0]) cylinder(h=size[2], r=r);
        translate([size[0]-r, r, 0]) cylinder(h=size[2], r=r);
        translate([size[0]-r, size[1]-r, 0]) cylinder(h=size[2], r=r);
        translate([r, size[1]-r, 0]) cylinder(h=size[2], r=r);
    }
}
