// ============================================================
// 3D PRINTER TORTURE TEST MODEL
// Tests: Holes, Pins, Thin Walls, Bridges, Overhangs
// Prints as a single piece - all dimensions in mm
// ============================================================

$fn = 64;
base_h = 3;

// Embossed label helper
module label(txt, size=2.5, h=0.4) {
    linear_extrude(h)
        text(txt, size=size, halign="center", valign="center",
             font="Liberation Sans:style=Bold");
}

// ============================================================
// SECTION 1: HOLES
// 10 through-holes: 1-10mm diameter
// ============================================================
module holes_section() {
    diams = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    sp = 13;
    cols = 5;
    w = cols * sp + 2;
    d = 2 * sp + 8;

    difference() {
        cube([w, d, base_h]);
        for (i = [0:9]) {
            c = i % cols;
            r = floor(i / cols);
            translate([c*sp + sp/2 + 1, r*sp + sp/2 + 7, -0.1])
                cylinder(d=diams[i], h=base_h+0.2);
        }
    }

    for (i = [0:9]) {
        c = i % cols;
        r = floor(i / cols);
        cx = c*sp + sp/2 + 1;
        cy = r*sp + sp/2 + 7;
        translate([cx, cy - diams[i]/2 - 2.2, base_h])
            label(str(diams[i]), 1.6, 0.4);
    }

    translate([w/2, 3, base_h]) label("HOLES", 3, 0.4);
}

// ============================================================
// SECTION 2: PINS
// 10 cylinders: 1-10mm diameter, heights 1-5mm
// ============================================================
module pins_section() {
    diams = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    hts  = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5];
    sp = 13;
    cols = 5;
    w = cols * sp + 2;
    d = 2 * sp + 8;

    cube([w, d, base_h]);

    for (i = [0:9]) {
        c = i % cols;
        r = floor(i / cols);
        cx = c*sp + sp/2 + 1;
        cy = r*sp + sp/2 + 7;
        translate([cx, cy, base_h])
            cylinder(d=diams[i], h=hts[i]);
        translate([cx, cy - diams[i]/2 - 2.2, base_h])
            label(str(diams[i]), 1.6, 0.4);
    }

    translate([w/2, 3, base_h]) label("PINS", 3, 0.4);
}

// ============================================================
// SECTION 3: THIN WALLS
// 7 walls: 0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0mm thick
// 15mm tall, 8mm deep
// ============================================================
module thin_walls_section() {
    ts = [0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0];
    wh = 15;
    wd = 8;
    sp = 7;
    n = len(ts);
    w = n * sp + 4;
    d = wd + 10;

    cube([w, d, base_h]);

    for (i = [0:n-1]) {
        t = ts[i];
        cx = i*sp + sp/2 + 2;
        translate([cx - t/2, 5, base_h])
            cube([t, wd, wh]);
        translate([cx, 2.5, base_h])
            label(str(t), 1.5, 0.4);
    }

    translate([w/2, d - 2, base_h]) label("WALLS mm", 2.2, 0.4);
}

// ============================================================
// SECTION 4: BRIDGES
// 8 unsupported spans: 5-50mm
// ============================================================
module bridges_section() {
    blens = [5, 10, 15, 20, 25, 30, 40, 50];
    bw = 5;
    bt = 1.5;
    ph = 8;
    pw = 3;
    gap = 2;
    n = len(blens);
    
    w = 62;
    d = n * (bw + gap) + gap + 5;

    cube([w, d, base_h]);

    for (i = [0:n-1]) {
        bl = blens[i];
        y = i*(bw+gap) + gap + 5;
        xc = w/2;
        xs = xc - bl/2 - pw;

        translate([xs, y, base_h]) cube([pw, bw, ph]);
        translate([xs+pw+bl, y, base_h]) cube([pw, bw, ph]);
        translate([xs+pw, y, base_h + ph - bt]) cube([bl, bw, bt]);

        translate([3.5, y + bw/2, base_h]) label(str(bl), 1.6, 0.4);
    }

    translate([w/2, 2.5, base_h]) label("BRIDGES mm", 2.8, 0.4);
}

// ============================================================
// SECTION 5: OVERHANGS
// 7 angled surfaces: 10-70 degrees from vertical
// ============================================================
module overhangs_section() {
    angs = [10, 20, 30, 40, 50, 60, 70];
    oh = 15;
    ow = 6;
    sw = 3;
    st = 2;
    sp = 10;
    n = len(angs);

    max_ext = oh * tan(70);
    w = max_ext + sw + 12;
    d = n * sp + 6;

    cube([w, d, base_h]);

    for (i = [0:n-1]) {
        ang = angs[i];
        y = i*sp + sp/2 + 3;

        // Vertical support wall
        translate([3, y - ow/2, base_h])
            cube([sw, ow, oh]);

        // Angled overhang slab
        translate([3 + sw, y - ow/2, base_h + oh]) {
            rotate([0, ang, 0])
                translate([0, 0, -oh])
                    cube([st, ow, oh]);
        }

        // Label
        translate([w - 5, y, base_h])
            label(str(ang), 1.6, 0.4);
    }

    translate([w/2, 1.5, base_h]) label("OVERHANG deg", 2.2, 0.4);
}

// ============================================================
// ASSEMBLY
// ============================================================

// Calculated widths
holes_w = 5*13+2;  // 67
pins_w = 67;
holes_d = 2*13+8;  // 34
walls_w = 7*7+4;   // 53
walls_d = 18;
bridges_w = 62;
bridges_d = 8*7+2+5; // 63
oh_w = 15*tan(70)+3+12; // ~56
oh_d = 7*10+6; // 76

sec_gap = 2;

// Row 1 (y=8): Holes | Pins
r1y = 8;
translate([0, r1y, 0]) holes_section();
translate([holes_w + sec_gap, r1y, 0]) pins_section();

// Row 2 (below row 1): Thin Walls + gap
r2y = r1y + holes_d + sec_gap;
translate([0, r2y, 0]) thin_walls_section();

// Row 3 (below row 2): Bridges | Overhangs
r3y = r2y + walls_d + sec_gap;
translate([0, r3y, 0]) bridges_section();
translate([bridges_w + sec_gap, r3y, 0]) overhangs_section();

// Main title at bottom
translate([(holes_w + sec_gap + pins_w)/2, 3, 0])
    linear_extrude(0.6)
        text("3D PRINTER TORTURE TEST", size=4,
             halign="center", valign="bottom",
             font="Liberation Sans:style=Bold");
