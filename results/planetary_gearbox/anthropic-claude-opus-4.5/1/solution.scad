// Print-in-Place Planetary Gearbox
// Designed for PETG, 0.4mm nozzle, 0.1mm layer height
// All parts print together and rotate freely after printing

// === PARAMETERS ===

// Clearances for print-in-place (PETG with 0.4mm nozzle, 0.1mm layer)
clearance_xy = 0.4;      // Horizontal clearance between moving parts
clearance_z = 0.3;       // Vertical clearance (3 layers)

// Gear parameters
module_size = 2.5;       // Gear module (tooth size)
pressure_angle = 20;     // Standard pressure angle
gear_height = 12;        // Height of gear teeth

// Tooth counts (must satisfy: ring = sun + 2*planet for proper meshing)
sun_teeth = 12;
planet_teeth = 9;
ring_teeth = 30;         // 12 + 2*9 = 30 ✓

// Number of planet gears
num_planets = 3;

// Derived dimensions
sun_pitch_r = (module_size * sun_teeth) / 2;        // 15
planet_pitch_r = (module_size * planet_teeth) / 2;  // 11.25
ring_pitch_r = (module_size * ring_teeth) / 2;      // 37.5
planet_orbit_r = sun_pitch_r + planet_pitch_r;      // 26.25

// Component radii
sun_outer_r = sun_pitch_r + module_size;            // 17.5
planet_outer_r = planet_pitch_r + module_size;      // 13.75
ring_inner_r = ring_pitch_r - module_size;          // 35
ring_outer_r = ring_pitch_r + module_size * 2.5 + 5; // ~48.75

// Carrier dimensions - must fit inside ring teeth with clearance
carrier_outer_r = ring_inner_r - clearance_xy - 1;

// Heights
base_thickness = 4;       // Bottom plate
top_thickness = 4;        // Top plate  
total_height = base_thickness + gear_height + top_thickness;

// Pin dimensions for planet axles
pin_r = 3;

$fn = 64;

// === EXTERNAL GEAR ===
module external_gear_2d(teeth, backlash = 0) {
    pitch_r = module_size * teeth / 2;
    addendum = module_size;
    dedendum = module_size * 1.25;
    outer_r = pitch_r + addendum - backlash/2;
    root_r = pitch_r - dedendum;
    
    tooth_angle = 360 / teeth;
    tooth_arc = PI * module_size / 2 - backlash;
    half_tooth_angle = (tooth_arc / pitch_r) * 180 / PI / 2;
    
    union() {
        circle(r = root_r, $fn = teeth * 6);
        
        for(i = [0:teeth-1]) {
            rotate([0, 0, i * tooth_angle]) {
                polygon([
                    [root_r * cos(-half_tooth_angle * 1.1), root_r * sin(-half_tooth_angle * 1.1)],
                    [pitch_r * cos(-half_tooth_angle * 0.85), pitch_r * sin(-half_tooth_angle * 0.85)],
                    [outer_r * cos(-half_tooth_angle * 0.45), outer_r * sin(-half_tooth_angle * 0.45)],
                    [outer_r * cos(half_tooth_angle * 0.45), outer_r * sin(half_tooth_angle * 0.45)],
                    [pitch_r * cos(half_tooth_angle * 0.85), pitch_r * sin(half_tooth_angle * 0.85)],
                    [root_r * cos(half_tooth_angle * 1.1), root_r * sin(half_tooth_angle * 1.1)]
                ]);
            }
        }
    }
}

// === INTERNAL GEAR (Ring) ===
module internal_gear_2d(teeth, backlash = 0) {
    pitch_r = module_size * teeth / 2;
    inner_r = pitch_r - module_size + backlash/2;
    root_r = pitch_r + module_size * 1.25;
    
    tooth_angle = 360 / teeth;
    space_arc = PI * module_size / 2 + backlash;
    half_space_angle = (space_arc / pitch_r) * 180 / PI / 2;
    
    difference() {
        circle(r = root_r + 3, $fn = teeth * 6);
        
        union() {
            circle(r = inner_r, $fn = teeth * 6);
            
            for(i = [0:teeth-1]) {
                rotate([0, 0, i * tooth_angle]) {
                    polygon([
                        [inner_r * cos(-half_space_angle * 1.1), inner_r * sin(-half_space_angle * 1.1)],
                        [pitch_r * cos(-half_space_angle * 0.85), pitch_r * sin(-half_space_angle * 0.85)],
                        [(pitch_r + module_size * 0.5) * cos(-half_space_angle * 0.35), (pitch_r + module_size * 0.5) * sin(-half_space_angle * 0.35)],
                        [(pitch_r + module_size * 0.5) * cos(half_space_angle * 0.35), (pitch_r + module_size * 0.5) * sin(half_space_angle * 0.35)],
                        [pitch_r * cos(half_space_angle * 0.85), pitch_r * sin(half_space_angle * 0.85)],
                        [inner_r * cos(half_space_angle * 1.1), inner_r * sin(half_space_angle * 1.1)]
                    ]);
                }
            }
        }
    }
}

// === SUN GEAR (INPUT) ===
module sun_gear() {
    shaft_r = 5;
    
    // Main gear teeth
    linear_extrude(height = gear_height)
        external_gear_2d(sun_teeth, clearance_xy);
    
    // Lower bearing shaft
    translate([0, 0, -base_thickness + clearance_z])
        cylinder(r = shaft_r, h = base_thickness - clearance_z);
    
    // Upper shaft through carrier
    translate([0, 0, gear_height])
        cylinder(r = shaft_r, h = top_thickness + 8);
    
    // Input handle
    translate([0, 0, gear_height + top_thickness + 8])
        cylinder(r = shaft_r + 8, h = 5, $fn = 6);
}

// === PLANET GEAR ===
module planet_gear() {
    difference() {
        linear_extrude(height = gear_height - clearance_z * 2)
            external_gear_2d(planet_teeth, clearance_xy);
        
        translate([0, 0, -0.1])
            cylinder(r = pin_r + clearance_xy, h = gear_height);
    }
}

// === CARRIER (OUTPUT) ===
module carrier() {
    shaft_hole_r = 5 + clearance_xy;
    post_r = 4;
    
    // Bottom plate (captured by ring housing)
    translate([0, 0, -base_thickness + clearance_z]) {
        difference() {
            cylinder(r = carrier_outer_r, h = base_thickness - clearance_z * 2);
            translate([0, 0, -0.1])
                cylinder(r = shaft_hole_r, h = base_thickness);
        }
    }
    
    // Planet axle pins
    for(i = [0:num_planets-1]) {
        angle = i * 360 / num_planets;
        rotate([0, 0, angle])
            translate([planet_orbit_r, 0, clearance_z])
                cylinder(r = pin_r, h = gear_height - clearance_z * 2);
    }
    
    // Top plate
    translate([0, 0, gear_height]) {
        difference() {
            union() {
                cylinder(r = carrier_outer_r, h = top_thickness - clearance_z * 2);
                
                // Output hub
                translate([0, 0, top_thickness - clearance_z * 2])
                    cylinder(r = carrier_outer_r - 6, h = 10);
            }
            
            translate([0, 0, -0.1])
                cylinder(r = shaft_hole_r, h = top_thickness + 20);
            
            // Pin connection holes
            for(i = [0:num_planets-1]) {
                angle = i * 360 / num_planets;
                rotate([0, 0, angle])
                    translate([planet_orbit_r, 0, -0.1])
                        cylinder(r = pin_r + 0.2, h = top_thickness);
            }
            
            // Output hex
            translate([0, 0, top_thickness + 2])
                cylinder(r = 10, h = 15, $fn = 6);
        }
    }
    
    // Connection posts (in spaces between planets, must clear ring gear teeth)
    for(i = [0:num_planets-1]) {
        angle = i * 360 / num_planets + 60;
        rotate([0, 0, angle])
            translate([carrier_outer_r - post_r - 2, 0, -base_thickness + clearance_z])
                cylinder(r = post_r, h = gear_height + base_thickness + top_thickness - clearance_z * 4);
    }
}

// === RING GEAR HOUSING ===
module ring_housing() {
    gear_cavity_r = ring_pitch_r + module_size * 1.5;
    shaft_hole_r = 5 + clearance_xy;
    carrier_cavity_r = carrier_outer_r + clearance_xy;
    post_r = 4;
    
    difference() {
        union() {
            // Main body
            cylinder(r = ring_outer_r, h = total_height);
            
            // Base flange
            translate([0, 0, -3])
                cylinder(r = ring_outer_r + 12, h = 3);
        }
        
        // Internal gear teeth
        translate([0, 0, base_thickness - 0.05])
            linear_extrude(height = gear_height + 0.1)
                difference() {
                    circle(r = gear_cavity_r);
                    internal_gear_2d(ring_teeth, clearance_xy);
                }
        
        // Bottom cavity for carrier base (CAPTIVE - smaller opening below)
        translate([0, 0, clearance_z])
            cylinder(r = carrier_cavity_r, h = base_thickness);
        
        // Top cavity for carrier top
        translate([0, 0, base_thickness + gear_height])
            cylinder(r = carrier_cavity_r, h = top_thickness);
        
        // Output opening
        translate([0, 0, base_thickness + gear_height + top_thickness - clearance_z * 2])
            cylinder(r = carrier_outer_r - 6 + clearance_xy, h = 15);
        
        // Sun shaft bearing (bottom)
        translate([0, 0, -0.1])
            cylinder(r = shaft_hole_r + 1, h = clearance_z + 0.2);
        
        // Carrier post channels
        for(i = [0:num_planets-1]) {
            angle = i * 360 / num_planets + 60;
            rotate([0, 0, angle])
                translate([carrier_outer_r - post_r - 2, 0, base_thickness - 0.1])
                    cylinder(r = post_r + clearance_xy, h = gear_height + 0.2);
        }
        
        // Retention lip opening at bottom center (sun can pass but carrier trapped)
        translate([0, 0, -0.1])
            cylinder(r = carrier_outer_r - post_r - 4, h = base_thickness + 0.2);
        
        // Vents
        for(i = [0:5]) {
            rotate([0, 0, i * 60 + 30])
                translate([ring_outer_r - 1.5, -1.5, base_thickness + 2])
                    cube([4, 3, gear_height - 4]);
        }
    }
}

// === ASSEMBLY ===
module assembly() {
    color("orange", 0.85) ring_housing();
    
    color("gold") translate([0, 0, base_thickness]) sun_gear();
    
    color("limegreen") translate([0, 0, base_thickness]) carrier();
    
    color("deepskyblue")
        for(i = [0:num_planets-1]) {
            angle = i * 360 / num_planets;
            rotate([0, 0, angle])
                translate([planet_orbit_r, 0, base_thickness + clearance_z])
                    planet_gear();
        }
}

// === CROSS SECTION ===
module cross_section() {
    difference() {
        assembly();
        translate([0, -100, -10]) cube([200, 200, 200]);
    }
}

// Full assembly
assembly();
