// IKEA Citronhaj spice jar stand
$fn = 64;

// Parameters
jar_d = 40;
jar_h = 120;
clearance = 2;           // extra diameter for easy removal
socket_d = jar_d + clearance;
socket_depth = 25;      // how deep jar sits
bottom_thickness = 5;   // material under socket

tier_step = 30;         // 3 cm per level
rows = 3;
cols = 3;

spacing = 46;            // center-to-center spacing
margin = 6;              // outer margin
row_depth = spacing;     // depth of each row area

width = cols*spacing + 2*margin;
depth = rows*row_depth + 2*margin;

// Tier heights
front_h = bottom_thickness + socket_depth;             // 30mm
middle_h = front_h + tier_step;                        // 60mm
back_h = front_h + 2*tier_step;                        // 90mm

// Y positions for rows
row_y = [
    margin + row_depth/2,                     // front row center
    margin + row_depth/2 + row_depth,         // middle row center
    margin + row_depth/2 + 2*row_depth        // back row center
];

// X positions for columns
col_x = [
    margin + spacing/2,
    margin + spacing/2 + spacing,
    margin + spacing/2 + 2*spacing
];

module tier_block(y_start, height) {
    translate([0, y_start, 0])
        cube([width, row_depth, height]);
}

module socket_at(x, y, tier_top) {
    translate([x, y, tier_top - socket_depth])
        cylinder(d=socket_d, h=socket_depth);
}

difference() {
    // Main stepped body
    union() {
        // front row block
        tier_block(margin, front_h);
        // middle row block
        tier_block(margin + row_depth, middle_h);
        // back row block
        tier_block(margin + 2*row_depth, back_h);
    }

    // Sockets for front row
    for (x = col_x)
        socket_at(x, row_y[0], front_h);

    // Sockets for middle row
    for (x = col_x)
        socket_at(x, row_y[1], middle_h);

    // Sockets for back row
    for (x = col_x)
        socket_at(x, row_y[2], back_h);
}
