$fn=120;

function default_norm(v) = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);

module rod_between(p1, p2, r) {
    v = [p2[0] - p1[0], p2[1] - p1[1], p2[2] - p1[2]];
    len = default_norm(v);
    if (len > 0) {
        axis = cross([0,0,1], v);
        axis_norm = default_norm(axis);
        angle = acos(v[2]/len) * 180 / PI;
        if (axis_norm < 1e-6) {
            translate(p1)
                cylinder(h=len, r=r, center=false);
        } else {
            translate(p1)
                rotate(a=angle, v=axis)
                    cylinder(h=len, r=r, center=false);
        }
    }
}

module base_plate() {
    union() {
        cylinder(h=5, r=20);
        translate([0,0,5]) cylinder(h=3, r=15);
    }
}

module gusset() {
    hull() {
        translate([0,0,5]) cylinder(h=5, r=15);
        translate([0,18,7]) rotate([80,0,0]) cylinder(h=22, r=4.5);
    }
}

module hook_arm() {
    pts = [
        [0,0,5],
        [0,24,10],
        [0,32,15],
        [0,40,20]
    ];
    radii = [4.7, 4.2, 3.8];
    union() {
        for (i = [0 : len(radii) - 1]) {
            rod_between(pts[i], pts[i + 1], radii[i]);
        }
        for (p = pts) {
            translate(p) sphere(r=4.2);
        }
    }
}

module countersink() {
    translate([0,0,0]) cylinder(h=8, r=1.6, center=false);
    translate([0,0,5]) cylinder(h=5, r1=4.5, r2=1.6, center=false);
}


difference() {
    union() {
        base_plate();
        gusset();
        hook_arm();
    }
    countersink();
}
