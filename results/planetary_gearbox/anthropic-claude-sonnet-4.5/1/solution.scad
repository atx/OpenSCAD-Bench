// Print-in-Place Planetary Gearbox
// Single stage with 3 planet gears orbiting a sun gear inside a ring gear
// Designed for PETG with 0.4mm nozzle, 0.1mm layer height
// Print orientation: Z-up (gear axis vertical)

$fn = 100;

// PRINT-IN-PLACE CLEARANCES (optimized for PETG)
clearance = 0.4;      // Horizontal clearance (1 perimeter width)
z_clearance = 0.3;    // Vertical clearance (3 layers)

// GEAR PARAMETERS
sun_teeth = 12;
planet_teeth = 15;
ring_teeth = sun_teeth + 2 * planet_teeth;  // = 42 (proper planetary ratio)
module_pitch = 2.0;   // Module in mm

// Calculated pitch diameters
sun_pitch_dia = sun_teeth * module_pitch;
planet_pitch_dia = planet_teeth * module_pitch;
ring_pitch_dia = ring_teeth * module_pitch;

// GEOMETRY
gear_thickness = 8;
base_height = 2.5;
num_planets = 3;
planet_orbit_radius = (sun_pitch_dia + planet_pitch_dia) / 2;  // = 27mm

// Ring housing
ring_inner_radius = ring_pitch_dia/2 + module_pitch * 1.4;  // ~44mm
ring_outer_radius = ring_inner_radius + 4;

// GEAR TOOTH PROFILE
// Simplified involute approximation for print-in-place gears
module involute_tooth(pitch_radius, addendum, dedendum, tooth_angle) {
    outer_radius = pitch_radius + addendum;
    root_radius = pitch_radius - dedendum;
    tooth_thickness = tooth_angle * 0.45;
    
    polygon([
        [root_radius * cos(-tooth_thickness), 
         root_radius * sin(-tooth_thickness)],
        [pitch_radius * cos(-tooth_thickness * 0.8), 
         pitch_radius * sin(-tooth_thickness * 0.8)],
        [outer_radius * cos(-tooth_thickness * 0.6), 
         outer_radius * sin(-tooth_thickness * 0.6)],
        [outer_radius * cos(tooth_thickness * 0.6), 
         outer_radius * sin(tooth_thickness * 0.6)],
        [pitch_radius * cos(tooth_thickness * 0.8), 
         pitch_radius * sin(tooth_thickness * 0.8)],
        [root_radius * cos(tooth_thickness), 
         root_radius * sin(tooth_thickness)]
    ]);
}

// EXTERNAL SPUR GEAR
module spur_gear(teeth, thickness, bore_dia, backlash=0) {
    pitch_radius = teeth * module_pitch / 2;
    addendum = module_pitch * 1.0;
    dedendum = module_pitch * 1.25;
    tooth_angle = 360 / teeth;
    
    difference() {
        union() {
            // Root cylinder
            cylinder(h=thickness, r=pitch_radius - dedendum + backlash/2, center=false);
            
            // Teeth array
            for (i = [0:teeth-1]) {
                rotate([0, 0, i * tooth_angle])
                linear_extrude(height=thickness, convexity=10, scale=0.95)
                involute_tooth(pitch_radius - backlash/2, 
                              addendum - backlash/2, 
                              dedendum - backlash/2, 
                              tooth_angle);
            }
        }
        
        // Center bore
        if (bore_dia > 0) {
            translate([0, 0, -0.1])
            cylinder(h=thickness+0.2, d=bore_dia, center=false);
        }
    }
}

// INTERNAL RING GEAR
module internal_ring_gear(teeth, thickness, backlash=0) {
    pitch_radius = teeth * module_pitch / 2;
    addendum = module_pitch * 1.0;
    dedendum = module_pitch * 1.25;
    tooth_angle = 360 / teeth;
    inner_radius = pitch_radius - addendum + backlash/2;
    outer_radius = pitch_radius + dedendum + 2;
    
    difference() {
        // Solid ring
        cylinder(h=thickness, r=outer_radius, center=false);
        
        // Cut out center and tooth spaces
        translate([0, 0, -0.1]) {
            union() {
                // Inner circle
                cylinder(h=thickness+0.2, r=inner_radius, center=false);
                
                // Tooth pockets
                for (i = [0:teeth-1]) {
                    rotate([0, 0, i * tooth_angle])
                    linear_extrude(height=thickness+0.2, convexity=10)
                    polygon([
                        [inner_radius * cos(-tooth_angle * 0.47), 
                         inner_radius * sin(-tooth_angle * 0.47)],
                        [pitch_radius * cos(-tooth_angle * 0.42), 
                         pitch_radius * sin(-tooth_angle * 0.42)],
                        [outer_radius * cos(-tooth_angle * 0.35), 
                         outer_radius * sin(-tooth_angle * 0.35)],
                        [outer_radius * cos(tooth_angle * 0.35), 
                         outer_radius * sin(tooth_angle * 0.35)],
                        [pitch_radius * cos(tooth_angle * 0.42), 
                         pitch_radius * sin(tooth_angle * 0.42)],
                        [inner_radius * cos(tooth_angle * 0.47), 
                         inner_radius * sin(tooth_angle * 0.47)]
                    ]);
                }
            }
        }
    }
}

// SUN GEAR (Input shaft - rotates freely)
module sun_gear() {
    sun_bore = 5;
    shaft_dia = sun_bore - clearance;
    shaft_height = 20;
    
    translate([0, 0, base_height + z_clearance]) {
        // Gear body
        spur_gear(sun_teeth, gear_thickness, sun_bore, clearance);
        
        // Input shaft extending upward
        translate([0, 0, gear_thickness])
        difference() {
            cylinder(h=shaft_height - gear_thickness, d=shaft_dia, center=false);
            
            // Hex socket for manual rotation/driving
            translate([0, 0, shaft_height - gear_thickness - 4])
            cylinder(h=4.1, d=3.2, $fn=6, center=false);
        }
    }
}

// PLANET GEAR (3x, rotate on pins)
module planet_gear() {
    planet_bore = 4 + clearance;
    spur_gear(planet_teeth, gear_thickness, planet_bore, clearance);
}

// PLANET CARRIER (Output - captures planet gears)
module planet_carrier() {
    pin_dia = 4 - clearance;
    pin_height = gear_thickness - z_clearance;
    carrier_thickness = 3;
    carrier_radius = planet_orbit_radius * 0.55;  // Stay clear of ring gear
    output_height = 10;
    arm_width = 4;
    
    translate([0, 0, base_height + z_clearance]) {
        // Planet pins (printed in place inside planet gears)
        for (i = [0:num_planets-1]) {
            rotate([0, 0, i * 360/num_planets])
            translate([planet_orbit_radius, 0, 0])
            cylinder(h=pin_height, d=pin_dia, center=false, $fn=40);
        }
        
        // Top carrier plate
        translate([0, 0, gear_thickness + z_clearance])
        difference() {
            union() {
                // Central hub
                cylinder(h=carrier_thickness, r=carrier_radius, center=false);
                
                // Three arms connecting to planet pins
                for (i = [0:num_planets-1]) {
                    rotate([0, 0, i * 360/num_planets])
                    hull() {
                        // Hub connection
                        translate([carrier_radius * 0.5, 0, 0])
                        cylinder(h=carrier_thickness, r=arm_width/2, center=false);
                        
                        // Planet pin connection
                        translate([planet_orbit_radius, 0, 0])
                        cylinder(h=carrier_thickness, d=pin_dia + 2, center=false);
                    }
                }
                
                // Output shaft
                translate([0, 0, carrier_thickness])
                cylinder(h=output_height, d=11, center=false);
            }
            
            // Sun shaft clearance hole through entire carrier
            translate([0, 0, -0.1])
            cylinder(h=carrier_thickness + output_height + 0.2, d=6.5, center=false);
            
            // Hex socket in output shaft
            translate([0, 0, carrier_thickness + output_height - 5])
            cylinder(h=5.1, d=4.5, $fn=6, center=false);
        }
    }
}

// RING GEAR ASSEMBLY (Fixed base and housing)
module ring_gear_assembly() {
    wall_thickness = 3;
    total_height = 25;
    
    // BASE PLATE
    difference() {
        union() {
            // Main base
            cylinder(h=base_height, r=ring_outer_radius, center=false);
            
            // Three support feet for better bed adhesion
            for (i = [0:2]) {
                rotate([0, 0, i * 120])
                translate([ring_outer_radius * 0.75, 0, 0])
                cylinder(h=base_height, d=7, center=false);
            }
        }
        
        // Central bearing for sun gear shaft
        translate([0, 0, -0.1])
        cylinder(h=base_height+0.2, d=6 + clearance, center=false);
    }
    
    // RING GEAR WITH INTERNAL TEETH
    translate([0, 0, base_height + z_clearance])
    difference() {
        internal_ring_gear(ring_teeth, gear_thickness, clearance);
        
        // Inspection windows to see meshing
        for (i = [0:2]) {
            rotate([0, 0, i * 120 + 60])
            translate([ring_outer_radius - 2, 0, -0.1])
            cylinder(h=gear_thickness+0.2, d=8, center=false);
        }
    }
    
    // OUTER HOUSING WALLS
    translate([0, 0, base_height + z_clearance]) {
        difference() {
            // Outer cylinder
            cylinder(h=total_height - base_height - z_clearance, 
                    r=ring_outer_radius, center=false);
            
            // Inner cavity
            translate([0, 0, -0.1])
            cylinder(h=total_height - base_height - z_clearance + 0.2, 
                    r=ring_outer_radius - wall_thickness, center=false);
            
            // Top opening for carrier output shaft (no overhang >45°)
            translate([0, 0, gear_thickness + z_clearance + 5])
            cylinder(h=total_height, 
                    r=ring_outer_radius - wall_thickness - 3, center=false);
            
            // Side viewing windows
            for (i = [0:2]) {
                rotate([0, 0, i * 120 + 60])
                translate([ring_outer_radius - 1.5, 0, gear_thickness + 2])
                cylinder(h=10, d=8, center=false);
            }
        }
    }
}

// COMPLETE ASSEMBLY
module complete_gearbox() {
    ring_gear_assembly();  // Fixed to print bed
    sun_gear();            // Rotates (input)
    
    // Three planet gears (rotate and orbit)
    for (i = [0:num_planets-1]) {
        rotate([0, 0, i * 360/num_planets])
        translate([planet_orbit_radius, 0, base_height + z_clearance])
        planet_gear();
    }
    
    planet_carrier();      // Rotates (output)
}

// RENDER
complete_gearbox();
