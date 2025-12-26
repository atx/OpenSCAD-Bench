// Tiered stand for 9 IKEA Citronhaj spice jars (3x3 grid)
// Jar specs: 40mm diameter, 120mm height

$fn = 100; // smooth circles

// Jar dimensions
jar_diameter = 40;
jar_radius = jar_diameter / 2;

// Stand parameters
clearance = 0.5; // clearance for easy insertion/removal
holder_diameter = jar_diameter + 2 * clearance;
holder_radius = holder_diameter / 2;

// Wall thickness around each jar
wall_thickness = 3;
outer_radius = holder_radius + wall_thickness;

// Height of the holder walls (enough to secure jar but easy to remove)
holder_height = 25; // about 20% of jar height for stability

// Base thickness
base_thickness = 3;

// Spacing between jars
jar_spacing = 10; // gap between jar holders

// Tier step height
tier_step = 30; // 3cm per level

// Calculate positions for 3x3 grid
pitch = holder_diameter + wall_thickness * 2 + jar_spacing;

module jar_holder(height) {
    difference() {
        // Outer cylinder with slight taper for easier jar insertion
        cylinder(r1 = outer_radius, r2 = outer_radius - 0.3, h = height);
        
        // Inner cutout for jar
        translate([0, 0, base_thickness])
            cylinder(r1 = holder_radius, r2 = holder_radius + 0.2, h = height + 1);
        
        // Add a chamfer to the top edge for comfort
        translate([0, 0, height - 1])
            cylinder(r1 = holder_radius, r2 = holder_radius + 2, h = 1.5);
    }
}

module tiered_stand() {
    union() {
        // Create a unified sloped base platform
        hull() {
            // Front row positions (tier 0)
            for (col = [0:2]) {
                translate([col * pitch, 0, 0])
                    cylinder(r = outer_radius, h = base_thickness);
            }
            
            // Middle row positions (tier 1)
            for (col = [0:2]) {
                translate([col * pitch, pitch, tier_step])
                    cylinder(r = outer_radius, h = base_thickness);
            }
            
            // Back row positions (tier 2)
            for (col = [0:2]) {
                translate([col * pitch, 2 * pitch, 2 * tier_step])
                    cylinder(r = outer_radius, h = base_thickness);
            }
        }
        
        // Add jar holders on top of the base
        for (row = [0:2]) {
            for (col = [0:2]) {
                // Calculate tier height (front row = 0, middle = 1 step, back = 2 steps)
                tier_height = row * tier_step;
                
                translate([col * pitch, row * pitch, tier_height]) {
                    jar_holder(holder_height + base_thickness);
                }
            }
        }
    }
}

tiered_stand();
