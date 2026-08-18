#!/usr/bin/env python3
"""
Dimensioned drawing set for the bladeRF x40 enclosure.

Sheets 1, 3, 4, 6 are A3 landscape at 1:1 (readable at any print scale).
Sheet 5 is an A3 section at 2:1. Sheet 2 is a schedule. Sheet 6 elevates the
three walls that carry openings, seen from outside. Sheet 7 is an A4 1:1
overlay that MUST print at 100 %.

Parameters below mirror bladerf_x40_case.scad. Edit them together.
"""
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm as MM
import math

# ---------------------------------------------------------------- parameters
PCB_X, PCB_Y, PCB_T = 130.68, 87.00, 1.60
HOLE_INSET = 3.65

FIT_CLR, WALL, FLOOR_T, TOP_T = 0.80, 3.00, 2.40, 2.60
CORNER_R = 3.00
CH_BOT, CH_TOP = 0.80, 1.20   # 45 deg chamfers, outer bottom and outer top faces
UNDER_PCB, OVER_PCB, LIP_H = 4.00, 15.00, 3.00
LIP_T, LIP_RELIEF, JOINT_CLR = 1.20, 0.35, 0.20
BOSS_D, INSERT_D, INSERT_H = 7.60, 3.20, 4.00
SCREW_D, HEAD_D, HEAD_H = 2.40, 4.40, 2.60
SCREW_LEN, TIP_CLR = 20.00, 0.40    # length under the head; gap left in the bore
PCB_HOLE_D = 2.44   # #2 clearance, per Nuand's 2-56 screw spec. Verify.
SCREW_NAME = "M2"   # change with SCREW_D / HEAD_D / INSERT_D if you move to M3
CUT_CLR, RELIEF = 0.80, 2.00
VENT_W, VENT_GAP, VENT_LEN = 3.00, 4.00, 55.00

# C3 / C4 SMA edge launches: a 9.50 wide x 8.10 high block across the board edge,
# 4.50 above the PCB top face and 2.00 below its underside, barrel on its centre.
# C5 SMB clock: on-board connector, protrusion centred 5.00 above the PCB top face.
SMA_BODY_W, SMA_UP, SMA_DOWN = 9.50, 4.50, 2.00
SMA_HOLE_D = 11.00
SMB_HOLE_D, SMB_AXIS_Z = 10.00, 5.00
SLOT_BORES = True   # bored openings are drawn out into a vertical slot: the round
                    # end stays on the connector axis and the other end is pushed
                    # to the parting plane, so the arc's horizontal tangent - the
                    # unsupported spot on a face printed sideways - lands on the
                    # split, where neither half has material above it

CAV_X, CAV_Y = PCB_X + 2 * FIT_CLR, PCB_Y + 2 * FIT_CLR
OUT_X, OUT_Y = CAV_X + 2 * WALL, CAV_Y + 2 * WALL
PX = PY = WALL + FIT_CLR
PCB_Z0 = FLOOR_T + UNDER_PCB
PCB_ZT = PCB_Z0 + PCB_T
SPLIT_Z = PCB_ZT + LIP_H
TOTAL_H = FLOOR_T + UNDER_PCB + PCB_T + OVER_PCB + TOP_T

SMA_BLOCK_H = SMA_UP + PCB_T + SMA_DOWN
SMA_AXIS_Z = (SMA_UP - SMA_DOWN - PCB_T) / 2     # block centre above the PCB top face


def slot_ends(zc):
    """The two circle centres a bored opening is drawn between. Equal when
    SLOT_BORES is off, which collapses the stadium back to a plain circle."""
    return (min(zc, SPLIT_Z), max(zc, SPLIT_Z)) if SLOT_BORES else (zc, zc)

# Fastener stack. The head recess depth follows from the screw length: sink the
# seat far enough that a fully driven tip stops TIP_CLR above the floor of the
# insert bore, but never so little that the head would stand proud of the lid.
INSERT_Z0 = PCB_Z0 - INSERT_H
SEAT_Z = min(INSERT_Z0 + TIP_CLR + SCREW_LEN, TOTAL_H - HEAD_H)
CBORE_H = TOTAL_H - SEAT_Z
TIP_Z = SEAT_Z - SCREW_LEN
ENGAGE = PCB_Z0 - TIP_Z

HOLES = [("H1", HOLE_INSET, HOLE_INSET),
         ("H2", HOLE_INSET, PCB_Y - HOLE_INSET),
         ("H3", PCB_X - HOLE_INSET, HOLE_INSET),
         ("H4", PCB_X - HOLE_INSET, PCB_Y - HOLE_INSET)]
HOLES_XB = [("X1", 47.52, 9.14), ("X2", 47.52, 70.33),
            ("X3", 115.77, 9.14), ("X4", 115.77, 70.33)]

# ref, edge, centre, body width, form, a, b, name
#   form "rect"  -> a = z low, b = z high, both relative to the PCB top face
#   form "round" -> a = finished bore diameter, b = bore axis above the PCB top face
CONNECTORS = [
    ("C1", "X-", 39.01, 13.00, "rect", -0.80, 12.60, "USB 3.0 Standard-B"),
    ("C2", "X-", 58.24,  9.40, "rect", -0.60, 11.40, "5 V DC barrel jack"),
    ("C3", "X+", 20.45, SMA_BODY_W, "round", SMA_HOLE_D, SMA_AXIS_Z, "SMA, TX"),
    ("C4", "X+", 60.33, SMA_BODY_W, "round", SMA_HOLE_D, SMA_AXIS_Z, "SMA, RX"),
    ("C5", "Y+", 91.25,  8.00, "round", SMB_HOLE_D, SMB_AXIS_Z,
     "SMB reference clock, right angle"),
]
UNFITTED = [
    ("U1", "Y-", 70.84, 10.00, "Third SMA position, unfitted"),
    ("U2", "Y-", 25.25, 33.50, "Expansion header, 2 x 20 at 1.27 mm"),
    ("U3", "X+", 34.79,  8.13, "U.FL alternate, 2.1 mm inboard"),
    ("U4", "X+", 45.22,  8.13, "U.FL alternate, 2.1 mm inboard"),
    ("U5", "Y-", 57.66,  8.13, "U.FL alternate, 1.4 mm inboard"),
]

THIN, MED, THICK = 0.25, 0.5, 0.9
GREY, RED = (0.55, 0.55, 0.55), (0.72, 0.10, 0.10)

# Text that runs under the title block or off the frame is invisible on the page
# but silently present in the file, so a column that outgrows its budget reads as
# a missing line rather than an error.  Every horizontal string is measured as it
# is drawn and anything out of bounds is reported when the set is written.
LAYOUT_WARNINGS = []


def openings():
    out = []
    for ref, edge, p, w, form, a, b, name in CONNECTORS:
        base = PX if edge.startswith("Y") else PY
        if form == "round":
            zc = PCB_ZT + b
            zlo, zhi = slot_ends(zc)
            out.append(dict(ref=ref, edge=edge, name=name, form="round", c=base + p,
                            bw=w, w=a, d=a, rw=None, zc=zc, zlo=zlo, zhi=zhi,
                            z0=zlo - a / 2, z1=zhi + a / 2))
        else:
            ow = w + 2 * CUT_CLR
            out.append(dict(ref=ref, edge=edge, name=name, form="rect", c=base + p,
                            bw=w, w=ow, d=None, rw=ow + 2 * RELIEF, zc=None,
                            z0=PCB_ZT + a, z1=PCB_ZT + b))
    return out


class Sheet:
    def __init__(self, c, w, h, title, no, of, scale="1:1", warn=None):
        self.c, self.w, self.h = c, w, h
        c.setPageSize((w * MM, h * MM))
        c.setLineWidth(THICK); c.setStrokeColorRGB(0, 0, 0)
        c.rect(10 * MM, 10 * MM, (w - 20) * MM, (h - 20) * MM)
        bw, bh = w - 20, 18
        c.setLineWidth(MED)
        c.rect(10 * MM, 10 * MM, bw * MM, bh * MM)
        c.line(10 * MM, 19 * MM, (10 + bw) * MM, 19 * MM)
        c.setFont("Helvetica-Bold", 10)
        c.drawString(13 * MM, 21.5 * MM, "bladeRF x40 enclosure")
        c.setFont("Helvetica", 9)
        c.drawString(13 * MM, 13 * MM, title)
        c.setFont("Helvetica", 7.5)
        c.drawRightString((7 + bw) * MM, 21.5 * MM,
                          "All dimensions mm.  Datum marked on each view.")
        c.drawRightString((7 + bw) * MM, 13 * MM,
                          "Scale %s   Sheet %d of %d" % (scale, no, of))
        self.no, self.body_y0, self.body_x0, self.body_x1 = no, 10 + bh, 10.0, w - 10
        if warn:
            c.setFont("Helvetica-Bold", 8)
            c.setFillColorRGB(*RED)
            c.drawCentredString((10 + bw / 2) * MM, 21.5 * MM, warn)
            c.setFillColorRGB(0, 0, 0)

    def line(self, x1, y1, x2, y2, w=MED, dash=None, col=(0, 0, 0)):
        self.c.setLineWidth(w); self.c.setStrokeColorRGB(*col)
        self.c.setDash(dash or []); self.c.line(x1*MM, y1*MM, x2*MM, y2*MM); self.c.setDash([])

    def rect(self, x, y, w, h, lw=MED, dash=None, col=(0, 0, 0), r=0.0):
        self.c.setLineWidth(lw); self.c.setStrokeColorRGB(*col); self.c.setDash(dash or [])
        if r > 0: self.c.roundRect(x*MM, y*MM, w*MM, h*MM, r*MM)
        else: self.c.rect(x*MM, y*MM, w*MM, h*MM)
        self.c.setDash([])

    def circle(self, x, y, d, lw=MED, col=(0, 0, 0)):
        self.c.setLineWidth(lw); self.c.setStrokeColorRGB(*col)
        self.c.circle(x*MM, y*MM, d/2*MM)

    def cross(self, x, y, r=3.0, col=GREY):
        self.line(x-r, y, x+r, y, THIN, [2, 1.2], col)
        self.line(x, y-r, x, y+r, THIN, [2, 1.2], col)

    def text(self, x, y, s, size=7, anchor="l", rot=0, col=(0, 0, 0), bold=False):
        c = self.c
        wd = c.stringWidth(s, "Helvetica-Bold" if bold else "Helvetica", size) / MM
        if rot == 0:
            x0 = x - (wd if anchor == "r" else wd / 2 if anchor == "c" else 0)
            where = ("under the title block" if y < self.body_y0 else
                     "off the right frame" if x0 + wd > self.body_x1 else
                     "off the left frame" if x0 < self.body_x0 else None)
        elif rot == 90:
            # ordinate labels read bottom-to-top and hang down off their anchor
            y0 = y - (wd if anchor == "r" else wd / 2 if anchor == "c" else 0)
            where = "under the title block" if y0 < self.body_y0 else None
        else:
            where = None
        if where:
            LAYOUT_WARNINGS.append("sheet %d: text runs %s at x %.1f y %.1f: %r"
                                   % (self.no, where, x, y, s))
        c.saveState(); c.setFillColorRGB(*col)
        c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
        c.translate(x*MM, y*MM); c.rotate(rot)
        (c.drawCentredString if anchor == "c" else
         c.drawRightString if anchor == "r" else c.drawString)(0, 0, s)
        c.restoreState()

    def arrow(self, x, y, ang, size=1.7):
        c = self.c; a = math.radians(ang)
        bx, by = x - size*math.cos(a), y - size*math.sin(a)
        px, py = -math.sin(a)*size*0.3, math.cos(a)*size*0.3
        p = c.beginPath(); p.moveTo(x*MM, y*MM)
        p.lineTo((bx+px)*MM, (by+py)*MM); p.lineTo((bx-px)*MM, (by-py)*MM); p.close()
        c.setFillColorRGB(0, 0, 0); c.drawPath(p, stroke=0, fill=1)

    def dim_h(self, x1, x2, y, label=None, ext_from=None):
        if ext_from is not None:
            self.line(x1, ext_from, x1, y+1.5, THIN, col=GREY)
            self.line(x2, ext_from, x2, y+1.5, THIN, col=GREY)
        self.line(x1, y, x2, y, THIN); self.arrow(x1, y, 180); self.arrow(x2, y, 0)
        self.text((x1+x2)/2, y+1.0, label or "%.2f" % abs(x2-x1), 7, "c")

    def dim_v(self, y1, y2, x, label=None, ext_from=None):
        if ext_from is not None:
            self.line(ext_from, y1, x-1.5, y1, THIN, col=GREY)
            self.line(ext_from, y2, x-1.5, y2, THIN, col=GREY)
        self.line(x, y1, x, y2, THIN); self.arrow(x, y1, 270); self.arrow(x, y2, 90)
        self.text(x-1.0, (y1+y2)/2, label or "%.2f" % abs(y2-y1), 7, "c", rot=90)

    def ord_x(self, x, y_feat, y_base, label):
        self.line(x, y_feat, x, y_base, THIN, col=GREY)
        self.arrow(x, y_base, 270, 1.5)
        self.text(x, y_base-2.0, label, 6.5, "r", rot=90)

    def ord_y(self, y, x_feat, x_base, label):
        self.line(x_feat, y, x_base, y, THIN, col=GREY)
        self.arrow(x_base, y, 180, 1.5)
        self.text(x_base-2.0, y, label, 6.5, "r")

    def datum(self, x, y, tag="0,0"):
        self.circle(x, y, 3.4, MED, RED)
        self.line(x-5.5, y, x+5.5, y, MED, col=RED)
        self.line(x, y-5.5, x, y+5.5, MED, col=RED)
        self.text(x+3.4, y+3.4, tag, 7, "l", col=RED, bold=True)


def ordinates(s, ox, oy, xvals, yvals, xtop, ybase_from, xb1=-22, xb2=-36, yb=-14):
    for x in sorted(xvals):
        s.ord_x(ox+x, oy-1, oy+yb, "%.2f" % x)
    s.line(ox-4, oy+yb, ox+xtop+4, oy+yb, THIN, col=GREY)
    for i, y in enumerate(sorted(yvals)):
        s.ord_y(oy+y, ox-1, ox+(xb1 if i % 2 == 0 else xb2), "%.2f" % y)
    s.line(ox+xb1, oy-4, ox+xb1, oy+ybase_from+4, THIN, col=GREY)
    s.line(ox+xb2, oy-4, ox+xb2, oy+ybase_from+4, THIN, col=GREY)


# ------------------------------------------------------------------- sheet 1
def sheet_pcb(c, n, of):
    s = Sheet(c, 420, 297, "PCB feature map, ordinate dimensions from datum", n, of)
    ox, oy = 150.0, 105.0
    s.rect(ox, oy, PCB_X, PCB_Y, THICK)

    for tag, x, y in HOLES:
        s.circle(ox+x, oy+y, PCB_HOLE_D, MED)
        s.circle(ox+x, oy+y, 4.57, THIN, GREY)
        s.cross(ox+x, oy+y, 6.5)
        s.text(ox+x+4.6, oy+y+4.6, tag, 7.5, bold=True)
    for tag, x, y in HOLES_XB:
        s.circle(ox+x, oy+y, PCB_HOLE_D, THIN, GREY)
        s.cross(ox+x, oy+y, 5, GREY)
        s.text(ox+x+3.8, oy+y+3.8, tag, 6, col=GREY)

    for ref, edge, p, w, form, a, b, name in CONNECTORS:
        if edge == "X-":
            s.line(ox-9, oy+p, ox+14, oy+p, MED, [3, 1.5], RED)
            s.line(ox-5, oy+p-w/2, ox-5, oy+p+w/2, THICK, col=RED)
            s.text(ox-8, oy+p+1.2, ref, 7, "r", col=RED, bold=True)
        elif edge == "X+":
            s.line(ox+PCB_X-14, oy+p, ox+PCB_X+9, oy+p, MED, [3, 1.5], RED)
            s.line(ox+PCB_X+5, oy+p-w/2, ox+PCB_X+5, oy+p+w/2, THICK, col=RED)
            s.text(ox+PCB_X+8, oy+p+1.2, ref, 7, "l", col=RED, bold=True)
        else:
            s.line(ox+p, oy+PCB_Y-14, ox+p, oy+PCB_Y+9, MED, [3, 1.5], RED)
            s.line(ox+p-w/2, oy+PCB_Y+5, ox+p+w/2, oy+PCB_Y+5, THICK, col=RED)
            s.text(ox+p+1.2, oy+PCB_Y+8, ref, 7, "l", col=RED, bold=True)
    for ref, edge, p, w, note in UNFITTED:
        if edge == "Y-":
            s.line(ox+p-w/2, oy+3.0, ox+p+w/2, oy+3.0, MED, [1.5, 1.5], GREY)
            s.text(ox+p, oy+4.4, ref, 6, "c", col=GREY)

    xv = ({0.0, PCB_X} | {x for _, x, _ in HOLES} | {x for _, x, _ in HOLES_XB} |
          {p for r, e, p, w, f, a, b, nm in CONNECTORS if e == "Y+"})
    yv = ({0.0, PCB_Y} | {y for _, _, y in HOLES} | {y for _, _, y in HOLES_XB} |
          {p for r, e, p, w, f, a, b, nm in CONNECTORS if e.startswith("X")})
    ordinates(s, ox, oy, xv, yv, PCB_X, PCB_Y)

    s.datum(ox, oy)
    s.dim_h(ox, ox+PCB_X, oy+PCB_Y+18, ext_from=oy+PCB_Y)
    s.dim_v(oy, oy+PCB_Y, ox+PCB_X+22, ext_from=ox+PCB_X)
    s.text(ox+PCB_X/2, oy+PCB_Y+26, "PCB OUTLINE  130.68 x 87.00 x 1.60", 10, "c", bold=True)

    # legend
    lx, ly = 22, 272
    s.text(lx, ly, "LEGEND", 8.5, bold=True); ly -= 6
    for ref, edge, p, w, form, a, b, name in CONNECTORS:
        s.text(lx, ly, ref, 7, col=RED, bold=True)
        how = ("bored %.2f dia, axis %.2f above the PCB top face, slotted vertically"
               % (a, b) if form == "round"
               else "slot %.2f to %.2f about the PCB top face" % (a, b))
        s.text(lx+10, ly, "%s   edge %s, centre %.2f, body %.2f wide, %s"
               % (name, edge, p, w, how), 7)
        ly -= 5.2
    ly -= 2
    for ref, edge, p, w, note in UNFITTED:
        s.text(lx, ly, ref, 7, col=GREY, bold=True)
        s.text(lx+10, ly, "%s   edge %s, centre %.2f" % (note, edge, p), 7, col=GREY)
        ly -= 5.2

    ny = 78
    for t in ["H1 to H4  mounting holes used by this case.  %.2f drill shown solid," % PCB_HOLE_D,
              "          0.180 in (4.57) DXF pad shown grey.  Nuand specify 2-56 screws,",
              "          so the drill is a #2 clearance.  Measure yours to confirm.",
              "X1 to X4  further DXF holes, most likely XB-200 standoffs.  Not used.",
              "Red        connector body centre and width at the board edge.",
              "Grey       features that get no wall opening."]:
        s.text(22, ny, t, 7.5); ny -= 5.2
    c.showPage()


# ------------------------------------------------------------------- sheet 2
def sheet_table(c, n, of):
    s = Sheet(c, 297, 210, "Feature schedule", n, of, scale="-")
    x0, y = 18, 176
    s.text(x0, y+8, "PCB FEATURES  (datum = bottom-left PCB corner)", 8.5, bold=True)
    for h in [("Ref", "Feature", "X", "Y", "Note")]:
        for cx, v in zip([0, 13, 62, 78, 95], h): s.text(x0+cx, y, v, 7.5, bold=True)
    s.line(x0, y-2, x0+128, y-2, MED); y -= 7
    rows = ([(t, "Mounting hole, case screw", hx, hy, "%.2f clr" % PCB_HOLE_D) for t, hx, hy in HOLES] +
            [(t, "Mounting hole, unused", hx, hy, "XB-200") for t, hx, hy in HOLES_XB] +
            [(r, nm, 0.0 if e == "X-" else (PCB_X if e == "X+" else p),
              p if e.startswith("X") else PCB_Y, "body %.2f" % w)
             for r, e, p, w, f, a, b, nm in CONNECTORS] +
            [(r, nt, 0.0 if e == "X-" else (PCB_X if e == "X+" else p),
              p if e.startswith("X") else 0.0, "no opening")
             for r, e, p, w, nt in UNFITTED])
    for r in rows:
        for cx, v in zip([0, 13, 62, 78, 95],
                         [r[0], r[1], "%.2f" % r[2], "%.2f" % r[3], r[4]]):
            s.text(x0+cx, y, v, 7.5)
        y -= 5.2

    x1, y1 = 160, 176
    s.text(x1, y1+8, "WALL OPENINGS  (datum = outside corner of the case)", 8.5, bold=True)
    cols = [0, 11, 24, 40, 54, 86]
    for cx, v in zip(cols, ["Ref", "Edge", "Form", "Centre", "Size", "Height range"]):
        s.text(x1+cx, y1, v, 7.5, bold=True)
    s.line(x1, y1-2, x1+118, y1-2, MED); y1 -= 7
    for o in openings():
        size = ("%.2f dia + %.2f slot" % (o["d"], o["zhi"] - o["zlo"])
                if o["form"] == "round" else "%.2f wide" % o["w"])
        for cx, v in zip(cols,
                         [o["ref"], o["edge"], o["form"], "%.2f" % o["c"], size,
                          "%.2f to %.2f" % (o["z0"], o["z1"])]):
            s.text(x1+cx, y1, v, 7.5)
        y1 -= 5.2
    y1 -= 3
    s.text(x1, y1, "Rectangular openings also get an outer relief pocket %.2f wider on"
           % RELIEF, 7); y1 -= 4.6
    s.text(x1, y1, "every side, %.2f deep, for cable overmoulds.  Bored holes get none."
           % (WALL-1.0), 7); y1 -= 4.6
    s.text(x1, y1, "C3 and C4 are bored on the SMA block centre, %.2f above the PCB top"
           % SMA_AXIS_Z, 7); y1 -= 4.6
    s.text(x1, y1, "face: a %.2f x %.2f block, %.2f up and %.2f down off the board."
           % (SMA_BODY_W, SMA_BLOCK_H, SMA_UP, SMA_DOWN), 7); y1 -= 4.6
    s.text(x1, y1, "Bored openings are drawn out into a vertical slot on the same "
                   "diameter: the round", 7); y1 -= 4.6
    s.text(x1, y1, "end stays on the connector axis and the far end sits on the "
                   "parting plane at %.2f," % SPLIT_Z, 7); y1 -= 4.6
    s.text(x1, y1, "so no half carries the arc's level tangent, which would print "
                   "unsupported on a", 7); y1 -= 4.6
    s.text(x1, y1, "wall that stands vertical on the bed.  The height range column "
                   "is the full slot.", 7); y1 -= 10

    s.text(x1, y1, "HEIGHT STACK-UP  (from outside of base floor)", 8.5, bold=True); y1 -= 7
    for lab, v in [("Outside of floor", 0.0), ("Inside of floor", FLOOR_T),
                   ("Insert bore floor", INSERT_Z0),
                   ("Screw tip, fully driven", TIP_Z),
                   ("Standoff top, PCB underside", PCB_Z0), ("PCB top surface", PCB_ZT),
                   ("Parting plane, base to lid", SPLIT_Z),
                   ("Head seat, recess floor", SEAT_Z),
                   ("Cavity ceiling", TOTAL_H-TOP_T), ("Outside of lid", TOTAL_H)]:
        s.text(x1+12, y1, lab, 7.5); s.text(x1+78, y1, "%.2f" % v, 7.5); y1 -= 5.2
    y2 = 62
    s.text(x0, y2, "CASE SUMMARY", 8.5, bold=True)
    s.line(x0, y2-2, x0+128, y2-2, MED); y2 -= 7
    for t in ["Overall %.2f x %.2f x %.2f" % (OUT_X, OUT_Y, TOTAL_H),
              "Cavity %.2f x %.2f,  wall %.2f,  corner R%.2f"
              % (CAV_X, CAV_Y, WALL, CORNER_R),
              "Outer edge chamfers  bottom %.2f, top %.2f, both 45 deg"
              % (CH_BOT, CH_TOP),
              "Fasteners  4 x %s x %.0f through lid into %s inserts, bore %.2f x %.2f deep"
              % (SCREW_NAME, SCREW_LEN, SCREW_NAME, INSERT_D, INSERT_H),
              "Head recess %.2f dia x %.2f deep, seat z %.2f, %.2f of thread in the insert"
              % (HEAD_D, CBORE_H, SEAT_Z, ENGAGE)]:
        s.text(x0, y2, t, 8, bold=t.startswith("Overall")); y2 -= 5.2
    c.showPage()


# ---------------------------------------------------------------- sheets 3, 4
def case_plan(c, n, of, which):
    s = Sheet(c, 420, 297,
              "Base, plan on inside face" if which == "base" else "Lid, plan on inside face",
              n, of)
    ox, oy = 150.0, 105.0
    s.rect(ox, oy, OUT_X, OUT_Y, THICK, r=CORNER_R)
    s.rect(ox+WALL, oy+WALL, CAV_X, CAV_Y, MED, r=max(CORNER_R-WALL, 0.6))
    s.rect(ox+PX, oy+PY, PCB_X, PCB_Y, THIN, [3, 2], GREY)
    s.text(ox+PX+2.5, oy+PY+PCB_Y-5, "PCB envelope", 6.5, col=GREY)

    for tag, hx, hy in HOLES:
        cx, cy = ox+PX+hx, oy+PY+hy
        if which == "base":
            s.circle(cx, cy, BOSS_D, MED); s.circle(cx, cy, INSERT_D, MED)
        else:
            s.circle(cx, cy, BOSS_D, MED); s.circle(cx, cy, SCREW_D, MED)
            s.circle(cx, cy, HEAD_D, THIN, GREY)
        s.cross(cx, cy, 7); s.text(cx+5.2, cy+5.2, tag, 7.5, bold=True)

    for o in openings():
        if o["edge"] == "X-":
            s.rect(ox-0.7, oy+o["c"]-o["w"]/2, WALL+1.4, o["w"], MED, col=RED)
            s.line(ox-9, oy+o["c"], ox+12, oy+o["c"], THIN, [3, 1.5], RED)
            s.text(ox-11, oy+o["c"]+1.2, o["ref"], 7, "r", col=RED, bold=True)
        elif o["edge"] == "X+":
            s.rect(ox+OUT_X-WALL-0.7, oy+o["c"]-o["w"]/2, WALL+1.4, o["w"], MED, col=RED)
            s.line(ox+OUT_X-12, oy+o["c"], ox+OUT_X+9, oy+o["c"], THIN, [3, 1.5], RED)
            s.text(ox+OUT_X+11, oy+o["c"]+1.2, o["ref"], 7, "l", col=RED, bold=True)
        else:
            s.rect(ox+o["c"]-o["w"]/2, oy+OUT_Y-WALL-0.7, o["w"], WALL+1.4, MED, col=RED)
            s.line(ox+o["c"], oy+OUT_Y-12, ox+o["c"], oy+OUT_Y+9, THIN, [3, 1.5], RED)
            s.text(ox+o["c"]+1.2, oy+OUT_Y+11, o["ref"], 7, "l", col=RED, bold=True)

    if which == "lid":
        nv = max(1, int((CAV_Y-34+VENT_GAP)//(VENT_W+VENT_GAP)))
        tot = nv*VENT_W + (nv-1)*VENT_GAP
        for i in range(nv):
            s.rect(ox+OUT_X/2-VENT_LEN/2, oy+OUT_Y/2-tot/2+i*(VENT_W+VENT_GAP),
                   VENT_LEN, VENT_W, THIN, col=GREY)
        s.text(ox+OUT_X/2, oy+OUT_Y/2+tot/2+3.5,
               "%d vent slots %.2f x %.2f, pitch %.2f" % (nv, VENT_W, VENT_LEN,
                                                          VENT_W+VENT_GAP), 6.5, "c", col=GREY)

    xv = {0.0, WALL, OUT_X-WALL, OUT_X} | {PX+hx for _, hx, _ in HOLES} | \
         {o["c"] for o in openings() if o["edge"] == "Y+"}
    yv = {0.0, WALL, OUT_Y-WALL, OUT_Y} | {PY+hy for _, _, hy in HOLES} | \
         {o["c"] for o in openings() if o["edge"].startswith("X")}
    ordinates(s, ox, oy, xv, yv, OUT_X, OUT_Y)

    s.datum(ox, oy, "0,0")
    s.dim_h(ox, ox+OUT_X, oy+OUT_Y+18, ext_from=oy+OUT_Y)
    s.dim_v(oy, oy+OUT_Y, ox+OUT_X+22, ext_from=ox+OUT_X)
    s.text(ox+OUT_X/2, oy+OUT_Y+26,
           "%s  %.2f x %.2f" % ("BASE" if which == "base" else "LID", OUT_X, OUT_Y),
           10, "c", bold=True)

    ny = 78
    notes = (["Standoff OD %.2f, height %.2f above the floor." % (BOSS_D, UNDER_PCB),
              "Insert bore %.2f dia x %.2f deep for %s heat-set inserts."
              % (INSERT_D, INSERT_H, SCREW_NAME),
              "Wall reduced to %.2f for the top %.2f to form the lip rebate."
              % (WALL - LIP_RELIEF - LIP_T - JOINT_CLR, LIP_H),
              "Base height %.2f. Floor %.2f." % (SPLIT_Z, FLOOR_T),
              "Bottom outer edge chamfered %.2f x 45 deg. See sheet 5." % CH_BOT]
             if which == "base" else
             ["Boss OD %.2f, from PCB top face to cavity ceiling." % BOSS_D,
              "Screw %.2f clr, head recess %.2f dia x %.2f deep, seat z %.2f, 45 deg cone under."
              % (SCREW_D, HEAD_D, CBORE_H, SEAT_Z),
              "Recess depth follows the %s x %.0f screw, not the plate thickness."
              % (SCREW_NAME, SCREW_LEN),
              "Tip stops %.2f above the insert bore floor, %.2f of thread engaged."
              % (TIP_CLR, ENGAGE),
              "Lip %.2f thick x %.2f deep, %.2f slip fit, %.2f relief off the cavity wall."
              % (LIP_T, LIP_H, JOINT_CLR, LIP_RELIEF),
              "Lid height %.2f above the parting plane. Top plate %.2f."
              % (TOTAL_H-SPLIT_Z, TOP_T),
              "Top outer edge chamfered %.2f x 45 deg. See sheet 5." % CH_TOP])
    s.text(22, ny+6, "NOTES", 8.5, bold=True)
    for t in notes:
        s.text(22, ny, t, 7.5); ny -= 5.2

    ly = 272
    s.text(22, ly, "OPENING REFS", 8.5, bold=True); ly -= 6
    for o in openings():
        s.text(22, ly, o["ref"], 7, col=RED, bold=True)
        how = ("%.2f dia slot, axis z %.2f, ends z %.2f and %.2f"
               % (o["d"], o["zc"], o["zlo"], o["zhi"]) if o["form"] == "round"
               else "%.2f wide, z %.2f to %.2f" % (o["w"], o["z0"], o["z1"]))
        s.text(32, ly, "%s   centre %.2f, %s" % (o["name"], o["c"], how), 7)
        ly -= 5.2
    c.showPage()


def edge_detail(s, ox, oy):
    """Corner sections of both chamfered edges, drawn at 8:1, side by side.

    Both details occupy the same horizontal band, oy to oy + BAND: the base
    detail grows upward off its bottom face, the lid detail hangs down off its
    top face.  Labels therefore line up along the top of the band.  Stacking
    them vertically does not fit - one detail is BAND tall on its own.
    """
    kd, Wd, Hd = 8.0, 11.0, 7.0
    band, gap = Hd * kd, 20.0
    dw = Wd * kd

    def corner(bx, ch, plate, label, up):
        """up=+1 draws a bottom edge, up=-1 draws a top edge."""
        d = lambda v: v * kd
        sg = up
        by = oy if up > 0 else oy + band        # y of the chamfered outer face
        pts = [(0, d(Hd) * sg), (0, d(ch) * sg), (d(ch), 0), (d(Wd), 0)]
        for a, b in zip(pts, pts[1:]):
            s.line(bx + a[0], by + a[1], bx + b[0], by + b[1], THICK)
        inner = [(d(Wd), d(plate) * sg), (d(WALL), d(plate) * sg), (d(WALL), d(Hd) * sg)]
        for a, b in zip(inner, inner[1:]):
            s.line(bx + a[0], by + a[1], bx + b[0], by + b[1], MED)
        # chamfer dimension and angle
        s.line(bx, by, bx + d(ch), by, THIN, [2, 1.5], GREY)
        s.line(bx, by, bx, by + d(ch) * sg, THIN, [2, 1.5], GREY)
        s.text(bx + d(ch) + 2, by + d(ch) / 2 * sg, "%.2f x 45 deg" % ch, 7, "l", col=RED)
        s.text(bx + d(WALL) + 2, by + d(plate) / 2 * sg, "%.2f" % plate, 6.5, "l", col=GREY)
        s.text(bx, oy + band + 4, label, 7.5, "l", bold=True)

    corner(ox, CH_BOT, FLOOR_T, "Base, bottom outer edge", +1)
    corner(ox + dw + gap, CH_TOP, TOP_T, "Lid, top outer edge", -1)
    s.text(ox, oy + band + 11, "DETAIL  OUTER EDGE CHAMFERS    8:1", 8.5, bold=True)
    s.text(ox, oy - 6, "Wall %.2f.  Parting line edges left sharp so the halves mate flush."
           % WALL, 7)


# ------------------------------------------------------------------- sheet 5
def sheet_section(c, n, of):
    s = Sheet(c, 420, 297, "Section through both SMA openings and one screw column",
              n, of, scale="2:1")
    k, ox, oy = 2.0, 120.0, 130.0
    X = lambda v: ox + v*k
    Y = lambda v: oy + v*k

    s.rect(X(0), Y(0), OUT_Y*k, FLOOR_T*k, MED)
    s.rect(X(0), Y(0), WALL*k, SPLIT_Z*k, MED)
    s.rect(X(OUT_Y-WALL), Y(0), WALL*k, SPLIT_Z*k, MED)
    s.rect(X(0), Y(SPLIT_Z), OUT_Y*k, (TOTAL_H-SPLIT_Z)*k, MED)
    s.rect(X(WALL), Y(SPLIT_Z), CAV_Y*k, (TOTAL_H-SPLIT_Z-TOP_T)*k, THIN, col=GREY)
    s.rect(X(PY), Y(PCB_Z0), PCB_Y*k, PCB_T*k, THICK)
    s.text(X(PY+PCB_Y/2), Y(PCB_Z0)-5, "PCB  %.2f thick" % PCB_T, 7.5, "c")

    hy = PY + HOLES[0][2]
    s.rect(X(hy-BOSS_D/2), Y(FLOOR_T), BOSS_D*k, UNDER_PCB*k, MED)
    s.rect(X(hy-(BOSS_D-0.5)/2), Y(PCB_ZT), (BOSS_D-0.5)*k, (TOTAL_H-TOP_T-PCB_ZT)*k, MED)
    s.rect(X(hy-INSERT_D/2), Y(INSERT_Z0), INSERT_D*k, INSERT_H*k, MED)
    s.rect(X(hy-HEAD_D/2), Y(SEAT_Z), HEAD_D*k, CBORE_H*k, MED)
    s.rect(X(hy-SCREW_D/2), Y(TIP_Z), SCREW_D*k, SCREW_LEN*k, THIN, [2, 1.5], RED)
    s.line(X(hy), Y(-4), X(hy), Y(TOTAL_H+4), THIN, [5, 2, 1, 2], RED)
    s.text(X(hy), Y(TOTAL_H+5), "%s x %.0f through-bolt, H1" % (SCREW_NAME, SCREW_LEN),
           7, "c", col=RED)

    for o in openings():
        if o["edge"] != "X+":
            continue
        if o["form"] == "round":
            # SMA body block, grey, so the bore can be read against it
            s.rect(X(o["c"]-SMA_BODY_W/2), Y(PCB_Z0-SMA_DOWN), SMA_BODY_W*k,
                   SMA_BLOCK_H*k, THIN, [2, 1.5], GREY)
            s.rect(X(o["c"]-o["d"]/2), Y(o["z0"]), o["d"]*k, (o["z1"]-o["z0"])*k,
                   MED, col=RED, r=o["d"]/2*k)
            s.cross(X(o["c"]), Y(o["zc"]), 5, RED)
            if o["zhi"] > o["zlo"]:
                s.cross(X(o["c"]), Y(o["zhi"] if o["zc"] == o["zlo"] else o["zlo"]),
                        5, RED)
            s.text(X(o["c"]), Y(o["z1"])+2.5,
                   "%s  %.2f dia slot" % (o["ref"], o["d"]), 7, "c", col=RED)
        else:
            s.rect(X(o["c"]-o["w"]/2), Y(o["z0"]), o["w"]*k, (o["z1"]-o["z0"])*k,
                   MED, [2, 1.5], RED)
            s.text(X(o["c"]), Y(o["z1"])+2.5, "%s  %.2f wide" % (o["ref"], o["w"]),
                   7, "c", col=RED)

    s.line(X(-8), Y(SPLIT_Z), X(OUT_Y+8), Y(SPLIT_Z), THIN, [6, 2, 1, 2], RED)
    s.text(X(OUT_Y+9), Y(SPLIT_Z), "parting plane", 7, "l", col=RED)

    for v, lab in [(0, "outside of floor"), (FLOOR_T, "inside of floor"),
                   (PCB_Z0, "PCB underside"), (PCB_ZT, "PCB top"),
                   (SPLIT_Z, "parting plane"), (TOTAL_H-TOP_T, "cavity ceiling"),
                   (TOTAL_H, "outside of lid")]:
        s.line(X(-7), Y(v), X(0), Y(v), THIN, col=GREY)
        s.text(X(-8), Y(v)-0.8, "%6.2f   %s" % (v, lab), 7, "r")

    s.dim_h(X(0), X(OUT_Y), Y(TOTAL_H)+14, "%.2f" % OUT_Y, ext_from=Y(TOTAL_H))
    s.dim_v(Y(0), Y(TOTAL_H), X(OUT_Y)+26, "%.2f" % TOTAL_H, ext_from=X(OUT_Y))
    edge_detail(s, 150, 212)

    s.text(22, 80, "Cut plane runs parallel to the short PCB edge, %.2f from the case "
                   "datum, through openings C3 and C4 and the H1 screw column." % (PX+HOLE_INSET),
           7.5)
    s.text(22, 74, "Drawn at 2:1. Values on the left are heights above the outside of the "
                   "base floor.", 7.5)
    s.text(22, 68, "%s x %.0f screw: head seat z %.2f, recess %.2f deep, tip z %.2f, %.2f of "
                   "thread inside the %.2f deep insert bore."
           % (SCREW_NAME, SCREW_LEN, SEAT_Z, CBORE_H, TIP_Z, ENGAGE, INSERT_H), 7.5)
    s.text(22, 62, "C3 and C4 bored %.2f dia about the SMA block centre, %.2f above the PCB "
                   "top face, then drawn up to the parting plane as a slot on the same "
                   "diameter. Grey dashed"
           % (SMA_HOLE_D, SMA_AXIS_Z), 7.5)
    s.text(22, 56, "outline is the %.2f x %.2f block, %.2f above and %.2f below the board. "
                   "Crosses mark the two slot end centres."
           % (SMA_BODY_W, SMA_BLOCK_H, SMA_UP, SMA_DOWN), 7.5)
    c.showPage()


# ------------------------------------------------------------------- sheet 6
def wall_elevation(s, ox, oy, tx, edge, span, sgn, axis, title):
    """One wall seen from outside the case, at 1:1, with its openings.

    sgn is the direction the datum axis runs across the page.  Looking at a face
    from outside puts +z up and the datum axis to the right only on X+; on X- and
    Y+ the axis reverses, because the eye has moved to the far side of the case.
    Rather than quietly mirror the numbers, every ordinate below a view is the
    true datum coordinate and the heading says which way it runs - so the figures
    read correctly whichever direction the face is drawn.
    """
    H = lambda v: ox + (v if sgn > 0 else span - v)
    top = oy + TOTAL_H

    # Silhouette.  The outer top and bottom edges are chamfered all round, so
    # face on they read as a band: full width between the two tangents, drawing
    # in by the chamfer at each end.
    s.line(ox+CH_BOT, oy, ox+span-CH_BOT, oy, THICK)
    s.line(ox+CH_TOP, top, ox+span-CH_TOP, top, THICK)
    for x0, x1 in ((ox, ox), (ox+span, ox+span)):
        s.line(x0, oy+CH_BOT, x1, top-CH_TOP, THICK)
    s.line(ox+CH_BOT, oy, ox, oy+CH_BOT, THICK)
    s.line(ox+span-CH_BOT, oy, ox+span, oy+CH_BOT, THICK)
    s.line(ox, top-CH_TOP, ox+CH_TOP, top, THICK)
    s.line(ox+span, top-CH_TOP, ox+span-CH_TOP, top, THICK)
    s.line(ox, oy+CH_BOT, ox+span, oy+CH_BOT, THIN, [2, 1.5], GREY)
    s.line(ox, top-CH_TOP, ox+span, top-CH_TOP, THIN, [2, 1.5], GREY)

    # Corner radius tangents: openings have to sit on the flat between these.
    for v in (CORNER_R, span-CORNER_R):
        s.line(ox+v, oy-2, ox+v, top+2, THIN, [2, 1.5], GREY)

    s.line(ox-6, oy+SPLIT_Z, ox+span+6, oy+SPLIT_Z, THIN, [6, 2, 1, 2], RED)
    s.text(ox+span+7, oy+SPLIT_Z-0.8, "parting", 6.5, "l", col=RED)

    for v in (0.0, SPLIT_Z, TOTAL_H):
        s.line(ox-6, oy+v, ox, oy+v, THIN, col=GREY)
        s.text(ox-7, oy+v-0.8, "%.2f" % v, 6.5, "r")

    here = [o for o in openings() if o["edge"] == edge]
    for o in here:
        if o["form"] == "round":
            s.rect(H(o["c"])-o["d"]/2, oy+o["z0"], o["d"], o["z1"]-o["z0"],
                   MED, col=RED, r=o["d"]/2)
        else:
            # shallow relief pocket in the outer skin, then the through opening
            s.rect(H(o["c"])-o["rw"]/2, oy+o["z0"]-RELIEF/2, o["rw"],
                   o["z1"]-o["z0"]+RELIEF, THIN, [2, 1.5], GREY)
            s.rect(H(o["c"])-o["w"]/2, oy+o["z0"], o["w"], o["z1"]-o["z0"], MED, col=RED)
        s.line(H(o["c"]), oy+o["z0"]-3, H(o["c"]), top+2.5, THIN, [3, 1.5], RED)
        s.text(H(o["c"]), top+3.5, o["ref"], 7.5, "c", col=RED, bold=True)

    vals = sorted({0.0, span} | {o["c"] for o in here})
    for v in vals:
        s.ord_x(H(v), oy-1, oy-13, "%.2f" % v)
    s.line(ox-4, oy-13, ox+span+4, oy-13, THIN, col=GREY)

    s.text(ox, top+14, title, 8.5, bold=True)
    s.text(ox, top+9, "Outside face at 1:1, %s to the %s" %
           (axis, "right" if sgn > 0 else "left"), 7, col=GREY)

    ty = top - 1
    for o in here:
        s.text(tx, ty, o["ref"], 7, col=RED, bold=True)
        s.text(tx+9, ty, o["name"], 7); ty -= 4.4
        size = ("%.2f dia slot, %.2f straight" % (o["d"], o["zhi"] - o["zlo"])
                if o["form"] == "round"
                else "%.2f wide, plus %.2f relief all round %.2f deep"
                     % (o["w"], RELIEF, WALL-1.0))
        s.text(tx+9, ty, "centre %s %.2f,  %s" % (axis[-1], o["c"], size), 6.5, col=GREY)
        ty -= 4.4
        s.text(tx+9, ty, "opening z %.2f to %.2f,  %s the parting plane"
               % (o["z0"], o["z1"],
                  "spans" if o["z0"] < SPLIT_Z < o["z1"] else
                  "below" if o["z1"] <= SPLIT_Z else "above"), 6.5, col=GREY)
        ty -= 7.0


def sheet_elevations(c, n, of):
    s = Sheet(c, 420, 297, "Outside elevations of the three connector walls", n, of)
    ox, tx = 62.0, 235.0
    walls = [(228.0, "X+", OUT_Y, +1, "+y", "WALL X+   short edge, SMA end"),
             (152.0, "X-", OUT_Y, -1, "+y", "WALL X-   short edge, USB and power end"),
             (76.0,  "Y+", OUT_X, -1, "+x", "WALL Y+   long edge, reference clock")]
    for oy, edge, span, sgn, axis, title in walls:
        wall_elevation(s, ox, oy, tx, edge, span, sgn, axis, title)

    ny = 68
    s.text(tx, ny+6, "NOTES", 8.5, bold=True)
    for t in ["Each wall is drawn as seen from outside the case, at 1:1, so the "
              "printed part can be held",
              "against the page.  Two of the three views therefore run their datum "
              "axis right to left;",
              "the figures under every view are absolute datum coordinates either way.",
              "Grey dashed verticals are the corner radius tangents - every opening "
              "must stay between",
              "them, on the flat.  Grey dashed horizontals are the %.2f bottom and "
              "%.2f top chamfer" % (CH_BOT, CH_TOP),
              "tangents.  Y- carries no opening; the expansion header stays inside "
              "the case.",
              "Material below the red parting line at %.2f is base, above it is lid."
              % SPLIT_Z]:
        s.text(tx, ny, t, 7); ny -= 4.6
    c.showPage()


# ------------------------------------------------------------------- sheet 7
def sheet_overlay(c, n, of):
    s = Sheet(c, 297, 210, "1:1 verification overlay", n, of,
              warn="PRINT AT 100 PERCENT, NO FIT TO PAGE")
    ox, oy = 84.0, 74.0
    s.rect(ox, oy, PCB_X, PCB_Y, THICK)
    for tag, hx, hy in HOLES:
        s.circle(ox+hx, oy+hy, PCB_HOLE_D, MED); s.cross(ox+hx, oy+hy, 8)
        s.text(ox+hx+5, oy+hy+5, tag, 7.5, bold=True)
    for tag, hx, hy in HOLES_XB:
        s.circle(ox+hx, oy+hy, PCB_HOLE_D, THIN, GREY); s.cross(ox+hx, oy+hy, 5.5, GREY)
        s.text(ox+hx+4, oy+hy+4, tag, 6, col=GREY)
    for ref, edge, p, w, form, a, b, name in CONNECTORS:
        if edge == "X-":
            s.line(ox-13, oy+p, ox+7, oy+p, MED, [3, 1.5], RED)
            s.line(ox-2.5, oy+p-w/2, ox-2.5, oy+p+w/2, THICK, col=RED)
            s.text(ox-14, oy+p+1.2, ref, 7, "r", col=RED, bold=True)
        elif edge == "X+":
            s.line(ox+PCB_X-7, oy+p, ox+PCB_X+13, oy+p, MED, [3, 1.5], RED)
            s.line(ox+PCB_X+2.5, oy+p-w/2, ox+PCB_X+2.5, oy+p+w/2, THICK, col=RED)
            s.text(ox+PCB_X+14, oy+p+1.2, ref, 7, "l", col=RED, bold=True)
        else:
            s.line(ox+p, oy+PCB_Y-7, ox+p, oy+PCB_Y+13, MED, [3, 1.5], RED)
            s.line(ox+p-w/2, oy+PCB_Y+2.5, ox+p+w/2, oy+PCB_Y+2.5, THICK, col=RED)
            s.text(ox+p+1.2, oy+PCB_Y+14, ref, 7, "l", col=RED, bold=True)
    s.datum(ox, oy)

    bx, by = 30, 56
    s.line(bx, by, bx+100, by, THICK)
    for i in range(11):
        s.line(bx+i*10, by, bx+i*10, by + (4.5 if i % 5 == 0 else 2.5), MED)
        if i % 5 == 0:
            s.text(bx+i*10, by+6, "%d" % (i*10), 7, "c")
    s.text(bx, by-6, "SCALE CHECK.  This bar must measure exactly 100.0 mm.", 8, bold=True)
    s.text(bx, by-11, "If it does not, reprint with scaling set to 100 percent or actual size.", 7.5)
    s.text(bx, by-17, "Lay the PCB on the outline. Every hole centre and connector "
                      "centreline should sit under its mark.", 7.5)
    s.text(bx, by-22, "Ticks outside the outline show connector body width; the dashed "
                      "line is its centre.", 7.5)
    c.showPage()


def main(path):
    del LAYOUT_WARNINGS[:]
    c = canvas.Canvas(path)
    c.setTitle("bladeRF x40 enclosure, dimensioned drawing set")
    sheet_pcb(c, 1, 7); sheet_table(c, 2, 7)
    case_plan(c, 3, 7, "base"); case_plan(c, 4, 7, "lid")
    sheet_section(c, 5, 7); sheet_elevations(c, 6, 7); sheet_overlay(c, 7, 7)
    c.save()
    for w in LAYOUT_WARNINGS:
        print("WARNING: " + w)
    return len(LAYOUT_WARNINGS)


if __name__ == "__main__":
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else "bladerf_x40_case_drawing.pdf")
