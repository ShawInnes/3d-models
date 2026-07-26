rack_width = 254.0; // [ 254.0:10 inch, 152.4:6 inch]
// Height of the rack in U units, can be a fraction for partial U (e.g. 1.5 for 1U plus half of the next U)
rack_height = 3.5; // [0.5:0.5:5]

// N100: 116 W x 103 D x 39 H
component_width = 116.0;
component_depth = 103.0;
component_height = 39.0;

// GMKtec NucBox M6 Ultra: 129.5 W x 127.2 D x 47.8 H
// component_width = 129.5;
// component_depth = 127.2;
// component_height = 47.8;

// Number of components side by side across the rack. Each extra bay adds
// (component + tolerance + divider_thickness) to the chassis width.
// 10 inch rack fits 4 rotated NucBoxes with 4mm dividers (218.56 of 221.5 usable).
component_count = 4; // [1:1:6]
// Wall left between adjacent bays. Ignored when component_count is 1.
divider_thickness = 4.0;

// ========================================
/* [Keystones] */
// Add keystone jacks to the front panel
keystones = true; // [true: Place keystone jacks, false: Remove keystone jacks]
// Jacks per component, aligned under each opening. Only used when the chassis is
// too wide for jacks beside it (multi-bay); the row then sits below the openings
// and the chassis shifts up. Total jacks = this x component_count.
keystones_per_component = 1; // [1:1 per component, 2:2 per component]
// Plate material left between the jacks and the plate edge, and between the jacks and
// the chassis. This strip is the thinnest part of the face plate, so don't starve it.
keystone_clearance = 3;

// ========================================
/* [Holes] */
// Adds small cutout a USB or Power cable could be routed through to the front
front_wire_holes = false; // [true:Show front wire holes, false:Hide front wire holes]
// Diameter of wire to route through front_wire_holes.
wire_diameter = 7; // Diameter of power wire holes
// Adds hexagon air cutouts to reduce material and improve cooling.
air_holes = true; // [true:Show air holes, false:Hide air holes]

// ========================================
/* [Advanced] */
// Used when rack_height is a fraction, cuts a half oval for screws, otherwise will cover up the hole
half_height_holes = false; // [true:Show partial holes at edges, false:Hide partial holes]
// Thickness of the shell that wraps around the part.
case_thickness = 6; // Thickness of case walls
// Thickness of the front panel (the flat face plate). 4mm over 3mm buys 1.8x strength
// and 2.4x stiffness in the thin strips beside the rack slots, for ~25g of filament.
front_plate_thickness = 4.0;
// Make the front plate solid (no hole), useful to hide a part not needing to be accessed from the exterior.
front_plate_hole = true; // [true:Show front plate hole, false:Solid front plate]
// Prevent part from sliding out the front by adding a lip around the front plate hole.
front_lip = true; // [true:Show front lip, false:Hide front lip]
// How far the lip reaches inward over the part's face. Real engagement is this minus the
// tolerance slack, so a part shoved to one side only catches (lip_thickness - 2*tolerance).
// Check the part's front face: this much of its edge gets covered, so mind edge ports.
lip_thickness = 3.0;
// Thickness of the lip ledge measured back from the front face. Keep this a comfortable
// multiple of layer height — 0.6 is only 3 layers at 0.2mm and delaminates easily.
lip_depth = 1.8;
// Radius of the rounded inside corners of the front opening. Cosmetic only: the lip already
// covers the component's corners, so this reshapes material that was blocking the view
// anyway. The pocket behind the lip stays square, so component fit is untouched. 0 gives
// square corners. Clamped to half the aperture, and only used when front_lip is on.
lip_corner_radius = 2.0;
// Default gap between part and print walls
tolerance = 0.42;

// ========================================
/* [Hidden] */
height = 44.45 * rack_height;


// The main module containing all internal variables
module switch_mount(switch_width, switch_height, switch_depth) {
    //6 inch racks (mounts=152.4mm; rails=15.875mm; usable space=120.65mm)
    //10 inch racks (mounts=254.0mm; rails=15.875mm; usable space=221.5mm)
    usable_width = (rack_width == 152.4) ? 120.65 : 221.5;
    bay_count = max(1, floor(component_count));
    divider = (bay_count > 1) ? divider_thickness : 0;
    // Total opening span: all bays plus the dividers between them
    inner_span = bay_count * (switch_width + 2 * tolerance) + (bay_count - 1) * divider;
    chassis_width = min(inner_span + (2 * case_thickness), usable_width);
    chassis_side_margin = (rack_width - chassis_width) / 2;
    corner_radius = 4.0;
    chassis_edge_radius = 2.0;
    // `tolerance` is deliberately NOT redeclared here. A local copy shadowed the global
    // for every use below this line while `inner_span` above still read the global, so
    // overriding the parameter widened the bay span without widening the bays.

    // How far cuts overshoot a surface so no cut plane lands flush with it. Flush
    // planes are exact in F6 but z-fight in OpenCSG preview.
    cut_e = 0.5;

    zip_tie_hole_count = 8;
    zip_tie_hole_width = 1.5;
    zip_tie_hole_length = 5;
    zip_tie_indent_depth = 2;
    zip_tie_cutout_depth = 7;

    // When the front is solid the switch slides in from the back, so everything
    // shifts rearward by front_plate_thickness to keep zip ties at the switch's back face.
    solid_z_offset = front_plate_hole ? 0 : front_plate_thickness;
    chassis_depth_main = switch_depth + zip_tie_cutout_depth + solid_z_offset;
    chassis_depth_indented = chassis_depth_main - zip_tie_indent_depth;

    hole_total_width = zip_tie_hole_count * zip_tie_hole_width;
    space_between_holes = (rack_width - hole_total_width) / (zip_tie_hole_count + 1);

    $fn = 64;

    // Calculated dimensions
    cutout_w = switch_width + (2 * tolerance);
    cutout_h = switch_height + (2 * tolerance);
    // Left edge of the whole multi-bay opening, then per bay
    span_x = (rack_width - inner_span) / 2;
    bay_pitch = cutout_w + divider;
    function bay_x(i) = span_x + i * bay_pitch;
    cutout_x = span_x;

    // Keystone placement — jack X span (width) goes horizontal, jack Z span (height) goes vertical
    keystone_outer_width  = 19.9; // jack_width + wall = (front_hole_width + wall) + wall
    keystone_outer_height = 27.5; // jack_height + wall

    // SIDE placement: left edge of left keystone pinned to 210/2 from centreline
    // → 210mm outer-to-outer for the mirrored pair. Needs a free band beside the chassis.
    keystone_side_tx = rack_width/2 - 105;
    keystone_side_fits = (keystone_side_tx + keystone_outer_width) <= (chassis_side_margin - keystone_clearance);
    // BOTTOM ROW placement: multi-bay chassis swallows the side bands, so the jacks go
    // in a row below the openings, one group per component, and the chassis shifts up.
    keystone_bottom_row = keystones && !keystone_side_fits;

    // Vertical budget: the bottom row reserves a band, leaving the rest for the chassis
    keystone_band = keystone_bottom_row ? keystone_outer_height + (2 * keystone_clearance) : 0;
    chassis_avail_h = height - keystone_band;
    chassis_height = min(switch_height + (2 * case_thickness), chassis_avail_h);
    chassis_y = keystone_band + (chassis_avail_h - chassis_height) / 2; // chassis bottom edge
    cutout_y = chassis_y + (chassis_height - cutout_h) / 2; // openings centred in the chassis
    chassis_mid_y = chassis_y + chassis_height / 2;

    keystone_ty = keystone_bottom_row
        ? keystone_clearance
        : (height - keystone_outer_height) / 2;
    // Jacks butt together panel style, each group centred under its own bay
    keystone_group_n = max(1, min(2, floor(keystones_per_component)));
    keystone_group_w = keystone_group_n * keystone_outer_width;
    keystone_xs = keystone_bottom_row
        ? [ for (b = [0:bay_count-1], j = [0:keystone_group_n-1])
                bay_x(b) + (cutout_w - keystone_group_w)/2 + j * keystone_outer_width ]
        : [ keystone_side_tx, rack_width - keystone_side_tx - keystone_outer_width ];

    // Helper modules
    module capsule_slot_2d(L, H) {
        hull() {
            translate([-L/2 + H/2, 0]) circle(r=H/2);
            translate([L/2 - H/2, 0]) circle(r=H/2);
        }
    }
    
    module rounded_rect_2d(w, h, r) {
        hull() {
            translate([r, r]) circle(r=r);
            translate([w-r, r]) circle(r=r);
            translate([w-r, h-r]) circle(r=r);
            translate([r, h-r]) circle(r=r);
        }
    }

    module rounded_chassis_profile(width, height, radius, depth) {
        hull() {
            translate([radius, radius, 0]) cylinder(h = depth, r = radius);
            translate([width - radius, radius, 0]) cylinder(h = depth, r = radius);
            translate([radius, height - radius, 0]) cylinder(h = depth, r = radius);
            translate([width - radius, height - radius, 0]) cylinder(h = depth, r = radius);
        }
    }
    
    // Create the main body as a separate module
    module main_body() {
        union() {
            // Front panel
            linear_extrude(height = front_plate_thickness) {
                rounded_rect_2d(rack_width, height, corner_radius);
            }
            // Chassis body
            translate([chassis_side_margin, chassis_y, front_plate_thickness]) {
                rounded_chassis_profile(chassis_width, chassis_height, chassis_edge_radius, chassis_depth_main - front_plate_thickness);
            }
        }
    }
    
    // Create switch cutout with optional lip
    module switch_cutout() {
        // The lip aperture — the opening you actually see from the front. Rounding its
        // corners only reshapes lip material, which covers the component's corners either
        // way, so the pocket below stays square and the fit is unchanged.
        aperture_w = cutout_w - 2*lip_thickness;
        aperture_h = cutout_h - 2*lip_thickness;
        aperture_r = min(lip_corner_radius, min(aperture_w, aperture_h) / 2);
        for (i = [0:bay_count-1]) {
            if (front_plate_hole && front_lip) {
                // Main cutout minus lip
                translate([
                    bay_x(i) + lip_thickness,
                    cutout_y + lip_thickness,
                    -tolerance
                ]) {
                    if (aperture_r > 0) {
                        linear_extrude(height = chassis_depth_main)
                            rounded_rect_2d(aperture_w, aperture_h, aperture_r);
                    } else {
                        cube([aperture_w, aperture_h, chassis_depth_main]);
                    }
                }
                // Switch cutout above the lip
                translate([
                    bay_x(i),
                    cutout_y,
                    lip_depth
                ]) {
                    cube([cutout_w, cutout_h, chassis_depth_main]);
                }
            } else {
                // Full cutout: starts at front face when front_plate_hole, or behind front panel when solid
                z_start = front_plate_hole ? -tolerance : front_plate_thickness;
                z_depth = front_plate_hole ? chassis_depth_main + 2*tolerance : chassis_depth_main - front_plate_thickness + tolerance;
                translate([
                    bay_x(i),
                    cutout_y,
                    z_start
                ]) {
                    cube([cutout_w, cutout_h, z_depth]);
                }
            }
        }
    }
    
    // Create all rack holes
    module all_rack_holes() {
        // Rack standard: 3 holes per U, with specific positioning
        // Each U is 44.45mm, holes are at specific positions within each U
        hole_spacing_x = (rack_width == 152.4) ? 136.526 : 236.525; // 6 inch : 10 inch rack
        hole_left_x = (rack_width - hole_spacing_x) / 2;
        hole_right_x = (rack_width + hole_spacing_x) / 2;

        // 10 inch rack = 10x7mm oval
        // 6 inch rack = 3.25 x 6.5mm oval
        slot_len = (rack_width == 152.4) ? 6.5 : 10.0;
        slot_height = (rack_width == 152.4) ? 3.25 : 7.0;

        // Standard rack hole positions within each 1U (44.45mm) unit:
        // First hole: 6.35mm from top of U
        // Second hole: 22.225mm from top of U (middle)
        // Third hole: 38.1mm from top of U (6.35mm from bottom)
        u_hole_positions = [6.35, 22.225, 38.1]; // positions within each U
        
        // Calculate how many full and partial U units we need to consider
        max_u = ceil(rack_height); // Include partial U units
        
        for (side_x = [hole_left_x, hole_right_x]) {
            for (u = [0:max_u-1]) {
                for (hole_pos = u_hole_positions) {
                    // Calculate hole position from top of entire rack
                    hole_y = height - (u * 44.45 + hole_pos);
                    // Always show holes that are at least partially within the rack height
                    // Always show holes fully inside the rack
                    fully_inside = (hole_y >= slot_height/2 && hole_y <= height - slot_height/2);
                    // Show partial holes at edge only if half_height_holes is true
                    partially_inside = (hole_y + slot_height/2 > 0 && hole_y - slot_height/2 < height);
                    show_hole = fully_inside || (half_height_holes && partially_inside && !fully_inside);
                    if (show_hole) {
                        // Start behind the front face: a cut coplanar with the plate
                        // z-fights in OpenCSG preview (harmless in F6, ugly in F5).
                        translate([side_x, hole_y, -1]) {
                            linear_extrude(height = chassis_depth_main + 2) {
                                capsule_slot_2d(slot_len, slot_height);
                            }
                        }
                    }
                }
            }
        }
    }

    // Power wire cutouts: configurable diameter holes at top and bottom rack hole positions
    module power_wire_cutouts() {
        hole_spacing_x = inner_span; // flank the whole multi-bay opening
        hole_left_x = (rack_width - hole_spacing_x) / 2 - (wire_diameter /5);
        hole_right_x = (rack_width + hole_spacing_x) / 2 + (wire_diameter /5);
        // Midplane of switch opening
        for (side_x = [hole_left_x, hole_right_x]) {
            translate([side_x, chassis_mid_y, -1]) {
                linear_extrude(height = chassis_depth_main + 2) {
                    circle(d=wire_diameter);
                }
            }
        }
    }
    
    // Create zip tie holes and indents
    module zip_tie_features() {
        // Zip tie holes — one set per bay so every component gets its own tie points
        zip_z = switch_depth + solid_z_offset;
        for (b = [0:bay_count-1]) {
            bay_left = bay_x(b) + tolerance; // component left edge inside the bay
            for (i = [0:zip_tie_hole_count-1]) {
                x_pos = bay_left + (switch_width/(zip_tie_hole_count+1)) * (i+1);
                translate([x_pos, 0, zip_z]) {
                    cube([zip_tie_hole_width, height, zip_tie_hole_length]);
                }
            }

            // Zip tie indents (top and bottom). Both overshoot the chassis skin in Y and
            // the chassis back in Z — flush cut planes there z-fight in preview.
            // Bottom indent
            translate([bay_left, chassis_y - cut_e, zip_z]) {
                cube([switch_width, zip_tie_indent_depth + cut_e, zip_tie_cutout_depth + cut_e]);
            }
            // Top indent
            translate([bay_left, chassis_y + chassis_height - zip_tie_indent_depth, zip_z]) {
                cube([switch_width, zip_tie_indent_depth + cut_e, zip_tie_cutout_depth + cut_e]);
            }
        }
    }

    // Simplified air holes with staggered honeycomb pattern on all faces
    module air_holes() {
        hole_d = 16;
        spacing_x = 15;  // Horizontal spacing (X and Y directions)
        spacing_z = 17;  // Vertical spacing (Z direction) - tighter to match visual density
        margin = 3; // Keep holes away from edges

        // Chassis dimensions come from the enclosing scope

        // TOP/BOTTOM FACE HOLES (Y-axis, penetrating top and bottom chassis walls)
        // Calculate available space for holes within switch dimensions
        available_width = switch_width - (2 * margin);
        available_depth = switch_depth - (2 * margin);

        // Calculate number of holes that fit
        x_cols = floor(available_width / spacing_x);
        z_rows = floor(available_depth / spacing_z);

        // Calculate actual grid size for centering
        actual_grid_width = (x_cols - 1) * spacing_x;
        actual_grid_depth = (z_rows - 1) * spacing_z;

        // Center the grid within each bay's cutout area
        cutout_center_z = front_plate_thickness + switch_depth / 2;

        z_start = cutout_center_z - actual_grid_depth / 2;

        // Cylinder must span the full chassis height in Y, including when chassis_height > height
        // (chassis body can protrude above/below the front panel bounds)
        y_hole_top = chassis_y + chassis_height + 1;
        y_hole_h = chassis_height + 2;

        // Create top/bottom face holes with VERTICAL staggered pattern, per bay
        if (x_cols > 0 && z_rows > 0) {
            for (b = [0:bay_count-1], i = [0:x_cols-1]) {
                x_start = bay_x(b) + cutout_w/2 - actual_grid_width / 2;
                for (j = [0:z_rows-1]) {
                    // Stagger every other COLUMN (i) instead of row (j) for vertical honeycomb pattern
                    z_offset = (i % 2 == 1) ? spacing_z/2 : 0;
                    x_pos = x_start + i * spacing_x;
                    z_pos = z_start + j * spacing_z + z_offset;

                    // Only place hole if it fits within bounds after staggering
                    if (z_pos + hole_d/2 <= cutout_center_z + switch_depth/2 - margin &&
                        z_pos - hole_d/2 >= cutout_center_z - switch_depth/2 + margin) {
                        translate([x_pos, y_hole_top, z_pos]) {
                            rotate([90, 0, 0]) {
                                cylinder(h = y_hole_h, d = hole_d, $fn = 6);
                            }
                        }
                    }
                }
            }
        }

        // SIDE FACE HOLES (X-axis through left and right walls)

        // Calculate available space within chassis height (includes case walls above/below switch)
        available_height = chassis_height - (2 * margin);
        available_side_depth = switch_depth - (2 * margin);

        // Calculate number of holes that fit on sides
        y_cols = floor(available_height / spacing_x);  // Use spacing_x for Y direction
        z_rows_side = floor(available_side_depth / spacing_z);

        // Calculate actual grid size for sides
        actual_grid_height = (y_cols - 1) * spacing_x;
        actual_grid_depth_side = (z_rows_side - 1) * spacing_z;

        // Center the grid within the chassis height (Y) and switch depth (Z)
        cutout_center_y = chassis_mid_y;

        y_start = cutout_center_y - actual_grid_height / 2;
        z_start_side = cutout_center_z - actual_grid_depth_side / 2;

        // Each cylinder runs from 1mm outside the left wall all the way through to 1mm outside
        // the right wall. Using a single cylinder per position avoids the right-side cylinder
        // going in the wrong direction (away from the chassis).
        if (y_cols > 0 && z_rows_side > 0) {
            for (i = [0:y_cols-1]) {
                for (j = [0:z_rows_side-1]) {
                    // Stagger every other COLUMN (i) instead of row (j) for vertical honeycomb pattern
                    z_offset = (i % 2 == 1) ? spacing_z/2 : 0;
                    y_pos = y_start + i * spacing_x;
                    z_pos = z_start_side + j * spacing_z + z_offset;

                    // Only place hole if it fits within bounds after staggering
                    if (y_pos + hole_d/2 <= cutout_center_y + chassis_height/2 - margin &&
                        y_pos - hole_d/2 >= cutout_center_y - chassis_height/2 + margin &&
                        z_pos + hole_d/2 <= cutout_center_z + switch_depth/2 - margin &&
                        z_pos - hole_d/2 >= cutout_center_z - switch_depth/2 + margin) {
                        translate([chassis_side_margin - 1, y_pos, z_pos]) {
                            rotate([0, 90, 0]) {
                                rotate([0, 0, 90]) {  // Rotate hexagon 90 degrees to match front/back orientation
                                    cylinder(h = chassis_width + 2, d = hole_d, $fn = 6);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Complete keystone with embossed triangle
    module keystone(){
        e=0.01; // epsilon for coplanar face fixes, fixes bug where some faces leave a thin sliver of material
        face_e=0.5; // how far cuts overshoot the front face so nothing lands coplanar with it
        wall=2.5;
        front_hole_width=14.9;
        front_hole_height=16.3;
        front_hole_z_offset=4.28;
        front_hole_lip=0;

        jack_width=front_hole_width+wall;
        jack_height=25;
        jack_depth=9.7;
        front_large_catch_depth=3;
        front_chamfer_angle=50; // degrees from horizontal (depth axis)

        back_hole_height=24.4;
        back_hole_z_offset=1.9;

        back_small_catch_length=2;
        back_small_catch_depth=1.4;

        back_large_catch_length=2.6;
        back_large_catch_depth=1.3;
        
        back_chamfer=1.2;

        // Blanks overshoot the cut volume on every face except the two that define the catch
        // (its front face and its inner end), so no blank plane is coplanar with a hole plane.
        // Overshooting the x sides and the outer z end protects only material no cut reaches,
        // so it is a no-op geometrically — but leaving those faces flush is not: a coplanar
        // face inside difference(cuts, blanks) is the same degeneracy this whole module avoids.
        blank_e = face_e;
        blank_y_out = jack_depth + wall + blank_e;

        // The two back catches, as material to PROTECT from the cuts rather than solids to
        // union on afterwards. A unioned catch touches the body face-to-face on three planes
        // (its back on y=jack_depth, its ends on the back hole's own end planes). The Manifold
        // backend welds such contacts with ~3nm of coordinate noise, leaving sliver triangles;
        // a slicer loads STL vertices as float32, those pairs collapse, the slivers go
        // degenerate and get dropped, and the result is non-manifold edges. Subtracting the
        // blanks from the cut volume leaves the catches as untouched body material, so no
        // interface exists to weld. The blanks must also survive the front hole: the large
        // catch overhangs it by (back_hole_z_offset + back_large_catch_length -
        // front_hole_z_offset) = 0.22mm, which a plain difference would eat.
        module back_catch_blanks() {
            translate([wall + front_hole_width + blank_e, 0, 0])
                rotate([0, -90, 0])
                    linear_extrude(front_hole_width + 2*blank_e) {
                        // Small back catch
                        polygon([
                            [back_hole_z_offset + back_hole_height - back_small_catch_length, jack_depth - back_small_catch_depth],
                            [back_hole_z_offset + back_hole_height + blank_e,                 jack_depth - back_small_catch_depth],
                            [back_hole_z_offset + back_hole_height + blank_e,                 blank_y_out],
                            [back_hole_z_offset + back_hole_height - back_small_catch_length, blank_y_out]
                        ]);
                        // Large back catch
                        polygon([
                            [back_hole_z_offset - blank_e,                 jack_depth - back_large_catch_depth],
                            [back_hole_z_offset + back_large_catch_length, jack_depth - back_large_catch_depth],
                            [back_hole_z_offset + back_large_catch_length, blank_y_out],
                            [back_hole_z_offset - blank_e,                 blank_y_out]
                        ]);
                    }
        }

        // Flip entire part because I accidentially desinged it upside down
        translate([0, 0, jack_height + wall])
        mirror([0, 0, 1]) {
            // Back edge chamfer via intersection with hull (4 separate cuts → 1 operation)
            intersection() {
                difference(){
                    cube([jack_width+wall,jack_depth,jack_height+wall]);
                    difference() {
                        union() {
                            // Front hole — start ahead of the face, otherwise the cut's front
                            // cap is coplanar with the jack face and z-fights in preview.
                            // face_e is deliberately larger than e: 0.01 is inside depth-buffer noise.
                            translate([(jack_width+wall-front_hole_width)/2,-face_e,front_hole_z_offset])
                                cube([front_hole_width,jack_depth+wall+face_e,front_hole_height]);
                            // Back hole
                            translate([(jack_width+wall-front_hole_width)/2,front_large_catch_depth,back_hole_z_offset])
                                cube([front_hole_width,jack_depth+wall-front_large_catch_depth,back_hole_height]);
                            // Chamfer on front face of small catch
                            translate([wall + front_hole_width, 0, 0])
                                rotate([0, -90, 0])
                                    linear_extrude(front_hole_width)
                                        polygon([
                                            [front_hole_z_offset + front_hole_height - e, front_hole_lip - e],
                                            [front_hole_z_offset + front_hole_height + (front_large_catch_depth - front_hole_lip) * tan(front_chamfer_angle), front_large_catch_depth],
                                            [front_hole_z_offset + front_hole_height - e, front_large_catch_depth]
                                        ]);
                            // Front directional triangle emboss (cut into face)
                            // 0.4mm deep, overshooting the face by face_e so the cut isn't flush with it
                            translate([(jack_width+wall)/2, 0.4, (front_hole_z_offset + front_hole_height + jack_height + wall) / 2])
                                rotate([90, 0, 0])
                                    linear_extrude(height = 0.4+face_e)
                                        polygon([[0, -2], [-2, 2], [2, 2]]);
                        } // end union of cuts
                        back_catch_blanks();
                    } // end protected cut volume
                } // end difference
                // Chamfer all 4 back edges in one hull operation
                hull() {
                    cube([jack_width+wall, jack_depth-back_chamfer, jack_height+wall]);
                    translate([back_chamfer, 0, back_chamfer])
                        cube([jack_width+wall-2*back_chamfer, jack_depth, jack_height+wall-2*back_chamfer]);
                }
            } // end intersection
        } // end mirror
    } // end module keystone



    // Punch the keystone footprint through the front face plate.
    // Inset slightly: a cutout exactly the size of the jack body leaves the hole wall
    // and the jack wall on the same plane, which z-fights in OpenCSG preview. Undersizing
    // buries the jack wall in plate material instead — the union merges them cleanly.
    module keystone_front_cutout(tx) {
        inset = 0.1;
        translate([tx + inset, keystone_ty + inset, -tolerance]) {
            cube([keystone_outer_width - 2*inset, keystone_outer_height - 2*inset,
                  front_plate_thickness + 2 * tolerance]);
        }
    }

    // Fit checks — the chassis is clamped to the rail width, so an oversized bay
    // count silently shrinks the shell rather than failing.
    if (inner_span + (2 * case_thickness) > usable_width) {
        echo(str("WARNING: ", bay_count, " bays need ", inner_span + (2 * case_thickness),
                 "mm but only ", usable_width, "mm fits between the rails. Reduce component_count or divider_thickness."));
    }
    if (chassis_height < switch_height + (2 * case_thickness)) {
        echo(str("WARNING: chassis clipped to ", chassis_height, "mm — needs ",
                 switch_height + (2 * case_thickness), "mm",
                 keystone_bottom_row ? str(" plus a ", keystone_band, "mm keystone band. Raise rack_height to ",
                                           ceil((switch_height + (2 * case_thickness) + keystone_band) / 44.45 * 2) / 2, ".")
                                     : "."));
    }
    if (keystone_bottom_row && keystone_group_w > bay_pitch) {
        // Groups are centred per bay, so an oversized group runs into its neighbour
        echo(str("WARNING: ", keystone_group_n, " jacks span ", keystone_group_w,
                 "mm but the bay pitch is only ", bay_pitch,
                 "mm — adjacent groups overlap. Use keystones_per_component = 1."));
    }

    // Main assembly - cleaner boolean structure
    translate([-rack_width/2, -height/2, 0]) {
        difference() {
            main_body();
            union() {
                switch_cutout();
                all_rack_holes();
                zip_tie_features();
                if (front_wire_holes) {
                    power_wire_cutouts();
                }
                if (air_holes) {
                    air_holes();
                }
                if (keystones) {
                    for (tx = keystone_xs) keystone_front_cutout(tx);
                }
            }
        }
        if (keystones) {
            // The jack body is symmetric in X, so every position is a plain translate.
            // rotate([90,0,0]) maps keystone Y→rack Z (depth), keystone Z→rack -Y (compensated by +keystone_outer_height in translate)
            for (tx = keystone_xs) {
                translate([tx, keystone_ty + keystone_outer_height, 0]) rotate([90,0,0]) keystone();
            }
        }
    }
}

// Call the module
// Component rotated 90deg about the depth axis: width and height swap, so the
// part stands on its side in the rack opening.
if ($preview) {
    rotate([-90,0,0])
        translate([0, -height/2, -component_depth/2])
            switch_mount(component_height, component_width, component_depth);
} else {
    switch_mount(component_height, component_width, component_depth);
}
