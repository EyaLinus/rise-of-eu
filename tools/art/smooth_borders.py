#!/usr/bin/env python3
"""Rounds the inland province borders of data/map.json (art only, no gameplay change).

gen_map builds Voronoi cells with jagged (midpoint-displaced) edges and then simplifies every province on
its own, so neighbours do not share exact vertices and the borders read as straight, angular strokes.
This step turns the provinces back into one clean coverage and bends every shared inland border into a
soft curve (Chaikin corner cutting, the ends fixed so three-province corners stay put). Coasts, province
centres, adjacency and ids stay as they are. The result: rounder, organic provinces whose neighbours share
exactly the same border line (drawn once, no double strokes).

Usage: python3 tools/art/smooth_borders.py          (rewrites data/map.json, once: it marks the file)
gen_map.py calls smooth() itself on a freshly generated map.
"""
import json
import math
import os
import sys
import zlib

import shapely
from shapely import STRtree
from shapely.geometry import LineString, MultiPolygon, Point, Polygon
from shapely.ops import polygonize, unary_union

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ITER = 2  # Chaikin rounds after the bow: the jagged corners become gentle bends
BOW = 0.13  # how far an inland border bows out, as a share of its length
SIMPLIFY = 1.5  # coverage simplification after smoothing (px): keeps the curves, drops redundant points
GAP_FILL = 1.6  # slivers between neighbours narrower than this (px) are closed


def chaikin(pts, closed=False, iters=ITER):
    for _ in range(iters):
        out = [] if closed else [pts[0]]
        n = len(pts)
        rng = range(n) if closed else range(n - 1)
        for i in rng:
            a, b = pts[i], pts[(i + 1) % n]
            out.append((0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]))
            out.append((0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1]))
        if not closed:
            out.append(pts[-1])
        pts = out
    return pts


def bend(arc, centres):
    """A soft bow along an inland border: the line is resampled and pushed sideways by one or two smooth
    half-waves (fixed per border), never more than a fraction of the way to either province centre. The ends
    stay where they are, so the three-province corners do not move."""
    a, b = arc.coords[0], arc.coords[-1]
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    if L < 8.0:
        return list(arc.coords)
    nx, ny = -(b[1] - a[1]) / L, (b[0] - a[0]) / L
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    d = min(math.hypot(c[0] - mx, c[1] - my) for c in centres)
    rnd = zlib.crc32(("%.0f,%.0f,%.0f,%.0f" % (min(a, b) + max(a, b))).encode())
    r1 = ((rnd & 0xFFFF) / 0xFFFF - 0.5) * 2.0
    r2 = (((rnd >> 16) & 0xFFFF) / 0xFFFF - 0.5) * 2.0
    if a > b:  # the same bow whichever way the arc runs
        r1 = -r1
    amp = min(BOW * L, 0.3 * d)
    steps = max(2, int(arc.length / 5.0))
    out = []
    for k in range(steps + 1):
        t = k / steps
        q = arc.interpolate(t, normalized=True)
        off = amp * (r1 * math.sin(math.pi * t) + 0.5 * r2 * math.sin(2.0 * math.pi * t))
        out.append((q.x + nx * off, q.y + ny * off))
    out[0], out[-1] = tuple(a), tuple(b)
    return out


def _poly_of(pd):
    parts = []
    for ring in pd["polys"]:
        if len(ring) >= 3:
            q = Polygon(ring)
            if not q.is_valid:
                q = q.buffer(0)
            parts.append(q)
    return unary_union(parts)


def _parts(g):
    if g.is_empty:
        return []
    if g.geom_type == "Polygon":
        return [g]
    return [q for q in getattr(g, "geoms", []) if q.geom_type == "Polygon"]


def smooth(provinces, verbose=True):
    n = len(provinces)
    orig = [_poly_of(pd) for pd in provinces]
    # 1. one clean coverage: overlaps go to the lower id, thin slivers between neighbours are closed
    land = unary_union(orig)
    closed = land.buffer(GAP_FILL, join_style="mitre").buffer(-GAP_FILL, join_style="mitre")
    slivers = [q for q in _parts(closed.difference(land)) if q.area < 400.0]
    cov = []
    taken = None
    tree0 = STRtree(orig)
    for i, g in enumerate(orig):
        if taken is not None:
            near = [cov[int(j)] for j in tree0.query(g) if int(j) < i]
            if near:
                g = g.difference(unary_union(near))
        cov.append(g)
        taken = True
    tree = STRtree(cov)
    filled = 0
    for s in slivers:
        # an enclosed sliver (not a bay): most of its rim lies on provinces
        rim = s.exterior
        touch = [int(j) for j in tree.query(s.buffer(0.3))]
        if not touch:
            continue
        on = unary_union([cov[j].boundary for j in touch]).buffer(0.3)
        if rim.intersection(on).length < 0.9 * rim.length:
            continue
        best = max(touch, key=lambda j: cov[j].boundary.intersection(s.buffer(0.3)).length)
        cov[best] = unary_union([cov[best], s.buffer(0.05)])
        filled += 1
    # overlaps created by the sliver buffer: lower id wins again
    tree = STRtree(cov)
    for i in range(n):
        near = [cov[int(j)] for j in tree.query(cov[i]) if int(j) < i]
        if near:
            cov[i] = cov[i].difference(unary_union(near))
    cov = [shapely.set_precision(g, 0.01) for g in cov]
    # 2. the borders as one noded line network, split into arcs between junctions
    lines = unary_union([g.boundary for g in cov])
    arcs = shapely.line_merge(lines)
    arcs = list(getattr(arcs, "geoms", [arcs]))
    tree = STRtree(cov)
    out_lines = []
    inland = 0
    for a in arcs:
        cs = list(a.coords)
        mid = a.interpolate(0.5, normalized=True)
        who = [int(j) for j in tree.query(mid.buffer(0.05)) if cov[int(j)].boundary.distance(mid) < 0.05]
        if len(who) >= 2 and len(cs) >= 2:
            ring = a.is_ring
            pts = cs[:-1] if ring else bend(a, [provinces[j]["center"] for j in who])
            sm = chaikin(pts, closed=ring)
            out_lines.append(LineString(sm + [sm[0]] if ring else sm))
            inland += 1
        else:
            out_lines.append(a)
    # 3. faces of the new network back to their provinces (largest overlap with the clean coverage)
    faces = list(polygonize(unary_union(out_lines)))
    parts = [[] for _ in range(n)]
    for f in faces:
        hit = [int(j) for j in tree.query(f)]
        if not hit:
            continue
        best, area = -1, 0.0
        for j in hit:
            ar = cov[j].intersection(f).area
            if ar > area:
                best, area = j, ar
        if best >= 0 and area > 0.3 * f.area:
            parts[best].append(f)
    # 4. thin out the curve points together (shared borders stay identical on both sides)
    ids = [i for i in range(n) if parts[i]]
    merged = shapely.coverage_simplify([unary_union(parts[i]) for i in ids], SIMPLIFY)
    changed = 0
    for i, g in zip(ids, merged):
        pd = provinces[i]
        polys = []
        for q in _parts(g):
            if q.area <= 25.0:
                continue
            ring = [[round(x, 1), round(y, 1)] for x, y in list(q.exterior.coords)[:-1]]
            if len(ring) < 3 or not Polygon(ring).is_valid:
                polys = None
                break
            polys.append(ring)
        c = Point(pd["center"])
        if not polys or not any(Polygon(r).buffer(0.5).contains(c) for r in polys):
            continue
        pd["polys"] = polys
        changed += 1
    if verbose:
        print("smooth_borders: %d slivers closed, %d inland arcs rounded, %d/%d provinces reshaped" % (filled, inland, changed, n))
    return provinces


def main():
    path = os.path.join(ROOT, "data", "map.json")
    m = json.load(open(path))
    if m.get("smooth") and "--force" not in sys.argv:
        print("map.json is already smoothed (pass --force to round it once more)")
        return
    smooth(m["provinces"])
    m["smooth"] = ITER
    with open(path, "w") as f:
        json.dump(m, f, separators=(",", ":"), ensure_ascii=False)


if __name__ == "__main__":
    main()
