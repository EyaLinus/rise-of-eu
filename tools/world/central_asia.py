"""Phase B of the world map: Central Asia, eastern Persia, Afghanistan and the Indus (Sindh, Multan, Baluchistan).

1444: Shah Rukh's Timurid empire still holds Khorasan, Herat (its capital), Transoxiana, Khwarazm, Kabul and
Kandahar. North of the Syr Darya Abu'l-Khayr's Uzbeks rule the Kipchak steppe, east of them the khans of
Moghulistan the Seven Rivers and the oases of the Tarim basin. Turkmen tribes roam the Karakum and the Caspian
shore, the Mihrabanid maliks hold Sistan, Baloch chiefs Makran and Kalat. On the lower Indus the Samma rule
Sindh from Thatta, Multan is breaking away from Delhi.
"""

BLOCK = "ca"
FLAGS = {}

PROVINCES = [
    # eastern Persia and Khorasan
    ("kerman", "Kerman", 57.1, 30.3, "TIM", 5, 2.4),
    ("tabas", "Tabas", 56.9, 33.6, "TIM", 2, 2.4),
    ("astarabad", "Astarabad", 54.6, 36.9, "TIM", 4),
    ("nishapur", "Nischapur", 58.8, 36.2, "TIM", 7),
    ("kuhistan", "Kuhistan", 59.2, 33.4, "TIM", 3, 2.4),
    ("herat", "Herat", 62.2, 34.35, "TIM", 10),
    ("merv", "Merw", 61.8, 37.6, "TIM", 5),
    ("sistan", "Sistan", 61.5, 31.0, "SIS", 3, 2.6),
    # the Turkmen
    ("dahistan", "Dehistan", 55.2, 38.8, "TKM", 2, 2.6),
    ("mangyshlak", "Mangyschlak", 52.6, 44.0, "TKM", 1, 3.0),
    ("karakum", "Karakum", 59.4, 39.4, "TKM", 1, 3.0),
    ("ustyurt", "Ustjurt", 56.6, 42.6, "TKM", 1, 3.0),
    # Transoxiana and Khwarazm
    ("khwarazm", "Choresmien", 60.6, 41.6, "TIM", 6),
    ("bukhara", "Buchara", 64.4, 39.8, "TIM", 9),
    ("samarkand", "Samarkand", 66.96, 39.65, "TIM", 12),
    ("balkh", "Balch", 66.9, 36.75, "TIM", 7),
    ("maimana", "Fariab", 64.8, 35.9, "TIM", 3),
    ("badakhshan", "Badachschan", 70.8, 37.1, "TIM", 3),
    ("hissar", "Hissar", 68.8, 38.6, "TIM", 4),
    ("khujand", "Chudschand", 69.6, 40.3, "TIM", 5),
    ("ferghana", "Ferghana", 72.0, 40.7, "TIM", 6),
    ("tashkent", "Taschkent", 69.3, 41.35, "TIM", 6),
    # Afghanistan
    ("kabul", "Kabul", 69.2, 34.5, "TIM", 7),
    ("kandahar", "Kandahar", 65.7, 31.6, "TIM", 5, 2.6),
    ("ghazni", "Ghazni", 68.4, 33.4, "TIM", 3),
    ("hazara", "Hazaradschat", 66.2, 34.2, "TIM", 2),
    ("peshawar", "Peschawar", 71.6, 34.0, "TIM", 4),
    # the Uzbeks of the Kipchak steppe
    ("turkestan", "Turkestan", 68.2, 43.3, "SHY", 4),
    ("syr_darya", "Syrdarja", 65.5, 44.9, "SHY", 2, 3.0),
    ("ulytau", "Ulytau", 67.0, 48.0, "SHY", 2, 4.0),
    ("turgai", "Turgai", 63.5, 50.4, "SHY", 1, 4.0),
    ("irgiz", "Irgis", 60.6, 48.2, "SHY", 1, 4.0),
    ("emba", "Emba", 56.0, 47.6, "NOG", 1, 3.5),
    ("kokshetau", "Kökschetau", 69.4, 53.0, "SHY", 1, 4.0),
    ("saryarka", "Sarjarka", 75.0, 49.6, "SHY", 1, 4.0),
    ("semey", "Semipalatinsk", 80.4, 50.6, "SHY", 1, 4.0),
    ("betpak", "Betpak-Dala", 70.4, 45.8, "SHY", 1, 4.0),
    # Moghulistan: the Seven Rivers and the Tarim oases
    ("taraz", "Taras", 71.4, 42.9, "MOG", 3),
    ("almaty", "Almaty", 76.9, 43.3, "MOG", 3),
    ("jetisu", "Siebenstromland", 78.8, 45.4, "MOG", 2, 3.5),
    ("issyk_kul", "Issyk-Kul", 78.4, 41.8, "MOG", 2),
    ("ili", "Ili", 81.4, 44.0, "MOG", 2, 3.0),
    ("kashgar", "Kaschgar", 76.0, 39.5, "MOG", 5, 2.6),
    ("yarkand", "Jarkand", 77.3, 38.2, "MOG", 4, 2.6),
    ("khotan", "Chotan", 79.9, 37.1, "MOG", 3, 3.0),
    ("aksu", "Aksu", 80.3, 41.2, "MOG", 3, 3.0),
    ("kucha", "Kutscha", 83.0, 41.7, "MOG", 2, 3.0),
    ("turfan", "Turfan", 89.2, 42.95, "MOG", 3, 3.0),
    # Baluchistan, Sindh and Multan
    ("kalat", "Kalat", 66.6, 29.0, "BLC", 2, 2.6),
    ("makran", "Makran", 63.0, 26.2, "BLC", 2, 2.6),
    ("bampur", "Bampur", 60.4, 27.3, "BLC", 1, 2.6),
    ("thatta", "Thatta", 67.9, 24.8, "SND", 6),
    ("sehwan", "Sehwan", 67.9, 26.4, "SND", 3),
    ("bakkar", "Bakkar", 68.9, 27.8, "SND", 4),
    ("multan", "Multan", 71.5, 30.2, "MUL", 7),
    ("derajat", "Deradschat", 70.6, 31.8, "MUL", 2),
]

STRAITS = []
LAND_LINKS = []

DESERT = {"tabas", "kerman", "sistan", "karakum", "ustyurt", "mangyshlak", "dahistan", "syr_darya", "betpak", "khotan", "kucha",
          "turfan", "makran", "bampur", "kalat", "kuhistan", "khwarazm", "irgiz"}
TERRAIN = {"khwarazm": "plains", "bukhara": "plains", "samarkand": "plains", "merv": "plains", "kashgar": "plains", "ferghana": "plains",
           "thatta": "plains", "bakkar": "plains", "sehwan": "plains", "multan": "plains", "derajat": "desert"}


def DEFAULT_TERRAIN(key, lat):
    return "desert" if key in DESERT else "plains"


RANGES = [
    (0.6, [(54.0, 37.6), (56.0, 37.9), (58.0, 37.6), (59.6, 37.0), (61.0, 36.4)]),  # Kopet Dag
    (0.45, [(56.4, 36.6), (58.0, 36.5), (59.6, 36.0)]),  # Binalud
    (0.55, [(61.6, 34.8), (63.4, 34.9), (65.2, 35.0), (66.8, 34.8)]),  # Paropamisus
    (1.0, [(66.8, 34.8), (68.4, 35.0), (69.8, 35.4), (71.0, 36.0), (72.4, 36.4), (74.0, 36.8)]),  # Hindu Kush
    (1.0, [(72.0, 37.4), (73.0, 38.2), (74.2, 38.6), (75.0, 38.0)]),  # Pamir
    (0.85, [(69.6, 39.6), (71.4, 39.7), (73.2, 39.6)]),  # Alai
    (0.9, [(70.0, 42.0), (72.6, 42.4), (75.0, 42.6), (77.6, 42.8), (80.0, 42.4), (82.6, 42.6), (85.0, 43.0), (87.6, 43.2), (90.2, 43.4), (93.6, 43.4)]),  # Tian Shan
    (0.55, [(70.6, 41.4), (71.8, 41.6), (73.0, 41.5)]),  # Chatkal
    (0.6, [(78.6, 45.0), (80.6, 45.2), (82.0, 45.4)]),  # Dzungarian Alatau
    (0.95, [(74.6, 37.0), (77.0, 36.4), (79.6, 35.8), (82.4, 36.0), (85.4, 36.2), (88.4, 36.4), (91.0, 36.6)]),  # Kunlun
    (1.0, [(74.2, 36.2), (75.6, 35.8), (77.0, 35.4), (78.4, 34.8)]),  # Karakoram
    (0.6, [(69.6, 28.8), (69.9, 30.2), (70.2, 31.4), (70.4, 32.6)]),  # Sulaiman
    (0.45, [(67.6, 25.6), (67.4, 26.8), (67.2, 28.0)]),  # Kirthar
    (0.4, [(57.8, 26.6), (60.0, 26.8), (62.4, 26.4), (64.6, 26.2)]),  # Makran range
    (0.45, [(65.6, 28.4), (66.4, 29.6), (67.2, 30.8)]),  # Central Brahui
    (0.4, [(56.4, 29.6), (57.6, 29.0), (58.6, 28.6)]),  # Kerman ranges
    (0.35, [(52.8, 43.0), (53.6, 43.6)]),  # Mangyshlak (Karatau)
]

RIVERS = [
    ("Amudarja", 3, [(73.0, 37.4), (70.6, 37.4), (68.4, 37.2), (66.4, 37.4), (65.0, 38.6), (63.4, 39.6), (61.6, 41.0), (60.4, 42.0), (59.8, 43.0), (59.6, 43.6)]),
    ("Syrdarja", 2, [(72.6, 40.8), (71.0, 40.9), (69.6, 40.4), (68.8, 41.0), (68.4, 42.2), (67.6, 43.6), (66.2, 44.6), (64.0, 45.4), (62.2, 46.0), (61.6, 46.2)]),
    ("Serafschan", 1, [(69.4, 39.4), (67.9, 39.6), (66.9, 39.65), (65.4, 39.8), (64.4, 39.8), (63.8, 39.6)]),
    ("Ili", 1, [(83.0, 43.8), (80.6, 44.0), (78.0, 44.0), (76.4, 44.4), (75.2, 45.0), (74.6, 45.4)]),
    ("Tarim", 2, [(76.0, 39.4), (78.4, 40.4), (80.4, 40.6), (82.6, 41.0), (85.0, 41.0), (87.4, 40.6), (88.4, 40.0)]),
    ("Indus", 3, [(77.6, 34.6), (75.6, 35.6), (74.4, 35.8), (73.0, 35.0), (72.4, 34.0), (71.6, 33.0), (71.2, 31.6), (70.6, 30.0), (69.4, 28.6),
                  (68.8, 27.6), (68.2, 26.4), (68.0, 25.4), (67.6, 24.4), (67.2, 24.0)]),
    ("Kabul", 1, [(68.2, 34.4), (69.2, 34.5), (70.4, 34.4), (71.6, 34.0), (72.2, 33.9)]),
    ("Hilmend", 2, [(68.4, 34.4), (66.6, 33.2), (65.0, 31.8), (63.4, 31.0), (62.0, 31.0), (61.4, 31.2)]),
    ("Harirud", 1, [(65.8, 34.6), (63.6, 34.4), (62.2, 34.4), (61.0, 35.4), (60.8, 36.4), (61.4, 37.2), (61.8, 37.6)]),
]

NATIONS = {
    "SHY": {"religion": "sunni", "name": "Usbeken", "color": "#4f8f8a", "emoji": "🏹", "capital": "turkestan", "aggression": 1.2,
            "bonus": {"manpower": 0.15, "combat": 0.05}, "idea": "Abu'l-Chairs Steppenreiter: +15 % Mannschaften, +5 % Kampfkraft",
            "rulers": ["Abu'l-Chair", "Schaibani", "Köchkundschi", "Ubaidullah"]},
    "MOG": {"religion": "sunni", "name": "Moghulistan", "color": "#9c7a4a", "emoji": "🐎", "capital": "almaty", "aggression": 1.0,
            "bonus": {"manpower": 0.1, "trade": 0.05}, "idea": "Chane der Seidenstraße: +10 % Mannschaften, +5 % Handelseinnahmen",
            "rulers": ["Esen Buqa", "Yunus", "Ahmad Alaq", "Mansur"]},
    "TKM": {"religion": "sunni", "name": "Turkmenen", "color": "#8a9a6a", "emoji": "🐪", "capital": "dahistan", "aggression": 0.9,
            "bonus": {"manpower": 0.1, "defense": 0.05}, "idea": "Stämme der Karakum: +10 % Mannschaften, +5 % Verteidigung",
            "rulers": ["Ali Jan", "Kara Tegin", "Salor Khan"]},
    "SIS": {"religion": "sunni", "name": "Sistan", "color": "#c07a5a", "emoji": "🌾", "capital": "sistan", "aggression": 0.5,
            "bonus": {"production": 0.1}, "idea": "Kornkammer am Hilmend: +10 % Produktion",
            "rulers": ["Shah Mahmud", "Nizam ad-Din Yahya", "Shah Ali"]},
    "BLC": {"religion": "sunni", "name": "Belutschen", "color": "#a08a6a", "emoji": "🏜️", "capital": "kalat", "aggression": 0.8,
            "bonus": {"defense": 0.15}, "idea": "Bergstämme von Kalat: +15 % Verteidigung",
            "rulers": ["Mir Chakar", "Mir Shahdad", "Mir Gwahram"]},
    "SND": {"religion": "sunni", "name": "Sindh", "color": "#5aa08a", "emoji": "🛶", "capital": "thatta", "aggression": 0.6,
            "bonus": {"trade": 0.1, "production": 0.05}, "idea": "Samma-Sultanat am Indusdelta: +10 % Handel, +5 % Produktion",
            "rulers": ["Jam Sikandar", "Jam Sanjar", "Jam Nizamuddin", "Jam Feroz"]},
    "MUL": {"religion": "sunni", "name": "Multan", "color": "#b04a6a", "emoji": "🕌", "capital": "multan", "aggression": 0.7,
            "bonus": {"tax": 0.1}, "idea": "Stadt der Heiligen: +10 % Steuern",
            "rulers": ["Shaikh Yusuf", "Rai Sahra", "Husain Langah", "Mahmud Langah"]},
}

# changes to realms of the old map: the Timurids rule from Herat (Shah Rukh)
NATION_UPDATES = {"TIM": {"capital": "herat"}}


def flag_art(h):
    rc, cen, solid = h["recolor"], h["centred"], h["solid"]
    return {
        "SHY": (cen(solid("L"), rc(h["TAMGA"], h["TO_WHITE"]), cy=4), "Uzbeks – white tamga on green (stylised)"),
        "MOG": (cen(h["field"]("G", "O"), rc(h["CRESCENT"], h["TO_WHITE"]), cy=3), "Moghulistan – white crescent on gold and brown (stylised)"),
        "TKM": (cen(solid("F"), rc(h["CRESCENT"], h["TO_GOLD"]), cy=3), "Turkmen – gold crescent on dark green (stylised)"),
        "SIS": (h["field"]("R", "G", "R"), "Sistan – red, gold, red (stylised)"),
        "BLC": (h["per_pale"]("R", "k"), "Baloch – red and black (stylised)"),
        "SND": (cen(h["field"]("L", "w"), rc(h["CRESCENT"], {"G": "L", "D": "F"}), cy=3), "Sindh – green crescent on green and white (stylised)"),
        "MUL": (cen(solid("E"), rc(h["CRESCENT"], h["TO_WHITE"]), cy=3), "Multan – white crescent on dark red (stylised)"),
    }


GOODS = """
silk: samarkand bukhara merv khotan
cotton: khwarazm ferghana sehwan
horses: ulytau turgai saryarka jetisu ili kokshetau
livestock: irgiz emba semey betpak syr_darya karakum mangyshlak ustyurt dahistan hazara maimana taraz almaty issyk_kul kalat
cloth: herat tashkent nishapur multan
grain: kerman tabas astarabad kuhistan sistan balkh hissar khujand kabul ghazni peshawar turkestan aksu kucha derajat bakkar
dyes: kandahar thatta
silver: badakhshan
spices: kashgar
copper: yarkand
salt: makran bampur
glass: turfan
"""
MARKETS = ["samarkand", "herat", "thatta"]

ALLIANCES = []
RIVALS = [["TIM", "SHY"], ["MOG", "SHY"], ["TIM", "QAR"], ["SND", "MUL"]]
