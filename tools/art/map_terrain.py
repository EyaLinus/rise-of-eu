"""Paints the map base texture assets/art/map/terrain.png from data/map.json.

Old-atlas look: deep-to-shallow sea with coastal ripple lines, parchment land with hillshade,
mountain ranges (real lon/lat polylines) as relief plus small peak glyphs, darker wasteland
outside the playable provinces. Colours come from the art_profile palette; noise only blends
between neighbouring ramp colours. Needs numpy, scipy, pillow, pyyaml.

    python3 tools/art/map_terrain.py [--jobs 4] [--only terrain_3_1.png]

writes one PNG per map.json "terrain_tiles" entry (2048 px grid cells with land nearby). Every tile is painted
on its own with a margin, so memory stays small however large the world gets; the noise is a function of
the map position (value-noise lattices shared by all tiles), so the tiles fit seamlessly. Open sea fades to
the plain deep-sea colour away from the coasts, which is also what the map view draws where no tile is.
"""
import json
import math
import os
import sys

import numpy as np
import yaml
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT_DIR = os.path.join(ROOT, "assets", "art", "map")

# shared with tools/gen_map.py
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from mapproj import COSLAT, LAT0, LON0, SCALE, proj  # noqa: E402,F401


# rough ridge lines (lon, lat); height = relative strength
RANGES = [
    (1.0, [(5.6, 44.2), (6.9, 45.6), (7.8, 46.0), (9.0, 46.5), (10.6, 46.7), (12.4, 47.0), (14.0, 47.2), (15.6, 47.4)]),  # Alps
    (0.8, [(-1.8, 43.1), (0.0, 42.8), (1.5, 42.6), (2.8, 42.5)]),  # Pyrenees
    (0.75, [(17.4, 48.8), (19.5, 49.3), (21.5, 49.2), (23.5, 48.5), (24.8, 47.6), (25.6, 46.4), (25.4, 45.5), (24.0, 45.4), (22.6, 45.3), (22.2, 44.7)]),  # Carpathians
    (0.6, [(14.6, 45.4), (16.0, 44.4), (17.6, 43.6), (19.0, 42.8), (20.2, 42.2), (21.0, 41.4), (21.6, 40.2), (22.0, 39.2)]),  # Dinarides, Pindus
    (0.55, [(22.4, 43.3), (24.0, 42.9), (25.6, 42.8), (27.0, 42.7)]),  # Balkan mountains
    (0.55, [(8.4, 44.4), (10.4, 44.2), (12.4, 43.3), (13.6, 42.4), (14.8, 41.4), (15.8, 40.4), (16.2, 39.3)]),  # Apennines
    (0.5, [(-7.2, 43.0), (-5.6, 43.1), (-4.0, 43.1)]),  # Cantabrian
    (0.45, [(-6.4, 40.3), (-5.0, 40.4), (-3.6, 40.9)]),  # Sistema Central
    (0.5, [(-4.2, 37.1), (-3.0, 37.1), (-2.4, 37.2)]),  # Sierra Nevada
    (0.35, [(2.6, 45.6), (3.0, 45.0), (3.6, 44.4)]),  # Massif Central
    (0.4, [(12.3, 50.4), (13.6, 50.7), (15.4, 50.8), (16.6, 50.4), (17.4, 50.1)]),  # Ore, Sudetes
    (0.3, [(12.8, 49.4), (13.6, 48.9)]),  # Bohemian Forest
    (0.6, [(5.8, 58.8), (7.4, 60.4), (9.0, 61.6), (11.6, 62.4), (13.2, 63.0)]),  # Scandes
    (0.4, [(-5.6, 56.6), (-4.6, 57.2), (-3.8, 57.6)]),  # Highlands
    (0.35, [(-3.8, 52.0), (-3.6, 53.0)]),  # Cambrian
    (0.4, [(8.6, 40.0), (9.2, 40.6), (9.0, 42.2)]),  # Sardinia/Corsica
    (0.35, [(14.4, 37.8), (15.0, 37.7)]),  # Etna
    (0.7, [(29.5, 36.9), (31.5, 37.2), (33.0, 36.9), (34.8, 37.3), (36.2, 37.9), (38.0, 38.3), (40.0, 38.4), (42.5, 38.2)]),  # Taurus
    (0.5, [(31.0, 40.9), (33.5, 41.0), (36.0, 40.8), (38.5, 40.6), (40.5, 40.7), (42.0, 41.0)]),  # Pontic
    (0.9, [(37.8, 44.6), (40.0, 43.6), (42.4, 43.0), (44.4, 42.7), (46.4, 42.0), (48.4, 41.2)]),  # Greater Caucasus
    (0.6, [(43.0, 37.4), (44.6, 36.8), (45.6, 35.6), (46.6, 34.4)]),  # Zagros
    (0.4, [(35.9, 33.6), (36.2, 34.2), (36.4, 34.7)]),  # Lebanon
    (0.8, [(-9.4, 30.8), (-7.8, 31.2), (-6.0, 32.0), (-4.6, 32.6), (-3.0, 33.0)]),  # High Atlas
    (0.5, [(-5.6, 33.4), (-4.2, 33.8), (-3.0, 34.2)]),  # Middle Atlas
    (0.45, [(-1.5, 34.6), (1.0, 35.2), (3.4, 36.3), (5.4, 36.4), (7.0, 35.4), (8.6, 35.2)]),  # Tell Atlas
    (0.3, [(24.6, 35.2), (25.6, 35.2)]),  # Crete
    # the Middle East and the Horn of Africa
    (0.65, [(46.6, 34.4), (47.8, 33.2), (49.4, 31.8), (51.0, 30.6), (52.6, 29.3), (54.4, 28.4)]),  # southern Zagros
    (0.85, [(48.9, 37.6), (50.4, 36.7), (52.0, 36.0), (53.6, 36.2), (55.2, 36.7)]),  # Alborz
    (0.9, [(39.5, 14.8), (38.6, 13.4), (38.3, 12.0), (38.8, 10.6), (39.4, 9.4), (38.6, 8.0)]),  # Ethiopian highlands, Simien
    (0.55, [(37.0, 11.4), (37.7, 10.4)]),  # Choke (Gojjam)
    (0.7, [(43.8, 13.4), (44.1, 15.0), (43.6, 16.6), (42.6, 18.4), (41.4, 20.2), (40.4, 21.6)]),  # Yemen highlands, Sarawat
    (0.35, [(40.0, 22.8), (38.8, 24.6), (36.8, 27.4), (35.4, 29.0)]),  # Hejaz
    (0.3, [(34.6, 25.0), (35.6, 22.5), (36.6, 20.0)]),  # Red Sea hills
    (0.45, [(41.2, 9.4), (43.0, 9.8), (45.4, 10.0), (47.4, 10.5), (49.0, 11.0)]),  # Harar plateau, Somali ridge
    (0.3, [(53.2, 17.3), (54.6, 17.4)]),  # Dhofar
    # Africa south of the Sahara
    (0.5, [(17.2, 21.6), (18.2, 20.8), (19.0, 20.2)]),  # Tibesti
    (0.3, [(8.4, 18.8), (8.8, 17.6)]),  # Aïr
    (0.4, [(9.2, 4.2), (10.2, 5.6), (11.5, 6.6), (13.5, 7.3)]),  # Cameroon line, Adamawa
    (0.35, [(23.0, 13.4), (24.2, 13.0)]),  # Jebel Marra
    (0.55, [(29.9, 0.8), (29.9, 0.0), (29.4, -1.5)]),  # Rwenzori, Virunga
    (0.75, [(35.8, 1.0), (36.6, 0.0), (37.3, -0.2), (37.0, -2.0), (37.35, -3.1)]),  # Kenyan highlands, Kilimanjaro
    (0.35, [(34.5, -8.0), (34.2, -9.6), (33.8, -11.0)]),  # southern highlands, Livingstone
    (0.4, [(32.7, -18.0), (32.9, -19.6)]),  # Eastern Highlands (Zimbabwe)
    (0.7, [(27.4, -31.0), (28.4, -30.0), (29.2, -29.2), (29.6, -28.4), (30.4, -27.0), (30.9, -25.6)]),  # Drakensberg
    (0.4, [(19.4, -33.4), (21.0, -33.6), (23.0, -33.5), (24.8, -33.4)]),  # Cape Fold Belt
    (0.35, [(14.6, -19.6), (15.6, -22.2), (16.4, -25.0), (17.0, -27.4)]),  # Namib escarpment
    (0.3, [(15.0, -11.6), (15.6, -13.0)]),  # Bié plateau
    (0.5, [(49.0, -13.6), (48.2, -16.4), (47.4, -18.8), (46.9, -21.4), (46.6, -23.6)]),  # Madagascar highlands
    # the New World
    (0.55, [(-84.6, 34.4), (-83.0, 35.6), (-81.4, 36.6), (-79.8, 38.0), (-78.4, 39.6), (-76.8, 41.0), (-75.0, 42.0), (-73.8, 43.4), (-72.2, 44.4), (-70.8, 45.0)]),  # Appalachians
    (0.35, [(-74.6, 44.0), (-74.0, 44.4)]),  # Adirondacks
    (0.85, [(-100.8, 22.2), (-100.2, 23.8), (-100.6, 25.4), (-101.8, 26.8), (-102.8, 28.6)]),  # Sierra Madre Oriental
    (0.85, [(-104.4, 21.4), (-105.0, 23.4), (-105.9, 25.4), (-107.0, 27.4), (-108.2, 29.4), (-108.8, 31.0)]),  # Sierra Madre Occidental
    (1.0, [(-105.6, 35.6), (-105.8, 37.4), (-106.0, 38.8), (-106.4, 40.4), (-107.4, 42.0), (-109.6, 43.2), (-110.6, 44.6),
           (-112.2, 46.2), (-113.8, 48.0), (-115.2, 49.6), (-116.8, 51.2), (-118.6, 53.0), (-120.6, 54.8), (-122.6, 56.6), (-124.4, 58.4)]),  # Rocky Mountains
    (0.6, [(-111.6, 39.6), (-111.6, 41.0), (-111.2, 42.4)]),  # Wasatch
    (0.55, [(-110.8, 40.6), (-109.4, 40.8)]),  # Uinta
    (0.65, [(-116.0, 44.8), (-115.0, 45.6), (-114.6, 46.8)]),  # Bitterroot, Salmon River
    (0.95, [(-118.0, 35.4), (-118.6, 36.6), (-119.4, 37.6), (-120.2, 38.6), (-121.0, 39.8)]),  # Sierra Nevada (California)
    (0.85, [(-121.4, 40.6), (-121.6, 42.2), (-121.8, 43.8), (-121.8, 45.4), (-121.6, 46.8), (-121.2, 48.4), (-121.6, 49.6)]),  # Cascades
    (0.5, [(-123.4, 40.0), (-123.0, 41.2), (-123.4, 42.4)]),  # Klamath, Coast Range
    (0.45, [(-117.0, 34.2), (-116.4, 33.4), (-115.8, 31.8), (-115.4, 30.4), (-114.0, 28.6), (-112.4, 26.4), (-110.4, 23.8)]),  # Peninsular ranges, Baja
    (0.7, [(-123.2, 49.8), (-124.4, 51.2), (-126.2, 52.6), (-127.6, 54.0)]),  # Coast Mountains
    (0.45, [(-111.6, 34.8), (-109.8, 34.0), (-108.6, 33.4)]),  # Mogollon rim
    (1.0, [(-103.4, 19.6), (-101.6, 19.4), (-99.8, 19.2), (-98.6, 19.0), (-97.3, 19.0)]),  # Trans-Mexican volcanic belt
    (0.75, [(-98.8, 17.4), (-97.4, 17.0), (-96.2, 16.8), (-95.2, 16.6)]),  # Sierra Madre del Sur
    (0.8, [(-93.4, 16.0), (-91.8, 15.2), (-90.0, 14.6), (-88.4, 14.0), (-86.6, 13.4), (-85.6, 12.2), (-84.4, 10.2), (-82.8, 9.0)]),  # Central American cordillera
    (0.45, [(-103.6, 30.4), (-102.6, 31.2), (-103.4, 32.4)]),  # Davis / Guadalupe
    (0.35, [(-94.4, 34.6), (-93.0, 34.8), (-92.4, 36.0)]),  # Ouachita / Ozarks
    (0.5, [(-77.0, 18.2), (-76.4, 18.1)]),  # Blue Mountains
    (0.55, [(-72.0, 19.0), (-71.0, 18.9), (-70.4, 19.0)]),  # Cordillera Central (Hispaniola)
    (0.4, [(-77.0, 20.0), (-75.8, 20.1)]),  # Sierra Maestra
    (0.4, [(-66.2, 49.0), (-65.4, 48.8)]),  # Chic-Chocs
    (0.4, [(-63.0, 56.6), (-63.6, 58.4), (-64.4, 59.6)]),  # Torngat
    # South America
    (0.6, [(-74.0, 10.6), (-73.4, 10.9)]),  # Sierra Nevada de Santa Marta
    (0.75, [(-77.6, 1.2), (-76.2, 3.6), (-75.6, 5.8), (-75.4, 7.2)]),  # Cordillera Central (Colombia)
    (0.7, [(-76.4, 2.0), (-74.6, 4.2), (-73.2, 6.2), (-72.6, 8.0), (-71.2, 8.8), (-70.0, 9.6)]),  # Cordillera Oriental, Mérida Andes
    (1.0, [(-78.0, 0.6), (-78.6, -1.4), (-79.0, -3.8), (-78.3, -6.4), (-77.5, -8.6), (-76.3, -10.4), (-74.9, -12.0), (-73.2, -13.6), (-71.3, -14.6), (-69.8, -15.6)]),  # the Andes of Ecuador and Peru
    (1.0, [(-73.4, -15.2), (-71.4, -16.6), (-69.8, -18.6), (-68.6, -21.6), (-68.4, -24.6), (-69.2, -27.6), (-70.0, -30.6), (-70.1, -33.0), (-70.6, -35.6), (-71.2, -38.2), (-71.8, -41.0)]),  # Cordillera Occidental, the Andes of Chile
    (0.7, [(-72.4, -44.0), (-73.0, -47.4), (-73.2, -50.4), (-72.4, -52.6), (-70.6, -54.4)]),  # Patagonian Andes
    (0.7, [(-68.0, -15.6), (-66.6, -17.6), (-65.6, -20.0), (-65.2, -23.0)]),  # Cordillera Oriental (Bolivia)
    (0.35, [(-64.8, -30.6), (-64.6, -32.8)]),  # Sierras de Córdoba
    (0.45, [(-64.0, 4.8), (-61.6, 5.2), (-60.6, 4.6)]),  # Guiana highlands, Roraima
    (0.45, [(-48.8, -25.6), (-46.4, -23.6), (-44.4, -22.8), (-42.4, -22.2)]),  # Serra do Mar
    (0.35, [(-44.0, -21.2), (-43.6, -18.6), (-42.6, -15.6)]),  # Mantiqueira, Espinhaço
    (0.3, [(-41.6, -12.8), (-41.0, -10.6)]),  # Chapada Diamantina
]


MARGIN = 256  # px painted around each tile (blurs, distances and noise fades must fit in it)
SEA_FLAT = 240.0  # px from land where the sea is the plain deep-sea colour (the view's background)


import world  # noqa: E402  (tools/world: ridges of the regions appended later)
for _r in world.REGIONS:
    RANGES = RANGES + _r.RANGES

def palette():
    prof = yaml.safe_load(open(os.path.join(ROOT, "art_profile.yaml")))
    return {k: np.array([int(v[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float32) for k, v in prof["palette"].items()}


class Noise:
    """Fractal value noise in [0,1] as a function of the map position: one random lattice per octave
    (cell size W / (base * 2^octave)), sampled with cubic splines; normalised by the global range."""

    def __init__(self, W, H, rng, octaves, base):
        self.layers = []
        amp = 1.0
        for o in range(octaves):
            c = W / (base * 2 ** o)
            grid = rng.random((int(H / c) + 6, int(W / c) + 6)).astype(np.float32)
            self.layers.append((c, amp, ndimage.spline_filter(grid, order=3)))
            amp *= 0.5
        self.tot = sum(a for _, a, _ in self.layers)
        coarse = self.raw(0, 0, W, H, step=16)
        self.lo, self.hi = float(coarse.min()), float(coarse.max())

    def raw(self, x0, y0, w, h, step=1):
        ys = (np.arange(y0, y0 + h, step, dtype=np.float32))
        xs = (np.arange(x0, x0 + w, step, dtype=np.float32))
        out = np.zeros((len(ys), len(xs)), np.float32)
        for c, amp, grid in self.layers:
            yy, xx = np.meshgrid(ys / c + 2.0, xs / c + 2.0, indexing="ij")
            out += amp * ndimage.map_coordinates(grid, [yy, xx], order=3, prefilter=False, mode="nearest")
        return out / self.tot

    def __call__(self, x0, y0, w, h):
        return np.clip((self.raw(x0, y0, w, h) - self.lo) / (self.hi - self.lo + 1e-6), 0, 1)


def ramp(t, cols):
    """Piecewise-linear blend through palette colours, t in [0,1] (array)."""
    t = np.clip(t, 0, 1)[..., None]
    n = len(cols) - 1
    idx = np.minimum((t * n).astype(int), n - 1)
    f = t * n - idx
    a = np.stack(cols)[idx[..., 0]]
    b = np.stack(cols)[idx[..., 0] + 1]
    return a + (b - a) * f


def raster(polys, x0, y0, w, h, ss=1):
    im = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(im)
    for poly in polys:
        if len(poly) >= 3:
            d.polygon([((x - x0) * ss, (y - y0) * ss) for x, y in poly], fill=255)
    if ss > 1:
        im = im.resize((w, h), Image.LANCZOS)
    return np.asarray(im, np.float32) / 255.0


def _bbox(poly):
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    return min(xs), min(ys), max(xs), max(ys)


def _near(items, x0, y0, x1, y1):
    return [poly for poly, (a, b, c, d) in items if c >= x0 and a <= x1 and d >= y0 and b <= y1]


class World:
    """Everything shared by the tiles (built once, then forked into the worker processes)."""

    def __init__(self):
        self.m = json.load(open(os.path.join(ROOT, "data", "map.json")))
        self.W, self.H = int(math.ceil(self.m["size"][0])), int(math.ceil(self.m["size"][1]))
        self.P = palette()
        rng = np.random.default_rng(1444)
        self.n_sea = Noise(self.W, self.H, rng, 4, 5)
        self.hills = Noise(self.W, self.H, rng, 6, 8)
        self.prov = [(poly, _bbox(poly)) for p in self.m["provinces"] for poly in p["polys"]]
        terr = json.load(open(os.path.join(ROOT, "data", "terrain.json")))
        self.biome = {}  # terrain type -> [(poly, bbox)] (data/terrain.json, the same types the game uses)
        for p in self.m["provinces"]:
            for poly in p["polys"]:
                self.biome.setdefault(terr.get(p["key"], "plains"), []).append((poly, _bbox(poly)))
        brng = np.random.default_rng(1492)  # own stream: the peaks below keep their places
        self.n_biome = Noise(self.W, self.H, brng, 4, 14)
        self.n_edge = Noise(self.W, self.H, brng, 3, 70)
        self.waste = [(poly, _bbox(poly)) for poly in self.m["background"]]
        self.ridges = []
        self.peaks = []
        for strength, pts in RANGES:
            xy = [proj(*p) for p in pts]
            self.ridges.append((strength, xy))
            for (x0, y0), (x1, y1) in zip(xy, xy[1:]):
                seg = math.hypot(x1 - x0, y1 - y0)
                nx, ny = -(y1 - y0) / max(seg, 1), (x1 - x0) / max(seg, 1)
                rows = (-1, 1) if strength >= 0.6 else (0,)
                for i in range(int(seg / 11) + 1):
                    f = i * 11 / max(seg, 1)
                    for row in rows:
                        jitter = rng.normal(0, 2.5, 2)
                        off = row * 6.0 + (3.0 if i % 2 else 0.0) * row
                        self.peaks.append((x0 + (x1 - x0) * f + nx * off + jitter[0], y0 + (y1 - y0) * f + ny * off + jitter[1], strength))
        self.peaks.sort(key=lambda p: p[1])

    def paint(self, tx, ty, tw, th):
        P = self.P
        x0, y0 = tx - MARGIN, ty - MARGIN
        w, h = tw + 2 * MARGIN, th + 2 * MARGIN
        box = (x0 - 4, y0 - 4, x0 + w + 4, y0 + h + 4)
        prov = raster(_near(self.prov, *box), x0, y0, w, h, 2)
        waste = raster(_near(self.waste, *box), x0, y0, w, h, 2)
        # close hairline gaps between neighbouring province polygons
        closed = ndimage.binary_closing(prov > 0.5, iterations=2)
        prov = np.maximum(prov, closed.astype(np.float32))
        land = np.clip(prov + waste, 0, 1)
        land_bin = land > 0.5

        # ---- sea: distance from the coast (2x supersampled, smoothed so ripple lines stay round)
        big = np.asarray(Image.fromarray((land * 255).astype(np.uint8)).resize((w * 2, h * 2), Image.BILINEAR)) > 127
        if big.any():
            dist = ndimage.distance_transform_edt(~big).astype(np.float32)
        else:
            dist = np.full(big.shape, 2 * (MARGIN + SEA_FLAT), np.float32)
        dist = ndimage.gaussian_filter(dist, 2.0)
        dist = np.asarray(Image.fromarray(dist).resize((w, h), Image.BILINEAR)) / 2.0
        n_sea = self.n_sea(x0, y0, w, h)
        # far from land the sea turns into the plain colour of the untextured map background
        calm = np.clip((SEA_FLAT - dist) / (SEA_FLAT * 0.5), 0, 1)
        t = np.clip(dist / 90.0, 0, 1) ** 0.6 + (n_sea - 0.5) * 0.25 * calm
        sea = ramp(1 - t, [P["sea_deep"], P["sea"], P["sea_shallow"]])
        for k, a in ((5.0, 0.35), (10.0, 0.22), (16.0, 0.12)):
            line = np.clip(1.0 - np.abs(dist - k) / 0.9, 0, 1) * a
            sea = sea + (P["foam"] - sea) * line[..., None]
        foam = np.clip(1.0 - (dist - 0.5) / 2.0, 0, 1) * 0.5
        sea = sea + (P["foam"] - sea) * foam[..., None]

        # ---- relief
        ridge = Image.new("L", (w, h), 0)
        rd = ImageDraw.Draw(ridge)
        for strength, xy in self.ridges:
            xs = [p[0] for p in xy]
            ys = [p[1] for p in xy]
            if max(xs) < x0 - 60 or min(xs) > x0 + w + 60 or max(ys) < y0 - 60 or min(ys) > y0 + h + 60:
                continue
            rd.line([(x - x0, y - y0) for x, y in xy], fill=int(255 * strength), width=int(10 + 14 * strength), joint="curve")
        mount = ndimage.gaussian_filter(np.asarray(ridge, np.float32) / 255.0, 6) * 2.2
        hills = self.hills(x0, y0, w, h)
        height = hills * 0.9 + np.clip(mount, 0, 1.4) * (0.6 + hills * 0.6)
        gy, gx = np.gradient(ndimage.gaussian_filter(height, 1.2))
        shade = np.clip(0.55 - (gx + gy) * 22.0, 0, 1)  # light from the top-left

        lowland = ramp(shade, [P["land_dark"], P["land"], P["land_light"]])
        rock_t = np.clip(shade * 0.8 + np.clip(mount - 0.9, 0, 1) * 0.6, 0, 1)
        rocky = ramp(rock_t, [P["rock_dark"], P["rock"], P["rock_light"], P["snow"]])
        rock_w = np.clip((mount - 0.25) * 1.4, 0, 1)[..., None]
        landc = lowland + (rocky - lowland) * rock_w
        wastec = ramp(shade, [P["waste_dark"], P["waste"]])
        wastec = wastec + (rocky * 0.7 + wastec * 0.3 - wastec) * rock_w * 0.6

        landc, masks, lat = self._biomes(landc, shade, mount, hills, x0, y0, w, h, box)

        img = sea
        img = img + (wastec - img) * waste[..., None]
        img = img + (landc - img) * prov[..., None]
        out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
        self._stipple(out, masks, lat, mount, land_bin, x0, y0, w, h)

        # ---- peak glyphs (stamped, land only)
        d = ImageDraw.Draw(out)
        for x, y, s in self.peaks:
            if y < y0 - 20 or y > y0 + h + 20:
                continue
            xi, yi = int(x) - x0, int(y) - y0
            if not (0 <= xi < w and 0 <= yi < h) or not land_bin[yi, xi]:
                continue
            x, y = x - x0, y - y0
            r = 4.5 + 3.5 * s
            top = (x, y - r * 1.25)
            left, right, mid = (x - r, y + r * 0.45), (x + r, y + r * 0.45), (x + r * 0.15, y + r * 0.45)
            d.polygon([top, left, mid], fill=tuple(int(c) for c in P["rock_light"]))
            d.polygon([top, mid, right], fill=tuple(int(c) for c in P["rock_dark"]))
            if s >= 0.7:  # snow cap
                cap = r * 0.45
                d.polygon([top, (x - cap * 0.8, y - r * 1.25 + cap), (x + cap * 0.8, y - r * 1.25 + cap)], fill=tuple(int(c) for c in P["snow"]))
            d.line([left, top, right], fill=tuple(int(c) for c in P["rock_dark"]), width=1)
        return out.crop((MARGIN, MARGIN, MARGIN + tw, MARGIN + th))


    # ---- biomes: soft colour by terrain type and latitude, then small stamped glyphs (trees, dunes, reeds)

    def _biomes(self, landc, shade, mount, hills, x0, y0, w, h, box):
        masks = {}
        edge = self.n_edge(x0, y0, w, h)
        for kind in ("forest", "desert", "marsh", "hills", "mountains"):
            m = raster(_near(self.biome.get(kind, []), *box), x0, y0, w, h)
            if m.any():
                # soft, ragged edges instead of the straight province borders the regions come from
                m = ndimage.gaussian_filter(m, 14.0)
                m = np.clip((m - 0.5) * 1.8 + 0.5 + (edge - 0.5) * 1.3, 0, 1)
            masks[kind] = m
        lat = (LAT0 - (y0 + np.arange(h, dtype=np.float32)) / SCALE)[:, None] * np.ones((1, w), np.float32)
        nb = self.n_biome(x0, y0, w, h)
        light = (0.80 + 0.40 * shade)[..., None]
        out = landc
        jungle = np.clip((20.0 - np.abs(lat)) / 6.0, 0, 1)
        taiga = np.clip((lat - 50.0) / 8.0, 0, 1)
        forest_col = BIOME["forest"] + (BIOME["jungle"] - BIOME["forest"]) * jungle[..., None]
        forest_col = forest_col + (BIOME["taiga"] - forest_col) * taiga[..., None]
        for kind, col, k in (("forest", forest_col, 0.55), ("desert", BIOME["desert"], 0.6), ("marsh", BIOME["marsh"], 0.5),
                             ("hills", BIOME["hills"], 0.35)):
            a = masks[kind] * (k * (0.75 + 0.5 * nb))
            out = out + (col * light - out) * a[..., None]
        # the far north and south: pale tundra, then ice
        tundra = np.clip((np.abs(lat) - 61.0) / 5.0, 0, 1) * (1.0 - np.clip(mount - 0.3, 0, 1)) * 0.55
        out = out + (BIOME["tundra"] * light - out) * tundra[..., None]
        return out, masks, lat

    def _stipple(self, out, masks, lat, mount, land_bin, x0, y0, w, h):
        d = ImageDraw.Draw(out)

        def cells(step, kind, thr):
            m = masks[kind]
            if m.max() < thr:
                return
            for gy in range((y0 - 8) // step, (y0 + h + 8) // step + 1):
                for gx in range((x0 - 8) // step, (x0 + w + 8) // step + 1):
                    hsh = (gx * 73856093 ^ gy * 19349663 ^ step * 83492791) & 0xFFFFFFFF
                    jx = (hsh & 0xFF) / 255.0
                    jy = ((hsh >> 8) & 0xFF) / 255.0
                    pick = ((hsh >> 16) & 0xFF) / 255.0
                    x = gx * step + jx * step * 0.8
                    y = gy * step + jy * step * 0.8
                    xi, yi = int(x) - x0, int(y) - y0
                    if not (2 <= xi < w - 2 and 2 <= yi < h - 2) or not land_bin[yi, xi]:
                        continue
                    if m[yi, xi] < thr + pick * 0.35:  # thinner towards the edges of the region
                        continue
                    yield x - x0, y - y0, pick, xi, yi

        dark, mid = tuple(int(c) for c in BIOME["tree_dark"]), tuple(int(c) for c in BIOME["tree"])
        for x, y, pick, xi, yi in cells(11, "forest", 0.35):
            if mount[yi, xi] > 0.9:
                continue
            if lat[yi, xi] > 48.0 or pick > 0.75:  # conifer
                d.polygon([(x, y - 4.5), (x - 2.6, y + 1.5), (x + 2.6, y + 1.5)], fill=mid)
                d.line([(x, y - 4.5), (x + 2.6, y + 1.5)], fill=dark, width=1)
                d.line([(x, y + 1.5), (x, y + 2.8)], fill=dark, width=1)
            else:  # broadleaf crown with a shadow
                d.ellipse([x - 2.6, y - 3.4, x + 2.6, y + 1.2], fill=mid)
                d.arc([x - 2.6, y - 3.4, x + 2.6, y + 1.2], 300, 120, fill=dark, width=1)
                d.line([(x, y + 1.2), (x, y + 2.6)], fill=dark, width=1)
        sand = tuple(int(c) for c in BIOME["dune"])
        for x, y, pick, xi, yi in cells(19, "desert", 0.4):
            d.arc([x - 5, y - 2, x + 5, y + 3], 200, 340, fill=sand, width=1)
            if pick > 0.5:
                d.arc([x - 1, y + 1, x + 7, y + 5], 200, 340, fill=sand, width=1)
        reed = tuple(int(c) for c in BIOME["reed"])
        for x, y, pick, xi, yi in cells(13, "marsh", 0.4):
            d.line([(x - 4, y + 2), (x + 4, y + 2)], fill=reed, width=1)
            for dx in (-2, 0, 2):
                d.line([(x + dx, y + 1), (x + dx * 1.4, y - 2.5)], fill=reed, width=1)
        hill = tuple(int(c) for c in BIOME["hill_line"])
        for x, y, pick, xi, yi in cells(17, "hills", 0.4):
            if mount[yi, xi] > 0.5:
                continue
            d.arc([x - 5, y - 3, x + 5, y + 5], 200, 340, fill=hill, width=1)
        rl, rd_ = tuple(int(c) for c in self.P["rock_light"]), tuple(int(c) for c in self.P["rock_dark"])
        for x, y, pick, xi, yi in cells(16, "mountains", 0.45):
            if mount[yi, xi] > 0.6:  # the ranges already carry their own peaks
                continue
            r = 3.5 + pick * 2.0
            d.polygon([(x, y - r * 1.2), (x - r, y + r * 0.45), (x + r * 0.15, y + r * 0.45)], fill=rl)
            d.polygon([(x, y - r * 1.2), (x + r * 0.15, y + r * 0.45), (x + r, y + r * 0.45)], fill=rd_)


def _hex(c):
    return np.array([int(c[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float32)


# biome colours: muted atlas tones that sit between the parchment land and the palette greens and sands
BIOME = {k: _hex(v) for k, v in {
    "forest": "#a7aa72", "jungle": "#879a5c", "taiga": "#9a9f80", "desert": "#e6d29c", "marsh": "#a3aa8c",
    "hills": "#c2ad7c", "tundra": "#d9d8cc", "tree": "#6f7f4a", "tree_dark": "#46522f", "dune": "#c2a66a",
    "reed": "#6f7a5c", "hill_line": "#8f7c55",
}.items()}


_WORLD = None


def _paint_tile(td):
    name, tx, ty, tw, th = td
    img = _WORLD.paint(tx, ty, tw, th)
    f = os.path.join(OUT_DIR, name)
    img.save(f, optimize=True)
    return f


def main():
    global _WORLD
    import argparse
    from multiprocessing import get_context
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--only", action="append", default=[])
    a = ap.parse_args()
    _WORLD = World()
    tiles = [t for t in _WORLD.m["terrain_tiles"] if not a.only or t[0] in a.only]
    os.makedirs(OUT_DIR, exist_ok=True)
    with get_context("fork").Pool(a.jobs) as pool:
        for f in pool.imap_unordered(_paint_tile, tiles):
            print(os.path.relpath(f, ROOT), os.path.getsize(f) // 1024, "KiB", flush=True)
    # .import next to every tile: VRAM-compressed with mipmaps (Godot fills in the uid on the next import)
    keep = {t[0] for t in _WORLD.m["terrain_tiles"]}
    for f in os.listdir(OUT_DIR):
        if f.startswith("terrain") and f.endswith(".png") and f not in keep and not a.only:
            os.remove(os.path.join(OUT_DIR, f))
            if os.path.exists(os.path.join(OUT_DIR, f + ".import")):
                os.remove(os.path.join(OUT_DIR, f + ".import"))
            print("removed", f)
    for name in keep:
        imp = os.path.join(OUT_DIR, name + ".import")
        if not os.path.exists(imp):
            open(imp, "w").write(IMPORT % name)


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"
metadata={
"imported_formats": ["s3tc_bptc", "etc2_astc"],
"vram_texture": true
}

[deps]

source_file="res://assets/art/map/%s"

[params]

compress/mode=2
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""


if __name__ == "__main__":
    main()
