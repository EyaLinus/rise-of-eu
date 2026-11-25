"""Phase F of the world map: Australia, New Guinea, Melanesia, New Zealand and Hawaii.

1444 no realm of the Old World knows these lands. They are open land of their peoples (NAT) for colonisation,
across seas nobody has charted yet (seas.py NEW: arafura, coral, tasman, south_aus, melanesia,
south_pacific). Region "oceania" (map.json "oc"), so the peoples of the Americas do not know them.
Hawaii lies in the New World window of the map but belongs to Oceania too.
"""

BLOCK = "oc"
FLAGS = {"nw": True, "oc": True}

PROVINCES = [
    # Australia
    ("cape_york", "Kap York", 142.8, -13.5, "NAT", 1, 5.5),
    ("carpentaria", "Carpentaria", 139.5, -18.0, "NAT", 1, 6.5),
    ("arnhem", "Arnhemland", 134.5, -12.8, "NAT", 1, 5.5),
    ("kimberley", "Kimberley", 126.5, -16.5, "NAT", 1, 6.5),
    ("pilbara", "Pilbara", 118.5, -21.5, "NAT", 1, 6.5),
    ("gascoyne", "Gascoyne", 115.3, -25.5, "NAT", 1, 5.5),
    ("swan", "Swan River", 116.0, -31.8, "NAT", 1, 5.5),
    ("western_desert", "Westliche Wüste", 123.0, -26.5, "NAT", 1, 7.5),
    ("nullarbor", "Nullarbor", 128.0, -31.0, "NAT", 1, 6.5),
    ("arrernte", "Arrernte", 133.9, -23.7, "NAT", 1, 7.5),
    ("lake_eyre", "Eyresee", 138.5, -28.0, "NAT", 1, 6.5),
    ("kaurna", "Kaurna", 138.6, -34.6, "NAT", 1, 5.5),
    ("murray", "Murray", 142.5, -34.5, "NAT", 1, 5.5),
    ("kulin", "Kulin", 145.0, -37.6, "NAT", 1, 5.0),
    ("wiradjuri", "Wiradjuri", 147.0, -32.5, "NAT", 1, 5.5),
    ("eora", "Eora", 151.0, -33.8, "NAT", 1, 3.0),
    ("kamilaroi", "Kamilaroi", 149.5, -29.5, "NAT", 1, 5.5),
    ("turrbal", "Turrbal", 152.6, -27.2, "NAT", 1, 5.0),
    ("capricornia", "Capricornia", 148.5, -22.5, "NAT", 1, 5.5),
    ("gugu", "Guugu Yimithirr", 145.4, -17.0, "NAT", 1, 5.5),
    ("palawa", "Lutruwita", 146.6, -42.0, "NAT", 1, 3.0),
    # New Guinea and Melanesia
    ("vogelkop", "Vogelkop", 133.0, -1.3, "NAT", 1, 5.0),
    ("sepik", "Sepik", 143.0, -4.0, "NAT", 1, 5.5),
    ("png_highlands", "Hochland Neuguineas", 139.8, -4.6, "NAT", 2, 5.5),
    ("trans_fly", "Fly", 141.5, -8.0, "NAT", 1, 5.5),
    ("motu", "Motu", 147.0, -9.4, "NAT", 1, 5.0),
    ("huon", "Huon", 146.8, -6.4, "NAT", 1, 3.0),
    ("new_britain", "Neubritannien", 151.0, -5.4, "NAT", 1, 3.0),
    ("solomons", "Salomonen", 160.0, -9.4, "NAT", 1, 3.0),
    ("vanuatu", "Vanuatu", 167.5, -16.0, "NAT", 1, 2.5),
    ("new_caledonia", "Neukaledonien", 165.5, -21.4, "NAT", 1, 2.5),
    ("fiji", "Fidschi", 178.0, -17.8, "NAT", 2, 2.5),
    # Aotearoa (New Zealand)
    ("northland", "Te Tai Tokerau", 174.0, -35.8, "NAT", 1, 3.0),
    ("waikato", "Waikato", 175.5, -38.4, "NAT", 1, 3.0),
    ("te_whanganui", "Te Whanganui-a-Tara", 175.6, -40.8, "NAT", 1, 3.0),
    ("waitaha", "Waitaha", 172.0, -43.4, "NAT", 1, 5.0),
    ("otago", "Ōtākou", 169.4, -45.6, "NAT", 1, 5.0),
    # Hawaii
    ("hawaii", "Hawaiʻi", -155.5, 19.6, "NAT", 2, 2.5),
    ("oahu", "Oʻahu", -158.0, 21.4, "NAT", 1, 2.0),
]

STRAITS = [("kulin", "palawa"), ("cape_york", "trans_fly"), ("huon", "new_britain"), ("new_britain", "solomons"),
           ("solomons", "vanuatu"), ("vanuatu", "new_caledonia"), ("vanuatu", "fiji"), ("waikato", "northland"),
           ("te_whanganui", "waitaha"), ("hawaii", "oahu"), ("vogelkop", "ambon"), ("arnhem", "timor")]
LAND_LINKS = []

TERRAIN = {"western_desert": "desert", "arrernte": "desert", "nullarbor": "desert", "lake_eyre": "desert", "pilbara": "desert",
           "gascoyne": "desert", "carpentaria": "plains", "kimberley": "hills", "png_highlands": "mountains", "sepik": "forest",
           "vogelkop": "forest", "trans_fly": "marsh", "murray": "plains", "wiradjuri": "plains", "kamilaroi": "plains",
           "waitaha": "plains", "otago": "hills", "palawa": "forest", "hawaii": "hills", "oahu": "hills"}


def DEFAULT_TERRAIN(key, lat):
    return "forest" if lat > -20.0 else "plains"


RANGES = [
    (0.45, [(145.4, -16.0), (146.6, -20.0), (148.6, -23.4), (150.6, -27.0), (151.6, -30.0), (150.4, -33.0), (148.6, -36.2), (146.6, -37.4)]),  # Great Dividing Range
    (0.35, [(132.0, -23.6), (134.0, -23.6), (136.0, -23.8)]),  # MacDonnell
    (0.3, [(117.0, -22.6), (119.0, -22.8)]),  # Hamersley
    (0.3, [(138.4, -31.0), (138.6, -33.0)]),  # Flinders
    (0.35, [(145.8, -41.6), (146.4, -42.4)]),  # Tasmania
    (1.0, [(134.0, -3.0), (136.6, -3.8), (138.6, -4.2), (140.6, -4.6), (142.6, -5.4), (144.6, -6.0), (146.6, -7.0), (148.0, -8.4)]),  # New Guinea Highlands
    (0.8, [(168.0, -44.6), (169.6, -43.8), (171.0, -42.8), (172.6, -41.8)]),  # Southern Alps
    (0.4, [(175.6, -39.2), (176.0, -40.6)]),  # Ruapehu / ranges
    (0.6, [(-155.6, 19.4), (-155.4, 19.8)]),  # Mauna Loa
]

RIVERS = [
    ("Murray", 2, [(148.0, -36.4), (146.0, -36.0), (144.0, -35.6), (142.6, -34.4), (141.0, -34.2), (139.6, -34.6), (139.2, -35.4)]),
    ("Darling", 1, [(151.0, -28.8), (148.6, -29.6), (146.0, -30.4), (144.0, -31.6), (142.6, -33.4), (142.0, -34.0)]),
    ("Sepik", 1, [(141.4, -4.6), (142.6, -4.0), (143.6, -3.8), (144.4, -3.8)]),
    ("Fly", 1, [(141.4, -5.6), (141.6, -7.0), (142.6, -8.0), (143.4, -8.4)]),
]

NATIONS = {}


def flag_art(h):
    return {}


GOODS = """
livestock: carpentaria western_desert nullarbor arrernte lake_eyre pilbara gascoyne kimberley murray wiradjuri kamilaroi waitaha
fish: cape_york arnhem swan kaurna kulin eora turrbal capricornia gugu palawa northland te_whanganui otago oahu new_caledonia solomons vanuatu
timber: vogelkop sepik trans_fly motu huon new_britain waikato
spices: png_highlands
sugar: fiji hawaii
"""
MARKETS = []

ALLIANCES = []
RIVALS = []
