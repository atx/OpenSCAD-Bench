// 3D Printer Torture Test Model
// Single-piece compact calibration/torture test
// Units: mm

$fn = 72;

// ---------- Parameters ----------
base_size = [160, 100];
base_t = 4;
base_corner_r = 6;

labels_on = true;
label_h = 0.8;
label_z = base_t + 0.2;

// ---------- Helpers ----------
module rounded_plate(size=[100,80], t=4, r=4){
    linear_extrude(height=t)
        offset(r=r)
            square([size[0]-2*r, size[1]-2*r], center=true);
}

module label3d(s, pos=[0,0,0], size=4, rot=0){
    if(labels_on)
        translate(pos)
            rotate([0,0,rot])
                linear_extrude(height=label_h)
                    text(s, size=size, font="Liberation Sans:style=Bold", halign="center", valign="center");
}

function sum_upto(v, i) = (i < 0) ? 0 : v[i] + sum_upto(v, i-1);

// ---------- Features ----------
module hole_grid(origin=[-50, 15], pitch=[12, 14]){
    // 10 holes: diameters 1..10
    for(r=[0:1])
        for(c=[0:4]){
            d = r*5 + c + 1;
            x = origin[0] + c*pitch[0];
            y = origin[1] + r*pitch[1];
            translate([x,y,-1]) cylinder(d=d, h=base_t+2);
        }
}

module pin_grid(origin=[-50, -22], pitch=[12, 14]){
    // 10 pins: diameters 1..10, heights 1..5mm repeating
    for(r=[0:1])
        for(c=[0:4]){
            d = r*5 + c + 1;
            h = (d-1)%5 + 1;
            x = origin[0] + c*pitch[0];
            y = origin[1] + r*pitch[1];
            translate([x,y,base_t]) cylinder(d=d, h=h);
        }
}

module thin_walls(origin=[30, -5]){
    // walls thicknesses from 0.2..2mm
    ts = [0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.2, 1.5, 2.0];
    wall_len = 34;
    wall_h = 22;
    gap = 3.2;

    x0 = origin[0];
    y0 = origin[1];

    for(i=[0:len(ts)-1]){
        t = ts[i];
        translate([x0 + i*gap, y0, base_t])
            cube([t, wall_len, wall_h]);
    }
}

module bridge_ladder(y0=-43){
    // Compact bridge test: a single roof spanning multiple gaps.
    // Gap lengths include 5mm and up to 50mm.
    gaps = [5, 10, 20, 30, 50];

    support_t = 3;
    depth = 18;
    h = 14;
    roof_t = 1.2;

    n = len(gaps);
    support_count = n + 1;

    total_len = support_count*support_t + sum_upto(gaps, n-1);
    x0 = -total_len/2;

    for(i=[0:support_count-1]){
        xi = x0 + i*support_t + sum_upto(gaps, i-1);
        translate([xi, y0, base_t]) cube([support_t, depth, h]);
    }

    translate([x0, y0, base_t + h]) cube([total_len, depth, roof_t]);
}

module overhang_row(y0=35){
    // Overhang angles measured from vertical: 10..70 deg
    angles = [10,20,30,40,50,60,70];

    depth = 10;
    pillar_w = 4;
    H = 12;
    clearance = 0.6;
    spacing = 2;

    Ls = [ for(a=angles) (H - clearance) * tan(a) ];
    widths = [ for(i=[0:len(angles)-1]) pillar_w + Ls[i] + spacing ];
    total_w = sum_upto(widths, len(widths)-1) - spacing; // remove last trailing spacing
    x_start = -total_w/2;

    for(i=[0:len(angles)-1]){
        xi = x_start + sum_upto(widths, i-1);
        L = Ls[i];

        translate([xi, y0, base_t]) cube([pillar_w, depth, H]);

        // triangular prism wedge; angled face is the overhang surface
        translate([xi + pillar_w, y0, base_t])
            polyhedron(
                points=[
                    [0,0,clearance],
                    [0,0,H],
                    [L,0,clearance],
                    [0,depth,clearance],
                    [0,depth,H],
                    [L,depth,clearance]
                ],
                faces=[
                    [0,2,1],
                    [3,4,5],
                    [0,1,4,3],
                    [0,3,5,2],
                    [1,2,5,4]
                ]
            );
    }
}

module group_labels(){
    label3d("HOLES D1-10", pos=[-45, 34, label_z], size=5);
    label3d("PINS D1-10",  pos=[-45, -34, label_z], size=5);

    label3d("THIN WALLS 0.2-2.0", pos=[55, 33, label_z], size=5);
    label3d("BRIDGES 5-50", pos=[0, -49, label_z], size=5);
    label3d("OVERHANG 10-70 deg", pos=[30, 46, label_z], size=5);
}

// ---------- Assemble ----------

difference(){
    union(){
        rounded_plate(size=base_size, t=base_t, r=base_corner_r);

        // Additive features
        pin_grid();
        thin_walls();
        bridge_ladder();
        overhang_row();
        group_labels();
    }

    // Subtractive features
    hole_grid();
}
