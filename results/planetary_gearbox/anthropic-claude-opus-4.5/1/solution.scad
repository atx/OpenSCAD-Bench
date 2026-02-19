// Print-in-Place Planetary Gearbox
// Designed for PETG, 0.4mm nozzle, 0.1mm layer height
// All parts print captured but free to rotate immediately after printing

// === PRINT-IN-PLACE DESIGN NOTES ===
// - XY clearance: 0.4mm between all horizontally adjacent moving parts
// - Z clearance: 0.35mm vertical gaps for bridging layers
// - No overhangs exceed 45 degrees (self-supporting)
// - Gear teeth simplified for reliable FDM printing
// - Housing has viewing windows and grip grooves

// === PARAMETERS ===

// Clearances for print-in-place
clearance_xy = 0.4;        // Horizontal gap between moving parts
clearance_z = 0.35;        // Vertical gap for bridging

// Gear parameters
mod = 2.0;                 // Gear module
gear_height = 12;          // Height of gear teeth

// Tooth counts (ring = sun + 2*planet)
sun_teeth = 12;
planet_teeth = 9;
ring_teeth = 30;

num_planets = 3;

// Calculated geometry
sun_pitch_r = (mod * sun_teeth) / 2;
planet_pitch_r = (mod * planet_teeth) / 2;
ring_pitch_r = (mod * ring_teeth) / 2;

sun_outer_r = sun_pitch_r + mod;
planet_outer_r = planet_pitch_r + mod;
planet_root_r = planet_pitch_r - mod * 1.25;

orbit_r = sun_pitch_r + planet_pitch_r;

// Housing dimensions
ring_root_r = ring_pitch_r + mod * 1.25;
housing_wall = 4;
housing_outer_r = ring_root_r + housing_wall;

// Carrier dimensions
carrier_plate_thickness = 5;
carrier_outer_r = orbit_r + planet_outer_r + 2;
planet_pin_r = planet_root_r - clearance_xy - 1.5;

// Sun shaft
sun_shaft_r = 5;

// Vertical layout
base_thickness = 4;
z_lower_carrier = base_thickness;
z_gears = z_lower_carrier + carrier_plate_thickness + clearance_z;
z_upper_carrier = z_gears + gear_height + clearance_z;
z_top = z_upper_carrier + carrier_plate_thickness + base_thickness;
total_height = z_top;

$fn = 80;

// === GEAR MODULES ===

module external_tooth_2d(pitch_r, mod) {
    outer_r = pitch_r + mod;
    root_r = pitch_r - mod * 1.25;
    circular_pitch = mod * PI;
    tooth_thick = circular_pitch / 2 - 0.2;
    
    pitch_half_angle = asin((tooth_thick/2) / pitch_r);
    tip_half_angle = pitch_half_angle * 0.5;
    root_half_angle = pitch_half_angle * 1.3;
    
    polygon([
        [root_r * cos(root_half_angle), root_r * sin(root_half_angle)],
        [outer_r * cos(tip_half_angle), outer_r * sin(tip_half_angle)],
        [outer_r * cos(-tip_half_angle), outer_r * sin(-tip_half_angle)],
        [root_r * cos(-root_half_angle), root_r * sin(-root_half_angle)]
    ]);
}

module external_gear_2d(teeth, mod) {
    pitch_r = mod * teeth / 2;
    root_r = pitch_r - mod * 1.25;
    tooth_angle = 360 / teeth;
    
    union() {
        circle(r=root_r, $fn=teeth*6);
        for(i = [0:teeth-1]) {
            rotate([0, 0, i * tooth_angle])
            external_tooth_2d(pitch_r, mod);
        }
    }
}

module internal_tooth_space_2d(pitch_r, mod, clearance=0) {
    root_r = pitch_r + mod * 1.25;
    tip_r = pitch_r - mod;
    circular_pitch = mod * PI;
    space_width = circular_pitch / 2 + 0.2 + clearance;
    
    pitch_half_angle = asin((space_width/2) / pitch_r);
    tip_half_angle = pitch_half_angle * 1.4;
    root_half_angle = pitch_half_angle * 0.6;
    
    polygon([
        [root_r * cos(root_half_angle), root_r * sin(root_half_angle)],
        [(tip_r - clearance) * cos(tip_half_angle), (tip_r - clearance) * sin(tip_half_angle)],
        [(tip_r - clearance) * cos(-tip_half_angle), (tip_r - clearance) * sin(-tip_half_angle)],
        [root_r * cos(-root_half_angle), root_r * sin(-root_half_angle)]
    ]);
}

module internal_gear_cavity_2d(teeth, mod, clearance) {
    pitch_r = mod * teeth / 2;
    root_r = pitch_r + mod * 1.25;
    tooth_angle = 360 / teeth;
    
    union() {
        circle(r=root_r + clearance, $fn=teeth*6);
        for(i = [0:teeth-1]) {
            rotate([0, 0, i * tooth_angle])
            internal_tooth_space_2d(pitch_r, mod, clearance);
        }
    }
}

// === COMPONENTS ===

module sun_gear() {
    color("Gold") {
        translate([0, 0, z_gears])
        linear_extrude(height=gear_height, convexity=10)
        external_gear_2d(sun_teeth, mod);
        
        cylinder(r=sun_shaft_r, h=z_gears + 2, $fn=48);
        
        translate([0, 0, z_gears + gear_height - 2])
        cylinder(r=sun_shaft_r, h=total_height - z_gears - gear_height + 2 + 8, $fn=6);
    }
}

module planet_gear(angle) {
    bore_r = planet_pin_r + clearance_xy;
    
    color("Silver")
    rotate([0, 0, angle])
    translate([orbit_r, 0, z_gears])
    difference() {
        linear_extrude(height=gear_height, convexity=10)
        external_gear_2d(planet_teeth, mod);
        
        translate([0, 0, -0.1])
        cylinder(r=bore_r, h=gear_height + 0.2, $fn=48);
    }
}

module carrier() {
    sun_clearance_r = sun_outer_r + clearance_xy + 1;
    pin_height = carrier_plate_thickness * 2 + clearance_z * 2 + gear_height;
    
    color("SteelBlue") {
        difference() {
            union() {
                translate([0, 0, z_lower_carrier])
                cylinder(r=carrier_outer_r, h=carrier_plate_thickness, $fn=90);
                
                translate([0, 0, z_upper_carrier])
                cylinder(r=carrier_outer_r, h=carrier_plate_thickness, $fn=90);
                
                for(i = [0:num_planets-1]) {
                    rotate([0, 0, i * 360/num_planets])
                    translate([orbit_r, 0, z_lower_carrier])
                    cylinder(r=planet_pin_r, h=pin_height, $fn=48);
                }
            }
            
            translate([0, 0, z_lower_carrier - 0.1])
            cylinder(r=sun_clearance_r, h=pin_height + 0.2, $fn=60);
            
            for(i = [0:num_planets-1]) {
                rotate([0, 0, i * 360/num_planets + 60])
                translate([orbit_r * 0.55, 0, z_lower_carrier - 0.1])
                cylinder(r=4.5, h=carrier_plate_thickness + 0.2, $fn=30);
                
                rotate([0, 0, i * 360/num_planets + 60])
                translate([orbit_r * 0.55, 0, z_upper_carrier - 0.1])
                cylinder(r=4.5, h=carrier_plate_thickness + 0.2, $fn=30);
            }
        }
    }
}

module ring_housing() {
    carrier_cavity_r = carrier_outer_r + clearance_xy;
    shaft_hole_r = sun_shaft_r + clearance_xy + 0.5;
    
    color("ForestGreen", 0.92) {
        difference() {
            cylinder(r=housing_outer_r, h=total_height, $fn=120);
            
            translate([0, 0, z_gears - 0.05])
            linear_extrude(height=gear_height + 0.1, convexity=10)
            internal_gear_cavity_2d(ring_teeth, mod, clearance_xy);
            
            translate([0, 0, z_lower_carrier - 0.1])
            cylinder(r=carrier_cavity_r, h=carrier_plate_thickness + clearance_z + 0.15, $fn=90);
            
            translate([0, 0, z_upper_carrier - clearance_z - 0.1])
            cylinder(r=carrier_cavity_r, h=carrier_plate_thickness + base_thickness + clearance_z + 0.2, $fn=90);
            
            translate([0, 0, -0.1])
            cylinder(r=shaft_hole_r, h=base_thickness + 0.2, $fn=48);
            
            translate([0, 0, total_height - base_thickness - 0.1])
            cylinder(r=shaft_hole_r + 0.5, h=base_thickness + 0.2, $fn=6);
            
            for(i = [0:2]) {
                rotate([0, 0, i * 120 + 60])
                translate([housing_outer_r - housing_wall/2 - 0.5, 0, z_gears + gear_height/2])
                rotate([0, 90, 0])
                cylinder(r=4.5, h=housing_wall + 2, center=true, $fn=32);
            }
            
            for(i = [0:11]) {
                rotate([0, 0, i * 30])
                translate([housing_outer_r - 0.8, 0, -0.1])
                cylinder(r=1, h=total_height + 0.2, $fn=16);
            }
        }
    }
}

// === ASSEMBLY ===

module planetary_gearbox() {
    ring_housing();
    sun_gear();
    carrier();
    for(i = [0:num_planets-1]) {
        planet_gear(i * 360/num_planets);
    }
}

// Render complete assembly
planetary_gearbox();

// Print information
echo("═══════════════════════════════════════════════════════");
echo("  PRINT-IN-PLACE PLANETARY GEARBOX");
echo("═══════════════════════════════════════════════════════");
echo(str("  Diameter: ", housing_outer_r * 2, " mm"));
echo(str("  Height: ", total_height, " mm (+8mm shaft extension)"));
echo(str("  Gear Ratio: ", 1 + ring_teeth/sun_teeth, ":1"));
echo("───────────────────────────────────────────────────────");
echo(str("  XY Clearance: ", clearance_xy, " mm"));
echo(str("  Z Clearance: ", clearance_z, " mm"));
echo("───────────────────────────────────────────────────────");
echo("  Print: PETG, 0.4mm nozzle, 0.1mm layer, Z-up");
echo("═══════════════════════════════════════════════════════");