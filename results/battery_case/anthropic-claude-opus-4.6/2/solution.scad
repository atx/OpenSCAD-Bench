// =============================================================
// Case for 4× Olympus BLS-5 Batteries (56 × 36 × 13 mm)
// Linear 4×1, upright on 13×36 face, largest faces adjacent
// Snap-fit retention + finger push-out holes
// Print: opening UP, no supports required
// =============================================================

$fn = 64;

// -------------------- Battery --------------------
bat_w  = 13;     // X – narrow side
bat_d  = 36;     // Y – medium side (faces touch dividers)
bat_h  = 56;     // Z – tall, standing upright

// -------------------- Tolerances --------------------
tol = 0.5;       // clearance per side

// -------------------- Construction --------------------
wall     = 2.5;
floor_t  = 3.0;
divider  = 1.8;  // wall between adjacent batteries
num      = 4;

// -------------------- Slot interior --------------------
sw = bat_w + 2*tol;   // 14
sd = bat_d + 2*tol;   // 37
sh = bat_h + 2.0;     // 58  (battery slightly recessed)

// -------------------- Case envelope --------------------
iw = num*sw + (num-1)*divider;
cw = iw + 2*wall;
cd = sd + 2*wall;
ch = sh + floor_t;
cr = 3;

echo(str("Case: ", cw, " × ", cd, " × ", ch, " mm"));

// -------------------- Snap-fit --------------------
snap_into = 1.2;       // protrusion into slot
snap_bh   = 5.0;       // bump height along Z
snap_len  = 10.0;      // bump width along X
snap_z    = sh - 10;   // Z in slot (near top)

// Flex relief
flex_slit_w = 1.0;     // width of vertical slit
flex_slit_h = snap_bh + 14;  // height of flex zone
flex_base_h = 1.0;     // horizontal slit at bottom

// -------------------- Finger hole --------------------
fhole_d = 16;

// -------------------- Top chamfer --------------------
cham_h  = 3.0;
cham_ex = 1.5;

// ==================== MODULES ====================

// Rounded rectangle (XY plane)
module rrect2d(w, d, r) {
    offset(r) offset(-r) square([w, d]);
}

// Snap bump: protrudes in +Y from wall face
// Ramp on top for easy insertion, ledge on bottom for retention
module snap_bump() {
    // Lower portion: wall to tip (ledge)
    hull() {
        cube([snap_len, 0.01, snap_bh]);                          // on wall face
        translate([0, snap_into, snap_bh*0.20])
            cube([snap_len, 0.01, snap_bh*0.45]);                 // tip
    }
    // Upper ramp: tip back to wall
    hull() {
        translate([0, snap_into, snap_bh*0.20 + snap_bh*0.45])
            cube([snap_len, 0.01, 0.01]);                         // top of tip
        translate([0, 0, snap_bh])
            cube([snap_len, 0.01, 2.0]);                          // ramp meets wall
    }
}

// ==================== MAIN CASE ====================

module battery_case() {
    difference() {
        // ======== ADD ========
        union() {
            // Outer shell
            linear_extrude(ch)
                rrect2d(cw, cd, cr);

            // Snap bumps (front & back wall of each slot)
            for (i = [0:num-1]) {
                sx = wall + i*(sw + divider);
                cx = sx + sw/2;

                // Front snap (protrudes +Y into slot from front inner wall)
                translate([cx - snap_len/2, wall, floor_t + snap_z])
                    snap_bump();

                // Back snap (mirrored, protrudes -Y into slot from back inner wall)
                translate([cx + snap_len/2, cd - wall, floor_t + snap_z])
                    mirror([1, 0, 0]) mirror([0, 1, 0])
                        snap_bump();
            }
        }

        // ======== SUBTRACT ========
        for (i = [0:num-1]) {
            sx = wall + i*(sw + divider);
            cx = sx + sw/2;
            cy = cd / 2;

            // Slot cavity
            translate([sx, wall, floor_t])
                cube([sw, sd, sh + 10]);

            // Finger hole (through floor)
            translate([cx, cy, -1])
                cylinder(d=fhole_d, h=floor_t + 2);

            // Top entry chamfer
            translate([cx, cy, ch - cham_h])
                linear_extrude(cham_h + 0.1,
                    scale=[(sw + 2*cham_ex)/sw, (sd + 2*cham_ex)/sd])
                    translate([-sw/2, -sd/2])
                        square([sw, sd]);

            // ---- Flex relief slits (front wall) ----
            fz_bot = floor_t + snap_z - 4;
            // Left slit
            translate([cx - snap_len/2 - flex_slit_w, -0.1, fz_bot])
                cube([flex_slit_w, wall + 0.2, flex_slit_h]);
            // Right slit
            translate([cx + snap_len/2, -0.1, fz_bot])
                cube([flex_slit_w, wall + 0.2, flex_slit_h]);
            // Bottom horizontal slit (creates cantilever anchored at bottom)
            translate([cx - snap_len/2 - flex_slit_w, -0.1, fz_bot])
                cube([snap_len + 2*flex_slit_w, wall*0.55, flex_base_h]);

            // ---- Flex relief slits (back wall) ----
            // Left slit
            translate([cx - snap_len/2 - flex_slit_w, cd - wall - 0.1, fz_bot])
                cube([flex_slit_w, wall + 0.2, flex_slit_h]);
            // Right slit
            translate([cx + snap_len/2, cd - wall - 0.1, fz_bot])
                cube([flex_slit_w, wall + 0.2, flex_slit_h]);
            // Bottom horizontal slit
            translate([cx - snap_len/2 - flex_slit_w, cd - wall*0.55 - 0.1 + 0.1, fz_bot])
                cube([snap_len + 2*flex_slit_w, wall*0.55, flex_base_h]);
        }

        // ---- Engraved slot numbers on front ----
        for (i = [0:num-1]) {
            sx = wall + i*(sw + divider);
            translate([sx + sw/2, 0.6, floor_t + 10])
                rotate([90, 0, 0])
                    linear_extrude(0.8)
                        text(str(i+1), size=8, halign="center",
                             valign="center",
                             font="Liberation Sans:style=Bold");
        }

        // ---- "BLS-5" text on back ----
        translate([cw/2, cd - 0.6, floor_t + 10])
            rotate([90, 0, 180])
                linear_extrude(0.8)
                    text("BLS-5", size=5.5, halign="center",
                         valign="center",
                         font="Liberation Sans");
    }
}

battery_case();
