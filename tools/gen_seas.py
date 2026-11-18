"""Splits the water of the map into sea regions and lists their coastal provinces: writes data/seas.json.

Each sea grows from a few seed points (lon, lat) over the water pixels (nearest seed wins);
a coastal province (data/coastal.json) borders every sea that touches it. Sea crossings
(data/straits.json) belong to the sea at their midpoint. Run after changing the map:
    python3 tools/gen_seas.py
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "art"))
from map_terrain import proj  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "data", "seas.json")

# id, name, label position (lon, lat), seed points (lon, lat) in open water
SEAS = [
    ("north", "Nordsee", (3.0, 56.0), [(3.0, 56.0), (6.0, 54.5), (1.5, 58.5), (4.5, 59.5), (-1.0, 60.0)]),
    ("channel", "Ärmelkanal", (-2.6, 50.0), [(-2.0, 50.0), (0.5, 50.3), (-4.5, 49.6), (1.6, 51.0)]),
    ("irish", "Irische See", (-5.0, 53.8), [(-5.0, 53.8), (-4.8, 52.0), (-5.5, 55.0)]),
    ("atlantic", "Atlantik", (-10.5, 44.0), [(-10.5, 44.0), (-4.0, 45.5), (-11.0, 52.0), (-10.5, 38.0), (-10.0, 33.0), (-8.0, 57.5), (-7.0, 36.3)]),
    ("baltic", "Ostsee", (19.0, 56.5), [(19.0, 56.5), (14.0, 54.8), (20.0, 59.0), (25.0, 59.6), (21.0, 62.0), (11.2, 56.5), (23.0, 57.5)]),
    ("west_med", "Westliches Mittelmeer", (5.5, 39.5), [(5.5, 39.5), (2.0, 37.5), (-2.5, 36.2), (5.0, 42.5), (10.0, 39.5), (12.0, 40.5), (9.5, 43.5), (11.5, 37.5)]),
    ("adriatic", "Adria", (15.5, 42.8), [(15.5, 42.8), (13.0, 44.8), (18.0, 41.5)]),
    ("east_med", "Östliches Mittelmeer", (24.0, 34.0), [(18.5, 37.0), (24.0, 34.0), (30.0, 33.5), (33.5, 34.5), (19.0, 33.0), (15.0, 35.0), (35.0, 36.2), (32.4, 31.7), (34.2, 32.0)]),
    ("aegean", "Ägäis", (25.0, 38.5), [(25.0, 38.5), (25.5, 40.2), (28.0, 40.7), (26.5, 36.8)]),
    ("caspian", "Kaspisches Meer", (50.5, 42.0), [(50.5, 42.0), (51.0, 39.5), (50.0, 45.0)]),
    ("black", "Schwarzes Meer", (34.0, 43.3), [(34.0, 43.3), (30.5, 43.0), (38.0, 42.5), (35.5, 45.5), (40.5, 42.0), (31.5, 45.5)]),
    # the New World and the open ocean (lon -35..-12 is open water drawn between the two land windows)
    ("ocean", "Offener Atlantik", (-18.0, 40.0), [(-18.0, 40.0), (-18.0, 50.0), (-19.0, 30.0), (-22.0, 20.0), (-22.0, 12.0), (-22.0, 6.0), (-20.0, 58.0), (-14.0, 62.0)]),
    # West Africa: the coast down to Sierra Leone is known from the start, the Gulf of Guinea is not
    ("west_africa", "Westafrikanische Küste", (-19.0, 17.0), [(-18.6, 21.5), (-18.2, 17.5), (-17.9, 13.5), (-16.8, 10.6), (-14.6, 8.2), (-15.5, 25.0)]),
    ("guinea", "Golf von Guinea", (-2.0, 4.6), [(-11.0, 5.2), (-7.5, 4.4), (-3.0, 4.4), (1.0, 5.3), (4.0, 4.6), (7.5, 4.2)]),
    # the Middle East: known from the start (Old World); the Persian Gulf reaches the Arabian Sea through Hormuz, east of the map
    ("red_sea", "Rotes Meer", (38.4, 20.6), [(38.4, 20.6), (35.6, 25.5), (40.4, 17.6), (42.2, 14.8), (33.0, 28.6), (34.6, 28.4), (36.6, 23.0)]),
    ("aden", "Golf von Aden", (48.0, 12.6), [(46.0, 12.4), (48.5, 13.0), (51.0, 13.4), (44.0, 12.0)]),
    ("arabian", "Arabisches Meer", (53.5, 11.0), [(53.5, 11.0), (53.0, 8.0), (50.0, 6.0), (55.0, 15.5), (48.5, 4.5), (55.0, 5.0)]),
    ("persian_gulf", "Persischer Golf", (51.4, 27.2), [(51.4, 27.2), (49.6, 28.6), (52.4, 25.6), (54.6, 25.9), (50.6, 26.4), (48.8, 29.6)]),
    # Africa south of the equator: unknown to Europe until explored; the Swahili coast is known to the
    # monsoon traders of Arabia (Colonial.MONSOON) and to the Swahili towns themselves
    ("south_atlantic", "Südatlantik", (6.0, -14.0), [(8.0, -1.0), (5.0, -4.0), (10.5, -8.0), (11.0, -14.0), (11.5, -20.0), (13.0, -26.0), (15.0, -31.0),
                                                   (0.0, -15.0), (-1.0, -5.0), (-4.0, -22.0), (-6.0, -32.0), (4.0, -26.0), (-3.0, -40.0), (8.0, -42.0)]),
    ("cape", "Kap der Guten Hoffnung", (22.0, -35.0), [(18.0, -35.2), (21.0, -35.3), (25.0, -34.6), (28.5, -33.8), (31.0, -31.8), (15.5, -34.8)]),
    ("mozambique", "Straße von Mosambik", (41.0, -20.0), [(41.0, -17.0), (38.0, -21.0), (41.5, -23.0), (36.5, -24.5), (42.5, -14.0), (34.5, -27.0), (40.0, -26.0)]),
    ("swahili", "Swahiliküste", (42.5, -4.0), [(41.5, -1.5), (40.5, -5.5), (41.0, -9.0), (43.5, -1.0), (44.5, -6.0), (46.5, 0.5), (41.2, -12.0)]),
    ("indian", "Indischer Ozean", (53.0, -18.0), [(52.0, -10.0), (52.0, -20.0), (50.0, -28.0), (54.5, -3.0), (45.0, -32.0), (53.5, -30.0)]),
    ("af_lakes", "Afrikanische Seen", (33.0, -1.0), [(33.0, -1.0), (29.6, -6.5), (34.5, -12.0), (32.6, -2.2), (30.5, -8.0), (34.7, -10.5), (34.3, -13.6)]),
    ("labrador", "Labradorsee", (-50.0, 53.0), [(-50.0, 53.0), (-50.0, 47.0), (-54.0, 57.0), (-58.0, 59.5), (-52.0, 61.0), (-47.0, 50.0)]),
    ("st_lawrence", "Sankt-Lorenz-Golf", (-62.0, 48.4), [(-62.0, 48.4), (-66.0, 49.6), (-68.8, 48.4), (-61.0, 47.0), (-64.0, 47.0)]),
    ("east_coast", "Neuenglandküste", (-69.0, 41.0), [(-69.0, 41.0), (-66.0, 43.5), (-72.0, 39.6), (-74.2, 37.0), (-75.0, 34.4), (-78.4, 31.4), (-62.0, 43.0)]),
    ("sargasso", "Sargassosee", (-62.0, 30.0), [(-62.0, 30.0), (-56.0, 38.0), (-55.0, 25.0), (-68.0, 26.0), (-73.0, 27.5), (-50.0, 32.0)]),
    ("caribbean", "Karibik", (-75.0, 15.0), [(-75.0, 15.0), (-80.0, 13.0), (-68.0, 14.0), (-63.0, 12.5), (-82.0, 17.0), (-86.0, 18.0), (-58.0, 15.0), (-79.0, 10.5)]),
    ("gulf", "Golf von Mexiko", (-90.0, 25.0), [(-90.0, 25.0), (-94.5, 23.0), (-86.0, 27.0), (-95.0, 27.5), (-84.0, 24.6), (-92.5, 20.5), (-88.5, 29.6)]),
    ("pacific", "Südsee", (-98.0, 13.0), [(-80.4, 4.0), (-86.0, 3.0), (-98.0, 13.0), (-102.5, 17.0), (-93.0, 13.5), (-88.0, 11.0), (-84.0, 8.0), (-80.0, 7.8), (-104.0, 19.5)]),
    ("hudson", "Hudsonbucht", (-86.0, 59.0), [(-86.0, 59.0), (-80.0, 56.5), (-80.0, 53.0), (-91.0, 60.0), (-71.0, 62.0), (-67.5, 59.0), (-84.0, 63.5)]),
    # South America (shifted New World coordinates: every longitude here is west of the Atlantic cut)
    ("guiana", "Guayanaküste", (-55.0, 8.0), [(-57.0, 8.0), (-53.0, 6.6), (-59.6, 9.4), (-50.0, 5.0), (-55.0, 10.5)]),
    ("amazon", "Amazonasmündung", (-44.0, 1.0), [(-47.0, 1.2), (-43.0, -1.0), (-39.0, -2.4), (-36.2, -4.2), (-48.6, 3.0), (-42.0, 2.0)]),
    ("brazil", "Brasilianische Küste", (-35.8, -14.0), [(-34.6, -9.6), (-35.6, -11.6), (-36.6, -13.6), (-37.6, -17.0), (-38.6, -20.6), (-35.2, -16.0)]),
    ("plata", "Südbrasilien und La Plata", (-46.0, -29.0), [(-41.8, -24.2), (-45.6, -26.4), (-47.6, -29.2), (-50.2, -32.4), (-53.2, -35.6), (-56.6, -36.6), (-44.0, -30.0)]),
    ("patagonian", "Patagonische See", (-60.0, -45.0), [(-57.0, -40.0), (-60.4, -44.0), (-63.0, -47.6), (-64.0, -51.6), (-60.0, -49.0), (-55.0, -45.0)]),
    ("horn", "Kap Hoorn", (-66.0, -55.8), [(-66.0, -56.0), (-70.0, -56.3), (-74.6, -55.2), (-62.0, -55.6), (-77.0, -53.0)]),
    ("humboldt", "Humboldtsee", (-80.0, -18.0), [(-81.8, -5.6), (-79.0, -12.0), (-76.0, -17.6), (-72.6, -23.6), (-73.6, -30.0), (-75.6, -36.0),
                                               (-77.0, -42.0), (-78.0, -48.0), (-81.6, -1.0), (-86.0, -12.0), (-86.0, -30.0), (-86.0, -46.0)]),
    # the North American Pacific coast (shifted west as part of the New World window)
    ("cortez", "Golf von Kalifornien", (-111.0, 27.6), [(-111.0, 27.6), (-112.8, 29.6), (-109.4, 25.0), (-110.2, 26.2), (-114.0, 31.0)]),
    ("california", "Kalifornische See", (-121.5, 33.0), [(-118.6, 32.4), (-121.5, 33.5), (-124.0, 36.6), (-116.6, 29.0), (-114.6, 26.0),
                                                      (-112.0, 22.6), (-126.6, 39.4), (-124.6, 31.0), (-120.0, 28.0), (-108.0, 21.0)]),
    ("cascadia", "Nordpazifik", (-126.6, 45.0), [(-125.6, 42.0), (-126.6, 45.0), (-127.2, 48.0), (-123.4, 48.6), (-124.2, 49.6), (-127.6, 50.6)]),
    ("lakes", "Große Seen", (-85.0, 45.0), [(-87.5, 47.6), (-87.0, 43.5), (-82.4, 44.6), (-81.2, 42.2), (-77.8, 43.6), (-97.5, 52.5)]),
]


# seas joined beyond the map edge
EXTRA_ADJ = [("persian_gulf", "arabian")]


def main():
    m = json.load(open(os.path.join(ROOT, "data", "map.json")))
    coastal = set(json.load(open(os.path.join(ROOT, "data", "coastal.json"))))
    W, H = int(math.ceil(m["size"][0])), int(math.ceil(m["size"][1]))
    land = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(land)
    for p in m["provinces"]:
        for poly in p["polys"]:
            d.polygon([tuple(c) for c in poly], fill=255)
    for poly in m["background"]:
        d.polygon([tuple(c) for c in poly], fill=255)
    water = np.asarray(land) == 0
    # nearest seed over water pixels
    seeds = []
    for i, s in enumerate(SEAS):
        for ll in s[3]:
            seeds.append((i, proj(*ll)))
    yy, xx = np.mgrid[0:H, 0:W]
    best = np.full((H, W), 1e12, np.float32)
    label = np.full((H, W), -1, np.int16)
    for i, (x, y) in seeds:
        dist = (xx - x) ** 2 + (yy - y) ** 2
        upd = dist < best
        best[upd] = dist[upd]
        label[upd] = i
    label[~water] = -1
    out = []
    members = {s[0]: [] for s in SEAS}
    for p in m["provinces"]:
        if p["key"] not in coastal:
            continue
        mask = Image.new("L", (W, H), 0)
        md = ImageDraw.Draw(mask)
        for poly in p["polys"]:
            md.polygon([tuple(c) for c in poly], fill=255)
        ring = ndimage.binary_dilation(np.asarray(mask) > 0, iterations=6)
        labs, counts = np.unique(label[ring & water], return_counts=True)
        tot = counts[labs >= 0].sum()
        for lab, c in zip(labs, counts):
            if lab >= 0 and c >= max(8, 0.12 * tot):
                members[SEAS[lab][0]].append(p["key"])
    centers = {p["key"]: p["center"] for p in m["provinces"]}
    straits = json.load(open(os.path.join(ROOT, "data", "straits.json")))
    strait_sea = {}
    for a, b in straits:
        x = (centers[a][0] + centers[b][0]) / 2
        y = (centers[a][1] + centers[b][1]) / 2
        # nearest water pixel's sea
        r = 0
        lab = -1
        while lab < 0 and r < 200:
            r += 4
            win = label[max(0, int(y) - r):int(y) + r, max(0, int(x) - r):int(x) + r]
            vals = win[win >= 0]
            if vals.size:
                lab = int(np.bincount(vals).argmax())
        strait_sea[a + "|" + b] = SEAS[lab][0]
    # neighbouring seas (their water touches): expeditions sail from a known sea to the next (Colonial)
    adj = {s[0]: set() for s in SEAS}
    for a, b in ((label[:, :-1], label[:, 1:]), (label[:-1, :], label[1:, :])):
        mask = (a >= 0) & (b >= 0) & (a != b)
        for x, y in set(zip(a[mask].tolist(), b[mask].tolist())):
            if {SEAS[x][0], SEAS[y][0]} in ({"caribbean", "pacific"}, {"guinea", "east_med"}, {"red_sea", "east_med"}, {"pacific", "ocean"}):  # map bottom edge; Suez lagoons
                continue
            if "af_lakes" in (SEAS[x][0], SEAS[y][0]):
                continue  # the African lakes are inland water
            if {SEAS[x][0], SEAS[y][0]} & {"humboldt", "pacific", "cortez", "california", "cascadia"} and {SEAS[x][0], SEAS[y][0]} & {"caribbean", "gulf", "guiana", "amazon", "ocean"}:
                continue  # the Pacific reaches the Atlantic only round Cape Horn (no Panama canal)
            if {SEAS[x][0], SEAS[y][0]} & {"south_atlantic", "cape"} and {SEAS[x][0], SEAS[y][0]} & {"pacific", "caribbean", "gulf", "sargasso", "humboldt"}:
                continue  # the map's empty south-west corner: no shortcut from the Americas to the Cape
            if "west_africa" in (SEAS[x][0], SEAS[y][0]) and {SEAS[x][0], SEAS[y][0]} & {"caribbean", "sargasso"}:
                continue  # the squeezed Atlantic puts them side by side; the way west is the open ocean
            adj[SEAS[x][0]].add(SEAS[y][0])
            adj[SEAS[y][0]].add(SEAS[x][0])
    for a, b in EXTRA_ADJ:
        adj[a].add(b)
        adj[b].add(a)
    for sid, name, lbl, _ in SEAS:
        out.append({"id": sid, "name": name, "center": [round(v, 1) for v in proj(*lbl)], "provinces": sorted(members[sid]),
                    "adj": sorted(adj[sid])})
    with open(OUT, "w") as f:
        f.write('{"seas": [\n' + ",\n".join(json.dumps(s, ensure_ascii=False) for s in out) + '\n],\n"straits": '
                + json.dumps(strait_sea, ensure_ascii=False, indent=0) + "}\n")
    write_fog(m, label, water)
    for s in out:
        print(s["id"], len(s["provinces"]), s["provinces"][:12])
    print(strait_sea)
    lone = [k for k in coastal if not any(k in s["provinces"] for s in out)]
    print("coastal without sea:", lone)


NEW_SEAS = {"guinea", "ocean", "labrador", "st_lawrence", "east_coast", "sargasso", "caribbean", "gulf", "pacific", "hudson", "lakes",
            "south_atlantic", "cape", "mozambique", "swahili", "indian", "af_lakes",
            "guiana", "amazon", "brazil", "plata", "patagonian", "horn", "humboldt", "cortez", "california", "cascadia"}
FOG_CELL = 8


def write_fog(m, label, water):
    """data/fog.json: a coarse grid (FOG_CELL px) over the map naming, for every cell that can be unknown,
    the New World province or sea it shows. The map view fogs the cells the player has not discovered.
    Background land takes the region of its nearest labelled neighbour. Rows are run-length encoded."""
    H, W = label.shape
    reg = np.zeros((H, W), np.int32)  # 0 = always known, else index + 1 into ids
    ids = []
    index = {}

    def rid(key):
        if key not in index:
            ids.append(key)
            index[key] = len(ids)
        return index[key]
    for i, s in enumerate(SEAS):
        if s[0] in NEW_SEAS:
            reg[(label == i) & water] = rid("s:" + s[0])
    old = np.zeros((H, W), bool)
    old[water & (reg == 0)] = True
    for p in m["provinces"]:
        mask = Image.new("L", (W, H), 0)
        md = ImageDraw.Draw(mask)
        for poly in p["polys"]:
            md.polygon([tuple(c) for c in poly], fill=255)
        mk = np.asarray(mask) > 0
        if p.get("nw"):
            reg[mk] = rid("p:%d" % p["id"])
        else:
            old[mk] = True
    # unlabelled background land: nearest labelled pixel (old world land stays known)
    known = (reg > 0) | old
    _, (iy, ix) = ndimage.distance_transform_edt(~known, return_indices=True)
    reg = np.where(known, reg, reg[iy, ix])
    reg[old] = 0
    gh, gw = H // FOG_CELL, W // FOG_CELL
    rows = []
    for gy in range(gh):
        # majority label per cell (sample the cell centre region)
        row = []
        for gx in range(gw):
            blk = reg[gy * FOG_CELL:(gy + 1) * FOG_CELL, gx * FOG_CELL:(gx + 1) * FOG_CELL].ravel()
            vals, cnt = np.unique(blk, return_counts=True)
            row.append(int(vals[cnt.argmax()]))
        rle = []
        for v in row:
            if rle and rle[-2] == v:
                rle[-1] += 1
            else:
                rle += [v, 1]
        rows.append(rle)
    with open(os.path.join(ROOT, "data", "fog.json"), "w") as f:
        json.dump({"cell": FOG_CELL, "w": gw, "h": gh, "ids": ids, "rows": rows}, f, separators=(",", ":"))
    print("fog grid", gw, "x", gh, "regions", len(ids))


if __name__ == "__main__":
    main()
