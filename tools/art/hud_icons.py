"""HUD resource icons (16x16 grid). Writes assets/src/pixel/icons/<key>.txt. Run tools/build_art.sh after."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from pixlib import blank, paste, layer, stack, write, outline

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "src", "pixel", "icons")
ICONS = {}

# mil: two crossed swords, steel blades, gold guards, wood grips
def sword(mirror, outlined=True):
    g = blank()
    pts = []
    for i in range(8):
        pts += [(2 + i, 2 + i, "a"), (3 + i, 2 + i, "g")]
    pts += [(8, 11, "G"), (9, 11, "G"), (9, 10, "D"), (10, 10, "G"), (10, 9, "G"), (11, 9, "G"), (11, 8, "G")]
    pts += [(11, 11, "O"), (12, 12, "H"), (13, 13, "D")]
    for x, y, c in pts:
        if mirror:
            x = 15 - x
            c = {"a": "g", "g": "a"}.get(c, c)
        g[y][x] = c
    return outline(g) if outlined else g
ICONS["mil"] = (stack(sword(True), sword(False)), "mil – military power: crossed swords")

# adm: parchment scroll with rolled ends and text lines
ICONS["adm"] = (layer([
    ".QPPPPPPPPQ.",
    "QPPPPPPPPPPQ",
    ".QQQQQQQQQQ.",
    "..PPPPPPPP..",
    "..PQQQQQPP..",
    "..PPPPPPPP..",
    "..PQQQQPPP..",
    "..PPPPPPPP..",
    "..PQQQQQPP..",
    ".QPPPPPPPPQ.",
    "QPPPPPPPPPPQ",
    ".QQQQQQQQQQ.",
], 2, 2), "adm – administrative power: parchment scroll")

# claim: sealed charter, sheet with red wax seal and ribbon
ICONS["claim"] = (stack(layer([
    "PPPPPPPPP.",
    "PQQQQQQPP.",
    "PPPPPPPPP.",
    "PQQQQQPPP.",
    "PPPPPPPPP.",
    "PQQQQQQPP.",
    "PPPPPPPPP.",
    "PQQQPPPPP.",
    "PPPPPPPPP.",
    "PPPPPPPQQ.",
], 2, 2), layer([
    ".rR.",
    "rRRE",
    "RRRE",
    ".EE.",
    ".E.E",
], 9, 9)), "claim – territorial claim: charter with red wax seal")

# dip: white dove with olive twig
ICONS["dip"] = (layer([
    "........aw..",
    ".......aww..",
    "......awww..",
    ".....awwwa..",
    ".ww.awwwa...",
    "Dwwwwwwaw...",
    ".wwwwwwwwwa.",
    "..aawwwwwaaa",
    "L...aaaaa.a.",
    "lL..........",
    ".L..........",
], 2, 2), "dip – diplomatic power: dove")

# manpower: two soldiers, kettle helmets over parchment faces, red tunics
def soldier(ox, oy, t, s):
    return layer([
        "..aaag..",
        ".aaaaggd",
        "..PPPQ..",
        "..PPPQ..",
        "..QPQQ..",
        ".%s%s%s%s%s%s." % (t, t, t, t, t, s),
        "%s%s%s%s%s%s%s%s" % (t, t, t, t, t, t, s, s),
        "%s%s%s%s%s%s%s%s" % (t, t, t, t, t, t, s, s),
    ], ox, oy)
back = soldier(6, 2, "B", "N")
front = soldier(2, 6, "R", "E")
ICONS["manpower"] = (stack(back, front), "manpower – recruits: two helmeted soldiers")

# army: heater shield, steel rim, red field with gold cross (same shape language as army_marker)
ICONS["army"] = (layer([
    "aaaaaaaaaaaa",
    "aRRRRGGRRRRg",
    "arRRRGGRRREg",
    "arRRRGGRRREg",
    "aGGGGGGGGGDg",
    "aGGGGGDDDDDg",
    "arRRRGDRRREg",
    ".arRRGDRREg.",
    ".arRRGDRREg.",
    "..arRGDREg..",
    "...arGDEg...",
    "....aggg....",
], 2, 2), "army – regiments / force limit: heater shield with cross")

# ae: angry red face
ICONS["ae"] = (layer([
    "...rrrrr....",
    ".rrrRRRRRR..",
    ".rRRRRRRRRR.",
    "rRkRRRRRkRRE",
    "rRRkRRRkRRRE",
    "rRkkRRRkkRRE",
    "rRRRRRRRRRRE",
    "rRRRkkkkRRRE",
    ".RRkRRRRkRE.",
    ".RRRRRRRRRE.",
    "...EEEEEE...",
], 2, 2), "ae – aggressive expansion: angry red face")

# prestige: five-point gold star
ICONS["prestige"] = (layer([
    ".....Y......",
    ".....YG.....",
    "....YGGG....",
    "....YGGG....",
    "YYYYGGGGGGGD",
    ".YGGGGGGGGD.",
    "..YGGGGGGD..",
    "...YGGGGD...",
    "...YGGDGD...",
    "..YGGD.DGD..",
    "..YGD...DD..",
    "..YD.....D..",
], 2, 2), "prestige – gold star")

# dev: two houses, parchment walls, red roofs, wood doors
ICONS["dev"] = (stack(layer([
    "...rR...",
    "..rRRE..",
    ".rRRRRE.",
    "rRRRRRRE",
    ".PPPPPQ.",
    ".PQPPPQ.",
    ".PPPPPQ.",
    ".PPPPPQ.",
], 7, 2), layer([
    "...rR...",
    "..rRRE..",
    ".rRRRRE.",
    "rRRRRRRE",
    ".PPPPPQ.",
    ".PPOOPQ.",
    ".PPOOPQ.",
    ".PPOHPQ.",
], 2, 6)), "dev – development: two houses")

# fort: stone tower with crenellations and gate
ICONS["fort"] = (layer([
    "aa.aa.aa.ag",
    "aa.aa.aa.ag",
    "aaaaaaaaagg",
    ".aaagggggd.",
    ".aagggggdd.",
    ".agdgggdgd.",
    ".agggggggd.",
    ".aggHHHggd.",
    ".agHOOOHgd.",
    ".agHOOOHgd.",
    ".agHOOOHdd.",
], 2, 3), "fort – fortification: stone tower")

# date: hourglass, wood frame, sand in paper
ICONS["date"] = (layer([
    "oOOOOOOOH",
    ".oOOOOOH.",
    ".aPPPPPg.",
    "..aPPPg..",
    "...aPg...",
    "....P....",
    "...a.g...",
    "..a.P.g..",
    ".a.PPP.g.",
    ".oOOOOOH.",
    "oOOOOOOOH",
], 3, 2), "date – game date: hourglass")

# siege: flame
ICONS["siege"] = (layer([
    "....r.......",
    "....rr...r..",
    "...rRr...rr.",
    "...rRRr..rR.",
    "..rRRRRr.rR.",
    "..rRGRRRrRRE",
    ".rRRGGRRRRRE",
    ".rRGYGRRGRRE",
    "rRGYYGGRGGRE",
    "rRGYYYGGGRE.",
    ".RRGYYGGRRE.",
    "..EERRRRE...",
], 2, 2), "siege – siege / burning: flame")

# stability: classical column in four states (stab_0 crisis .. stab_3 golden age), 12 px tall shaft
def column(state):
    cap = "YGGGGGGGGD" if state == 3 else "aggggggggd"
    rows = [
        cap,
        ".aggggggd.",
        "..agagd...",
        "..agagd...",
        "..agagd...",
        "..agagd...",
        "..agagd...",
        "..agagd...",
        "..agagd...",
        ".aggggggd.",
        "aggggggggd",
    ]
    if state == 3:
        rows[1] = ".YGGGGGGD."
        rows[9] = ".YGGGGGGD."
        rows[10] = "YGGGGGGGGD"
    rows = [list(r) for r in rows]
    if state <= 1:  # crack running down the shaft
        for x, y in [(4, 3), (5, 4), (4, 5), (4, 6), (5, 7)]:
            rows[y][x] = "k"
    if state == 0:  # top broken off, rubble at the foot
        rows[0] = list("..........")
        rows[1] = list("..........")
        rows[2] = list("...ag.....")
        rows[3] = list("..aggd....")
    return ["".join(r) for r in rows]

for st in range(4):
    lay = [layer(column(st), 3, 3 if st else 3)]
    if st == 3:  # green laurel sprigs on both sides
        lay.append(layer([".l", "lL", ".L", "lL", ".F"], 1, 5))
        lay.append(layer(["l.", "Ll", "L.", "Ll", "F."], 13, 5))
    if st == 0:  # broken drum lying at the foot, red glow of unrest
        lay.append(layer([".r.", "rR.", "rGR", "RYR", "EEE"], 11, 9))
        lay.append(layer(["ag", "gd"], 1, 12))
    ICONS["stab_%d" % st] = (stack(*lay), "stab_%d – stability level %d of 4: %s" % (st, st, ["broken column (crisis)", "cracked column (unrest)", "intact column (stable)", "gilded column with laurel (golden age)"][st]))

if __name__ == "__main__":
  os.makedirs(OUT, exist_ok=True)
  for key, (g, comment) in ICONS.items():
    write(os.path.join(OUT, key + ".txt"), g, comment + "\n16x16 grid, export x2 = 32 px. Generated by tools/art/hud_icons.py")
  print(" ".join(ICONS))
