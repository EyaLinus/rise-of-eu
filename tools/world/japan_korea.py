"""Phase D2 of the world map: Korea, Japan, Ryukyu and Ezo.

1444: Sejong the Great rules Joseon and is about to give Korea its own script. In Japan the Ashikaga shogun is
a boy; the great shugo houses rule the provinces: Hosokawa (Settsu, Shikoku), Hatakeyama (Kawachi, Kii,
Noto), Yamana (San'in, Harima after the Kakitsu affair), Ouchi (Suo, Nagato, north Kyushu), Shiba (Echizen,
Owari), Uesugi (the Kanto), Imagawa, Takeda, Date, the Ando in the far north, Otomo, Shoni and Shimazu on
Kyushu. The Sho kings have just united Ryukyu; Ezo is the land of the Ainu.
"""

BLOCK = "jk"
FLAGS = {}

PROVINCES = [
    # Joseon
    ("hanseong", "Hanseong", 127.0, 37.55, "JOS", 10),
    ("chungcheong", "Chungcheong", 127.3, 36.5, "JOS", 6),
    ("jeolla", "Jeolla", 126.9, 35.2, "JOS", 7),
    ("gyeongsang", "Gyeongsang", 128.6, 35.8, "JOS", 7),
    ("dongnae", "Dongnae", 129.05, 35.15, "JOS", 4),
    ("gangwon", "Gangwon", 128.4, 37.7, "JOS", 4),
    ("hwanghae", "Hwanghae", 125.9, 38.1, "JOS", 5),
    ("pyongyang", "Pjöngjang", 125.75, 39.1, "JOS", 6),
    ("uiju", "Uiju", 124.8, 40.2, "JOS", 3),
    ("hamhung", "Hamhung", 127.5, 39.9, "JOS", 4),
    ("six_garrisons", "Sechs Garnisonen", 129.6, 42.0, "JOS", 2),
    ("jeju", "Jeju", 126.55, 33.4, "JOS", 2),
    # Japan: the home provinces and the west
    ("kyoto", "Kyōto", 135.75, 35.0, "ASH", 10),
    ("kii", "Kii-Yamato", 135.6, 33.9, "HTK", 6),
    ("noto", "Noto", 136.9, 37.0, "HTK", 3),
    ("harima", "Harima", 134.7, 34.85, "YMN", 5),
    ("bizen", "Bizen", 133.9, 34.7, "YMN", 4),
    ("izumo", "Izumo", 132.75, 35.35, "YMN", 4),
    ("aki", "Aki", 132.45, 34.4, "OUC", 4),
    ("nagato", "Suō-Nagato", 131.3, 34.15, "OUC", 6),
    ("chikuzen", "Chikuzen", 130.4, 33.6, "OUC", 5),
    ("sanuki", "Sanuki", 134.0, 34.2, "HSK", 5),
    ("tosa", "Tosa", 133.4, 33.5, "HSK", 3),
    ("iyo", "Iyo", 132.8, 33.85, "HSK", 4),
    # Japan: the east
    ("owari", "Owari", 136.9, 35.2, "SBA", 6),
    ("echizen", "Echizen", 136.2, 36.05, "SBA", 5),
    ("shinano", "Shinano", 138.1, 36.3, "TKD", 3),
    ("kai", "Kai", 138.6, 35.65, "TKD", 3),
    ("suruga", "Suruga", 138.3, 34.95, "IMG", 4),
    ("sagami", "Sagami", 139.35, 35.35, "UES", 4),
    ("musashi", "Musashi", 139.6, 36.1, "UES", 5),
    ("hitachi", "Hitachi", 140.4, 36.4, "UES", 3),
    ("echigo", "Echigo", 139.0, 37.6, "UES", 4),
    ("mutsu", "Mutsu", 140.9, 38.3, "DTE", 4),
    ("dewa", "Dewa", 140.1, 39.0, "DTE", 3),
    ("tsugaru", "Tsugaru", 140.6, 40.6, "AND", 2),
    ("oshima", "Oshima", 140.6, 41.8, "AND", 1),
    ("ezo", "Ezo", 142.8, 43.4, "AIN", 1, 3.5),
    # Kyushu, Tsushima
    ("hizen", "Hizen", 129.9, 33.1, "SHO", 3),
    ("tsushima", "Tsushima", 129.3, 34.4, "SHO", 1),
    ("bungo", "Bungo", 131.6, 33.2, "OTO", 4),
    ("higo", "Higo", 130.75, 32.7, "OTO", 3),
    ("satsuma", "Satsuma", 130.5, 31.6, "SHZ", 4),
    ("hyuga", "Hyūga", 131.4, 32.0, "SHZ", 2),
    # Ryukyu
    ("okinawa", "Okinawa", 127.7, 26.3, "RYU", 3, 1.6),
    ("amami", "Amami", 129.5, 28.3, "RYU", 1, 1.6),
]

STRAITS = [("dongnae", "tsushima"), ("tsushima", "hizen"), ("nagato", "chikuzen"), ("aki", "iyo"), ("harima", "sanuki"),
           ("kii", "sanuki"), ("tsugaru", "oshima"), ("satsuma", "amami"), ("amami", "okinawa"), ("jeolla", "jeju")]
LAND_LINKS = []

TERRAIN = {"hanseong": "plains", "jeolla": "plains", "chungcheong": "hills", "gyeongsang": "hills", "gangwon": "mountains",
           "hamhung": "hills", "six_garrisons": "mountains", "pyongyang": "plains", "hwanghae": "plains", "uiju": "hills",
           "kyoto": "plains", "owari": "plains", "musashi": "plains", "echigo": "plains", "shinano": "mountains", "kai": "mountains",
           "hitachi": "plains", "harima": "plains", "ezo": "forest", "oshima": "forest", "okinawa": "forest", "amami": "forest",
           "tsushima": "hills"}


def DEFAULT_TERRAIN(key, lat):
    return "hills"


RANGES = [
    (0.6, [(127.0, 40.4), (127.8, 39.4), (128.4, 38.4), (128.8, 37.4), (129.2, 36.4), (128.8, 35.6)]),  # Taebaek
    (0.75, [(127.4, 41.4), (128.4, 41.6), (129.4, 41.8)]),  # Hamgyong
    (0.4, [(127.4, 36.8), (127.8, 36.0), (127.6, 35.2)]),  # Sobaek
    (0.95, [(137.6, 36.8), (137.8, 36.0), (138.2, 35.4)]),  # Japan Alps
    (0.6, [(138.6, 35.4), (138.7, 35.5)]),  # Fuji
    (0.5, [(140.0, 37.2), (140.4, 38.4), (140.8, 39.6), (140.9, 40.4)]),  # Ou mountains
    (0.4, [(132.0, 34.6), (133.0, 35.0), (134.0, 35.2), (135.0, 35.4)]),  # Chugoku
    (0.45, [(132.6, 33.6), (133.4, 33.8), (134.2, 33.8)]),  # Shikoku
    (0.5, [(131.0, 33.0), (131.1, 32.4), (130.9, 31.8)]),  # Kyushu (Aso, Kirishima)
    (0.45, [(142.6, 42.6), (142.8, 43.6), (143.0, 44.4)]),  # Hidaka
]

RIVERS = [
    ("Han", 1, [(128.6, 37.4), (127.8, 37.5), (127.0, 37.5), (126.6, 37.7)]),
    ("Naktong", 1, [(128.8, 36.6), (128.4, 35.9), (128.6, 35.4), (128.9, 35.1)]),
    ("Yalu", 1, [(128.0, 41.6), (126.4, 41.2), (125.4, 40.6), (124.4, 40.0)]),
    ("Taedong", 1, [(126.8, 39.8), (126.0, 39.2), (125.4, 38.8)]),
    ("Tone", 1, [(139.0, 36.8), (139.6, 36.2), (140.4, 35.8), (140.8, 35.7)]),
    ("Shinano", 1, [(138.4, 36.0), (138.2, 36.6), (138.8, 37.4), (139.0, 37.9)]),
]

NATIONS = {
    "JOS": {"religion": "confucian", "devout": True, "name": "Joseon", "color": "#4a8ab8", "emoji": "📜", "capital": "hanseong", "aggression": 0.4,
            "bonus": {"tech_cost": -0.1, "tax": 0.05}, "idea": "Sejongs Akademie der Weisen: Technik −10 %, +5 % Steuern",
            "rulers": ["Sejong", "Munjong", "Danjong", "Sejo", "Seongjong", "Jungjong"]},
    "ASH": {"religion": "shinto", "name": "Ashikaga-Shogunat", "color": "#e8e0d0", "emoji": "⛩️", "capital": "kyoto", "aggression": 0.6,
            "bonus": {"prestige": 1.0, "dip": 0.5}, "idea": "Der Shōgun in Kyōto: +1 Prestige/Jahr, +0,5 Diplomatie",
            "rulers": ["Ashikaga Yoshikatsu", "Ashikaga Yoshimasa", "Ashikaga Yoshihisa", "Ashikaga Yoshitane"]},
    "HSK": {"religion": "shinto", "name": "Hosokawa", "color": "#3a6a9a", "emoji": "🎌", "capital": "sanuki", "aggression": 0.9,
            "bonus": {"trade": 0.1, "combat": 0.05}, "idea": "Kanrei und Herren von Shikoku: +10 % Handel, +5 % Kampfkraft",
            "rulers": ["Hosokawa Katsumoto", "Hosokawa Masamoto", "Hosokawa Takakuni"]},
    "HTK": {"religion": "shinto", "name": "Hatakeyama", "color": "#9a5a3a", "emoji": "🎌", "capital": "kii", "aggression": 0.8,
            "bonus": {"manpower": 0.1}, "idea": "Kanrei-Haus von Kawachi: +10 % Mannschaften",
            "rulers": ["Hatakeyama Mochikuni", "Hatakeyama Yoshinari", "Hatakeyama Masanaga"]},
    "YMN": {"religion": "shinto", "name": "Yamana", "color": "#b03a4a", "emoji": "🎌", "capital": "izumo", "aggression": 1.0,
            "bonus": {"combat": 0.1}, "idea": "Herren über ein Sechstel Japans: +10 % Kampfkraft",
            "rulers": ["Yamana Sōzen", "Yamana Masatoyo", "Yamana Toshitoyo"]},
    "OUC": {"religion": "shinto", "name": "Ōuchi", "color": "#8a3a8a", "emoji": "🎌", "capital": "nagato", "aggression": 0.9,
            "bonus": {"trade": 0.15}, "idea": "Handel mit Ming und Joseon: +15 % Handelseinnahmen",
            "rulers": ["Ōuchi Norihiro", "Ōuchi Masahiro", "Ōuchi Yoshioki", "Ōuchi Yoshitaka"]},
    "SBA": {"religion": "shinto", "name": "Shiba", "color": "#6a9a4a", "emoji": "🎌", "capital": "echizen", "aggression": 0.7,
            "bonus": {"tax": 0.1}, "idea": "Kanrei-Haus von Echizen und Owari: +10 % Steuern",
            "rulers": ["Shiba Yoshitake", "Shiba Yoshitoshi", "Shiba Yoshikado"]},
    "TKD": {"religion": "shinto", "name": "Takeda", "color": "#c04a2a", "emoji": "🐎", "capital": "kai", "aggression": 1.0,
            "bonus": {"combat": 0.1, "manpower": 0.05}, "idea": "Reiter aus Kai: +10 % Kampfkraft, +5 % Mannschaften",
            "rulers": ["Takeda Nobushige", "Takeda Nobumasa", "Takeda Nobutora", "Takeda Shingen"]},
    "IMG": {"religion": "shinto", "name": "Imagawa", "color": "#c0a04a", "emoji": "🎌", "capital": "suruga", "aggression": 0.8,
            "bonus": {"production": 0.1}, "idea": "Hof von Sunpu: +10 % Produktion",
            "rulers": ["Imagawa Noritada", "Imagawa Yoshitada", "Imagawa Ujichika", "Imagawa Yoshimoto"]},
    "UES": {"religion": "shinto", "name": "Uesugi", "color": "#4a5a8a", "emoji": "🎌", "capital": "sagami", "aggression": 0.8,
            "bonus": {"defense": 0.1, "manpower": 0.05}, "idea": "Kantō-Kanrei: +10 % Verteidigung, +5 % Mannschaften",
            "rulers": ["Uesugi Noritada", "Uesugi Fusaaki", "Uesugi Akisada", "Uesugi Kenshin"]},
    "DTE": {"religion": "shinto", "name": "Date", "color": "#2a3a5a", "emoji": "🌙", "capital": "mutsu", "aggression": 0.8,
            "bonus": {"manpower": 0.1}, "idea": "Herren von Ōshū: +10 % Mannschaften",
            "rulers": ["Date Mochimune", "Date Shigemune", "Date Hisamune", "Date Masamune"]},
    "AND": {"religion": "shinto", "name": "Andō", "color": "#5a7a6a", "emoji": "⛵", "capital": "tsugaru", "aggression": 0.5,
            "bonus": {"trade": 0.1}, "idea": "Handel mit Ezo: +10 % Handelseinnahmen",
            "rulers": ["Andō Morisue", "Andō Masasue", "Andō Tadasue"]},
    "SHO": {"religion": "shinto", "name": "Shōni", "color": "#9a8a5a", "emoji": "🎌", "capital": "hizen", "aggression": 0.6,
            "bonus": {"trade": 0.05, "defense": 0.05}, "idea": "Hüter von Dazaifu: +5 % Handel, +5 % Verteidigung",
            "rulers": ["Shōni Noriyori", "Shōni Masasuke", "Shōni Sukemoto"]},
    "OTO": {"religion": "shinto", "name": "Ōtomo", "color": "#5a8aa0", "emoji": "🎌", "capital": "bungo", "aggression": 0.7,
            "bonus": {"trade": 0.1}, "idea": "Hafen von Funai: +10 % Handelseinnahmen",
            "rulers": ["Ōtomo Chikashige", "Ōtomo Chikatsuna", "Ōtomo Yoshiaki", "Ōtomo Sōrin"]},
    "SHZ": {"religion": "shinto", "name": "Shimazu", "color": "#d0d0d0", "emoji": "✚", "capital": "satsuma", "aggression": 0.9,
            "bonus": {"combat": 0.1, "manpower": 0.05}, "idea": "Krieger aus Satsuma: +10 % Kampfkraft, +5 % Mannschaften",
            "rulers": ["Shimazu Tadakuni", "Shimazu Tatsuhisa", "Shimazu Tadamasa", "Shimazu Yoshihisa"]},
    "RYU": {"religion": "shinto", "name": "Ryūkyū", "color": "#d08a5a", "emoji": "🐚", "capital": "okinawa", "aggression": 0.3,
            "bonus": {"trade": 0.2}, "idea": "Brücke der Völker: +20 % Handelseinnahmen",
            "rulers": ["Shō Shitatsu", "Shō Kinpuku", "Shō Taikyū", "Shō Toku", "Shō Shin"]},
    "AIN": {"religion": "native", "name": "Ainu", "color": "#6a8a9a", "emoji": "🐻", "capital": "ezo", "aggression": 0.4, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Kotan der Ainu: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Koshamain", "Shakushain", "Tanasashi"]},
}

TAEGEUK = ["..RRRR..", ".RRRRRR.", "RRRRRRRR", "RRRRBBBB", "BBBBBBBB", ".BBBBBB.", "..BBBB.."]
MON_RING = ["..kkkk..", ".k....k.", "k......k", "k......k", "k......k", ".k....k.", "..kkkk.."]
BARS = ["kkkkkkkk", "........", "........", "kkkkkkkk"]
CROSS_RING = ["..kkkk..", ".k.kk.k.", "k..kk..k", "kkkkkkkk", "k..kk..k", ".k.kk.k.", "..kkkk.."]


def flag_art(h):
    rc, cen, solid = h["recolor"], h["centred"], h["solid"]
    W = h["TO_WHITE"]
    ring_on = lambda base, ink: cen(solid(base), rc(MON_RING, {"k": ink}), cy=3)  # noqa: E731
    return {
        "JOS": (cen(solid("w"), TAEGEUK, cy=3), "Joseon – red and blue on white (stylised)"),
        "ASH": (cen(solid("w"), BARS, cy=5), "Ashikaga – two black bars (hikiryō, stylised)"),
        "HSK": (ring_on("B", "w"), "Hosokawa – white mon on blue (stylised)"),
        "HTK": (ring_on("O", "k"), "Hatakeyama – black mon on orange (stylised)"),
        "YMN": (ring_on("R", "w"), "Yamana – white mon on red (stylised)"),
        "OUC": (cen(solid("P"), rc(h["SUN"], W), cy=3), "Ōuchi – white mon on purple (stylised)"),
        "SBA": (cen(solid("L"), rc(BARS, {"k": "w"}), cy=5), "Shiba – white bars on green (stylised)"),
        "TKD": (cen(solid("R"), rc(h["KNOT"], {"w": "k"}), cy=3), "Takeda – black lozenges on red (stylised)"),
        "IMG": (cen(solid("Y"), rc(BARS, {}), cy=5), "Imagawa – black bars on gold (stylised)"),
        "UES": (ring_on("N", "w"), "Uesugi – white mon on navy (stylised)"),
        "DTE": (cen(solid("N"), rc(h["CRESCENT"], h["TO_GOLD"]), cy=3), "Date – gold crescent on navy (stylised)"),
        "AND": (h["field"]("w", "L"), "Andō – white and green (stylised)"),
        "SHO": (ring_on("D", "w"), "Shōni – white mon on dark gold (stylised)"),
        "OTO": (cen(solid("B"), rc(BARS, {"k": "w"}), cy=5), "Ōtomo – white bars on blue (stylised)"),
        "SHZ": (cen(solid("w"), CROSS_RING, cy=3), "Shimazu – cross in a ring (stylised)"),
        "RYU": (cen(solid("R"), rc(h["SUN"], W), cy=3), "Ryukyu – white sun on red (stylised)"),
        "AIN": (cen(solid("B"), rc(h["KNOT"], {}), cy=3), "Ainu – white pattern on blue (stylised)"),
    }


GOODS = """
grain: hanseong chungcheong jeolla hwanghae pyongyang owari musashi echigo harima kyoto
cloth: gyeongsang kii
paper: dongnae
livestock: gangwon uiju six_garrisons jeju
iron: hamhung izumo
silver: bizen
copper: aki
salt: nagato
spices: okinawa amami
fish: noto tsushima tsugaru oshima hitachi
silk: sanuki
timber: tosa iyo shinano mutsu dewa hyuga
horses: kai
tea: suruga
naval_supplies: sagami chikuzen
glass: hizen
gold: higo
wool: bungo satsuma
furs: ezo
dyes: echizen
"""
MARKETS = ["hanseong", "kyoto", "chikuzen"]

ALLIANCES = [["HSK", "ASH"]]
RIVALS = [["HSK", "YMN"], ["OUC", "SHO"], ["UES", "TKD"], ["SHZ", "OTO"], ["HTK", "HSK"], ["IMG", "SBA"]]
