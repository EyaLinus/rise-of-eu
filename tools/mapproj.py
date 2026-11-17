"""Map projection shared by every map tool (gen_map, map_terrain, gen_terrain, gen_seas, gen_fog).

Plate carrée at 48 px per degree latitude, longitude scaled by cos(50°). Two land windows: the Old
World (Europe, North and West Africa, the Near and Middle East, the Horn of Africa) and the New World (North and Central America). The New
World is shifted east by ATL_SHIFT degrees, which squeezes the empty mid-Atlantic out of the map so
the whole world stays under 4096 px wide (one texture on Android).
"""
import math

SCALE = 48.0  # pixels per degree latitude
COSLAT = math.cos(math.radians(50))
ATL_CUT = -35.0  # longitudes west of this belong to the New World window
ATL_SHIFT = 27.0  # ... and are moved this many degrees east
OLD_WORLD = (-18.0, 55.5)  # lon range of the Old World window (west edge: Cape Verde, east edge: Hormuz; width stays < 4096 px)
NEW_WORLD = (-104.0, -50.0)  # lon range of the New World window (before the shift)
LON0 = NEW_WORLD[0] + ATL_SHIFT  # x = 0
LAT0 = 64.0  # y = 0
MIN_LAT = 4.0  # bottom edge (Gulf of Guinea)
NW_MIN_LAT = 7.5  # the New World window stops here (no South America)


def shift_lon(lon):
    return lon + ATL_SHIFT if lon < ATL_CUT else lon


def proj(lon, lat):
    return ((shift_lon(lon) - LON0) * SCALE * COSLAT, (LAT0 - lat) * SCALE)


def unproj(x, y):
    """Inverse of proj (x in the shifted New World band maps back west of ATL_CUT)."""
    lon = x / (SCALE * COSLAT) + LON0
    if lon < NEW_WORLD[1] + ATL_SHIFT + 1.0:
        lon -= ATL_SHIFT
    return lon, LAT0 - y / SCALE


def size():
    w = (OLD_WORLD[1] - LON0) * SCALE * COSLAT
    h = (LAT0 - MIN_LAT) * SCALE
    return math.ceil(w), math.ceil(h)
