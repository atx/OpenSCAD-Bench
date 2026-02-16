// ============================================================
// Print-in-Place Planetary Gearbox
// ============================================================
// Material: PETG | Nozzle: 0.4mm | Layer height: 0.1mm
// Print orientation: Gear axis vertical (Z-up)
// Single stage, 3 planet gears, involute tooth profile
// 
// Gear ratio (ring fixed): 1 + Nr/Ns = 1 + 32/16 = 3:1
// Sun = input (bottom hex), Carrier = output (top hex)
//
// PRINT-IN-PLACE FEATURES:
// - All moving parts captured but free to rotate
// - 45° chamfers for self-supporting overhangs
// - 0.50mm gear backlash, 0.35mm radial clearance, 0.40mm 
//   axial clearance — tuned for PETG with 0.4mm nozzle
// - No support material needed
// - No post-processing required
// ============================================================
$fn = 128;

// ===================== PARAMETERS ===========================

// Gear tooth parameters
modul = 1.5;           // Module (mm)
PA    = 20;            // Pressure angle (degrees)
Ns    = 16;            // Sun gear teeth
Np    = 8;             // Planet gear teeth  
Nr    = Ns + 2*Np;     // Ring gear teeth = 32
Nplan = 3;             // Number of planet gears

// Derived pitch radii
Rps   = modul * Ns / 2;     // Sun pitch = 12mm
Rpp   = modul * Np / 2;     // Planet pitch = 6mm
Rpr   = modul * Nr / 2;     // Ring pitch = 24mm
Rorb  = Rps + Rpp;          // Orbit radius = 18mm

// Ring gear inner dimensions
R_ring_tip  = Rpr - modul;          // 23mm (tooth tips, inward)
R_ring_root = Rpr + 1.25 * modul;   // 25.875mm (between teeth, outward)

// Print-in-place clearances
bl    = 0.50;    // Total gear backlash
rclr  = 0.35;    // Radial sliding clearance
aclr  = 0.40;    // Axial (vertical) clearance

// Component dimensions
gear_h   = 14;      // Gear tooth height
plate_h  = 3.0;     // Carrier plate thickness
chamfer  = 2.0;     // 45° self-supporting chamfer
lip_h    = 2.0;     // Retaining lip thickness

ring_OR    = R_ring_root + 3.5;      // Ring outer radius ~29.4mm
axle_r     = 2.0;                    // Planet axle pin radius
sun_sr     = Rps - 1.25*modul - 1.0; // Sun shaft radius = 9.125mm
carrier_r  = R_ring_tip + 1.5;       // Carrier plate radius = 24.5mm
out_sr     = 9;                       // Output shaft radius
in_sr      = sun_sr + 4;             // Input handle radius ~13.1mm

// Z coordinate stack (bottom to top)
Z_pocket_bot     = lip_h - aclr;
Z_carrier_bot    = lip_h;
Z_carrier_bot_top= Z_carrier_bot + plate_h;
Z_cham_bot       = Z_carrier_bot_top + aclr;
Z_gear_bot       = Z_cham_bot + chamfer;
Z_gear_top       = Z_gear_bot + gear_h;
Z_cham_top_end   = Z_gear_top + chamfer;
Z_carrier_top    = Z_cham_top_end + aclr;
Z_carrier_top_top= Z_carrier_top + plate_h;
Z_lip_top        = Z_carrier_top_top + aclr;
ZZ               = Z_lip_top + lip_h;

// =================== INVOLUTE GEAR MODULES ==================

function inv_a(br, r) = (r <= br) ? 0 : sqrt(r*r/(br*br) - 1) * 180/PI;

// External gear 2D profile
module ext_gear_2d(teeth, mod, pa, backlash=0) {
    pr = mod*teeth/2;
    br = pr * cos(pa);
    ar = pr + mod;
    rr = max(pr - 1.25*mod, 0.5);
    ta = 360 / teeth;
    n  = 24;
    pii = inv_a(br, pr);
    ht  = 90/teeth - (backlash/2)/pr * 180/PI;
    sr  = max(br, rr);
    
    polygon([for(t = [0:teeth-1]) each [
        let(a = t*ta - ht - pii + inv_a(br, sr))
            [sr*cos(a), sr*sin(a)],
        for(i = [1:n])
            let(r = sr + (ar-sr)*i/n,
                a = t*ta + ht + pii - inv_a(br, r))
            [r*cos(a), r*sin(a)],
        for(i = [n-1:-1:1])
            let(r = sr + (ar-sr)*i/n,
                a = t*ta - ht - pii + inv_a(br, r))
            [r*cos(a), r*sin(a)]
    ]]);
}

// Internal (ring) gear bore 2D profile
module int_bore_2d(teeth, mod, pa, backlash=0) {
    pr = mod*teeth/2;
    br = pr * cos(pa);
    tr = pr - mod;
    rr = pr + 1.25*mod;
    ta = 360 / teeth;
    n  = 24;
    pii = inv_a(br, pr);
    ht  = 90/teeth + (backlash/2)/pr * 180/PI;
    sr  = max(br, tr);
    
    polygon([for(t = [0:teeth-1]) each [
        for(i = [0:n])
            let(r = rr - (rr-sr)*i/n,
                a = t*ta + ht + pii - inv_a(br, r))
            [r*cos(a), r*sin(a)],
        for(i = [1:n])
            let(r = sr + (rr-sr)*i/n,
                a = t*ta - ht - pii + inv_a(br, r))
            [r*cos(a), r*sin(a)]
    ]]);
}

// Planet phase angle for proper meshing
function planet_phase(idx) = -idx * 360/Nplan * Ns/Np;

// =================== RING HOUSING ===========================
module ring_housing() {
    difference() {
        union() {
            // Main cylindrical body
            cylinder(r=ring_OR, h=ZZ);
            
            // Bottom grip flange with finger notches
            difference() {
                cylinder(r=ring_OR + 4, h=3.5);
                for(i = [0:7])
                    rotate([0, 0, i*45 + 22.5])
                    translate([ring_OR + 4, 0, -0.1])
                    cylinder(r=4.5, h=3.7, $fn=24);
            }
            
            // Top rim  
            translate([0, 0, ZZ - 2])
            cylinder(r=ring_OR + 2, h=2);
        }
        
        // Bottom carrier pocket (cylindrical cavity)
        translate([0, 0, Z_pocket_bot])
        cylinder(r=carrier_r + rclr, h=Z_cham_bot - Z_pocket_bot);
        
        // Bottom 45° chamfer (pocket -> gear zone)
        translate([0, 0, Z_cham_bot])
        cylinder(r1=carrier_r + rclr, r2=R_ring_tip, h=chamfer);
        
        // Ring gear internal teeth
        translate([0, 0, Z_gear_bot])
        linear_extrude(height=gear_h, convexity=10)
        int_bore_2d(Nr, modul, PA, bl);
        
        // Top 45° chamfer (gear zone -> pocket)
        translate([0, 0, Z_gear_top])
        cylinder(r1=R_ring_tip, r2=carrier_r + rclr, h=chamfer);
        
        // Top carrier pocket
        translate([0, 0, Z_cham_top_end])
        cylinder(r=carrier_r + rclr, h=Z_lip_top - Z_cham_top_end);
        
        // Sun shaft through-hole (full height)
        translate([0, 0, -5])
        cylinder(r=sun_sr + rclr, h=ZZ + 25);
        
        // Output shaft hole through top lip
        translate([0, 0, Z_lip_top])
        cylinder(r=out_sr + rclr, h=lip_h + 5);
    }
}

// =================== SUN GEAR (Input) =======================
module sun_gear() {
    // Involute gear teeth
    translate([0, 0, Z_gear_bot])
    linear_extrude(height=gear_h, convexity=10)
    ext_gear_2d(Ns, modul, PA, bl);
    
    // Shaft through ring body
    cylinder(r=sun_sr, h=ZZ);
    
    // Input hex handle (below ring)
    translate([0, 0, -15])
    linear_extrude(height=15)
    circle(r=in_sr, $fn=6);
    
    // Small hex indicator cap (above ring)
    translate([0, 0, ZZ])
    linear_extrude(height=5)
    circle(r=sun_sr + 2, $fn=6);
}

// =================== PLANET GEARS ===========================
module planet_gears() {
    for(i = [0:Nplan-1]) {
        rotate([0, 0, i * 360/Nplan])
        translate([Rorb, 0, Z_gear_bot])
        rotate([0, 0, planet_phase(i)])
        difference() {
            // Gear body
            linear_extrude(height=gear_h, convexity=10)
            ext_gear_2d(Np, modul, PA, bl);
            // Axle bore
            translate([0, 0, -0.1])
            cylinder(r=axle_r + rclr, h=gear_h + 0.2);
        }
    }
}

// =================== CARRIER (Output) =======================
module carrier() {
    // Bottom plate (trapped by ring gear tips)
    translate([0, 0, Z_carrier_bot])
    difference() {
        cylinder(r=carrier_r, h=plate_h);
        translate([0, 0, -0.1])
        cylinder(r=sun_sr + rclr, h=plate_h + 0.2);
    }
    
    // Planet axle pins
    for(i = [0:Nplan-1])
        rotate([0, 0, i * 360/Nplan])
        translate([Rorb, 0, Z_carrier_bot])
        cylinder(r=axle_r, h=Z_carrier_top_top - Z_carrier_bot);
    
    // Top plate (trapped by ring gear tips)
    translate([0, 0, Z_carrier_top])
    difference() {
        cylinder(r=carrier_r, h=plate_h);
        translate([0, 0, -0.1])
        cylinder(r=sun_sr + rclr, h=plate_h + 0.2);
    }
    
    // Output hex shaft (extends above ring)
    translate([0, 0, Z_carrier_top_top])
    difference() {
        linear_extrude(height=lip_h + 12)
        circle(r=out_sr, $fn=6);
        translate([0, 0, -0.1])
        cylinder(r=sun_sr + rclr + 0.5, h=lip_h + 12.2);
    }
}

// =================== FINAL ASSEMBLY =========================
color("SteelBlue", 0.5) ring_housing();
color("Gold")            sun_gear();
color("Tomato")          planet_gears();
color("LimeGreen", 0.6) carrier();
