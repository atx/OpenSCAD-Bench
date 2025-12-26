// IKEA Citronhaj Spice Jar Stand
// Dimensions: Jar = 40mm diam, 120mm height.
// Grid: 3x3

jar_od = 40;
tolerance = 1.2; // 41.2mm hole
hole_od = jar_od + tolerance;
wall_thickness = 2.4; 
cylinder_od = hole_od + 2 * wall_thickness; // ~46.0mm

grid_spacing = 45.0; // Overlap: 46mm > 45mm, so 1mm overlap

rows = 3;
cols = 3;

step_height = 30; // Vertical step between rows
base_floor_thickness = 3; 
cup_depth = 40; // Depth of the holder cup
chamfer_height = 1.5;

$fn = 64;

module single_holder(r, c) {
    floor_z = base_floor_thickness + r * step_height;
    top_z = floor_z + cup_depth;
    
    translate([c * grid_spacing, r * grid_spacing, 0]) {
        difference() {
            // Positive shape
            cylinder(h = top_z, d = cylinder_od);
            
            // Cavity
            translate([0, 0, floor_z]) {
                cylinder(h = cup_depth + 1, d = hole_od);
            }
            
            // Beveled entry for easier insertion
            translate([0, 0, top_z - chamfer_height]) {
                 cylinder(h = chamfer_height + 0.1, d1 = hole_od, d2 = hole_od + 2*chamfer_height);
            }
        }
    }
}

module solid_base_web() {
    // Fills the gaps between cylinders at the base level (Z=0 to 3)
    // to creates a solid, stable footer.
    h = base_floor_thickness;
    
    // Hull every 2x2 square of cylinders
    for (r = [0 : rows - 2]) {
        for (c = [0 : cols - 2]) {
             translate([c * grid_spacing, r * grid_spacing, 0]) {
                 linear_extrude(h) {
                     hull() {
                         circle(d=cylinder_od);
                         translate([grid_spacing, 0]) circle(d=cylinder_od);
                         translate([0, grid_spacing]) circle(d=cylinder_od);
                         translate([grid_spacing, grid_spacing]) circle(d=cylinder_od);
                     }
                 }
             }
        }
    }
}

union() {
    // Generate Holders
    for (r = [0 : rows - 1]) {
        for (c = [0 : cols - 1]) {
            single_holder(r, c);
        }
    }
    
    // Generate Base Webbing
    solid_base_web();
}
