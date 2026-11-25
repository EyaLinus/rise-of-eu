"""Phase A of the world map: the far north of Europe, the Volga and the Urals, and Siberia to the Pacific.

1444: the Kalmar Union reaches Lapland and Iceland, Novgorod's tributary lands run to the Pechora, Great Perm
is a small Orthodox principality on the Kama. The Golden Horde has broken up: the Great Horde holds the lower
Volga at Sarai and Astrakhan, the Nogai roam between the Volga and the Ural river. East of the Urals the
Khanate of Sibir rules the Tobol and Irtysh; beyond it live forest and tundra peoples in small tribal realms
(native: weak technology, conquerable).
"""

BLOCK = "ru"
FLAGS = {}  # Old World: known from the start, not colonial

R = 7.0  # Siberian provinces are large: their Voronoi cells may reach this far (degrees)

PROVINCES = [
    # Scandinavia's north, Finland, Iceland (Kalmar Union)
    ("trondelag", "Trøndelag", 10.4, 63.4, "DAN", 4),
    ("nordland", "Nordland", 14.6, 67.0, "DAN", 1),
    ("finnmark", "Finnmark", 25.0, 69.6, "DAN", 1, R),
    ("norrland", "Norrland", 16.8, 63.0, "DAN", 2),
    ("lappmark", "Lappland", 21.5, 66.6, "DAN", 1),
    ("ostrobothnia", "Österbotten", 23.2, 63.4, "DAN", 2),
    ("savo", "Savolax", 27.7, 62.6, "DAN", 2),
    ("iceland", "Island", -19.0, 64.9, "DAN", 3),
    # Novgorod's north and the White Sea
    ("kola", "Kola", 34.5, 68.0, "NOV", 1),
    ("pomorye", "Pomorien", 34.8, 64.5, "NOV", 2),
    ("kargopol", "Kargopol", 39.0, 61.6, "NOV", 2),
    ("dvina", "Dwinaland", 41.6, 64.0, "NOV", 3),
    ("mezen", "Mesen", 46.0, 65.6, "NOV", 1),
    ("pechora", "Petschora", 54.0, 65.4, "NOV", 1, R),
    # Muscovy and its neighbours
    ("galich", "Galitsch", 42.4, 58.4, "RUS", 4),
    ("ustyug", "Weliki Ustjug", 46.3, 60.8, "RUS", 3),
    ("vyatka", "Wjatka", 49.7, 58.6, "RUS", 3),
    ("bryansk", "Brjansk", 34.4, 53.3, "LIT", 4),
    ("kursk", "Kursk", 36.2, 51.7, "LIT", 3),
    ("voronezh", "Woronesch", 39.2, 51.7, "RYA", 2),
    ("tambov", "Tambow", 41.5, 52.7, "RYA", 2),
    # Great Perm
    ("cherdyn", "Tscherdyn", 56.5, 60.4, "PRM", 3),
    ("perm", "Perm", 56.2, 58.0, "PRM", 3),
    ("komi", "Komi", 51.0, 62.0, "PRM", 2, R),
    # Kazan's lands
    ("cheremis", "Tscheremissen", 47.9, 57.0, "KAZ", 3),
    ("udmurt", "Udmurtien", 53.2, 57.0, "KAZ", 2),
    ("mordva", "Mordwinien", 44.8, 53.8, "KAZ", 3),
    # the Great Horde (lower Volga) and the Nogai
    ("sarai", "Sarai", 45.9, 48.4, "GHO", 4),
    ("astrakhan", "Astrachan", 48.0, 46.4, "GHO", 4),
    ("saratov", "Saratow", 46.0, 51.5, "GHO", 2),
    ("don", "Don-Steppe", 41.0, 49.5, "GHO", 1),
    ("terek", "Terek-Steppe", 45.6, 44.6, "GHO", 1),
    ("azov", "Asow", 39.4, 47.1, "CRI", 3),
    ("saraychik", "Saraitschik", 51.6, 47.6, "NOG", 3),
    ("yaik", "Jaik", 51.4, 51.2, "NOG", 2),
    ("samara", "Samara", 50.1, 53.2, "NOG", 2),
    ("bashkir", "Baschkirien", 56.0, 54.7, "NOG", 2),
    ("sakmara", "Sakmara", 56.0, 51.8, "NOG", 1),
    # the Khanate of Sibir
    ("isker", "Isker", 68.3, 58.1, "SIB", 3, R),
    ("tyumen", "Tjumen", 65.5, 57.1, "SIB", 3, R),
    ("iset", "Isset", 61.8, 56.0, "SIB", 1, R),
    ("ishim", "Ischim", 69.5, 55.6, "SIB", 2, R),
    ("tara", "Tara", 74.4, 56.9, "SIB", 2, R),
    ("baraba", "Baraba", 78.6, 55.0, "SIB", 1, R),
    # Yugra (Khanty and Mansi)
    ("pelym", "Pelym", 61.5, 61.0, "YUG", 1, R),
    ("yugra", "Jugra", 66.5, 61.4, "YUG", 2, R),
    ("berezov", "Berjosow", 65.1, 64.0, "YUG", 1, R),
    ("surgut", "Surgut", 73.4, 61.3, "YUG", 1, R),
    ("obdorsk", "Obdorsk", 66.6, 66.6, "YUG", 1, R),
    # the Piebald Horde (Selkup)
    ("narym", "Narym", 82.0, 59.0, "SEL", 1, R),
    ("tomsk", "Tomsk", 85.0, 56.5, "SEL", 2, R),
    # the Samoyeds of the tundra
    ("bolshezemel", "Große Tundra", 58.5, 67.4, "NEN", 1, R),
    ("yamal", "Jamal", 70.0, 69.6, "NEN", 1, R),
    ("taz", "Tas", 79.0, 67.0, "NEN", 1, R),
    ("taymyr", "Taimyr", 93.0, 70.2, "NEN", 1, R),
    # the Yenisei Kyrgyz
    ("khakas", "Minussinsk", 91.4, 53.7, "KYR", 2, R),
    ("kuznetsk", "Kusnezk", 87.1, 54.0, "KYR", 1, R),
    ("krasnoyarsk", "Krasnojarsk", 93.0, 56.4, "KYR", 1, R),
    # the Evenks (Tungus) of the taiga
    ("turukhansk", "Turuchansk", 87.9, 65.8, "EVK", 1, R),
    ("tunguska", "Tunguska", 100.0, 63.0, "EVK", 1, R),
    ("podkamennaya", "Steinige Tunguska", 95.0, 60.4, "EVK", 1, R),
    ("ilimsk", "Ilimsk", 104.0, 57.2, "EVK", 1, R),
    ("vitim", "Witim", 113.0, 58.0, "EVK", 1, R),
    ("olekma", "Oljokma", 120.4, 60.4, "EVK", 1, R),
    ("aldan", "Aldan", 130.5, 58.6, "EVK", 1, R),
    ("okhotsk", "Ochotsk", 143.3, 59.6, "EVK", 1, R),
    ("olenek", "Olenjok", 113.0, 68.6, "EVK", 1, R),
    # the Buryats round Lake Baikal
    ("irkutsk", "Irkut", 104.0, 52.4, "BRT", 2, R),
    ("bratsk", "Bratsk", 101.6, 55.6, "BRT", 1, R),
    ("barguzin", "Bargusin", 110.4, 54.4, "BRT", 1, R),
    ("zabaikal", "Transbaikalien", 113.8, 51.6, "BRT", 2, R),
    # the Yakuts (Sakha) on the Lena
    ("yakutsk", "Jakutsk", 129.7, 62.0, "YAK", 3, R),
    ("vilyuy", "Wiljui", 118.0, 63.6, "YAK", 1, R),
    ("zhigansk", "Schigansk", 123.4, 66.8, "YAK", 1, R),
    ("verkhoyansk", "Werchojansk", 133.4, 67.4, "YAK", 1, R),
    # the Yukaghirs, the Chukchi, Kamchatka
    ("indigirka", "Indigirka", 146.0, 68.0, "YUK", 1, R),
    ("kolyma", "Kolyma", 155.0, 66.0, "YUK", 1, R),
    ("anadyr", "Anadyr", 173.0, 65.4, "CHK", 1, R),
    ("chukotka", "Tschukotka", 179.0, 68.0, "CHK", 1, R),
    ("koryak", "Korjaken", 165.0, 61.4, "ITL", 1, R),
    ("kamchatka", "Kamtschatka", 158.6, 53.6, "ITL", 1, R),
    ("kamchatka_n", "Nordkamtschatka", 160.5, 57.4, "ITL", 1, R),
]

STRAITS = [("iceland", "bergen")]
LAND_LINKS = []

# terrain: the Urals and Siberia's ranges come from RANGES; here the low country
TUNDRA = {"finnmark", "kola", "mezen", "pechora", "bolshezemel", "yamal", "taz", "taymyr", "obdorsk", "chukotka",
          "anadyr", "indigirka", "kolyma", "verkhoyansk", "zhigansk", "olenek", "lappmark", "turukhansk"}
STEPPE = {"sarai", "astrakhan", "saratov", "don", "terek", "azov", "saraychik", "yaik", "samara", "sakmara", "voronezh",
          "tambov", "kursk", "ishim", "baraba", "iset", "khakas", "zabaikal", "irkutsk"}
TERRAIN = {"astrakhan": "marsh", "iceland": "hills", "kamchatka": "mountains", "kamchatka_n": "mountains", "koryak": "hills",
           "nordland": "mountains"}


def DEFAULT_TERRAIN(key, lat):
    if key in TUNDRA:
        return "desert"  # frozen waste: poor, hard to march through (no extra terrain type)
    if key in STEPPE:
        return "plains"
    return "forest"  # taiga


RANGES = [
    (0.6, [(59.4, 51.6), (59.0, 53.6), (59.4, 55.2), (59.2, 57.0), (59.4, 59.0), (59.4, 61.0), (59.8, 63.0), (61.0, 65.0), (64.4, 67.4), (66.0, 68.6)]),  # Urals
    (0.8, [(84.0, 50.4), (86.4, 50.6), (88.6, 49.8), (90.0, 50.6)]),  # Altai
    (0.65, [(89.0, 52.6), (92.0, 52.8), (95.6, 52.6), (98.6, 52.2), (100.8, 51.8)]),  # Sayan
    (0.5, [(107.4, 54.6), (109.6, 55.8), (111.6, 57.0)]),  # Baikal range
    (0.5, [(113.0, 56.6), (116.4, 57.0), (119.0, 57.0)]),  # Stanovoy upland
    (0.65, [(126.0, 56.0), (130.0, 56.4), (134.0, 56.4)]),  # Stanovoy range
    (0.7, [(129.0, 70.0), (131.0, 67.6), (133.0, 65.0), (136.6, 63.6), (139.4, 62.8)]),  # Verkhoyansk range
    (0.6, [(141.0, 66.4), (144.0, 65.4), (147.6, 64.6), (151.0, 64.0)]),  # Chersky range
    (0.5, [(160.0, 62.8), (165.0, 64.4), (170.0, 66.0), (175.0, 67.0)]),  # Kolyma upland, Anadyr plateau
    (0.9, [(156.6, 51.6), (158.0, 53.6), (159.6, 55.8), (160.6, 57.6)]),  # Kamchatka volcanoes
    (0.45, [(98.0, 68.0), (101.0, 67.4), (104.0, 66.0)]),  # Putorana plateau
    (0.3, [(15.0, 64.4), (17.0, 66.6), (18.6, 68.4), (20.0, 69.2)]),  # northern Scandes
    (0.45, [(-19.5, 64.4), (-18.0, 64.9), (-16.6, 64.6)]),  # Iceland
]

RIVERS = [
    ("Kama", 2, [(56.2, 59.6), (56.2, 58.2), (54.6, 56.6), (52.0, 56.0), (50.0, 55.4)]),
    ("Ural", 2, [(59.2, 54.4), (58.6, 52.0), (55.2, 51.8), (51.4, 51.2), (51.6, 48.8), (51.8, 47.0)]),
    ("Nördliche Dwina", 2, [(46.3, 60.8), (44.6, 62.2), (43.0, 63.0), (41.6, 64.0), (40.6, 64.6)]),
    ("Petschora", 2, [(57.0, 62.0), (56.6, 64.0), (54.0, 65.2), (52.6, 66.4), (53.6, 67.6), (54.4, 68.2)]),
    ("Ob", 3, [(84.0, 52.6), (83.0, 54.6), (85.0, 56.6), (82.6, 58.6), (79.6, 60.8), (75.0, 61.2), (70.0, 61.0), (68.8, 61.6),
               (66.0, 63.0), (65.0, 64.6), (66.0, 66.0), (68.0, 66.8), (70.6, 67.6), (72.6, 68.8)]),
    ("Irtysch", 2, [(80.0, 50.6), (76.8, 52.6), (75.0, 54.6), (73.4, 55.0), (72.0, 56.6), (69.6, 57.6), (68.3, 58.2), (68.6, 60.0), (68.8, 61.0)]),
    ("Tobol", 1, [(63.0, 53.4), (65.2, 55.6), (66.4, 57.4), (68.3, 58.2)]),
    ("Jenissei", 3, [(91.4, 53.6), (92.8, 56.0), (92.4, 58.4), (91.0, 60.4), (89.6, 62.4), (87.9, 65.8), (86.6, 67.6), (86.4, 69.4), (83.0, 71.0)]),
    ("Angara", 2, [(104.0, 52.0), (103.0, 54.0), (101.6, 56.2), (100.0, 58.0), (96.0, 58.2), (93.0, 58.2)]),
    ("Untere Tunguska", 1, [(106.0, 58.6), (104.0, 61.0), (100.0, 63.4), (95.0, 64.6), (90.0, 65.6), (87.9, 65.8)]),
    ("Lena", 3, [(106.0, 54.0), (108.4, 56.6), (112.0, 58.6), (116.0, 59.6), (120.4, 60.4), (124.0, 61.0), (127.0, 61.8),
                 (129.7, 62.0), (129.0, 64.0), (126.4, 65.6), (124.0, 66.8), (125.6, 69.0), (127.0, 71.4)]),
    ("Aldan", 1, [(125.0, 57.6), (130.5, 58.6), (134.6, 60.4), (134.0, 62.6), (130.6, 63.4)]),
    ("Kolyma", 1, [(150.0, 62.0), (153.0, 64.4), (155.0, 66.0), (157.6, 68.0), (160.6, 69.4)]),
]

NATIONS = {
    "GHO": {"religion": "sunni", "name": "Große Horde", "color": "#c49a3a", "emoji": "🐎", "capital": "sarai", "aggression": 1.0,
            "bonus": {"manpower": 0.1, "combat": 0.05}, "idea": "Erbe der Goldenen Horde: +10 % Mannschaften, +5 % Kampfkraft",
            "rulers": ["Küchük Muhammad", "Ahmad", "Sayyid Ahmad", "Shaykh Ahmad"]},
    "NOG": {"religion": "sunni", "name": "Nogaier", "color": "#b5654a", "emoji": "🏹", "capital": "saraychik", "aggression": 1.1,
            "bonus": {"manpower": 0.15}, "idea": "Reiterhorden zwischen Wolga und Jaik: +15 % Mannschaften",
            "rulers": ["Waqqas", "Musa", "Yusuf", "Ismail"]},
    "PRM": {"religion": "orthodox", "name": "Groß-Perm", "color": "#5d7fa3", "emoji": "🦌", "capital": "cherdyn", "aggression": 0.5,
            "bonus": {"trade": 0.1}, "idea": "Pelzhandel an der Kama: +10 % Handelseinnahmen",
            "rulers": ["Michail", "Matwei", "Fjodor"]},
    "SIB": {"religion": "sunni", "name": "Sibir", "color": "#7a6a9a", "emoji": "🐺", "capital": "isker", "aggression": 0.9,
            "bonus": {"manpower": 0.1, "tech_cost": 0.15}, "idea": "Khanat an Tobol und Irtysch: +10 % Mannschaften (Technik +15 % teurer)",
            "rulers": ["Hajji Muhammad", "Ibak", "Mamuq", "Kuchum"]},
    "YUG": {"religion": "native", "name": "Jugra", "color": "#4f7a8a", "emoji": "🦌", "capital": "yugra", "aggression": 0.6, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Fürstentümer der Chanten und Mansen: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Asyka", "Molkan", "Kurtschuk"]},
    "SEL": {"religion": "native", "name": "Bunte Horde", "color": "#8a8a4f", "emoji": "🐻", "capital": "narym", "aggression": 0.6, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Selkupen am mittleren Ob: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Woni", "Kitschei", "Taibochta"]},
    "NEN": {"religion": "native", "name": "Samojeden", "color": "#9ab0c0", "emoji": "🦌", "capital": "bolshezemel", "aggression": 0.4, "native": True,
            "bonus": {"defense": 0.15, "tech_cost": 0.3}, "idea": "Rentierhirten der Tundra: +15 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Wauli", "Pyrerka", "Ladukei"]},
    "KYR": {"religion": "native", "name": "Jenissei-Kirgisen", "color": "#a05a7a", "emoji": "🐎", "capital": "khakas", "aggression": 0.9, "native": True,
            "bonus": {"manpower": 0.1, "tech_cost": 0.3}, "idea": "Reiter des Minussinsker Beckens: +10 % Mannschaften (Technik +30 % teurer)",
            "rulers": ["Ischei", "Tabun", "Kartschyga"]},
    "EVK": {"religion": "native", "name": "Ewenken", "color": "#6a9a5a", "emoji": "🏹", "capital": "tunguska", "aggression": 0.4, "native": True,
            "bonus": {"defense": 0.15, "tech_cost": 0.3}, "idea": "Jäger der Taiga: +15 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Gantimur", "Bojaki", "Ljunda"]},
    "BRT": {"religion": "native", "name": "Burjaten", "color": "#c08040", "emoji": "🐎", "capital": "irkutsk", "aggression": 0.7, "native": True,
            "bonus": {"manpower": 0.1, "tech_cost": 0.3}, "idea": "Hirten am Baikal: +10 % Mannschaften (Technik +30 % teurer)",
            "rulers": ["Bulagat", "Ekirit", "Chori"]},
    "YAK": {"religion": "native", "name": "Jakuten", "color": "#8a5a3a", "emoji": "🐴", "capital": "yakutsk", "aggression": 0.6, "native": True,
            "bonus": {"production": 0.1, "tech_cost": 0.3}, "idea": "Pferde- und Rinderzucht an der Lena: +10 % Produktion (Technik +30 % teurer)",
            "rulers": ["Tygyn", "Omogoi", "Ellei"]},
    "YUK": {"religion": "native", "name": "Jukagiren", "color": "#5a6aa0", "emoji": "🦌", "capital": "indigirka", "aggression": 0.4, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Fischer an Indigirka und Kolyma: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Ataschka", "Kurile"]},
    "CHK": {"religion": "native", "name": "Tschuktschen", "color": "#a04040", "emoji": "🐋", "capital": "anadyr", "aggression": 0.7, "native": True,
            "bonus": {"defense": 0.2, "tech_cost": 0.3}, "idea": "Unbezwungene Krieger der Beringstraße: +20 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Kotschen", "Ejgeli"]},
    "ITL": {"religion": "native", "name": "Itelmenen", "color": "#3a8a8a", "emoji": "🐟", "capital": "kamchatka", "aggression": 0.4, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Lachsfischer Kamtschatkas: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Kamak", "Fedka", "Harschin"]},
}


def flag_art(h):
    """Stylised flags; h = the helpers of tools/art/flags.py."""
    rc, cen, solid = h["recolor"], h["centred"], h["solid"]
    return {
        "GHO": (cen(solid("G"), rc(h["TAMGA"], {"G": "R"}), cy=4), "Great Horde – red tamga on gold (stylised)"),
        "NOG": (cen(h["per_pale"]("O", "G"), rc(h["TAMGA"], h["TO_INK"]), cy=4), "Nogai – black tamga on brown and gold (stylised)"),
        "PRM": (h["cross"](solid("B"), "w", 3), "Great Perm – white cross on blue (stylised)"),
        "SIB": (cen(solid("U"), rc(h["CRESCENT"], h["TO_GOLD"]), cy=3), "Sibir – gold crescent on purple (stylised)"),
        "YUG": (cen(h["field"]("F", "w", "F"), h["BIRD"]), "Yugra – bird on green and white (stylised)"),
        "SEL": (h["stripes"](["G", "k"], 6, vertical=True), "Piebald Horde – gold and black pales (stylised)"),
        "NEN": (h["field"]("w", "B"), "Samoyeds – white over blue (stylised)"),
        "KYR": (cen(solid("R"), rc(h["SUN"], {"Y": "G", "D": "G"})), "Yenisei Kyrgyz – gold sun on red (stylised)"),
        "EVK": (h["field"]("L", "F"), "Evenks – light over dark green (stylised)"),
        "BRT": (cen(solid("O"), h["SUN"]), "Buryats – sun on brown (stylised)"),
        "YAK": (cen(solid("N"), rc(h["SUN"], h["TO_WHITE"])), "Yakuts – white sun on dark blue (stylised)"),
        "YUK": (h["field"]("B", "w", "B"), "Yukaghirs – blue, white, blue (stylised)"),
        "CHK": (h["border"](solid("w"), "R", 2), "Chukchi – white in a red border (stylised)"),
        "ITL": (cen(solid("L"), h["WAVES"]), "Itelmens – waves on green (stylised)"),
    }


GOODS = """
furs: kola pechora mezen komi cherdyn obdorsk berezov surgut narym yugra pelym turukhansk tunguska podkamennaya ilimsk vitim olekma aldan olenek bratsk vilyuy zhigansk verkhoyansk indigirka kolyma koryak kamchatka_n nordland lappmark
fish: finnmark pomorye iceland okhotsk kamchatka anadyr chukotka trondelag
naval_supplies: dvina ostrobothnia
timber: kargopol ustyug vyatka galich savo norrland taz
grain: bryansk kursk voronezh tambov mordva cheremis udmurt perm tyumen isker samara saratov
livestock: don terek saraychik yaik sakmara bashkir ishim baraba iset tara khakas irkutsk zabaikal yakutsk barguzin bolshezemel yamal taymyr
salt: astrakhan
horses: sarai
iron: kuznetsk
silver: krasnoyarsk
cloth: azov
copper: tomsk
"""
MARKETS = ["sarai", "isker"]

ALLIANCES = []
RIVALS = [["GHO", "CRI"], ["NOG", "GHO"], ["SIB", "NOG"], ["RUS", "GHO"]]
