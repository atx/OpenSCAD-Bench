// Print-in-place single-stage planetary gearbox (PETG, 0.4 nozzle, 0.1mm layer)
// Axis vertical (Z-up). Designed for supportless printing (<=45° overhangs).
// All moving parts are captive with built-in clearances.
// Units: mm

$fn = 140;

// ---------------------- Parameters ----------------------
// Gear set
m = 1.2;                    // module
pressure_angle = 20;        // degrees
z_sun = 12;
z_planet = 12;
z_ring = z_sun + 2*z_planet; // planetary constraint
planets = 3;

gear_h = 8;

// Print-in-place clearances (PETG)
clear_xy = 0.35;            // radial clearance for bearings/bores
clear_z  = 0.30;            // axial clearance between stacked parts
backlash = 0.30;            // tooth backlash (mm) for free-running gears

// Housing / carrier
bottom_thick  = 2.0;
carrier_thick = 2.4;

// Top retainers (self-supporting)
lip_h     = 2.6;            // vertical height of top constriction region
lip_inset = 2.6;            // radial inset (lip_inset ~= lip_h gives ~45°)

// Shafts / pins
post_r = 3.0;               // fixed center post radius
pin_r  = 2.2;               // planet pin shaft radius
head_h = 2.0;               // pin head (cone) height => 45° when dr=head_h

// Wall thickness
wall = 3.0;

// ---------------------- Helper math (radians) ----------------------
function deg(a) = a*180/PI;
function cosr(a) = cos(deg(a));
function sinr(a) = sin(deg(a));
function atanr(x) = atan(x)*PI/180;
function atan2r(y,x) = atan2(y,x)*PI/180;

function rot2(p, a) = [ p[0]*cosr(a) - p[1]*sinr(a), p[0]*sinr(a) + p[1]*cosr(a) ];

function involute_t(rb, r) = (r <= rb) ? 0 : sqrt((r*r)/(rb*rb) - 1);
function involute_theta(t) = t - atanr(t); // radians
function involute_xy(rb, r) = let(t=involute_t(rb,r), th=involute_theta(t)) [ r*cosr(th), r*sinr(th) ];

function arc_points(r, a0, a1, n) = [
    for (i=[0:n])
        let(a = a0 + (a1-a0)*i/n)
        [ r*cosr(a), r*sinr(a) ]
];

// ---------------------- Involute gear 2D (external) ----------------------
// A practical involute approximation suitable for FDM.
module gear2d_external(teeth, module_size, pa_deg=20,
                       addendum=undef, dedendum=undef,
                       backlash_mm=0.0,
                       inv_steps=10, arc_steps=7) {
    rp = module_size*teeth/2;

    add = (addendum == undef) ? module_size : addendum;
    ded = (dedendum == undef) ? 1.25*module_size : dedendum;

    rb = rp*cos(pa_deg);      // base radius
    ra = rp + add;            // outer radius
    rf = max(0.25, rp - ded); // root radius

    // tooth thickness at pitch circle
    tooth_thickness = PI*module_size/2 - backlash_mm;
    half_ang = tooth_thickness/(2*rp); // radians

    // involute polar angle at pitch
    tp = involute_t(rb, rp);
    thp = involute_theta(tp);

    rot = half_ang - thp;     // radians

    start_r = max(rb, rf);

    base_pts = [
        for (i=[0:inv_steps])
            let(r = start_r + (ra-start_r)*i/inv_steps)
                involute_xy(rb, r)
    ];

    right_pts = [ for (p=base_pts) rot2(p, +rot) ];
    left_pts  = [ for (p=base_pts) rot2([p[0], -p[1]], -rot) ];

    a_root_r = +rot;
    a_root_l = -rot;

    pr = right_pts[len(right_pts)-1];
    pl = left_pts[len(left_pts)-1];
    a_outer_r = atan2r(pr[1], pr[0]);
    a_outer_l = atan2r(pl[1], pl[0]);

    tooth_poly = concat(
        (rf < start_r) ? [[ rf*cosr(a_root_r), rf*sinr(a_root_r) ], [ start_r*cosr(a_root_r), start_r*sinr(a_root_r) ]] : [[ rf*cosr(a_root_r), rf*sinr(a_root_r) ]],
        right_pts,
        arc_points(ra, a_outer_r, a_outer_l, arc_steps),
        [ for (i=[len(left_pts)-1:-1:0]) left_pts[i] ],
        (rf < start_r) ? [[ start_r*cosr(a_root_l), start_r*sinr(a_root_l) ], [ rf*cosr(a_root_l), rf*sinr(a_root_l) ]] : [],
        arc_points(rf, a_root_l, a_root_r, arc_steps)
    );

    union() {
        for (i=[0:teeth-1])
            rotate(i*360/teeth)
                polygon(points=tooth_poly);
        circle(r=rf);
    }
}

// ---------------------- 3D gear ----------------------
module gear_external_3d(teeth, bore_r, z0, h,
                        module_size=m, pa_deg=pressure_angle,
                        backlash_mm=backlash) {
    translate([0,0,z0])
    difference() {
        linear_extrude(height=h)
            gear2d_external(teeth, module_size, pa_deg=pa_deg, backlash_mm=backlash_mm);
        translate([0,0,-0.25]) cylinder(h=h+0.5, r=bore_r);
    }
}

// ---------------------- Assembly Z layout ----------------------
z_carrier   = bottom_thick + clear_z;
z_gears     = z_carrier + carrier_thick + clear_z;
z_gear_top  = z_gears + gear_h;
z_lip_start = z_gear_top + clear_z;
z_total     = z_lip_start + lip_h;

// ---------------------- Parts ----------------------
module sun_gear() {
    gear_external_3d(z_sun, bore_r=post_r+clear_xy, z0=z_gears, h=gear_h);
}

module planet_gear(pos) {
    translate([pos[0], pos[1], 0])
        gear_external_3d(z_planet, bore_r=pin_r+clear_xy, z0=z_gears, h=gear_h);
}

module carrier() {
    rp_s = m*z_sun/2;
    rp_p = m*z_planet/2;
    center_dist = rp_s + rp_p;

    rp_ring = m*z_ring/2;
    r_ring_tip = rp_ring - m; // approx internal ring tooth tip radius

    carrier_r = r_ring_tip - 1.2;

    z_disc = z_carrier;
    z_disc_top = z_disc + carrier_thick;

    z_pin0 = z_disc_top;
    pin_shaft_h = (z_gear_top - z_pin0) + clear_z;

    union() {
        // Disc (bearing hole around fixed post) with large cutouts to reduce friction/contact area.
        translate([0,0,z_disc])
        difference() {
            cylinder(h=carrier_thick, r=carrier_r);

            // center bearing hole
            translate([0,0,-0.25]) cylinder(h=carrier_thick+0.5, r=post_r+clear_xy);

            // 3 large cutouts between planet pins
            cut_r = carrier_r*0.28;
            cut_center_r = carrier_r*0.52;
            for (i=[0:planets-1]) {
                ang = (i*360/planets) + 60; // between pins
                translate([cut_center_r*cos(ang), cut_center_r*sin(ang), -0.25])
                    cylinder(h=carrier_thick+0.5, r=cut_r);
            }
        }

        // Pins + 45° conical heads (capture planets)
        for (i=[0:planets-1]) {
            ang = i*360/planets;
            x = center_dist*cos(ang);
            y = center_dist*sin(ang);

            translate([x,y,z_pin0]) cylinder(h=pin_shaft_h, r=pin_r);

            // head begins above planet top by clear_z
            translate([x,y,z_gear_top + clear_z])
                cylinder(h=head_h, r1=pin_r, r2=pin_r+head_h);
        }

        // Grip rim on top of carrier (still below gears)
        translate([0,0,z_disc_top])
        difference() {
            cylinder(h=1.2, r=carrier_r);
            cylinder(h=1.2, r=carrier_r-1.0);
        }
    }
}

module housing_shell() {
    rp_ring = m*z_ring/2;

    add_int = m;
    ded_int = 1.25*m;

    r_hole_max = rp_ring + ded_int; // largest radius in tooth roots
    r_outer = r_hole_max + wall;

    // Cavity radius only slightly larger than tooth-root radius to avoid ledges
    r_cavity = r_hole_max + 0.15;

    difference() {
        // Outer body
        union() {
            cylinder(h=bottom_thick, r=r_outer);
            translate([0,0,bottom_thick]) cylinder(h=z_total-bottom_thick, r=r_outer);
        }

        // Lower smooth cavity (annulus; keep a solid region for the post)
        translate([0,0,bottom_thick])
        difference() {
            cylinder(h=z_gears-bottom_thick, r=r_cavity);
            cylinder(h=z_gears-bottom_thick, r=post_r+0.01);
        }

        // Gear tooth region cavity (internal ring gear via gear-shaped hole)
        translate([0,0,z_gears])
        linear_extrude(height=gear_h)
            gear2d_external(
                teeth=z_ring,
                module_size=m,
                pa_deg=pressure_angle,
                // swapped add/ded to form internal gear hole
                addendum=ded_int,
                dedendum=add_int,
                backlash_mm=backlash+0.15
            );

        // Upper cavity above gears up to start of lip (annulus; keep post)
        translate([0,0,z_gear_top])
        difference() {
            cylinder(h=z_lip_start-z_gear_top, r=r_cavity);
            cylinder(h=z_lip_start-z_gear_top, r=post_r+0.01);
        }

        // Top constriction (conical cavity to retain planets/carrier)
        translate([0,0,z_lip_start])
        difference() {
            cylinder(h=lip_h+0.02, r1=r_cavity, r2=r_cavity-lip_inset);
            cylinder(h=lip_h+0.02, r=post_r+0.01);
        }

        // Anti-elephant-foot chamfer on inner bottom edge
        translate([0,0,bottom_thick-0.01])
            cylinder(h=0.9, r1=r_cavity+0.8, r2=r_cavity);
    }
}

module housing_post_and_cap() {
    // Fixed center post plus 45° conical cap (captures sun+carrier).
    union() {
        cylinder(h=z_lip_start, r=post_r);
        translate([0,0,z_lip_start])
            cylinder(h=lip_h, r1=post_r, r2=post_r+lip_h);
    }
}

module housing() {
    union() {
        housing_shell();
        housing_post_and_cap();
    }
}

// ---------------------- Assembly ----------------------
module planetary_gearbox() {
    rp_s = m*z_sun/2;
    rp_p = m*z_planet/2;
    center_dist = rp_s + rp_p;

    planet_pos = [ for (i=[0:planets-1]) [ center_dist*cos(i*360/planets), center_dist*sin(i*360/planets) ] ];

    union() {
        housing();
        carrier();
        sun_gear();
        for (p=planet_pos) planet_gear(p);
    }
}

planetary_gearbox();
