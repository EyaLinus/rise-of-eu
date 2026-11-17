"""Major rivers for the world map, as pixel art.

Courses are rough (lon, lat) traces, enough for an old-atlas look, not for navigation. They are
smoothed, given deterministic meanders and then rasterised one art pixel per map pixel (the same
grid as the terrain glyphs and city sprites): water widening from the source to the mouth, a dark
bank pixel on each side, a few light ripples on the broad rivers. Pixels in the sea are dropped.

Writes
  data/rivers.json                 meandered polylines (map_view draws them as thin lines when zoomed out)
  data/river_tiles.json            {"tile": T, "tiles": [[map_x, map_y, atlas_x, atlas_y], ...]}
  assets/art/map/rivers_atlas.png  only the T x T tiles that hold river pixels, packed (one texture, one batch)

Needs numpy + pillow. Run after changing tools/mapproj.py or the map:
    python3 tools/art/rivers.py
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from mapproj import proj  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")

# (name, width class 1-3, [(lon, lat), ...] from source to mouth)
RIVERS = [
    ("Donau", 3, [(8.2, 48.0), (10.0, 48.5), (12.1, 49.0), (13.5, 48.6), (16.4, 48.2), (17.1, 48.1), (18.9, 47.8), (19.0, 47.5), (18.9, 46.0), (19.3, 45.2), (20.5, 44.8), (22.5, 44.6), (23.0, 43.8), (25.0, 43.6), (27.0, 44.1), (28.0, 45.0), (28.8, 45.3), (29.6, 45.2)]),
    ("Rhein", 3, [(9.5, 47.5), (7.6, 47.6), (8.1, 48.6), (8.4, 49.0), (8.3, 50.0), (7.6, 50.3), (7.0, 50.9), (6.6, 51.6), (5.9, 51.9), (4.6, 51.9), (4.1, 52.0)]),
    ("Elbe", 2, [(15.5, 50.4), (14.4, 50.6), (13.7, 51.05), (12.0, 51.8), (11.6, 52.3), (10.0, 53.5), (8.9, 53.9)]),
    ("Oder", 2, [(17.9, 49.8), (17.0, 51.1), (15.5, 51.9), (14.6, 52.5), (14.3, 53.4)]),
    ("Weichsel", 2, [(18.9, 49.6), (20.0, 50.05), (21.7, 50.6), (21.0, 52.2), (19.0, 52.9), (18.6, 53.5), (18.9, 54.35)]),
    ("Düna", 2, [(32.0, 56.0), (28.0, 55.6), (26.5, 55.9), (24.5, 56.6), (24.1, 57.0)]),
    ("Dnister", 2, [(23.5, 49.4), (25.5, 48.6), (28.0, 47.5), (29.6, 46.4), (30.3, 46.1)]),
    ("Dnepr", 3, [(33.0, 55.0), (31.0, 54.0), (30.4, 52.0), (30.5, 50.5), (31.5, 49.4), (34.6, 48.5), (35.0, 47.8), (33.5, 46.8), (32.4, 46.5)]),
    ("Don", 2, [(38.2, 54.0), (39.0, 52.0), (40.5, 50.0), (43.0, 49.0), (43.5, 48.0), (41.0, 47.4), (39.3, 47.1)]),
    ("Wolga", 3, [(33.0, 57.0), (36.0, 57.0), (39.9, 57.6), (42.5, 57.8), (44.0, 56.3), (47.3, 55.9), (49.1, 55.6), (48.4, 53.2), (46.0, 51.5), (45.0, 49.5), (46.0, 48.0), (47.6, 46.6), (48.0, 46.1)]),
    ("Loire", 2, [(4.0, 45.0), (3.9, 46.5), (3.0, 47.4), (1.9, 47.9), (0.7, 47.4), (-0.5, 47.4), (-2.2, 47.25)]),
    ("Seine", 2, [(4.6, 47.8), (4.0, 48.3), (2.3, 48.8), (1.2, 49.3), (0.1, 49.45)]),
    ("Rhône", 2, [(6.5, 46.4), (5.8, 46.1), (4.8, 45.75), (4.8, 44.9), (4.6, 43.7), (4.8, 43.4)]),
    ("Po", 2, [(7.3, 44.7), (7.7, 45.1), (9.0, 45.1), (10.5, 45.0), (11.7, 44.9), (12.4, 44.95)]),
    ("Ebro", 2, [(-4.0, 43.0), (-2.4, 42.4), (-0.9, 41.65), (0.5, 41.0), (0.9, 40.7)]),
    ("Tajo", 2, [(-1.9, 40.4), (-3.6, 40.0), (-4.0, 39.85), (-6.4, 39.6), (-8.0, 39.4), (-9.1, 38.7)]),
    ("Guadalquivir", 1, [(-3.0, 38.0), (-4.8, 37.9), (-6.0, 37.4), (-6.35, 36.8)]),
    ("Themse", 1, [(-1.9, 51.7), (-1.2, 51.75), (-0.1, 51.5), (0.6, 51.5)]),
    ("Nil", 3, [(32.5, 9.6), (32.5, 15.6), (33.8, 17.6), (32.0, 18.0), (30.5, 19.5), (31.0, 21.5), (32.9, 24.1), (32.7, 26.0), (31.2, 27.2), (30.8, 29.0), (31.24, 30.04), (31.4, 30.6), (31.8, 31.4)]),
    ("Blauer Nil", 2, [(37.3, 11.8), (36.4, 10.8), (35.0, 11.0), (34.4, 12.2), (33.6, 13.6), (32.5, 15.6)]),
    ("Euphrat", 3, [(39.5, 39.7), (38.4, 38.4), (38.0, 37.0), (38.5, 36.0), (40.1, 35.3), (41.5, 34.4), (43.0, 33.4), (44.4, 32.4), (45.8, 31.2), (47.0, 30.9), (47.8, 30.5), (48.4, 29.9)]),
    ("Tigris", 2, [(40.2, 38.0), (41.0, 37.6), (42.5, 37.1), (43.1, 36.3), (43.6, 35.2), (44.3, 33.9), (44.4, 33.3), (45.6, 32.5), (47.2, 31.0), (47.6, 30.6)]),
    ("Niger", 3, [(-10.6, 9.0), (-8.0, 12.6), (-6.3, 13.6), (-4.2, 14.5), (-3.0, 16.8), (0.0, 16.3), (1.5, 14.4), (3.4, 11.8), (4.5, 10.0), (6.7, 7.8), (6.6, 5.0)]),
    ("Weißer Nil", 2, [(33.2, 0.4), (32.2, 1.8), (31.4, 3.4), (31.6, 5.5), (30.6, 7.5), (31.0, 9.0), (32.5, 9.6)]),
    ("Kongo", 3, [(26.5, -10.5), (27.0, -8.0), (26.5, -5.5), (25.9, -3.0), (25.2, 0.5), (23.0, 1.5), (21.0, 1.6), (18.3, 0.0), (17.0, -1.5), (15.3, -4.3), (13.5, -5.8), (12.3, -6.05)]),
    ("Ubangi", 2, [(26.0, 4.6), (22.5, 4.6), (18.6, 4.3), (17.8, 1.5), (17.6, -0.5)]),
    ("Kasai", 2, [(22.0, -11.5), (21.5, -8.0), (20.5, -5.5), (19.5, -4.0), (17.2, -3.2), (16.2, -3.4)]),
    ("Sambesi", 3, [(24.0, -11.5), (23.0, -14.5), (23.5, -17.5), (25.8, -17.9), (28.0, -16.8), (30.5, -15.6), (33.0, -16.2), (35.5, -17.6), (36.4, -18.6)]),
    ("Limpopo", 2, [(27.5, -24.5), (29.5, -22.2), (31.3, -22.4), (32.5, -24.5), (33.6, -25.2)]),
    ("Oranje", 2, [(28.5, -29.0), (25.5, -29.6), (22.5, -28.5), (20.0, -28.5), (17.5, -28.7), (16.5, -28.6)]),
    ("Benue", 2, [(13.6, 9.3), (12.4, 9.2), (9.7, 8.0), (6.75, 7.8)]),
    ("Schari", 1, [(20.0, 9.0), (17.5, 10.5), (15.0, 12.1), (14.4, 12.9)]),
    ("Schabelle", 1, [(42.8, 7.0), (44.5, 4.5), (45.5, 2.6), (44.4, 1.2)]),
    ("Juba", 1, [(41.8, 4.0), (42.6, 1.5), (42.5, -0.3)]),
    ("Cuanza", 1, [(17.0, -12.6), (15.6, -9.6), (13.4, -9.3)]),
    ("Okavango", 1, [(16.0, -13.0), (18.5, -17.8), (22.5, -19.3)]),
    ("Senegal", 2, [(-11.0, 14.4), (-12.3, 14.9), (-13.2, 16.0), (-14.4, 16.6), (-16.5, 16.0)]),
    ("Mississippi", 3, [(-95.0, 47.2), (-93.1, 44.9), (-91.2, 43.0), (-90.5, 41.5), (-90.2, 38.6), (-89.2, 37.0), (-90.0, 35.1), (-91.1, 33.0), (-91.2, 31.0), (-90.1, 30.0), (-89.4, 29.2)]),
    ("Ohio", 2, [(-80.0, 40.4), (-82.6, 38.6), (-84.5, 39.1), (-86.0, 38.0), (-88.0, 37.8), (-89.2, 37.0)]),
    ("Rio Grande", 2, [(-103.8, 29.4), (-101.0, 29.6), (-99.5, 27.5), (-97.2, 25.95)]),
    ("Hudson", 1, [(-73.9, 43.0), (-73.7, 42.6), (-74.0, 40.7)]),
    ("Sankt-Lorenz-Strom", 3, [(-76.4, 44.2), (-74.6, 45.0), (-73.5, 45.5), (-71.2, 46.8), (-70.0, 47.5)]),
]


TILE = 32
# art_profile.yaml palette: river_bank / river / river_light
BANK = (0x1e, 0x35, 0x52, 235)
WATER = (0x3b, 0x6e, 0x9e, 255)
LIGHT = (0x8c, 0xbd, 0xd6, 255)
MAX_HALF = {1: 0.9, 2: 1.3, 3: 1.8}  # half width of the water at the mouth, per width class (map px)


def _catmull(pts, step=3.0):
    """Smooth curve through the trace points, resampled every `step` px."""
    p = [pts[0]] + pts + [pts[-1]]
    out = []
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = (np.array(q, float) for q in p[i - 1:i + 3])
        n = max(2, int(np.linalg.norm(p2 - p1) / step))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(0.5 * (2 * p1 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(np.array(pts[-1], float))
    return np.array(out)


def _meander(c, seed):
    """Perpendicular wiggle (two wave lengths, random phases), zero at source and mouth."""
    rng = np.random.default_rng(seed)
    d = np.diff(c, axis=0)
    seg = np.linalg.norm(d, axis=1)
    s = np.concatenate([[0.0], np.cumsum(seg)])
    tang = np.gradient(c, axis=0)
    tang /= np.maximum(np.linalg.norm(tang, axis=1, keepdims=True), 1e-6)
    nrm = np.stack([-tang[:, 1], tang[:, 0]], axis=1)
    L = max(s[-1], 1.0)
    off = np.zeros(len(c))
    for wl, amp in ((70.0, 5.0), (23.0, 2.2), (9.0, 0.8)):
        ph = rng.uniform(0, 2 * np.pi)
        wl2 = wl * rng.uniform(0.8, 1.25)
        off += amp * np.sin(2 * np.pi * s / wl2 + ph + 0.6 * np.sin(s / (wl2 * 2.7)))
    env = np.clip(np.minimum(s, L - s) / 25.0, 0.0, 1.0)
    return c + nrm * (off * env)[:, None], s / L


def _land_mask(W, H):
    m = json.load(open(os.path.join(ROOT, "data", "map.json")))
    img = Image.new("L", (W, H), 0)
    dr = ImageDraw.Draw(img)
    for pd in m["provinces"]:
        for poly in pd["polys"]:
            dr.polygon([tuple(q) for q in poly], fill=1, outline=1)
    for poly in m["background"]:
        dr.polygon([tuple(q) for q in poly], fill=1, outline=1)
    land = np.array(img, bool)
    # one pixel into the sea, so mouths touch the coast
    grow = land.copy()
    grow[1:] |= land[:-1]; grow[:-1] |= land[1:]; grow[:, 1:] |= land[:, :-1]; grow[:, :-1] |= land[:, 1:]
    return land, grow


def main():
    m = json.load(open(os.path.join(ROOT, "data", "map.json")))
    W, H = m["size"]
    land, grow = _land_mask(W, H)
    water = np.zeros((H, W), bool)
    light = np.zeros((H, W), bool)
    out = []
    for idx, (name, w, pts) in enumerate(RIVERS):
        trace = [proj(lon, lat) for lon, lat in pts]
        c, t = _meander(_catmull(trace), 1009 + idx * 7919)
        out.append({"name": name, "w": w, "pts": [[round(float(x), 1), round(float(y), 1)] for x, y in c[::3]] + ([[round(float(c[-1][0]), 1), round(float(c[-1][1]), 1)]] if (len(c) - 1) % 3 else [])})
        # dense samples for the raster
        dense = []
        for i in range(len(c) - 1):
            n = max(1, int(np.linalg.norm(c[i + 1] - c[i]) / 0.35))
            for k in range(n):
                f = k / n
                dense.append((c[i] * (1 - f) + c[i + 1] * f, t[i] * (1 - f) + t[i + 1] * f))
        for q, tt in dense:
            r = 0.5 + (MAX_HALF[w] - 0.5) * (tt ** 0.6)
            x0, y0 = int(np.floor(q[0] - r)), int(np.floor(q[1] - r))
            for y in range(y0, int(np.ceil(q[1] + r)) + 1):
                for x in range(x0, int(np.ceil(q[0] + r)) + 1):
                    if 0 <= x < W and 0 <= y < H and (x + 0.5 - q[0]) ** 2 + (y + 0.5 - q[1]) ** 2 <= r * r + 0.15:
                        water[y, x] = True
        # ripples: short light dashes on the middle line of broad stretches
        for j, (q, tt) in enumerate(dense):
            r = 0.5 + (MAX_HALF[w] - 0.5) * (tt ** 0.6)
            if r >= 1.25 and (j // 9) % 4 == 0:
                light[int(q[1]), int(q[0])] = True
    water &= grow
    light &= water
    # keep ripples off the bank-side pixels (only where all 4 neighbours are water)
    inner = water.copy()
    inner[1:] &= water[:-1]; inner[:-1] &= water[1:]; inner[:, 1:] &= water[:, :-1]; inner[:, :-1] &= water[:, 1:]
    light &= inner
    bank = np.zeros_like(water)
    bank[1:] |= water[:-1]; bank[:-1] |= water[1:]; bank[:, 1:] |= water[:, :-1]; bank[:, :-1] |= water[:, 1:]
    bank &= ~water & land
    rgba = np.zeros((H, W, 4), np.uint8)
    rgba[bank] = BANK
    rgba[water] = WATER
    rgba[light] = LIGHT
    # pack the non-empty tiles into one atlas
    used = []
    for ty in range(0, H, TILE):
        for tx in range(0, W, TILE):
            if rgba[ty:ty + TILE, tx:tx + TILE, 3].any():
                used.append((tx, ty))
    cols = 64
    rows = (len(used) + cols - 1) // cols
    atlas = np.zeros((rows * TILE, cols * TILE, 4), np.uint8)
    tiles = []
    for i, (tx, ty) in enumerate(used):
        ax, ay = (i % cols) * TILE, (i // cols) * TILE
        part = rgba[ty:ty + TILE, tx:tx + TILE]
        atlas[ay:ay + part.shape[0], ax:ax + part.shape[1]] = part
        tiles.append([tx, ty, ax, ay])
    Image.fromarray(atlas, "RGBA").save(os.path.join(ROOT, "assets", "art", "map", "rivers_atlas.png"), optimize=True)
    with open(os.path.join(ROOT, "data", "river_tiles.json"), "w") as f:
        json.dump({"tile": TILE, "tiles": tiles}, f, separators=(",", ":"))
    path = os.path.join(ROOT, "data", "rivers.json")
    with open(path, "w") as f:
        f.write("[\n" + ",\n".join(json.dumps(r, ensure_ascii=False, separators=(",", ":")) for r in out) + "\n]\n")
    print(len(out), "rivers ->", path, "|", len(tiles), "tiles, atlas", atlas.shape[1], "x", atlas.shape[0])


if __name__ == "__main__":
    main()
