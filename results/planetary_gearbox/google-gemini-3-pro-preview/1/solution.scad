// Planetary Gearbox - Print-in-Place (Final Revised v2)
// Designed for PETG, 0.4mm nozzle, 0.2mm layer height
// Fixes Ring Base overlap issue.

/* [Dimensions] */
// Height of the gears (Active gear area)
gear_height = 10;
// Height of the base/carrier structure
base_height = 2;
// Module (Tooth size)
module_val = 1.0;
// Helix Angle (safe printability)
helix_angle = 35; 

// Teeth
t_sun = 15;
t_planet = 9;
t_ring = 33; 

// Tolerances
tol = 0.25; // Radial clearance
z_gap = 0.25; // Vertical clearance
z_lift = 0.2; // Extra lift for floating parts to aid bridging

/* [Rendering] */
$fn = 64;

// Derived
p_sun = t_sun * module_val / 2;
p_planet = t_planet * module_val / 2;
p_ring = t_ring * module_val / 2;
dist = p_sun + p_planet;

// Twist Math
function calc_twist(R, H) = (H * tan(helix_angle) * 180) / (PI * R);

twist_sun = calc_twist(p_sun, gear_height);
twist_planet = calc_twist(p_planet, gear_height); 
twist_ring = calc_twist(p_ring, gear_height);

// Global V-shape split position (Halfway up the gear stack)
split_pos = gear_height / 2;

module assembly() {
    
    // 1. SUN GEAR (Input)
    color("Gold")
    union() {
        // Base - Captive mechanism
        cylinder(r1=p_sun + module_val + 1, r2=p_sun + module_val, h=base_height); 
        
        // Gear
        translate([0,0,base_height])
        herringbone_gear_custom(t_sun, p_sun, gear_height, twist_sun, split_pos);
        
        // Cap/Handle
        translate([0,0,base_height + gear_height])
        difference() {
             cylinder(r=p_sun*0.8, h=4);
             cylinder(r=3.2, h=5, $fn=6); // Hex Key Hole
        }
    }

    // 2. RING GEAR (Output/Fixed)
    color("Silver")
    union() {
        // Base Rim (Anchors Ring to bed) - NOW HOLLOW
        difference() {
            cylinder(r=p_ring + 3, h=base_height);
            translate([0,0,-1]) cylinder(r=p_ring - module_val + tol*2, h=base_height+2);
        }
        
        // Gear Housing
        translate([0,0,base_height])
        difference() {
            cylinder(r=p_ring + 3, h=gear_height);
            // Internal Teeth
            herringbone_gear_custom(t_ring, p_ring, gear_height, twist_ring, split_pos, internal=true);
            
            // Knurling
            for(i=[0:15:359]) rotate([0,0,i]) translate([p_ring+3,0,0]) cylinder(r=0.7, h=gear_height+1, center=true);
        }
    }

    // 3. CARRIER (Fixed to Bed - Cage Style)
    color("Red")
    difference() {
        union() {
            // Base Disk
            cylinder(r=p_ring - module_val - tol, h=base_height); 
            // Pins
            for(i=[0:120:359]) rotate([0,0,i]) translate([dist,0,base_height]) {
                 cylinder(r=p_planet/2 - tol, h=gear_height - z_gap);
                 // Cap on pin (Captive top)
                 translate([0,0,gear_height - z_gap]) cylinder(r1=p_planet/2 - tol, r2=p_planet/2 + 1.2, h=1.5);
            }
        }
        // Hollow out center for Sun Base
        translate([0,0,-1]) cylinder(r=p_sun + module_val + tol, h=base_height+2);
        
        // Relief cuts for friction reduction
        translate([0,0,0.6]) difference() {
             cylinder(r=p_ring - 2, h=5);
             cylinder(r=p_sun + 2, h=5);
        }
    }

    // 4. PLANETS (Floating)
    color("Cyan")
    for(i=[0:120:359]) rotate([0,0,i]) translate([dist, 0, base_height + z_gap]) {
        // Phase Correction Logic
        rotate([0,0, (-twist_planet/gear_height) * z_gap ])
        difference() {
            herringbone_gear_custom(t_planet, p_planet, gear_height - 2*z_gap, -twist_planet, split_pos - z_gap);
            
            // Bore
            cylinder(r=p_planet/2 + tol*1.5, h=gear_height+2, center=true);
            
            // Chamfers
            // Top Cap Clearance
            translate([0,0, gear_height - 2*z_gap - 1.5]) cylinder(r1=p_planet/2+tol, r2=p_planet/2+tol+2.5, h=2);
            // Bottom printing chamfer (Overhang minimizer)
            difference() {
                cylinder(r=p_planet, h=0.8);
                cylinder(r=p_planet-1.5, h=1);
            }
        }
    }
}

// Custom Herringbone Module with Split Control
module herringbone_gear_custom(N, R, h, total_twist, split_z_local, internal=false) {
    rate = total_twist / h; 
    
    // Bottom Section
    translate([0,0,0])
    linear_extrude(height=split_z_local, twist=rate * split_z_local, slices=25)
    gear_2d_trap(N, R, internal);
    
    // Top Section
    top_h = h - split_z_local;
    translate([0,0,split_z_local])
    rotate([0,0, rate * split_z_local]) 
    linear_extrude(height=top_h, twist= -rate * top_h, slices=25) 
    gear_2d_trap(N, R, internal);
}

module gear_2d_trap(N, R, internal) {
    // Trapezoidal Gear Profile
    if (internal) {
        difference() {
            circle(r=R + 5);
            for(i=[0:N-1]) rotate([0,0,i*360/N]) translate([0,R,0]) 
                polygon([
                    [-1.6*module_val, -module_val], 
                    [-0.7*module_val, 1.25*module_val], 
                    [0.7*module_val, 1.25*module_val], 
                    [1.6*module_val, -module_val]
                ]);
            cylinder(r=R - module_val + tol/2, $fn=N*2);
        }
    } else {
        difference() {
            circle(r=R + module_val - tol/2);
            for(i=[0:N-1]) rotate([0,0,i*360/N + 180/N]) translate([0,R,0]) 
                polygon([
                    [-1.6*module_val, module_val*1.4], 
                    [-0.6*module_val, -module_val], 
                    [0.6*module_val, -module_val], 
                    [1.6*module_val, module_val*1.4]
                ]);
        }
    }
}

assembly();
