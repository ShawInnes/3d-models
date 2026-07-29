// =====================================================================
// bladeRF x40 enclosure — two-part screwed box
// Units: mm.  Global origin = outside bottom-left corner of the base.
//
// Board geometry taken from Nuand's mechanical drawing (bladerf_top.dxf,
// drawn in mils) and the bladeRF product brief.
//   PCB outline .......... 5.145 x 3.425 in  =  130.68 x 87.00 mm
//   Mounting holes ....... 8 x 0.180 in pad, inset 0.1435 in from edges
//                          (drill assumed 0.125 in / M3 clearance — verify)
//   Overall envelope ..... 131 x 87 x 18 mm
//
// Connector layout (PCB frame, origin at the bottom-left PCB corner):
//   X- short edge .. USB 3.0 micro-B and 5 V barrel jack, side by side
//   X+ short edge .. SMA TX and SMA RX
//   Y+ long edge ... right-angle SMB reference clock, 70% along
//   Y- long edge ... expansion header (on board, no opening)
//
// Assembly: 4 x M3 screws enter from the top, pass through the lid bosses
// and the PCB corner holes, and thread into M3 heat-set inserts in the
// base standoffs.  One screw set clamps lid + PCB + base together.
// =====================================================================

$fa = 2;
$fs = 0.4;

/* [Output] */
// "base", "lid", "both" (print layout), "assembly"
part = "both";

/* [Board] */
pcb_x = 130.68;
pcb_y = 87.00;
pcb_t = 1.60;
hole_inset = 3.65;      // mounting hole centre inset from each PCB edge

/* [Shell] */
fit_clr   = 0.40;       // per-side gap between PCB edge and cavity wall
wall      = 2.40;
floor_t   = 2.40;
top_t     = 2.40;
corner_r  = 3.00;
under_pcb = 4.00;       // clearance below PCB (solder tails, bottom parts)
over_pcb  = 14.00;      // clearance above PCB (tallest connector ~11 mm)
lip_h     = 3.00;       // lid lip depth = base wall height above PCB top
joint_clr = 0.20;       // lip-to-rebate slip fit

/* [Fasteners] */
insert_d = 4.00;        // bore for M3 brass heat-set insert
insert_h = 5.00;
screw_d  = 3.40;        // M3 clearance
head_d   = 6.20;
head_h   = 3.20;
boss_d   = 7.00;

/* [Connector openings] */
cut_clr = 0.80;         // clearance added around each connector body
relief  = 2.00;         // extra opening on the outer skin for cable overmoulds

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
//   w     : opening width
//   z0/z1 : opening extents relative to the PCB top surface
connectors = [
    ["X+", 20.45, 10.00, -1.0,  9.0],   // SMA, edge launch  (TX)
    ["X+", 60.33, 10.00, -1.0,  9.0],   // SMA, edge launch  (RX)
    ["X-", 39.01, 13.00, -0.8,  5.6],   // USB 3.0 micro-B
    ["X-", 58.24,  9.40, -0.6, 11.4],   // 5 V DC barrel jack
    ["Y+", 91.25,  8.00, -0.8,  7.6]    // SMB reference clock (CLK), right angle
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

module edge_cut(edge, p, w, z0, z1, depth) {
    h = z1 - z0;
    if (edge == "X+") translate([out_x - depth, py + p - w/2, z0]) cube([depth + 1, w, h]);
    if (edge == "X-") translate([-1,             py + p - w/2, z0]) cube([depth + 1, w, h]);
    if (edge == "Y+") translate([px + p - w/2, out_y - depth,  z0]) cube([w, depth + 1, h]);
    if (edge == "Y-") translate([px + p - w/2, -1,             z0]) cube([w, depth + 1, h]);
}

module connector_cuts() {
    for (c = connectors)
        let (w  = c[2] + 2*cut_clr,
             z0 = pcb_zt + c[3],
             z1 = pcb_zt + c[4]) {
            // full-depth opening
            edge_cut(c[0], c[1], w, z0, z1, wall + 4);
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
                rbox(out_x, out_y, split_z, corner_r);
                // main cavity
                translate([wall, wall, floor_t])
                    rbox(cav_x, cav_y, split_z, in_r);
                // rebate for the lid lip: remove the inner half of the wall
                translate([wall/2, wall/2, split_z - lip_h])
                    rbox(cav_x + wall, cav_y + wall, lip_h + 1, in_r + wall/2);
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
                    rbox(out_x, out_y, total_h - split_z, corner_r);
                translate([wall, wall, split_z])
                    rbox(cav_x, cav_y, total_h - split_z - top_t, in_r);
            }
            // downward lip
            difference() {
                translate([wall/2 + joint_clr, wall/2 + joint_clr, split_z - lip_h])
                    rbox(cav_x + wall - 2*joint_clr, cav_y + wall - 2*joint_clr,
                         lip_h + eps, in_r + wall/2);
                translate([wall, wall, split_z - lip_h - 1])
                    rbox(cav_x, cav_y, lip_h + 2, in_r);
            }
            // screw bosses landing on the PCB top
            for (h = mount_holes)
                translate([px + h[0], py + h[1], pcb_zt])
                    cylinder(d = boss_d - 0.5, h = total_h - top_t - pcb_zt + eps);
        }
        for (h = mount_holes) {
            translate([px + h[0], py + h[1], pcb_zt - 0.1])
                cylinder(d = screw_d, h = total_h);
            translate([px + h[0], py + h[1], total_h - head_h])
                cylinder(d = head_d, h = head_h + 0.1);
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
                cylinder(d = 3.2, h = pcb_t + 2);
    }
}

// ---------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------
if (part == "base") base();
else if (part == "lid") lid();
else if (part == "assembly") { base(); lid(); %pcb(); }
else {
    base();
    translate([0, 2*out_y + 10, 0]) rotate([180, 0, 0]) translate([0, 0, -total_h]) lid();
}
