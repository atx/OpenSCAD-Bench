// Print-in-place planetary gearbox, single stage, 3 planets
// Parameters tuned for 0.4mm nozzle, 0.1mm layer height, PETG
// All dimensions in mm.

// ---------------- Parameters ----------------
module_size      = 1.2;       // gear module
sun_teeth        = 12;
planet_teeth     = 12;
ring_teeth       = 36;        // must satisfy: ring = sun + 2*planet
pressure_angle   = 20;        // degrees
backlash         = 0.15;      // circumferential backlash at pitch radius
radial_clearance = 0.30;      // radial gap between bodies to avoid fusing

gear_thickness   = 7.0;       // axial thickness of gears
base_thickness   = 1.2;       // solid floor under gears
axial_gap        = 0.25;      // vertical clearance between stacked parts
ring_rim         = 3.0;       // radial rim thickness outside pitch
ring_cap_height  = 0.6;       // top cap thickness (flat)
carrier_thickness = 3.5;      // carrier plate thickness
pin_radius       = 2.0;       // carrier pin radius (before clearance)
pin_head_clear   = 0.20;      // extra allowance in pin length
pin_head_thick   = 0.6;       // thickness of pin head cap
pin_head_rad_extra = 0.6;     // how much wider than pin radius
sun_bore_radius  = 3.0;       // bore through sun gear for shaft
sun_cap_thick    = 0.6;       // small retainer above sun
sun_cap_gap      = 0.2;       // axial clearance between sun top and cap

$fn = 120; // smoothness

// ---------------- Helper functions ----------------
function to_r(x) = x * PI / 180; // degrees to radians

// Involute curve parametric
function involute_point(rb, t) = [
    rb * (cos(t) + t * sin(t)),
    rb * (sin(t) - t * cos(t))
];

// Construct a single tooth 2D polygon for external gear
module involute_tooth(teeth, module_size, pressure_angle=20, backlash=0.1, clearance=0.0) {
    pa = to_r(pressure_angle);
    pitch_radius = module_size * teeth / 2;
    base_radius  = pitch_radius * cos(pa);
    addendum     = module_size;
    dedendum     = 1.25 * module_size + clearance; // standard + clearance
    outer_radius = pitch_radius + addendum;
    root_radius  = pitch_radius - dedendum;

    // Trim to base circle
    t_out = sqrt(max(0, (outer_radius*outer_radius)/(base_radius*base_radius) - 1));
    t_pitch = sqrt(max(0, (pitch_radius* pitch_radius)/(base_radius*base_radius) - 1));

    flank_pts = [ for (t=[t_pitch: (t_out - t_pitch)/6 : t_out]) involute_point(base_radius, t) ];
    // Add outer and mirror
    tooth = concat(
        [[root_radius*cos(-backlash/(2*pitch_radius)), root_radius*sin(-backlash/(2*pitch_radius))]],
        flank_pts,
        [[outer_radius*cos(backlash/(2*pitch_radius)), outer_radius*sin(backlash/(2*pitch_radius))]],
        [ for (p = flank_pts) [-p[0], p[1]] ],
        [[root_radius*cos(backlash/(2*pitch_radius)), root_radius*sin(backlash/(2*pitch_radius))]]
    );

    // Rotate to center tooth at x-axis
    rot = -90/teeth; // half tooth angle
    rotate(rot) polygon(points=tooth);
}

// External spur gear 2D profile
module gear2d(teeth, module_size, pressure_angle=20, backlash=0.1, clearance=0.0) {
    union() {
        for (i = [0:teeth-1])
            rotate(i * 360/teeth) involute_tooth(teeth, module_size, pressure_angle, backlash, clearance);
    }
}

// 3D extruded gear
module spur_gear(teeth, module_size, thickness, bore_radius=0, pressure_angle=20, backlash=0.1, clearance=0.0) {
    linear_extrude(height=thickness)
        difference() {
            gear2d(teeth, module_size, pressure_angle, backlash, clearance);
            if (bore_radius>0) circle(r=bore_radius);
        }
}

// Internal ring gear as disk minus oversized external gear (inverse profile)
module ring_gear_internal(teeth, module_size, thickness, rim=3.0, pressure_angle=20, backlash=0.1, clearance=0.0) {
    pitch_radius = module_size * teeth / 2;
    addendum = module_size;
    outer_radius = pitch_radius + addendum + rim;
    gear_cut_clear = clearance + 0.05; // slightly enlarge void for PIP

    difference() {
        cylinder(r=outer_radius, h=thickness);
        // create the void shaped like an external gear
        translate([0,0,0]) spur_gear(teeth, module_size, thickness+0.2, 0, pressure_angle, backlash, gear_cut_clear);
    }
}

// Carrier plate with 3 pins and reliefs under planets
module carrier(teeth_sun, teeth_planet, module_size, thickness, pin_r, pin_h, central_clear, planet_relief_r) {
    sun_pitch = module_size * teeth_sun / 2;
    planet_pitch = module_size * teeth_planet / 2;
    center_r = sun_pitch + planet_pitch;

    carrier_r = center_r + module_size + 1; // leave margin inside ring roots

    difference() {
        union() {
            // main plate
            linear_extrude(height=thickness)
                circle(r=carrier_r);
            // pins
            for (i=[0:2]) {
                angle = i*120;
                translate([center_r*cos(to_r(angle)), center_r*sin(to_r(angle)), 0])
                    cylinder(r=pin_r, h=pin_h);
            }
        }
        // reliefs under each planet
        for (i=[0:2]) {
            angle = i*120;
            translate([center_r*cos(to_r(angle)), center_r*sin(to_r(angle)), -1])
                cylinder(r=planet_relief_r, h=thickness+2);
        }
        // central clearance around sun
        translate([0,0,-1]) cylinder(r=central_clear, h=thickness+2);
    }
}

// ---------------- Assembly ----------------
module planetary_assembly() {
    pa = pressure_angle;
    sun_pitch = module_size * sun_teeth / 2;
    planet_pitch = module_size * planet_teeth / 2;
    ring_pitch = module_size * ring_teeth / 2;
    addendum = module_size;
    center_r = sun_pitch + planet_pitch;

    z_base = 0;
    z_gears = z_base + base_thickness + axial_gap; // gear bottoms
    z_carrier = z_base + base_thickness;           // carrier sits on the base with a gap below gears

    // Outer ring gear with base and shallow cap height allowance
    ring_height_body = base_thickness + axial_gap + gear_thickness + axial_gap + pin_head_thick + sun_cap_gap;
    ring_outer_radius = ring_pitch + addendum + ring_rim;

    // main ring body (with internal teeth)
    translate([0,0,z_base]) ring_gear_internal(ring_teeth, module_size, ring_height_body, rim=ring_rim, pressure_angle=pa, backlash=backlash, clearance=radial_clearance);

    // Sun gear
    translate([0,0,z_gears])
        spur_gear(sun_teeth, module_size, gear_thickness, bore_radius=sun_bore_radius, pressure_angle=pa, backlash=backlash, clearance=radial_clearance/2);

    // Planets
    for (i=[0:2]) {
        angle = i*120;
        translate([center_r*cos(to_r(angle)), center_r*sin(to_r(angle)), z_gears])
            spur_gear(planet_teeth, module_size, gear_thickness, bore_radius=pin_radius + radial_clearance, pressure_angle=pa, backlash=backlash, clearance=radial_clearance/2);
    }

    // Carrier (captured between base and top clearance)
    central_clearance = sun_pitch + addendum + radial_clearance + 0.4;
    planet_relief = planet_pitch + addendum + radial_clearance*1.5;
    pin_height = (z_gears - z_carrier) + gear_thickness + axial_gap + pin_head_clear;
    translate([0,0,z_carrier]) carrier(sun_teeth, planet_teeth, module_size, carrier_thickness, pin_radius, pin_height, central_clearance, planet_relief);

    // Pin heads to retain planets (sit above gear tops with axial gap)
    head_base_z = z_gears + gear_thickness + axial_gap;
    for (i=[0:2]) {
        angle = i*120;
        translate([center_r*cos(to_r(angle)), center_r*sin(to_r(angle)), head_base_z])
            cylinder(r=pin_radius + pin_head_rad_extra, h=pin_head_thick);
    }

    // Small central cap to retain sun gear while keeping a shaft hole
    translate([0,0, z_gears + gear_thickness + sun_cap_gap])
        difference() {
            cylinder(r=sun_pitch + addendum, h=sun_cap_thick);
            cylinder(r=sun_bore_radius + radial_clearance, h=sun_cap_thick+0.2);
        }
}

planetary_assembly();
