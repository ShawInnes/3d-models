// =====================================================================
// bladeRF x40 enclosure — two-part screwed box
// Units: mm.  Global origin = outside bottom-left corner of the base.
//
// Board geometry taken from Nuand's mechanical drawing (bladerf_top.dxf,
// drawn in mils) and the bladeRF product brief.
//   PCB outline .......... 5.145 x 3.425 in  =  130.68 x 87.00 mm
//   Mounting holes ....... 8 x 0.180 in pad, inset 0.1435 in from edges.
//                          Nuand specify 2-56 screws, so the drill is a #2
//                          clearance, nominally 0.096 in / 2.44 mm.  Verify.
//   Overall envelope ..... 131 x 87 x 18 mm
//
// Connector layout (PCB frame, origin at the bottom-left PCB corner):
//   X- short edge .. USB 3.0 micro-B and 5 V barrel jack, side by side
//   X+ short edge .. SMA TX and SMA RX
//   Y+ long edge ... right-angle SMB reference clock, 70% along
//   Y- long edge ... expansion header (on board, no opening)
//
// Assembly: 4 x M2 x 20 socket head screws enter from the top, pass through
// the lid bosses and the PCB corner holes, and thread into M2 heat-set
// inserts in the base standoffs.  One screw set clamps lid + PCB + base
// together.  The head recess is sunk to whatever depth `screw_len` requires,
// so changing the screw length moves the recess, not the case height.
// =====================================================================

$fa = 2;
$fs = 0.4;

/* [Output] */
// "base", "lid", "both" (print layout), "assembly".  base/lid/both are emitted in
// print orientation, sitting on z=0; only "assembly" keeps the halves mated.
part = "both";

/* [Board] */
pcb_x = 130.68;
pcb_y = 87.00;
pcb_t = 1.60;
hole_inset = 3.65;      // mounting hole centre inset from each PCB edge

/* [Shell] */
fit_clr    = 0.80;      // per-side gap between PCB edge and cavity wall
wall       = 3.00;
floor_t    = 2.40;
top_t      = 2.60;      // lid top plate.  The head recess is free to sink past it
                        // into the boss below, so it need not equal head_h.
corner_r   = 3.00;
ch_bot     = 0.80;      // 45 deg chamfer on the base bottom outer edge
ch_top     = 1.20;      // 45 deg chamfer on the lid top outer edge
                        // Chamfer, not fillet: both edges are the first layer
                        // in their print orientation, so a 45 deg flare is
                        // self supporting where a fillet would not be.
under_pcb  = 4.00;      // clearance below PCB (solder tails, bottom parts)
over_pcb   = 15.00;     // clearance above PCB (USB 3.0 Standard-B is ~12.9 mm)
lip_h      = 3.00;      // lid lip depth = base wall height above PCB top
lip_t      = 1.20;      // lid lip thickness
lip_relief = 0.35;      // lip inner face steps back from the cavity wall so the
                        // lip can never bind on the PCB edge
joint_clr  = 0.20;      // lip-to-rebate slip fit

/* [Fasteners] */
// Nuand specify 2-56 machine screws for the bladeRF mounting holes, so the PCB
// hole is a #2 clearance, nominally 0.096 in / 2.44 mm.  M2 is the metric
// equivalent that passes it with room.  If your board measures 0.125 in
// (3.18 mm) you can move up to M3: screw_d 3.40, head_d 6.40, insert_d 4.00,
// insert_h 5.00, top_t and head_h 3.00.
insert_d  = 3.20;       // bore for M2 brass heat-set insert
insert_h  = 4.00;
screw_d   = 2.40;       // M2 clearance
head_d    = 4.40;       // M2 socket head counterbore
head_h    = 2.60;       // depth reserved for the head, sets the shallowest recess
boss_d    = 7.60;
screw_len = 20.00;      // screw length under the head
tip_clr   = 0.40;       // gap left below the tip inside the insert bore, so the
                        // screw clamps on the head and never bottoms out

/* [Connector openings] */
cut_clr = 0.80;         // clearance added around each rectangular connector body
relief  = 2.00;         // extra opening on the outer skin for cable overmoulds.
                        // Rectangular openings only; a bored hole gets none.

// SMA edge launches (TX, RX).  The body is a 9.50 wide x 8.10 high block sitting
// across the board edge: 4.50 above the PCB top face, 2.00 below its underside.
// The barrel is on the block centre, which is 0.45 ABOVE the PCB top face - not
// on it, which is what the old rectangular cut assumed.
sma_body_w = 9.50;
sma_up     = 4.50;      // block height above the PCB top face
sma_down   = 2.00;      // block depth below the PCB underside
sma_hole_d = 11.00;     // finished bore.  Clears the 9.50 block width; the barrel
                        // itself is much smaller.  A bore that swallowed the whole
                        // 9.50 x 8.10 block corner to corner would need 12.48 dia,
                        // which reaches below the floor - so keep this under 12.10.
                        // The block never crosses the wall anyway: the PCB drops
                        // into the base vertically, only the barrel goes through.

// SMB reference clock.  On-board connector whose protrusion is centred 5.00
// above the PCB top face.
smb_hole_d = 10.00;
smb_axis_z = 5.00;

// Bored openings are drawn out into a vertical slot instead of being left as a
// full circle.  A circle cut through a wall that is vertical on the bed has a
// horizontal tangent at its widest point: the skin above that point appears out
// of thin air with nothing under it, so it prints as a sagging, unsupported lip
// right where the connector shoulder seats.  Straightening the arc at the two
// vertical tangents removes it - the sides run true vertical, which is the one
// direction a sideways face always prints cleanly.
//
// Only one horizontal tangent can be avoided per half, so the slot keeps the
// round end on the connector axis (where the barrel actually needs it) and
// pushes the other end to the parting plane.  That parks the remaining tangent
// exactly on the split, where neither half has any material above it.  So a
// connector below the split grows upward, one above it grows downward, and the
// straight run is only as long as the split demands - see slot_lo/slot_hi.
slot_bores = true;

/* [Ventilation] */
vents      = true;
vent_w     = 3.00;
vent_gap   = 4.00;
vent_len   = 55.00;

// ---------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------
eps     = 0.01;         // overlap on unioned solids, keeps preview free of z-fighting

cav_x   = pcb_x + 2*fit_clr;
cav_y   = pcb_y + 2*fit_clr;
out_x   = cav_x + 2*wall;
out_y   = cav_y + 2*wall;

px      = wall + fit_clr;               // PCB origin in global X
py      = wall + fit_clr;               // PCB origin in global Y
pcb_z0  = floor_t + under_pcb;          // PCB underside
pcb_zt  = pcb_z0 + pcb_t;               // PCB top surface
split_z = pcb_zt + lip_h;               // base / lid parting plane
total_h = floor_t + under_pcb + pcb_t + over_pcb + top_t;

in_r    = max(corner_r - wall, 0.6);

// Fastener stack.  The head recess depth follows from the screw length: sink the
// seat far enough that a fully driven tip stops tip_clr above the floor of the
// insert bore, but never so little that the head would stand proud of the lid.
insert_z0 = pcb_z0 - insert_h;                          // insert bore floor
seat_z    = min(insert_z0 + tip_clr + screw_len,
                total_h - head_h);                      // recess floor = head seat
cbore_h   = total_h - seat_z;                           // recess depth from the lid top
tip_z     = seat_z - screw_len;                         // tip of a fully driven screw
engage    = pcb_z0 - tip_z;                             // thread inside the insert

// SMA block, derived
sma_axis_z  = (sma_up - sma_down - pcb_t) / 2;          // bore axis above PCB top face
sma_block_h = sma_up + pcb_t + sma_down;

// Slot end-cap heights for a bored connector: the two circle centres the
// opening is hulled between.  Equal when slot_bores is off, which collapses the
// hull back to the original single bore.
function slot_lo(c) = slot_bores ? min(pcb_zt + c[4], split_z) : pcb_zt + c[4];
function slot_hi(c) = slot_bores ? max(pcb_zt + c[4], split_z) : pcb_zt + c[4];

// Stepped lip joint, worked out from the outside face inwards
lip_out    = wall - lip_relief - lip_t;              // lid lip outer face
lip_in     = wall - lip_relief;                      // lid lip inner face
rebate_off = wall - lip_relief - lip_t - joint_clr;  // base rebate outer face

// PCB mounting holes, PCB frame -----------------------------------------
mount_holes = [
    [hole_inset,          hole_inset         ],
    [hole_inset,          pcb_y - hole_inset ],
    [pcb_x - hole_inset,  hole_inset         ],
    [pcb_x - hole_inset,  pcb_y - hole_inset ]
];

// Inner hole set from the DXF (probably XB-200 standoffs) — unused:
//   [47.52, 9.14] [47.52, 70.33] [115.77, 9.14] [115.77, 70.33]

// Connector table, PCB frame --------------------------------------------
//   edge  : "X+" right short, "X-" left short, "Y+" far long, "Y-" near long
//   pos   : centre along that edge
//   form  : "rect" body-fitted slot, or "round" bored hole
//   a b c : rect  -> a = connector body width, b = z0, c = z1.  cut_clr is added
//                    around the body and a relief pocket is cut in the outer skin.
//           round -> a = finished bore diameter, b = bore axis height, c unused.
//                    The diameter is taken as given, no cut_clr, no relief.
//   All z values are relative to the PCB top surface.
connectors = [
    ["X+", 20.45, "round", sma_hole_d, sma_axis_z, 0],  // SMA, edge launch  (TX)
    ["X+", 60.33, "round", sma_hole_d, sma_axis_z, 0],  // SMA, edge launch  (RX)
    ["X-", 39.01, "rect",  13.00, -0.8, 12.6],          // USB 3.0 Standard-B
    ["X-", 58.24, "rect",   9.40, -0.6, 11.4],          // 5 V DC barrel jack
    ["Y+", 91.25, "round", smb_hole_d, smb_axis_z, 0]   // SMB reference clock (CLK)
];

// Unpopulated / on-board features, no opening cut.  Enable if needed:
//   ["Y-", 70.84, 10.00, -1.0,  9.0]   // third SMA position, normally unfitted
//   ["Y-", 25.25, 33.50, -0.5, 10.5]   // 2 x 20 / 1.27 mm expansion header
// Unfitted U.FL alternates sit 1.4-2.1 mm inboard at X+ y = 34.79 / 45.22
// and Y- x = 57.66; they need no wall opening.

// ---------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------
module rbox(x, y, z, r) {
    rr = max(r, 0.01);
    hull() for (i = [0,1], j = [0,1])
        translate([i ? x-rr : rr, j ? y-rr : rr, 0])
            cylinder(r = rr, h = z);
}

// One thin rounded-rectangle disc, inset from the x/y envelope
module rdisc(x, y, r, zoff, inset) {
    rr = max(r - inset, 0.01);
    for (i = [0,1], j = [0,1])
        translate([i ? x - inset - rr : inset + rr,
                   j ? y - inset - rr : inset + rr, zoff])
            cylinder(r = rr, h = 0.01);
}

// Rounded box with an optional 45 deg chamfer on the bottom and/or top face.
// Built as a convex hull of four discs, which is exact for a convex solid.
module rbox_ch(x, y, z, r, cb = 0, ct = 0) {
    hull() {
        rdisc(x, y, r, 0,            cb);
        rdisc(x, y, r, cb,           0);
        rdisc(x, y, r, z - ct - 0.01, 0);
        rdisc(x, y, r, z - 0.01,     ct);
    }
}

module edge_cut(edge, p, w, z0, z1, depth) {
    h = z1 - z0;
    if (edge == "X+") translate([out_x - depth, py + p - w/2, z0]) cube([depth + 1, w, h]);
    if (edge == "X-") translate([-1,             py + p - w/2, z0]) cube([depth + 1, w, h]);
    if (edge == "Y+") translate([px + p - w/2, out_y - depth,  z0]) cube([w, depth + 1, h]);
    if (edge == "Y-") translate([px + p - w/2, -1,             z0]) cube([w, depth + 1, h]);
}

// Bore normal to the named wall, axis at height zc
module edge_cut_round(edge, p, d, zc, depth) {
    if (edge == "X+") translate([out_x - depth, py + p, zc]) rotate([0, 90, 0])
        cylinder(d = d, h = depth + 1);
    if (edge == "X-") translate([-1,            py + p, zc]) rotate([0, 90, 0])
        cylinder(d = d, h = depth + 1);
    if (edge == "Y+") translate([px + p, out_y - depth, zc]) rotate([-90, 0, 0])
        cylinder(d = d, h = depth + 1);
    if (edge == "Y-") translate([px + p, -1,            zc]) rotate([-90, 0, 0])
        cylinder(d = d, h = depth + 1);
}

// Vertically slotted bore: the same hole at two heights, hulled.  Two coaxial
// cylinders hull to the exact stadium prism - semicircular caps joined by walls
// on the common vertical tangents - so the bore diameter is untouched and only
// the straight run is new.  zlo == zhi gives the plain circular bore back.
module edge_cut_slot(edge, p, d, zlo, zhi, depth) {
    hull() for (z = [zlo, zhi]) edge_cut_round(edge, p, d, z, depth);
}

module connector_cuts() {
    depth = wall + 4;
    // bored holes: diameter as tabled, no clearance and no outer relief.  These
    // take threaded barrels, not overmoulded boots, and the relief ring would
    // reach the floor at the SMA positions.
    for (c = connectors)
        if (c[2] == "round")
            edge_cut_slot(c[0], c[1], c[3], slot_lo(c), slot_hi(c), depth);
    // body-fitted slots
    for (c = connectors)
        if (c[2] != "round")
            let (w  = c[3] + 2*cut_clr,
                 z0 = pcb_zt + c[4],
                 z1 = pcb_zt + c[5]) {
                // full-depth opening
                edge_cut(c[0], c[1], w, z0, z1, depth);
                // shallow relief in the outer skin for plug overmoulds
                edge_cut(c[0], c[1], w + 2*relief, z0 - relief/2, z1 + relief/2,
                         max(wall - 1.0, 0.4));
            }
}

module vent_slots() {
    span  = cav_y - 34;
    n     = max(1, floor((span + vent_gap) / (vent_w + vent_gap)));
    total = n*vent_w + (n-1)*vent_gap;
    y0    = out_y/2 - total/2;
    for (i = [0 : n-1])
        translate([out_x/2 - vent_len/2, y0 + i*(vent_w + vent_gap), total_h - top_t - 0.5])
            hull() for (dx = [vent_w/2, vent_len - vent_w/2])
                translate([dx, vent_w/2, 0]) cylinder(d = vent_w, h = top_t + 1);
}

// ---------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------
module base() {
    difference() {
        union() {
            difference() {
                rbox_ch(out_x, out_y, split_z, corner_r, cb = ch_bot);
                // main cavity
                translate([wall, wall, floor_t])
                    rbox(cav_x, cav_y, split_z, in_r);
                // rebate for the lid lip
                translate([rebate_off, rebate_off, split_z - lip_h])
                    rbox(cav_x + 2*(wall - rebate_off), cav_y + 2*(wall - rebate_off),
                         lip_h + 1, in_r + (wall - rebate_off));
            }
            // PCB standoffs
            for (h = mount_holes)
                translate([px + h[0], py + h[1], floor_t - eps])
                    cylinder(d = boss_d, h = under_pcb + eps);
        }
        // heat-set insert bores
        for (h = mount_holes)
            translate([px + h[0], py + h[1], pcb_z0 - insert_h])
                cylinder(d = insert_d, h = insert_h + 0.1);
        connector_cuts();
    }
}

// ---------------------------------------------------------------------
// Lid
// ---------------------------------------------------------------------
module lid() {
    difference() {
        union() {
            // walls + top plate
            difference() {
                translate([0, 0, split_z])
                    rbox_ch(out_x, out_y, total_h - split_z, corner_r, ct = ch_top);
                translate([wall, wall, split_z])
                    rbox(cav_x, cav_y, total_h - split_z - top_t, in_r);
            }
            // downward lip
            difference() {
                translate([lip_out, lip_out, split_z - lip_h])
                    rbox(cav_x + 2*(wall - lip_out), cav_y + 2*(wall - lip_out),
                         lip_h + eps, in_r + (wall - lip_out));
                translate([lip_in, lip_in, split_z - lip_h - 1])
                    rbox(cav_x + 2*(wall - lip_in), cav_y + 2*(wall - lip_in),
                         lip_h + 2, in_r + (wall - lip_in));
            }
            // screw bosses landing on the PCB top
            for (h = mount_holes)
                translate([px + h[0], py + h[1], pcb_zt])
                    cylinder(d = boss_d, h = total_h - top_t - pcb_zt + eps);
        }
        for (h = mount_holes) {
            translate([px + h[0], py + h[1], pcb_zt - 0.1])
                cylinder(d = screw_d, h = total_h);
            // head recess, sunk to suit screw_len rather than to top_t
            translate([px + h[0], py + h[1], seat_z])
                cylinder(d = head_d, h = cbore_h + 0.1);
            // 45 deg cone out of the counterbore so the step prints unsupported
            translate([px + h[0], py + h[1], seat_z - (head_d - screw_d)/2])
                cylinder(d1 = screw_d, d2 = head_d, h = (head_d - screw_d)/2);
        }
        connector_cuts();
        if (vents) vent_slots();
    }
}

// ---------------------------------------------------------------------
// Reference PCB (preview only)
// ---------------------------------------------------------------------
module pcb() {
    difference() {
        translate([px, py, pcb_z0]) cube([pcb_x, pcb_y, pcb_t]);
        for (h = mount_holes)
            translate([px + h[0], py + h[1], pcb_z0 - 1])
                cylinder(d = 2.44, h = pcb_t + 2);
    }
}

// ---------------------------------------------------------------------
// Fit checks - read these in the console after an F6 / CLI render
// ---------------------------------------------------------------------
echo(str("screw ", screw_len, " under head: seat z=", seat_z, ", recess ", cbore_h,
         " deep, tip z=", tip_z, ", ", engage, " of thread in the ", insert_h,
         " insert bore"));
if (tip_z < insert_z0)
    echo(str("WARNING: screw too long, tip is ", insert_z0 - tip_z,
             " past the bottom of the insert bore and will jack the halves apart"));
if (seat_z >= total_h - head_h && tip_z > insert_z0 + tip_clr + 0.001)
    echo("WARNING: recess clamped at the head-flush limit");
if (engage < 2.0)
    echo(str("WARNING: only ", engage, " of thread engaged in the insert"));
if (seat_z < pcb_zt + 1)
    echo("WARNING: screw too short, the head recess sinks below the lid boss");
for (c = connectors)
    if (c[2] == "round" && slot_lo(c) - c[3]/2 < floor_t)
        echo(str("WARNING: bore ", c[0], " at ", c[1], " reaches z=",
                 slot_lo(c) - c[3]/2, ", below the floor top at ", floor_t));
for (c = connectors)
    if (c[2] == "round" && slot_hi(c) + c[3]/2 > total_h - top_t)
        echo(str("WARNING: bore ", c[0], " at ", c[1], " reaches the lid ceiling"));
for (c = connectors)
    if (c[2] == "round")
        echo(str("bore ", c[0], " at ", c[1], ": ", c[3], " dia on axis z=",
                 pcb_zt + c[4], ", slotted to ", slot_hi(c) - slot_lo(c),
                 " straight, opening z=", slot_lo(c) - c[3]/2, "..",
                 slot_hi(c) + c[3]/2));

// ---------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------
// The base already prints as modelled - its outer bottom face is z=0.  The lid
// has to be turned over onto its top plate, which puts the ch_top chamfer on the
// bed as the self-supporting first layer and leaves the lip pointing up.
module lid_print() {
    translate([0, out_y, 0]) rotate([180, 0, 0]) translate([0, 0, -total_h]) lid();
}

if (part == "base") base();
else if (part == "lid") lid_print();
else if (part == "assembly") { base(); lid(); %pcb(); }
else {
    base();
    translate([0, out_y + 10, 0]) lid_print();
}
