"""The world beyond the original map, one module per region (appended in this order, so province ids of
older blocks never change). Every region module defines:

    BLOCK       name of the block (map.json flag, also used by tests)
    FLAGS       extra map.json flags for its provinces ({"nw": True} = overseas/colonial land)
    PROVINCES   (key, name, lon, lat, owner, dev[, radius in degrees])  -> tools/gen_map.py
    STRAITS, LAND_LINKS                                                   -> tools/gen_map.py
    TERRAIN     {key: terrain} forced terrain; DEFAULT_TERRAIN(key, lat) for the rest (ridges make hills
                and mountains first)                                     -> tools/gen_terrain.py
    RANGES      [(strength, [(lon, lat), ...])] mountain ridges           -> tools/art/map_terrain.py
    RIVERS      [(name, width, [(lon, lat), ...])]                        -> tools/art/rivers.py
    NATIONS     {tag: nations.json entry}, FLAG_ART {tag: (grid, comment)} -> tools/world/apply.py
    GOODS       "good: key key ..." lines, MARKETS [key]                 -> tools/world/apply.py
    ALLIANCES, RIVALS  [[tag, tag]]                                        -> tools/world/apply.py
optional:
    NATION_UPDATES {tag: fields} changes to realms of the old map          -> tools/world/apply.py
    NEW_GOODS   {good: goods.json entry} (pixel glyph in tools/art/emoji_icons.py) -> tools/world/apply.py
    RELIGION    {key: faith} the people's faith where it is not the owner's  -> map.json "religion"
"""
from . import central_asia, china, india, japan_korea, russia

REGIONS = [russia, central_asia, india, china, japan_korea]


def provinces():
    out = []
    for r in REGIONS:
        out += r.PROVINCES
    return out


def region_of(key):
    for r in REGIONS:
        for p in r.PROVINCES:
            if p[0] == key:
                return r
    return None
