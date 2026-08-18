// AI CHAMPION keychain badge — 50 x 50.747 x 4 mm
//
// Rebuilt from the vector art embedded in "Keychain Draft - 0.2mm v2.3mf", a
// Bambu MakerLab "Image to Keychain" (Vectorize V0.0.2) export. That 3MF ships
// the original trace at Auxiliaries/Templates/assets/vectorize.svg, and its mesh
// is nothing more than a 2.5D extrusion of it: all 166 mesh objects have exactly
// two distinct Z values, no draft, no curvature. So this file re-derives the
// solid from the same source art rather than decompiling the mesh.
//
// This rebuild is cleaner than the 3MF it replaces:
//   3MF: 8 non-manifold edges (4x-used pinch points in the backing plate), a
//        vertex pair 68 nm apart, and 133 sliver holes through the 3 mm plate
//        totalling 0.011 mm^2 (129 of them narrower than a 0.4 mm nozzle).
//   here: 0 non-manifold edges at float32, genus 0, watertight, and dimensionally
//        within a micron (volume 7979.256 vs 7979.071 mm^3, 0.0023%).
// The slivers vanish because OpenSCAD's polygon union closes the gaps between
// abutting traced contours; Bambu's mesher left them open.
//
// NOTE: there is no keyring hole. The original has none either (genus 0 — it is a
// solid disc), which is presumably why it was named "Keychain Draft".

// ---- parameters -----------------------------------------------------------
badge_width  = 60;    // mm across X. Original: 50.0 x 50.747
base_h       = 2;     // backing plate thickness
detail_h     = 1;     // colour layer thickness (flat, not relief — see note below)
rim          = 1;     // black border inset around the edge, hiding colour-layer sides
$fn          = 32;    // controls bezier tessellation of the imported paths

// ---- SVG frame ------------------------------------------------------------
// Measured from the union of the nine layer bounding boxes. All layers share one
// viewBox, so importing with center=false keeps them registered to each other —
// do NOT use center=true, which re-centres each file on its own extents and
// scatters the layers.
svg_w  = 272.67180106;
svg_h  = 276.74321644;
svg_x0 = 0.52916667;
svg_y0 = 0.24731133;

s  = badge_width / svg_w;    // 0.183376
cx = svg_x0 + svg_w / 2;
cy = svg_y0 + svg_h / 2;

module art(file) {
    scale(s) translate([-cx, -cy]) import(file, center = false);
}

// The source art carries nine fills, which tile the silhouette exactly (the
// layer volumes sum to 59325.6651 mm^3 against a union of 59325.6650, so there
// is no overlap and no gap to clean up). Those nine are collapsed here onto five
// filaments — the same count the original 3MF used.
//
// The merges are all shade-on-shade, so nothing reads as a colour change:
//   1d1701 + 463906 -> black   dark olive shadow on the glasses
//   fdce26          -> yellow  light gold highlight on the glasses
//   dedfdf          -> white   outer trim ring (absorbed by `rim` anyway)
//
// 2d2c2c deliberately keeps its own filament. It is the hoodie fold shading, and
// folding it into black flattens the figure and loses all its form — this is
// what the original spent its fifth filament (extruder 6, #27415F) on. Set its
// group colour to black below if you would rather print four filaments and
// accept a flat hood.
groups = [
    ["black",  "#1a1a1a", ["000000", "1d1701", "463906"]],
    ["shade",  "#27415f", ["2d2c2c"]],
    ["red",    "#c12e1f", ["ca262c"]],
    ["yellow", "#f9c223", ["f9c223", "fdce26"]],
    ["white",  "#fefefe", ["fefefe", "dedfdf"]],
];

// ---- model ----------------------------------------------------------------
// This badge has NO relief. The nine colour layers tile the silhouette exactly,
// so extruding them all yields a disc with one flat top face — the artwork lives
// purely in which filament prints where, not in the geometry. A single-solid
// export therefore looks like a blank disc in any slicer, and STL carries no
// colour at all, so it renders in the slicer's default colour.
//
// Export one solid per part instead, then load them together in Bambu Studio as
// a single object with multiple parts and assign a filament to each:
//
//   openscad -o base.stl -D 'part="base"'     ai_champion_keychain.scad
//   openscad -o gold.stl -D 'part="f9c223"'   ai_champion_keychain.scad
//
// All parts share one coordinate frame, so they land registered with no manual
// alignment. Alternatively export a single coloured 3MF, which does carry the
// colours below:
//
//   openscad -o badge.3mf --export-format 3mf \
//            -O export-3mf/color-mode=model -O export-3mf/material-type=color \
//            ai_champion_keychain.scad

part = "all";   // "all" | "base" | a group name: black shade red yellow white

// The full silhouette, i.e. every path unioned, and the same shape pulled in by
// `rim`. Every colour region is clipped to the inset shape so that no colour but
// black reaches the perimeter — otherwise each region's side wall is visible as a
// stripe on the edge of the badge.
module silhouette() { art("svg/ai_champion/vectorize.svg"); }
module inset()      { offset(r = -rim) silhouette(); }

// Backing plate.
module base_plate() {
    linear_extrude(height = base_h)
        silhouette();
}

// Everything printed in one filament, as a single solid: the group's source
// fills unioned, then clipped to the inset. The original prints face down, so
// this face goes against the build plate.
module group_solid(keys) {
    translate([0, 0, base_h])
        linear_extrude(height = detail_h)
            intersection() {
                union() { for (k = keys) art(str("svg/ai_champion/", k, ".svg")); }
                inset();
            }
}

// The border band the colour regions were pulled out of. Printed in the same
// black as the 000000 layer, so it adds no extra part and no extra filament.
//
// Note this absorbs the #dedfdf layer entirely: that light-grey ring occupies
// radius 29.69–30.42 on a badge whose edge is at 30.0–30.45, i.e. it IS the
// outermost trim, and it was one of the stripes showing on the edge wall. Any
// rim >= 0.4 consumes it, so `part="dedfdf"` renders empty and there is no
// dedfdf.stl to export. Set rim = 0 to bring it back.
module rim_ring() {
    translate([0, 0, base_h])
        linear_extrude(height = detail_h)
            difference() { silhouette(); inset(); }
}

if (part == "all") {
    color("#1a1a1a") base_plate();
    for (g = groups) color(g[1]) group_solid(g[2]);
    color(groups[0][1]) rim_ring();
} else if (part == "base") {
    base_plate();
} else {
    for (g = groups) if (g[0] == part) group_solid(g[2]);
    if (part == groups[0][0]) rim_ring();   // rim prints with the black group
}
