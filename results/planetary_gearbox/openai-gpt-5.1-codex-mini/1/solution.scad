// Print-in-place single-stage planetary gearbox
// Material: PETG, nozzle 0.4mm, layer 0.1mm, Z-up orientation

// Parameters
base_thickness = 3;
gear_height = 6;
top_capture_height = 6;
post_height = base_thickness + gear_height + top_capture_height;
clearance = 0.6; // small gap to keep printing parts separate

module_size = 1.8;
sun_teeth = 12;
planet_teeth = 12;
planet_count = 3;

sun_pitch_radius = module_size * sun_teeth / 2;
planet_pitch_radius = module_size * planet_teeth / 2;
ring_pitch_radius = sun_pitch_radius + 2 * planet_pitch_radius;
planet_orbit_radius = sun_pitch_radius + planet_pitch_radius;
tooth_depth = module_size * 0.9;

ring_inner_radius = ring_pitch_radius + tooth_depth + clearance;
ring_wall_thickness = 6;
outer_radius = ring_inner_radius + ring_wall_thickness;
ring_teeth = sun_teeth + 2 * planet_teeth;
ring_tooth_width = min((2 * PI * ring_pitch_radius / ring_teeth) * 0.6, module_size * 3.5);

sun_post_radius = 1.6;
planet_post_radius = 1.6;
sun_center_hole = sun_post_radius + clearance / 2;
planet_center_hole = planet_post_radius + clearance / 2;

sun_cage_inner = sun_pitch_radius + tooth_depth + clearance;
sun_cage_outer = sun_cage_inner + 3.5;
sun_cage_height = gear_height + top_capture_height;

planet_cage_inner = planet_pitch_radius + tooth_depth + clearance;
planet_cage_outer = planet_cage_inner + 2;
planet_cage_height = top_capture_height;

arm_width = 3;
arm_length = ring_inner_radius - sun_cage_outer + 1;
arm_height = sun_cage_height;
arm_angles = [60, 180, 300];

planet_angles = [0, 120, 240];
planet_centers = [for (a = planet_angles) [planet_orbit_radius * cos(a), planet_orbit_radius * sin(a)]];

$fn = 120;

module spur_gear(teeth, module_size, thickness, center_hole = 0) {
    pitch_radius = module_size * teeth / 2;
    tooth_width = min((2 * PI * pitch_radius / teeth) * 0.65, module_size * 3);
    root_radius = max(pitch_radius - tooth_depth, module_size);
    difference() {
        linear_extrude(height = thickness) {
            union() {
                circle(r = root_radius, $fn = 200);
                for (i = [0:teeth - 1]) {
                    rotate(i * 360 / teeth)
                        translate([pitch_radius, -tooth_width / 2])
                            square([tooth_depth, tooth_width], center = false);
                }
            }
        }
        if (center_hole > 0)
            translate([0, 0, 0])
                linear_extrude(height = thickness)
                    circle(r = center_hole, $fn = 80);
    }
}

module ring_teeth(num_teeth, inner_radius) {
    union() {
        for (i = [0:num_teeth - 1]) {
            rotate(i * 360 / num_teeth)
                translate([inner_radius - tooth_depth, -ring_tooth_width / 2, base_thickness])
                    cube([tooth_depth, ring_tooth_width, gear_height], center = false);
        }
    }
}

module sun_cage() {
    translate([0, 0, 0])
        difference() {
            cylinder(r = sun_cage_outer, h = sun_cage_height, $fn = 120);
            translate([0, 0, -0.2])
                cylinder(r = sun_cage_inner, h = sun_cage_height + 0.4, $fn = 120);
        }
}

module planet_cage(center) {
    translate([center[0], center[1], base_thickness + gear_height - 0.2])
        difference() {
            cylinder(r = planet_cage_outer, h = planet_cage_height, $fn = 80);
            translate([0, 0, -0.1])
                cylinder(r = planet_cage_inner, h = planet_cage_height + 0.2, $fn = 80);
        }
}

module radial_arm(angle) {
    rotate([0, 0, angle])
        translate([sun_cage_outer, -arm_width / 2, 0])
            cube([arm_length, arm_width, arm_height], center = false);
}

module planet_post(center) {
    translate([center[0], center[1], 0])
        cylinder(r = planet_post_radius, h = post_height, $fn = 40);
}

module sun_post() {
    translate([0, 0, 0])
        cylinder(r = sun_post_radius, h = post_height, $fn = 40);
}

module ring_wall() {
    difference() {
        translate([0, 0, base_thickness])
            cylinder(r = outer_radius, h = gear_height);
        translate([0, 0, base_thickness])
            cylinder(r = ring_inner_radius, h = gear_height + 0.1);
    }
}

module sun_lid() {
    translate([0, 0, base_thickness + gear_height + 0.5])
        difference() {
            cylinder(r = sun_cage_outer, h = 1.5, $fn = 120);
            translate([0, 0, 0])
                cylinder(r = max(sun_cage_inner - 0.2, 0), h = 1.6, $fn = 120);
        }
}

module planetary_assembly() {
    union() {
        cylinder(r = outer_radius + 8, h = base_thickness);

        ring_wall();
        ring_teeth(ring_teeth, ring_inner_radius);

        sun_post();
        for (center = planet_centers)
            planet_post(center);

        sun_cage();
        sun_lid();

        for (center = planet_centers)
            planet_cage(center);

        for (angle = arm_angles)
            radial_arm(angle);

        translate([0, 0, base_thickness])
            spur_gear(sun_teeth, module_size, gear_height, sun_center_hole);
        for (center = planet_centers)
            translate([center[0], center[1], base_thickness])
                spur_gear(planet_teeth, module_size, gear_height, planet_center_hole);
    }
}

planetary_assembly();
