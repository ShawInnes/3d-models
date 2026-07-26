# 10-inch-rack

OpenSCAD model of a 10" rack shell (`10inch-rack.scad`). Parametric: bay count, dividers,
keystone jacks, vents, zip-tie retention.

## Always verify by render — never claim a geometry change works without it

The F5 preview is OpenCSG. It invents artifacts that are not in the model, and hides errors that
are. It proves nothing either way. Run the exact (CGAL/manifold) render instead:

```bash
openscad -o /tmp/check.stl 10inch-rack.scad 2>&1 | grep -E "Status|manifold|ECHO|WARNING"
```

Required:

```
Top level object is a 3D object (manifold):
Status:     NoError
```

Anything else — non-manifold, self-intersecting, `Current top level object is empty` — is a real
bug. Fix it before reporting. Also read the `ECHO:` lines; the model warns about fit problems
(bays wider than the rails, chassis clipped, jack groups overlapping) that render fine but are
unbuildable.

Render **every parameter combination the change touches**, not just the current defaults:

```bash
openscad -o /tmp/a.stl -D "component_count=1" -D "keystones=true" 10inch-rack.scad
openscad -o /tmp/b.stl -D "component_count=4" -D "keystones_per_component=2" 10inch-rack.scad
```

## Cut planes must never sit flush with a surface

A subtracted volume whose face lands exactly on a model surface is exact in F6 but z-fights in
preview — the green/hatched speckle. Always overshoot the surface; the module defines `cut_e = 0.5`
(and `face_e` inside `keystone()`) for this. `0.01` is too small — it is inside depth-buffer noise.

```scad
translate([x, y, -cut_e]) cube([w, h, depth + 2*cut_e]);   // not [x, y, 0] with depth
```

This has bitten the file three times: rack slots starting at `z=0`, the keystone front hole starting
at the jack face, and the zip-tie indents landing on both the chassis skin and `chassis_depth_main`.
When a "rendering issue" is reported, look for the flush plane before assuming it's cosmetic.

The same rule applies to **unions and to faces inside a nested boolean**, not just to cuts against
the final skin. `keystone()` used to union the two back catches onto the finished body, where their
back faces landed on `y=jack_depth` and their ends on the back hole's own end planes. That renders
`NoError` and manifold, but the Manifold backend welds face-to-face contact with ~3nm of coordinate
noise, leaving sliver triangles a slicer cannot survive (see below). The catches are now material
*protected* from the cuts — `difference(union(cuts), back_catch_blanks())` — so no interface exists
to weld, and the blanks themselves overshoot every hole plane they would otherwise sit flush with.

## "Manifold, NoError" does not mean the slicer will accept it

OpenSCAD's default Manifold backend can emit vertex pairs a few nanometres apart. They are distinct
in the double-precision STL, so OpenSCAD reports a clean manifold solid — but slicers load vertices
as **float32**, the pairs collapse, the slivers between them go degenerate and get dropped, and the
holes left behind surface as *"N non-manifold edges"*. Bambu reported 4; the mesh also carried 4
spurious handles (`Genus: 429` where the true topology is 425).

So `Status: NoError` is necessary, not sufficient. To check what a slicer will see, quantise every
vertex to float32, merge, drop faces with a repeated index, and count edges not used exactly twice.
A useful cross-check: `openscad --backend=CGAL` uses exact arithmetic and does not produce this
noise, so a defect that disappears under CGAL is backend noise, not a modelling error — but fix the
model rather than relying on the flag, since Manifold is the default anyone exporting will hit.

When changing geometry to chase this, prove the change is a no-op by rendering old and new and
checking **both** boolean differences are zero-thickness residue (~1e-7 mm³, one bbox axis of extent
0) and that the volumes agree. Facet count dropping while volume holds is the signature of a fix.

## Verify holes geometrically, not visually

Headless camera framing is unreliable and preview screenshots are ambiguous. To prove a hole is
open, intersect the model with a probe box: `Current top level object is empty` means clear,
facets mean blocked.

```scad
intersection() {
    switch_mount(component_height, component_width, component_depth);
    translate([-82,-78,-1]) cube([6,5,5]);
}
```

Probe boxes are in **world** coordinates. Everything inside `switch_mount()` is wrapped in
`translate([-rack_width/2, -height/2, 0])`, so a probe written from module-local values silently
misses and reports the opposite of the truth. Shift by `(-127, -88.9)` at the 10"/4U defaults.

Measuring positions from exported STL vertices is likewise better evidence than a screenshot —
cluster vertex coordinates per axis to read off wall planes, spans, and alignment.

Worked example: [KEYSTONE-FIT.md](KEYSTONE-FIT.md) — keystone aperture vs. a real Cat6A coupler,
with a reusable probe harness (`include`/`use` both fail on this file; truncate above the top-level
call instead).

## Geometry conventions

- The component is rotated 90°, so `switch_width` is the component's *height* (47.8) and
  `switch_height` is its width (128.8).
- `chassis_y` is the single source of truth for vertical placement. Everything (openings, zip ties,
  vents, wire holes) derives from it — do not reintroduce hardcoded `(height - chassis_height)/2`.
- Dividers between bays are leftover material, not added solids: the per-bay cutouts create them.
- 10" usable interior is 221.5mm (254 minus 15.875 rail each side); 6" is 120.65mm.
- `keystone()` is a standard keystone snap-in port (14.9 × 16.3 aperture, 3mm lip, 14.9 × 24.4
  rear pocket), not a pocket for one specific jack. Dimensions and fit limits: [KEYSTONE-FIT.md](KEYSTONE-FIT.md).
