// Print-in-place planetary gearbox
$fn = 80;

// --- Helper math (radians) ---
function cosr(a) = cos(a*180/PI);
function sinr(a) = sin(a*180/PI);
function atan2r(y,x) = atan2(y,x)*PI/180;
function rot2d(p, a) = [p[0]*cosr(a) - p[1]*sinr(a), p[0]*sinr(a) + p[1]*cosr(a)];
function polar(r,a) = [r*cosr(a), r*sinr(a)];

function involute_point(rb, t) = [rb*(cosr(t) + t*sinr(t)), rb*(sinr(t) - t*cosr(t))];
function involute_intersect_angle(rb, r) = sqrt(r*r - rb*rb)/rb - acos(rb/r)*PI/180;

// --- Gear profile (2D) ---
module gear2d(N, m, pressure_angle=20, clearance=0, backlash=0, steps=6) {
    pitch_radius = N*m/2;
    base_radius  = pitch_radius * cos(pressure_angle);
    addendum     = m;
    dedendum     = 1.25*m + clearance;
    outer_radius = pitch_radius + addendum;
    root_radius  = max(pitch_radius - dedendum, 0.1);
    tooth_thickness = PI*m/2 - backlash;
    half_thick_angle = (tooth_thickness/2)/pitch_radius; // radians
    angle_pitch = involute_intersect_angle(base_radius, pitch_radius);
    rot = half_thick_angle - angle_pitch; // radians
    t_outer = sqrt((outer_radius/base_radius)*(outer_radius/base_radius) - 1);

    tvals = [for (i=[0:steps]) i*t_outer/steps];
    right = [for (t=tvals) rot2d(involute_point(base_radius,t), rot)];
    left  = [for (p=right) [p[0], -p[1]]];

    right_outer = right[len(right)-1];
    left_outer  = left[len(left)-1];
    angle_right = atan2r(right_outer[1], right_outer[0]);
    angle_left  = atan2r(left_outer[1], left_outer[0]);
    arc_steps = 4;
    outer_arc = [for (i=[0:arc_steps]) polar(outer_radius, angle_left + (angle_right-angle_left)*i/arc_steps)];

    left_root  = polar(root_radius, -rot);
    right_root = polar(root_radius,  rot);

    tooth_pts = concat(
        [left_root],
        left,
        outer_arc,
        reverse(right),
        [right_root]
    );

    union() {
        circle(r=root_radius, $fn=max(40, N*4));
        for (i=[0:N-1])
            rotate(i*360/N) polygon(points=tooth_pts);
    }
}

module gear3d(N, m, thickness, bore=0, backlash=0) {
    difference() {
        linear_extrude(height=thickness) gear2d(N, m, backlash=backlash);
        if (bore > 0)
            translate([0,0,-1]) cylinder(r=bore/2, h=thickness+2, $fn=60);
    }
}

// --- Parameters ---
m = 1.5;
pressure_angle = 20;
backlash = 0.15;

sun_teeth = 12;
planet_teeth = 12;
ring_teeth = 36;

gear_thickness = 6.0;

bottom_thickness = 1.5;
carrier_thickness = 2.5;
axial_clearance = 0.25;
cap_height = 1.0;

pin_radius = 2.0;
pin_clearance = 0.2;
planet_bore = 2*(pin_radius + pin_clearance);

shaft_radius = 3.0;
sun_bore = 6.4;
carrier_bore = 6.6;

cap_radius = 3.0;
shaft_cap_radius = 4.0;

planet_center_radius = m*(sun_teeth + planet_teeth)/2; // 18

ring_pitch_radius = ring_teeth*m/2; // 27
ring_outer_radius = ring_pitch_radius + m + 4; // wall thickness

// Z positions
carrier_z0 = bottom_thickness + axial_clearance; // 1.75
carrier_z1 = carrier_z0 + carrier_thickness;     // 4.25
gear_z0 = carrier_z1 + axial_clearance;          // 4.5
gear_z1 = gear_z0 + gear_thickness;              // 10.5
cap_z0  = gear_z1 + axial_clearance;             // 10.75
cap_z1  = cap_z0 + cap_height;                   // 11.75

// --- Carrier shape ---
module carrier_shape() {
    union() {
        circle(r=8, $fn=60);
        for (i=[0:2]) {
            angle = i*120;
            rotate(angle) translate([8, -3]) square([planet_center_radius-8, 6]);
            rotate(angle) translate([planet_center_radius,0]) circle(r=4.5, $fn=40);
        }
    }
}

module carrier() {
    difference() {
        union() {
            translate([0,0,carrier_z0]) linear_extrude(height=carrier_thickness) carrier_shape();
            // planet pins
            for (i=[0:2]) {
                angle = i*120;
                x = planet_center_radius*cos(angle);
                y = planet_center_radius*sin(angle);
                translate([x,y,carrier_z0]) cylinder(r=pin_radius, h=cap_z0-carrier_z0, $fn=50);
                translate([x,y,cap_z0]) cylinder(r1=pin_radius, r2=cap_radius, h=cap_height, $fn=50);
            }
        }
        translate([0,0,carrier_z0-1]) cylinder(r=carrier_bore/2, h=carrier_thickness+2, $fn=60);
    }
}

// --- Fixed housing with ring gear ---
module ring_gear_housing() {
    difference() {
        cylinder(r=ring_outer_radius, h=cap_z1, $fn=120);
        // internal ring gear cavity (slightly enlarged for clearance)
        translate([0,0,0])
            scale([1.02,1.02,1])
            linear_extrude(height=cap_z1)
                gear2d(ring_teeth, m, backlash=backlash);
    }
}

module fixed_shaft() {
    union() {
        // base disc to anchor shaft
        cylinder(r=8, h=bottom_thickness, $fn=80);
        // central shaft
        cylinder(r=shaft_radius, h=cap_z1, $fn=60);
        // top cap to retain sun + carrier
        translate([0,0,cap_z0]) cylinder(r1=shaft_radius, r2=shaft_cap_radius, h=cap_height, $fn=60);
    }
}

// --- Assembly ---
ring_gear_housing();
fixed_shaft();

// Sun gear
translate([0,0,gear_z0]) gear3d(sun_teeth, m, gear_thickness, bore=sun_bore, backlash=backlash);

// Planet gears
for (i=[0:2]) {
    angle = i*120;
    x = planet_center_radius*cos(angle);
    y = planet_center_radius*sin(angle);
    translate([x,y,gear_z0]) gear3d(planet_teeth, m, gear_thickness, bore=planet_bore, backlash=backlash);
}

// Carrier
carrier();
