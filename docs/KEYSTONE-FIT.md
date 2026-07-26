# Keystone jack fit analysis

Verification that the `keystone()` module in `10inch-rack.scad` matches a real Cat6A keystone
coupler. Checked 2026-07-26 against a TecMojo-style slim Cat6A keystone coupler advertised as
16.0 mm × 19.5 mm × 30.0 mm (0.6" × 0.8" × 1.2").

**Verdict: correct module.** The aperture is the standard keystone snap-in opening. The one number
to confirm with calipers before printing a batch is the coupler's body *width* — see Caveats.

## What the module actually is

`keystone()` (`10inch-rack.scad:411`) is a standard keystone snap-in port, not a bespoke pocket for
one specific jack:

| Feature | Model | Keystone standard | Source |
| --- | --- | --- | --- |
| Front aperture | 14.9 W × 16.3 H | 14.5 × 16.0 | `front_hole_width` / `front_hole_height` |
| Front lip depth | 3.0 mm | plate thickness the latch bites | `front_large_catch_depth` |
| Rear pocket | 14.9 W × 24.4 H × 6.7 deep | clearance for latch tab + fixed hook | `back_hole_height`, `jack_depth - 3` |
| Total mount depth | 9.7 mm | — | `jack_depth` |
| Outer footprint | 19.9 × 27.5 | — | `keystone_outer_width` / `_height` (lines 113–114) |

The aperture is the standard opening plus +0.4 mm width / +0.3 mm height of slack. The jack inserts
from the front, its fixed hook and flexible latch land in the 24.4 mm-tall rear pocket, and the
latch clicks against the 3 mm front lip. That is the normal keystone retention mechanism.

## Geometry, in world coordinates

Everything inside `switch_mount()` is wrapped in `translate([-rack_width/2, -height/2, 0])`, so
module-local X/Y are offset by `(-127, -88.9)` at the defaults. Probes written in local coordinates
will silently miss — this cost a full round of wrong results during the original analysis.

At the defaults (10", 4 bays, `keystones_per_component = 1`, so the bottom-row layout is active):

```
ECHO: "KX=[38.09, 90.73, 143.37, 196.01] KTY=3 KOW=19.9 KOH=27.5 bottomrow=true"
```

For the leftmost jack (`tx = 38.09`, `keystone_ty = 3`):

| Region | X | Y | Z |
| --- | --- | --- | --- |
| Outer footprint | −88.91 … −69.01 | −85.90 … −58.40 | 0 … 9.7 |
| Front aperture | −86.41 … −71.51 | −81.62 … −65.32 | 0 … 3 |
| Rear pocket | −86.41 … −71.51 | −84.00 … −59.60 | 3 … 9.7 |

The `rotate([90,0,0])` at `10inch-rack.scad:560` maps jack-local Y to rack Z (depth) and jack-local
Z to rack −Y, which the `+keystone_outer_height` in the translate compensates for. The module also
mirrors itself internally (`translate([0,0,jack_height+wall]) mirror([0,0,1])`), so pre-mirror Z
values from the source read inverted relative to the table above.

## Probe results

All probes are `intersection()` against the model: `Current top level object is empty` means the
volume is clear, facets mean it is blocked.

| Probe | Volume | Result | Meaning |
| --- | --- | --- | --- |
| aperture void | 14.5 × 15.9, z 0 … 2.8 | empty | front opening clear |
| left wall | 1.5 mm at x = −88.7 | solid | aperture bounded, wall present |
| rear pocket | 14.5 × 23.8, z 3.5 … 8.0 | empty | pocket clear ahead of the catches |
| behind mount | 19.9 × 27.5, z 9.9 … 69.9 | empty | coupler + plug + boot all fit |
| 16.0 mm wide at front | 16.0 × 15.9, z 0 … 3 | **solid** | literal vendor width does not pass |
| 19.5 mm tall at front | 14.5 × 19.5, z 0 … 3 | **solid** | literal vendor height does not pass |
| full model | — | manifold / NoError | no regression |

## Caveats

### 1. The vendor's 16.0 mm width is the number to check

A probe box a literal 16.0 mm wide is blocked at the front face — the model's aperture is 14.9 mm.
The 0.6"/0.8" figures on the product page are rounded envelope dimensions, not the neck that has to
pass through the plate; a real keystone neck is 14.5 mm. Caliper the actual body before committing
to a print.

If the body really does measure wider than 14.9 mm, bump both together, or the wall math in the
comment on line 113 stops holding:

- `front_hole_width` (`10inch-rack.scad:415`)
- `keystone_outer_width` (`10inch-rack.scad:113`, which is `front_hole_width + 2*wall`)

Widening `keystone_outer_width` also widens `keystone_group_w`, which is checked against `bay_pitch`
at line 530 — watch for the "adjacent groups overlap" warning.

### 2. The 19.5 mm height is fine

That figure includes the latch tab, which lives in the 24.4 mm rear pocket. Only the ≤16.3 mm neck
has to pass the aperture.

### 3. The 30 mm depth is fine

Only 9.7 mm sits inside the mount; the remaining ~20.3 mm protrudes into the rack, and the plug and
boot add roughly another 25 mm behind that. Probed clear to 60 mm behind the mount face.

### 4. The printed rear catches do nothing for this coupler

The small (1.4 mm proud, 2 mm long) and large (1.3 mm proud, 2.6 mm long) back catches shrink the
pocket to 21.7 mm tall over the last ~1.4 mm of depth. A 19.5 mm-tall body slips straight past them.
Retention comes entirely from the coupler's own latch bearing on the 3 mm front lip — which is the
standard mechanism and works — but do not expect the catches to contribute. They appear to be sized
for a taller jack.

## Reproducing the probes

The top-level call at the end of `10inch-rack.scad` is unguarded, so `include <>` drags the whole
model in as a sibling and `use <>` drops the global variables the module depends on. Neither works.
Truncate the file above the call instead and append the probe:

```bash
head -n $(grep -n '^// Call the module' 10inch-rack.scad | cut -d: -f1) 10inch-rack.scad > /tmp/kbase.scad
cat >> /tmp/kbase.scad <<'EOF'
probe = 0;
intersection() {
    switch_mount(component_height, component_width, component_depth);
    if (probe == 0) translate([-86.2, -81.3, -1])  cube([14.5, 15.9, 3.8]);  // aperture void
    if (probe == 1) translate([-88.7, -81.3, 0])   cube([1.5, 15.9, 3]);     // left wall
    if (probe == 2) translate([-86.2, -83.7, 3.5]) cube([14.5, 23.8, 4.5]);  // pocket, ahead of catches
    if (probe == 3) translate([-88.9, -85.9, 9.9]) cube([19.9, 27.5, 60]);   // clearance behind mount
}
EOF

for p in 0 1 2 3; do
  printf "probe=%s -> " $p
  openscad -o /tmp/kb$p.stl -D "probe=$p" /tmp/kbase.scad 2>&1 | grep -E "Top level|empty" | head -1
done
```

To re-derive the jack positions after changing bay count or keystone parameters, insert an echo just
above the `// Helper modules` comment inside `switch_mount()`:

```scad
echo(str("KX=", keystone_xs, " KTY=", keystone_ty,
         " KOW=", keystone_outer_width, " KOH=", keystone_outer_height,
         " bottomrow=", keystone_bottom_row));
```

Then shift by `(-rack_width/2, -height/2)` to get world coordinates for the probe boxes.
