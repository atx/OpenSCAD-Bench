$fn = 70;

// Base mount plate that presses against the wall
module base_plate() {
    translate([0, -30, 0])
        cube([6, 60, 40]);
}

// Countersunk hole for an M3 flat-head screw
module screw_countersink() {
    // Tapered head area ~6.4 mm diameter
    translate([0, 0, 20])
        rotate([0, 90, 0])
            cylinder(h = 8, r1 = 3.3, r2 = 1.7, center = false);
    // Shaft clearance
    translate([0, 0, 20])
        rotate([0, 90, 0])
            cylinder(h = 10, r = 1.7, center = false);
}

// Curved hook formed by hulls between spheres along a path
module hook_curve() {
    points = [
        [6, 0, 18],
        [18, 0, 22],
        [28, 0, 30],
        [34, 0, 38],
        [34, 0, 48]
    ];

    for (i = [0 : len(points) - 2]) {
        hull() {
            translate(points[i]) sphere(r = 4);
            translate(points[i + 1]) sphere(r = 4);
        }
    }

    // End caps for smooth transitions
    translate(points[0]) sphere(r = 4);
    translate(points[len(points) - 1]) sphere(r = 4);
}

// Reinforcing rib supporting the hook's base
module support_rib() {
    hull() {
        translate([0, -8, 12]) cube([6, 16, 12], center = false);
        translate([6, 0, 22]) sphere(r = 4.2);
    }
}

// Triangular gusset between the plate and hook for better load transfer
module gusset() {
    hull() {
        translate([0, -20, 22]) cube([6, 40, 10], center = false);
        translate([18, 0, 30]) cube([10, 20, 12], center = true);
    }
}

union() {
    difference() {
        union() {
            base_plate();
            support_rib();
            gusset();
            hook_curve();
        }
        translate([0, 0, 20])
            screw_countersink();
    }
}
