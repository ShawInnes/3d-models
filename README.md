# 3d-models

Parametric OpenSCAD models for 3D printing. Each `.scad` file is a self-contained model with
Customizer-friendly parameters, and exported meshes for the configurations I actually print live
in [`stl/`](stl/).

## Models

| Model | What it is |
| --- | --- |
| [`10inch-rack.scad`](10inch-rack.scad) | Shell that mounts mini PCs (or any small box) into a 10" or 6" network rack. 1–6 bays, keystone jack ports, hex vents, zip-tie retention, front lip. Parameters and layout: [docs/RACK.md](docs/RACK.md). |
| [`bladerf_x40_case.scad`](bladerf_x40_case.scad) | Two-part screwed enclosure for the Nuand bladeRF x40, with openings for USB, power, SMA and reference clock. M2 screws into heat-set inserts. |
| [`ai_champion_keychain.scad`](ai_champion_keychain.scad) | Multi-colour keychain badge rebuilt from the source vector art in [`svg/`](svg/) rather than from a decompiled mesh. |

## Requirements

OpenSCAD 2021.01 or newer. The 2025.x builds default to the Manifold backend, which is what these
models assume.

## Rendering

Open a file in OpenSCAD and use the Customizer panel, or render from the command line and override
parameters with `-D`:

```bash
openscad -o rack.stl 10inch-rack.scad
openscad -o rack.stl -D "component_count=2" -D "keystones_per_component=2" 10inch-rack.scad
openscad -o base.stl -D 'part="base"' bladerf_x40_case.scad
```

Multi-part models take a `part` parameter (`"base"`, `"lid"`, `"both"`, `"assembly"`); the print
layouts sit flat on `z=0`.

Always read the console output. `Status: NoError` plus `Top level object is a 3D object
(manifold):` is the pass condition, and any `ECHO:` line starting `WARNING:` is a fit problem that
renders fine but doesn't build.

## Layout

```
*.scad     models
stl/       exported meshes and Bambu Studio 3MF projects
svg/       source vector art used by the keychain model
docs/      per-model design and fit analysis
```

## Verifying changes

F5 preview is OpenCSG — it invents artifacts that aren't in the model and hides errors that are.
Prove geometry changes with an exact render, across every parameter combination the change
touches. `Status: NoError` is also necessary but not sufficient: the Manifold backend can emit
vertex pairs nanometres apart that collapse when a slicer loads them as float32 and surface there
as "non-manifold edges".

[CLAUDE.md](CLAUDE.md) has the full set of working rules — flush cut planes, coplanar faces inside
nested booleans, probing holes geometrically, and how to check what a slicer will see.

## Docs

- [docs/RACK.md](docs/RACK.md) — rack shell parameter reference, included STL configs, and how the
  bay layout solves itself.
- [docs/DESIGN.md](docs/DESIGN.md) — rack shell width and vertical budgets, load path, cooling,
  known constraints, measured from exported STL vertices.
- [docs/KEYSTONE-FIT.md](docs/KEYSTONE-FIT.md) — keystone aperture against a real Cat6A coupler,
  with a reusable probe harness.
