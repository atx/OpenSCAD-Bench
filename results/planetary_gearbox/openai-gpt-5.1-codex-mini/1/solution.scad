$fn = 120;

// Parameters
clearance = 0.6;
base_thickness = 3;
gear_thickness = 8;
gear_z = base_thickness;
gear_top = gear_z + gear_thickness;
top_clearance = 1.2;
top_cap_thickness = 1.4;
top_total_height = gear_top + top_clearance + top_cap_thickness;

sun_radius = 12;
planet_radius = 8;
orbit_radius = sun_radius + planet_radius + clearance;
axle_radius = 1.6;
shaft_clearance = 0.45;

hub_radius = 10;
arm_width = 6;
arm_length = orbit_radius - hub_radius - 1.2;

ring_inner_radius = 33;
ring_outer_radius = 56;
ring_height = gear_thickness + top_clearance + top_cap_thickness;
ring_teeth = 36;
ring_tooth_depth = 3;
ring_tooth_width = 4;

cage_inner_radius = sun_radius + 0.8;
cage_outer_radius = cage_inner_radius + 3.5;

top_wedge_height = top_cap_thickness;
top_wedge_width = 12;
top_wedge_inner = cage_outer_radius;
top_wedge_outer = ring_inner_radius - 1;

top_wedge_z = gear_top + top_clearance;

module base_plate() {
    translate([0, 0, 0])
        cylinder(r = ring_outer_radius + 5, h = base_thickness, center = false);
}

module ring_gear() {
    translate([0, 0, base_thickness])
        union() {
            difference() {
                cylinder(r = ring_outer_radius, h = ring_height, center = false);
                translate([0, 0, -1])
                    cylinder(r = ring_inner_radius, h = ring_height + 2, center = false);
            }
            for (i = [0:ring_teeth - 1]) {
                angle = 360 * i / ring_teeth;
                rotate([0, 0, angle])
                    translate([ring_inner_radius - ring_tooth_depth / 2, 0, 0])
                        cube([ring_tooth_depth, ring_tooth_width, gear_thickness], center = true);
            }
        }
}

module central_cage() {
    translate([0, 0, base_thickness])
        difference() {
            cylinder(r = cage_outer_radius, h = ring_height, center = false);
            translate([0, 0, -1])
                cylinder(r = cage_inner_radius, h = ring_height + 2, center = false);
        }
}

module interior_lid() {
    translate([0, 0, gear_top + top_clearance])
        difference() {
            cylinder(r = cage_outer_radius + 0.5, h = top_cap_thickness, center = false);
            translate([0, 0, -1])
                cylinder(r = cage_inner_radius + 0.8, h = top_cap_thickness + 2, center = false);
        }
}

module top_wedges() {
    for (angle = [0:60:300]) {
        rotate([0, 0, angle])
            translate([0, 0, top_wedge_z])
                linear_extrude(height = top_wedge_height)
                    polygon(points = [
                        [top_wedge_inner, -top_wedge_width / 2],
                        [top_wedge_outer, -top_wedge_width / 2],
                        [top_wedge_outer, top_wedge_width / 2],
                        [top_wedge_inner, top_wedge_width / 2]
                    ]);
    }
}

module gear_shape(radius, thickness, teeth, tooth_depth, tooth_width) {
    base_radius = radius - tooth_depth;
    union() {
        cylinder(r = base_radius, h = thickness, center = false);
        for (i = [0:teeth - 1]) {
            angle = 360 * i / teeth;
            rotate([0, 0, angle])
                translate([base_radius + tooth_depth / 2, 0, 0])
                    cube([tooth_depth, tooth_width, thickness], center = true);
        }
    }
}

module simple_gear(radius, thickness, teeth, tooth_depth, tooth_width, hole_radius = 0) {
    if (hole_radius > 0) {
        difference() {
            gear_shape(radius, thickness, teeth, tooth_depth, tooth_width);
            translate([0, 0, -1])
                cylinder(r = hole_radius, h = thickness + 2, center = false);
        }
    } else {
        gear_shape(radius, thickness, teeth, tooth_depth, tooth_width);
    }
}

module sun() {
    translate([0, 0, gear_z])
        simple_gear(sun_radius, gear_thickness, sun_teeth, sun_tooth_depth, sun_tooth_width);
}

module planets() {
    for (angle = [0, 120, 240]) {
        rotate([0, 0, angle])
            translate([orbit_radius, 0, gear_z])
                simple_gear(planet_radius, gear_thickness, planet_teeth, planet_tooth_depth, planet_tooth_width, axle_radius + shaft_clearance);
    }
}

module carrier() {
    translate([0, 0, gear_z])
        union() {
            cylinder(r = hub_radius, h = gear_thickness, center = false);
            for (angle = [0, 120, 240]) {
                rotate([0, 0, angle]) {
                    translate([hub_radius, -arm_width / 2, 0])
                        cube([arm_length, arm_width, gear_thickness], center = false);
                    translate([orbit_radius, 0, 0]) {
                        cylinder(r = axle_radius, h = gear_thickness, center = false);
                        translate([0, 0, gear_thickness])
                            cylinder(r = axle_radius / 1.4, h = top_clearance + top_cap_thickness, center = false);
                    }
                }
            }
        }
}

union() {
    base_plate();
    ring_gear();
    central_cage();
    sun();
    planets();
    carrier();
    top_wedges();
    interior_lid();
}
