"""Phase F of the world map: Alaska and the North of Canada.

Open land of its peoples (NAT) in the New World: the Unangan, Yup'ik and Iñupiat of Alaska, the Dene of the
interior, the Tlingit and Haida of the northwest coast, the Inuit from the Mackenzie delta to Baffin Island.
Colonisable once a realm has explored the Pacific (gulf_alaska, bering, chukchi) or the Arctic waters.
"""

BLOCK = "ak"
FLAGS = {"nw": True}

PROVINCES = [
    ("unangan", "Unangan", -158.5, 57.2, "NAT", 1, 5.5),
    ("aleut", "Aleuten", -162.6, 55.2, "NAT", 1, 3.5),
    ("kodiak", "Kodiak", -153.4, 57.6, "NAT", 1, 2.5),
    ("yupik", "Yup'ik", -161.5, 61.2, "NAT", 1, 5.5),
    ("seward", "Seward-Halbinsel", -164.0, 65.3, "NAT", 1, 5.0),
    ("inupiat", "Iñupiat", -155.0, 69.8, "NAT", 1, 6.5),
    ("dena", "Dena", -149.0, 64.6, "NAT", 1, 6.5),
    ("cook_inlet", "Cook Inlet", -150.4, 61.4, "NAT", 1, 5.0),
    ("tlingit", "Tlingit", -135.0, 58.4, "NAT", 1, 6.0),
    ("haida", "Haida Gwaii", -132.1, 53.4, "NAT", 1, 2.5),
    ("yukon", "Yukon", -137.5, 63.6, "NAT", 1, 6.5),
    ("gwichin", "Gwich'in", -134.0, 67.4, "NAT", 1, 6.5),
    ("inuvialuit", "Inuvialuit", -130.0, 69.4, "NAT", 1, 5.5),
    ("sahtu", "Sahtu", -124.5, 65.2, "NAT", 1, 6.5),
    ("dene", "Tłı̨chǫ", -115.5, 62.6, "NAT", 1, 6.5),
    ("liard", "Liard", -121.0, 60.2, "NAT", 1, 5.5),
    ("chipewyan", "Denesuline", -105.0, 59.6, "NAT", 1, 5.5),
    ("kitikmeot", "Kitikmeot", -106.0, 68.2, "NAT", 1, 6.5),
    ("kivalliq", "Kivalliq", -94.5, 63.0, "NAT", 1, 6.5),
    ("iglulik", "Iglulik", -84.0, 68.6, "NAT", 1, 6.5),
    ("qikiqtaaluk", "Qikiqtaaluk", -70.5, 66.8, "NAT", 1, 6.5),
]

STRAITS = [("unangan", "kodiak"), ("haida", "tlingit"), ("qikiqtaaluk", "nunavik")]
LAND_LINKS = []

TERRAIN = {"inupiat": "plains", "kitikmeot": "plains", "kivalliq": "plains", "iglulik": "plains", "qikiqtaaluk": "hills",
           "inuvialuit": "plains", "yupik": "marsh", "tlingit": "mountains", "cook_inlet": "mountains", "haida": "forest"}


def DEFAULT_TERRAIN(key, lat):
    return "forest" if lat < 66.0 else "plains"


RANGES = [
    (0.95, [(-153.0, 61.6), (-151.0, 63.0), (-148.0, 63.4), (-145.0, 63.0), (-142.0, 62.4)]),  # Alaska Range (Denali)
    (0.85, [(-145.0, 60.8), (-141.0, 60.6), (-138.0, 60.0), (-136.0, 59.0)]),  # Saint Elias
    (0.55, [(-160.0, 68.0), (-155.0, 68.2), (-150.0, 68.2), (-145.0, 68.6)]),  # Brooks Range
    (0.5, [(-133.0, 66.0), (-129.0, 64.0), (-126.0, 62.0), (-124.0, 60.0)]),  # Mackenzie Mountains
    (0.45, [(-158.0, 56.6), (-155.0, 58.0), (-153.0, 59.6)]),  # Aleutian Range
    (0.4, [(-72.0, 67.0), (-68.0, 66.0), (-66.0, 65.0)]),  # Baffin mountains
]

RIVERS = [
    ("Yukon", 2, [(-135.0, 60.6), (-137.0, 62.6), (-140.0, 64.4), (-143.0, 65.6), (-146.0, 66.4), (-150.0, 65.4), (-154.0, 64.8),
                  (-157.0, 64.4), (-160.0, 62.6), (-163.6, 62.4)]),
    ("Mackenzie", 2, [(-117.0, 61.2), (-121.0, 61.8), (-123.6, 63.6), (-126.0, 65.4), (-130.0, 67.4), (-134.6, 68.8)]),
    ("Kuskokwim", 1, [(-154.0, 63.0), (-157.0, 61.6), (-161.0, 60.8), (-162.4, 60.0)]),
]

NATIONS = {}


def flag_art(h):
    return {}


GOODS = """
furs: liard dena yukon gwichin sahtu dene chipewyan cook_inlet tlingit
fish: aleut unangan kodiak yupik seward haida
ivory: inupiat inuvialuit kitikmeot kivalliq iglulik qikiqtaaluk
"""
MARKETS = []

ALLIANCES = []
RIVALS = []
