# 10" rack shell

Parametric OpenSCAD shell that mounts mini PCs (or any small box) into a 10" or 6" network rack.

One model, [`../10inch-rack.scad`](../10inch-rack.scad), generates the face plate, the chassis that
wraps the device, the rack mounting slots, ventilation, zip-tie retention points, and optional
keystone jack ports. Bay count, device dimensions and rack height are all parameters — the layout
re-solves itself around them.

## Features

- **Multi-bay** — 1 to 6 devices side by side. Dividers between bays are leftover material from the
  per-bay cutouts, not glued-on solids.
- **Keystone jacks** — proper snap-in keystone ports (14.9 × 16.3 aperture, 3mm latch lip). Placed
  beside the chassis when there's room, otherwise in a row below the openings with the chassis
  shifted up to make space. The model picks automatically.
- **Retention** — front lip stops the device sliding out; zip-tie slots and indents at the rear of
  each bay hold it in.
- **Cooling** — staggered hexagonal vents through the top, bottom and sides. Side vents run the full
  chassis width, so they pierce the dividers too and inner bays aren't blind.
- **Fit warnings** — the chassis is clamped to the rail width, so an oversized bay count silently
  shrinks the shell rather than erroring. The model echoes a `WARNING:` naming the problem and the
  value to change.

## Rendering

Preview (F5) shows the model rotated onto its side, the way the device actually sits. Export (F6 /
`-o`) renders it flat, face plate on the bed.

```bash
# defaults: 4 × N100 in a 10" rack at 3.5U
openscad -o rack.stl 10inch-rack.scad

# override anything from the command line
openscad -o rack.stl -D "component_count=2" -D "keystones_per_component=2" 10inch-rack.scad
```

## Included STLs

| File | Device | Config |
| --- | --- | --- |
| `stl/10inch-rack-4xN100.stl` | N100 mini PC, 116 × 103 × 39 | 4 bays, 10", defaults |
| `stl/10inch-rack-4xGMTek.stl` | GMKtec NucBox M6 Ultra, 129.5 × 127.2 × 47.8 | 4 bays, 10", 4U |

The GMKtec config needs 4U — the 47.8mm device plus walls plus the keystone band doesn't fit in
3.5U, and the model says so:

```bash
openscad -o stl/10inch-rack-4xGMTek.stl \
  -D "component_width=129.5" -D "component_depth=127.2" -D "component_height=47.8" \
  -D "rack_height=4" 10inch-rack.scad
```

## Parameters

Device and rack:

| Parameter | Default | Notes |
| --- | --- | --- |
| `rack_width` | 254.0 | 254.0 = 10", 152.4 = 6". Drives usable width, slot size and slot pitch. |
| `rack_height` | 3.5 | In U (44.45mm). Fractions allowed. |
| `component_width` / `_depth` / `_height` | 116 / 103 / 39 | The device's own dimensions. |
| `component_count` | 4 | Bays across. |
| `divider_thickness` | 4.0 | Wall between adjacent bays. Ignored at 1 bay. |
| `tolerance` | 0.42 | Gap between device and walls, per side. |

Keystones:

| Parameter | Default | Notes |
| --- | --- | --- |
| `keystones` | true | |
| `keystones_per_component` | 1 | 1 or 2. Two 19.9mm jacks need a bay pitch above 39.8mm. |
| `keystone_clearance` | 3 | Material left between jacks and the plate edge / chassis. The thinnest strip in the plate — don't starve it. |

Holes and vents:

| Parameter | Default | Notes |
| --- | --- | --- |
| `air_holes` | true | Hex vents. With this off the shell is sealed apart from the front and rear. |
| `front_wire_holes` | false | Cable pass-throughs flanking the openings. |
| `wire_diameter` | 7 | |

Advanced:

| Parameter | Default | Notes |
| --- | --- | --- |
| `case_thickness` | 6 | Chassis wall. |
| `front_plate_thickness` | 4.0 | 4mm over 3mm is ×1.78 strength and ×2.37 stiffness in the thin strips beside the rack slots, for ~25g of filament. |
| `front_plate_hole` | true | False gives a solid plate; the device then loads from the rear and everything shifts back to suit. |
| `front_lip` | true | |
| `lip_thickness` | 3.0 | Sets real retention. A device shoved to one side only catches `lip_thickness − 2 × tolerance` on the far side. Also covers this much of the device's front face — check for buttons and edge ports. |
| `lip_depth` | 1.8 | Ledge depth back from the front face. Print-reliability driven: keep it a comfortable multiple of layer height. |
| `lip_corner_radius` | 2.0 | Cosmetic; the pocket behind the lip stays square, so fit is unaffected. |
| `half_height_holes` | false | Half slots at the edges when `rack_height` is fractional. |

## How the layout solves itself

- Usable interior is **221.5mm** at 10" (254 minus a 15.875mm rail each side), **120.65mm** at 6".
- Chassis width is `bays × (device + 2 × tolerance) + dividers + 2 × case_thickness`, clamped to
  that usable width. At the 4 × NucBox config it comes to 218.56mm — 4mm dividers are what make
  four across work, with under 3mm spare.
- The device is **rotated 90°** in the opening, so it stands on its side: the model's
  `switch_width` is the device's height and `switch_height` is its width.
- Keystones go beside the chassis (mirrored pair, 210mm outer-to-outer) whenever a jack still
  clears it. A multi-bay chassis eats those side bands, so the jacks drop to a row under the
  openings, costing 33.5mm of vertical space — which is why 4 bays plus keystones needs 4U.

## Printing

Print face plate down on the bed. The front opening steps *outward* above the lip, so there is
nothing to bridge. Global bending is a non-issue — the load path is discussed in
[DESIGN.md](DESIGN.md); the thin parts are in-plane strips beside the rack slots and below the
jacks, which is what plate thickness and `keystone_clearance` are protecting.

## Verifying changes

To settle whether a hole is actually open, intersect the model with a probe box — `Current top
level object is empty` means clear, facets mean blocked. Probe boxes are in **world** coordinates;
everything inside `switch_mount()` is offset by `(-rack_width/2, -height/2)`.

The general rules for modifying these models are in [../CLAUDE.md](../CLAUDE.md).

## Related

- [DESIGN.md](DESIGN.md) — width and vertical budgets, load path, lip engagement, cooling, known
  constraints, all measured from exported STL vertices rather than screenshots.
- [KEYSTONE-FIT.md](KEYSTONE-FIT.md) — the keystone aperture against a real Cat6A coupler, with a
  reusable probe harness.
