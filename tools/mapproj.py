"""Map projection shared by every map tool (gen_map, map_terrain, gen_terrain, gen_seas, gen_fog).

Plate carrée at 48 px per degree latitude, longitude scaled by cos(50°). Two land windows: the Old
World (Europe, Africa, Asia and Oceania up to 180° E) and the New World (the Americas from Alaska to Cape
Horn). The New World is shifted east by ATL_SHIFT degrees, which squeezes the empty mid-Atlantic out of
the map. The world is about 10 000 x 6 200 px; Android caps textures at 4096 px, so the painted map is
cut into a grid of tiles (map.json "terrain_tiles"; open sea far from land is not painted at all).
"""
import math

SCALE = 48.0  # pixels per degree latitude
COSLAT = math.cos(math.radians(50))
ATL_CUT = -34.5  # longitudes west of this belong to the New World window (Cabo Branco, Brazil, is at -34.8)
ATL_SHIFT = 27.0  # ... and are moved this many degrees east
OLD_WORLD = (-18.0, 180.0)  # lon range of the Old World window (west edge: Cape Verde, east edge: the date line)
ICELAND = (-25.0, 62.5, -18.0, 67.5)  # lon/lat box added to the Old World window (Iceland reaches past its west edge)
NEW_WORLD = (-170.0, -50.0)  # lon range of the New World window (before the shift; west edge: the Bering Strait)
NW_NORTH_EAST = -57.0  # north of NW_NORTH_LAT the New World window stops here (Greenland is left out)
NW_NORTH_LAT = 59.0
LON0 = NEW_WORLD[0] + ATL_SHIFT  # x = 0
LAT0 = 72.0  # y = 0 (the Arctic coast of Norway and Russia)
MIN_LAT = -56.5  # bottom edge (Cape Horn)
NW_MIN_LAT = 7.5  # the North American window stops here; South America is its own window below
SOUTH_AMERICA = (-82.0, -56.5, -34.5, 13.0)  # lon/lat box of the South American window (lon_min, lat_min, lon_max, lat_max)


def shift_lon(lon):
    return lon + ATL_SHIFT if lon < ATL_CUT else lon


def proj(lon, lat):
    return ((shift_lon(lon) - LON0) * SCALE * COSLAT, (LAT0 - lat) * SCALE)


def unproj(x, y):
    """Inverse of proj (x in the shifted New World band maps back west of ATL_CUT)."""
    lon = x / (SCALE * COSLAT) + LON0
    lat = LAT0 - y / SCALE
    # north of the equator the shifted window ends at -50 + shift; south of 4° N the shifted Brazilian
    # coast reaches -34.5 + shift (no Old World land lies west of 5° E down there)
    nw_east = (NW_NORTH_EAST if lat >= NW_NORTH_LAT else NEW_WORLD[1]) + ATL_SHIFT + 1.0
    if lon < nw_east or (lat < 4.0 and lon < ATL_CUT + ATL_SHIFT + 1.0):
        lon -= ATL_SHIFT
    return lon, LAT0 - y / SCALE


def size():
    w = (OLD_WORLD[1] - LON0) * SCALE * COSLAT
    h = (LAT0 - MIN_LAT) * SCALE
    return math.ceil(w), math.ceil(h)


def windows():
    """The land windows as shapely geometries in lon/lat: [Old World, New World]."""
    from shapely.geometry import box
    old = box(OLD_WORLD[0], MIN_LAT, OLD_WORLD[1], LAT0).union(box(*ICELAND))
    nw = box(NEW_WORLD[0], NW_MIN_LAT, NEW_WORLD[1], NW_NORTH_LAT).union(box(NEW_WORLD[0], NW_NORTH_LAT, NW_NORTH_EAST, LAT0)).union(box(*SOUTH_AMERICA))
    return [old, nw]
