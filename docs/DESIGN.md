# Design analysis — 4-bay NucBox rack shell

Analysis of `10inch-rack.scad` as configured for 4 × GMKtec NucBox M6 Ultra in a 10" rack at 4U.
All figures derive from the model's own constants; measured values were read back from exported
STL vertices, not estimated from screenshots.

## Configuration

| Parameter | Value |
|---|---|
| Rack | 254mm (10"), 4U = 177.8mm |
| Component | 128.8 W × 127 D × 47.8 H, rotated 90° (stands on its side) |
| Bays | 4, 4mm dividers |
| Keystones | 1 jack per bay, bottom row |
| Face plate | 4mm |

Because the component is rotated, the module's `switch_width` is the NucBox's *height* (47.8) and
`switch_height` is its *width* (128.8). Bay openings are therefore tall and narrow.

## Width budget

10" rack usable interior is **221.5mm** (254 minus a 15.875mm rail each side).

| Item | mm |
|---|---|
| 4 openings @ 48.64 (47.8 + 2 × 0.42 tolerance) | 194.56 |
| 3 dividers @ 4.0 | 12.00 |
| 2 outer walls @ 6.0 | 12.00 |
| **Total chassis width** | **218.56** |
| Spare | 2.94 |

Verified from the STL: wall planes at ±109.28, dividers at ±(50.64–54.64) and (−2–2).

5 bays would need 271.2mm — impossible. 4 bays with 6mm dividers needs 224.56mm — also over. **4mm
dividers are what make 4-across work**, with under 3mm to spare. Dividers are leftover material
between per-bay cutouts, not added solids.

## Vertical budget (4U with keystones)

| Band | rack Y (mm) |
|---|---|
| Keystone clearance | 0 – 3.0 |
| Jack row | 3.0 – 30.5 |
| Clearance | 30.5 – 35.25 |
| Chassis | 35.25 – 176.05 (140.8 tall) |
| Top margin | 176.05 – 177.8 |

3.5U cannot hold this: 140.8 + 33.5 = 174.3 > 155.575. The model echoes a warning and names the
required `rack_height`.

## Load path

Everything cantilevers off the face plate. Load ≈ 4 × ~0.6kg devices + ~0.3kg shell ≈ **27N**, with
the centre of mass roughly 63mm behind the plate → **M ≈ 1.7 N·m** at the plate.

| Element | Section property | Stress |
|---|---|---|
| Chassis box | I ≈ 1.3 × 10⁷ mm⁴ | ~0.01 MPa |
| Plate as full-width flange | S = 381 mm³ (at 3mm) | ~4.5 MPa |

Against ~40 MPa for PLA, global bending is a non-issue by two to three orders of magnitude. The
134mm-deep shell is a very stiff box; the plate only has to hand its moment to the rails.

### Where it is actually thin

The weak spots are **in-plane strips**, not the plate's bending stiffness:

- **Rack slot bands.** Each 10mm mounting slot sits in a 17.72mm side band, leaving strips of
  **3.74mm and 3.98mm** to carry every screw load.
- **Keystone band.** The plate below each jack was **2mm** before this revision.

Both scale with plate thickness, which is why 4mm was chosen: **×1.78 strength, ×2.37 stiffness**
for ~20cm³ (~25g) of filament. 3mm survives the static load; 4mm is for handling a 2.7kg loaded
unit by its face, screw bearing, and flatness across a 254 × 178 printed plate. 5mm only earns its
keep if the unit is racked and unracked often.

`keystone_clearance` went 2 → 3mm, which is better value than plate thickness for that particular
strip: 50% more material under the jacks, and it still fits at 4U.

## Front lip

The lip is the only thing stopping a device sliding out the front (zip ties at the rear do the real
retention). Its **engagement is set by `lip_thickness`, not `lip_depth`** — a distinction that
matters, because the tolerance gap eats into it:

Opening is 48.64mm for a 47.8mm device → **0.84mm of slack**. A device resting hard against one side
gets full engagement on that side and `lip_thickness − 0.84` on the other:

| `lip_thickness` | nominal / side | worst case, far side |
|---|---|---|
| 1.2 (original) | 0.78 | **0.36** |
| 1.6 | 1.18 | 0.76 |
| **2.0 (now)** | 1.58 | **1.16** |

0.36mm is about one extrusion width — effectively no capture at all if the device sits off-centre.

`lip_depth` is *not* a strength constraint. A 0.6 × 1.2mm PLA ledge needs roughly 2N per mm of
length to break, and there is ~356mm of lip per bay — hundreds of newtons of capacity. It is a
**print reliability** constraint: 0.6mm is 3 layers at 0.2mm, prone to delaminating or laying down
badly. **1.2mm (6 layers)** costs nothing.

Print orientation is unaffected: face-down, the opening steps *outward* above the lip, so there is
no overhang to bridge.

Verified by probe: the lip band is solid through z 0.2–1.0, empty behind z 1.5, and the opening is
clear through the plate inboard of the lip.

### Caveat

A 2.0mm lip covers 2mm of the device's front face edge. Confirm the NucBox M6 Ultra's buttons and
front ports are inset more than that. If not, `lip_thickness = 1.6` still gives 0.76mm worst-case
engagement — double the original.

## Keystones

Jacks fit at 3.5U and above; height was never the constraint (housing is 27.5mm, 1U is 44.45mm).
The constraint is horizontal, and it is the bay count that kills side placement:

- **1 bay:** chassis is only 60.64mm wide, leaving 83.4mm of free plate each side — up to 4 jacks
  per side. The model keeps the original mirrored pair at 210mm outer-to-outer.
- **4 bays:** chassis reaches x ≈ 17.7, the side bands are gone, so jacks move to a row below the
  openings and the chassis shifts up to make room.

The model switches automatically on whether a jack still clears beside the chassis. Groups are
centred per bay (measured centres −78.96 / −26.32 / 26.32 / 78.96 — exact bay centres). Two jacks
per bay span 39.8mm of the 48.64mm bay and still fit.

## Cooling

Side vent cylinders run through the full chassis width, so they pierce the dividers as well as the
outer walls — inner bays are not blind. Top/bottom vent grids are per-bay. With `air_holes = false`
the shell is sealed apart from the front openings and the rear, which is worth remembering with four
mini PCs in one box.

## Known constraints and open items

- **Port clearance vs lip** — see caveat above. Only unverified dimension in this analysis.
- **4mm dividers** are the thinnest structural member; plate thickness does not help them. They
  carry little load (they separate bays, they do not span), but they are also only 4mm of printed
  wall between two hot devices.
- **Zip-tie density** — 8 slots per bay, 32 total across a 47.8mm bay pitch. Correct per component,
  but it perforates the rear of the top and bottom skins fairly heavily. Reduce
  `zip_tie_hole_count` if the rear rim feels weak.
- **Keystones and 4 bays are mutually exclusive on the sides** — the bottom row is the answer, and
  it costs 33.5mm of vertical space, which is why 4U is the floor for this configuration.

## Verification method

Every figure above is reproducible:

```bash
openscad -o /tmp/check.stl 10inch-rack.scad 2>&1 | grep -E "Status|manifold|ECHO"
```

Positions come from clustering exported STL vertex coordinates per axis; open/blocked questions are
settled with a probe `intersection()` against a small cube (`Current top level object is empty`
means clear). Preview screenshots were not used as evidence — see `CLAUDE.md`.
