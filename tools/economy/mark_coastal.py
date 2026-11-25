"""Writes data/coastal.json: keys of provinces that touch the sea (outline not covered by other land).
Run after tools/gen_map.py. Uses shapely."""
import json
from shapely.geometry import Polygon, box
from shapely import STRtree
from shapely.ops import unary_union

m = json.load(open('data/map.json'))
land = [Polygon(r) for r in m['background'] if len(r) >= 3]
shapes = {}
for p in m['provinces']:
    polys = [Polygon(r).buffer(0) for r in p['polys'] if len(r) >= 3]
    shapes[p['key']] = unary_union(polys)
W, H = m['size']
inner = box(4, 4, W - 4, H - 4)  # the map border is not sea
# inland provinces whose outline only touches a sliver of unclaimed land between Voronoi discs (Africa)
INLAND = {'kordofan', 'ogaden', 'bale', 'borana', 'limpopo'}
keys = list(shapes)
geoms = [shapes[k] for k in keys] + land
tree = STRtree(geoms)
coastal = []
for p in m['provinces']:
    me = shapes[p['key']]
    near = [geoms[int(i)] for i in tree.query(me.buffer(3.0)) if int(i) >= len(keys) or keys[int(i)] != p['key']]
    others = unary_union(near).buffer(2.0)
    rest = me.boundary.difference(others).intersection(inner)
    if rest.length > 12.0 and p['key'] not in INLAND:
        coastal.append(p['key'])
json.dump(sorted(coastal), open('data/coastal.json', 'w'), indent=0)
print(len(coastal), 'of', len(m['provinces']), 'coastal')
