// Print-in-place planetary gearbox
// Parameters tuned for 0.4mm nozzle, 0.1mm layers, PETG
// Axis vertical (Z-up)

$fn=100;

// Key parameters
m = 1.2;                // gear module (mm)
pa = 20;                // pressure angle (deg)
backlash = 0.12;        // linear backlash at pitch circle (mm)
clearance_radial = 0.3; // radial clearance between parts
clearance_axial = 0.25; // axial gap to top cap
gear_h = 6;             // gear face width (mm)
cap_t = 1.2;            // top cap thickness (mm)
ring_wall = 3;          // outer ring wall thickness (mm)

// Tooth counts
z_sun = 12;
z_planet = 18;
z_ring = 48; // should satisfy z_ring = z_sun + 2*z_planet

// Radii
rp_sun = m * z_sun / 2;
rp_planet = m * z_planet / 2;
rp_ring = m * z_ring / 2;

// Positions
planet_radius = rp_sun + rp_planet; // center distance sun-planet

function rot2d(p,a)= [p[0]*cos(a) - p[1]*sin(a), p[0]*sin(a) + p[1]*cos(a)];
function involute_point(rb,t) = [rb*(cos(t)+t*sin(t)), rb*(sin(t)-t*cos(t))];
function inv_fun(a) = tan(a) - a;

module gear2d(teeth, m=1, pa=20, backlash=0.1, internal=false){
    pa_rad = pa * PI/180;
    rp = m * teeth / 2;
    rb = rp * cos(pa_rad);
    ad = m;             // addendum
    dd = 1.25*m;        // dedendum
    half_thick = PI/(2*teeth) - backlash/(2*rp);
    psi = acos(rb/rp);
    alpha = half_thick + inv_fun(psi);
    ra = internal ? (rp - ad) : (rp + ad);
    rd = internal ? (rp + dd) : (rp - dd);
    tmax = sqrt((ra/rb)*(ra/rb) - 1);
    steps = 8;
    right = [for(i = [0:steps]) rot2d(involute_point(rb, (i/steps)*tmax), internal ? -alpha : alpha)];
    base_ang = atan2(right[0][1], right[0][0]);
    root_ang = base_ang;
    tip_ang = atan2(right[$-1][1], right[$-1][0]);
    left = [for(p = right) [p[0], -p[1]]];
    add_step = (-2*tip_ang)/6;
    add_arc = [for(a = [tip_ang:add_step:-tip_ang]) [ra*cos(a), ra*sin(a)]];
    root_step = (2*root_ang)/6;
    root_arc = [for(a = [-root_ang:root_step:root_ang]) [rd*cos(a), rd*sin(a)]];
    polygon(points=
        concat(
            concat(
                concat(
                    concat([[rd*cos(root_ang), rd*sin(root_ang)]], right),
                    add_arc),
                reverse(left)),
            root_arc)
    );
}

module spur_gear(teeth, m=1, pa=20, backlash=0.1, thickness=5, internal=false){
    linear_extrude(height=thickness)
        gear2d(teeth, m, pa, backlash, internal);
}

// Planet gear
module planet(){
    difference(){
        spur_gear(z_planet, m, pa, backlash, gear_h, internal=false);
        translate([0,0,-1]) cylinder(r=2.35, h=gear_h+2, $fn=60);
    }
}

// Sun gear with small knob
module sun(){
    union(){
        spur_gear(z_sun, m, pa, backlash, gear_h, internal=false);
        translate([0,0,gear_h]) cylinder(r=3, h=4, $fn=60);
    }
}

// Carrier with three pins and central ring hub
module carrier(){
    hub_r_inner = 4;
    hub_r_outer = 8;
    pin_r = 2;
    disk_r = rp_ring - (m + 1.5);
    difference(){
        union(){
            cylinder(r=disk_r, h=gear_h, $fn=100);
            translate([0,0,gear_h]) cylinder(r1=hub_r_outer, r2=hub_r_outer, h=3, $fn=80);
            for(i = [0:2]) rotate([0,0,i*120]) translate([planet_radius,0,0])
                cylinder(r=pin_r, h=gear_h+0.3, $fn=60);
        }
        translate([0,0,-1]) cylinder(r=hub_r_inner, h=gear_h+5, $fn=80);
    }
}

// Ring gear with internal teeth and top cap
module ring(){
    ra_outer = rp_ring + m + ring_wall;
    thickness_total = gear_h + clearance_axial + cap_t;
    difference(){
        cylinder(r=ra_outer, h=thickness_total, $fn=180);
        spur_gear(z_ring, m, pa, backlash, thickness_total, internal=true);
        translate([0,0,gear_h+clearance_axial]) cylinder(r=9, h=cap_t+1, $fn=80);
    }
    translate([0,0,gear_h+clearance_axial-0.4]) difference(){
        cylinder(r=ra_outer-0.4, h=0.4, $fn=180);
        cylinder(r=rp_ring+0.6, h=0.5, $fn=100);
    }
}

module assembly(){
    ring();
    sun();
    carrier();
    for(i = [0:2]) rotate([0,0,i*120]) translate([planet_radius,0,0]) planet();
}

assembly();
