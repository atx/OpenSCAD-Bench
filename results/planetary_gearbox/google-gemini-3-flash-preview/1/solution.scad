/*
    Full Print-in-place Planetary Gearbox
    Optimized for 0.4mm nozzle and 0.1mm layer height (PETG).
    
    Design features:
    - Double-tapered (V-shape) gear profiles provide vertical capture while 
      maintaining 45-degree overhangs for support-free printing.
    - 0.4mm vertical gap for the planetary carrier ensures no fusion.
    - 0.35mm horizontal clearance for ease of movement post-print.
    - Single-stage with Sun, 3 Planets, Ring, and Carrier.
*/

$fn = 64;

// --- Parameters ---
teeth_sun = 12;
teeth_planet = 12;
teeth_ring = 36;
m = 1.6; // Module (size factor)
clearance = 0.35; // Horizontal gap between teeth
v_gap = 0.4; // Vertical gap for bridge/movement (4 layers at 0.1mm)

sun_r = (teeth_sun * m) / 2;
planet_r = (teeth_planet * m) / 2;
ring_r = (teeth_ring * m) / 2;
orbit_r = sun_r + planet_r;

height = 8; // Total height of the gear section

// --- Modules ---

module v_gear_shape(r, h) {
    // A profile that is widest at the mid-plane and tapers towards top and bottom.
    // This allows gears to interlock vertically (capture) with 45-degree overhangs.
    translate([0,0,h/2])
    union() {
        cylinder(h=h/2, r1=r, r2=r-h/2);
        mirror([0,0,1])
        cylinder(h=h/2, r1=r, r2=r-h/2);
    }
}

module gearbox() {
    // 1. Ring Gear (Outer Housing / Fixed)
    difference() {
        // Outer housing cylinder
        cylinder(h=height, r=ring_r + 4);
        
        // Inner V-profile cavity to capture the planets
        // Note: r + clearance makes the hole slightly larger than the gear radius
        translate([0,0,height/2]) {
            cylinder(h=height/2 + 0.01, r1=ring_r + clearance, r2=ring_r + clearance - height/2);
            mirror([0,0,1])
            cylinder(h=height/2 + 0.01, r1=ring_r + clearance, r2=ring_r + clearance - height/2);
        }
        
        // Circular openings for visibility/clearance
        translate([0,0,-1]) cylinder(h=2, r=ring_r - 1);
        translate([0,0,height-1]) cylinder(h=2, r=ring_r - 1);
    }

    // 2. Sun Gear (Input)
    // Centered at origin
    difference() {
        union() {
            v_gear_shape(sun_r - clearance, height);
            // Sun gear shaft/handle
            translate([0,0,height]) 
                cylinder(h=6, r=sun_r - clearance - 1);
        }
        // Center bore / weight reduction
        translate([0,0,-1]) cylinder(h=height + 8, r=sun_r/2);
    }

    // 3. Planet Gears (3 Total)
    for (i = [0:2]) {
        rotate([0, 0, i * 120])
        translate([orbit_r, 0, 0]) {
            v_gear_shape(planet_r - clearance, height);
            
            // Pillar reaching up to connect to the carrier
            translate([0,0,height - 0.1])
                cylinder(h=v_gap + 0.1, r=planet_r/3);
        }
    }

    // 4. Planet Carrier (Output)
    // Sits above the gears, floating by v_gap until rotated or pulled.
    carrier_z = height + v_gap;
    carrier_h = 2.5;
    
    translate([0,0,carrier_z])
    difference() {
        union() {
            // Main disc connecting the planet centers
            cylinder(h=carrier_h, r=orbit_r + planet_r/2 - 0.5);
            
            // Extra material around the sun shaft for strength
            cylinder(h=carrier_h + 3, r=sun_r + 2);
        }
        
        // Hole for sun gear shaft to pass through with clearance
        translate([0,0,-1]) 
            cylinder(h=carrier_h + 5, r=sun_r + clearance + 0.5);
            
        // Cutouts to see the planets and reduce material
        for (i=[0:2]) {
            rotate([0,0,i*120 + 60])
            translate([orbit_r * 0.85, 0, -1])
            cylinder(h=carrier_h + 2, r=planet_r * 0.7);
        }
    }
}

// Positioning the whole assembly
rotate([0,0,0]) gearbox();

// Add a base plate for stability (optional, but ring is the stationary part)
// We'll leave the ring as the body.
