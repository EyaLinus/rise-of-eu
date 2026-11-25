"""Phase C of the world map: India, the Himalaya foothills and Ceylon.

1444: the Sayyid sultans of Delhi rule little more than the city and the Doab, Bahlul Lodi holds Sirhind and
Lahore for them. Jaunpur (Sharqi), Bengal (Ilyas Shahi), Malwa (Khalji), Gujarat (Ahmad Shahi), Khandesh
(Faruqi) and the Bahmanis of the Deccan are the great sultanates; their people are mostly Hindu. South of the
Krishna Deva Raya II rules Vijayanagara, Kapilendra's new Gajapati dynasty holds Orissa, Rana Kumbha Mewar.
The Zamorin of Calicut is master of the pepper coast, Kotte the strongest kingdom on Ceylon, Jaffna its Tamil
north. In the hills: the Malla of Kathmandu, the Chand of Kumaon, the Shah Mir sultans of Kashmir, Buddhist
Ladakh, the Ahom on the Brahmaputra.

Provinces carry the faith of their people (RELIGION) where it differs from the ruler's.
"""

BLOCK = "in"
FLAGS = {}

PROVINCES = [
    # Punjab and the Delhi sultanate
    ("lahore", "Lahore", 74.3, 31.55, "DLH", 8),
    ("jhelum", "Dschilam", 73.0, 32.9, "DLH", 3),
    ("dipalpur", "Dipalpur", 73.4, 30.6, "DLH", 3),
    ("sirhind", "Sirhind", 76.4, 30.6, "DLH", 5),
    ("hisar_firoza", "Hissar-Firoza", 75.6, 29.2, "DLH", 3),
    ("delhi", "Delhi", 77.2, 28.6, "DLH", 10),
    ("doab", "Doab", 78.5, 28.0, "DLH", 5),
    ("katehar", "Katehar", 79.5, 28.8, "DLH", 3),
    ("mewat", "Mewat", 76.6, 27.6, "DLH", 3),
    ("agra", "Agra", 78.0, 27.0, "DLH", 4),
    # Jaunpur
    ("kanauj", "Kannauj", 79.9, 27.05, "JNP", 4),
    ("awadh", "Awadh", 81.3, 26.8, "JNP", 6),
    ("kara", "Kara", 81.4, 25.6, "JNP", 4),
    ("jaunpur", "Jaunpur", 82.8, 25.6, "JNP", 8),
    ("gorakhpur", "Gorakhpur", 83.4, 26.8, "JNP", 3),
    ("bihar", "Bihar", 85.4, 25.2, "JNP", 6),
    ("tirhut", "Tirhut", 85.7, 26.3, "JNP", 4),
    ("kalinjar", "Kalindschar", 80.4, 25.0, "JNP", 3),
    ("rewa", "Baghelkhand", 81.5, 24.2, "JNP", 2),
    # Bengal
    ("gaur", "Gaur", 88.1, 24.9, "BNG", 10),
    ("varendra", "Varendra", 89.4, 24.8, "BNG", 4),
    ("sonargaon", "Sonargaon", 90.6, 23.65, "BNG", 7),
    ("mymensingh", "Mymensingh", 90.5, 24.85, "BNG", 3),
    ("satgaon", "Satgaon", 88.3, 22.9, "BNG", 6),
    ("birbhum", "Birbhum", 87.4, 23.8, "BNG", 3),
    ("jessore", "Chalifatabad", 89.5, 22.7, "BNG", 3),
    ("sylhet", "Sylhet", 91.9, 24.9, "BNG", 3),
    ("chittagong", "Chittagong", 91.85, 22.4, "BNG", 4),
    # Kamata, Ahom, Tripura
    ("kamata", "Kamata", 89.5, 26.3, "KMT", 3),
    ("kamrup", "Kamrup", 91.7, 26.2, "KMT", 3),
    ("nagaon", "Kaliabor", 93.1, 26.5, "AHO", 2),
    ("garhgaon", "Garhgaon", 94.6, 27.0, "AHO", 4),
    ("tripura", "Tripura", 91.5, 23.5, "TRP", 3),
    # the Himalaya
    ("kathmandu", "Kathmandu", 85.3, 27.7, "NPL", 5),
    ("morang", "Morang", 87.3, 26.7, "NPL", 2),
    ("palpa", "Palpa", 83.6, 28.0, "NPL", 2),
    ("jumla", "Dschumla", 82.0, 29.3, "NPL", 2),
    ("kumaon", "Kumaon", 79.7, 29.6, "KUM", 2),
    ("garhwal", "Garhwal", 78.7, 30.5, "KUM", 2),
    ("kangra", "Kangra", 76.3, 32.1, "KGR", 3),
    ("srinagar", "Srinagar", 74.8, 34.1, "KSH", 6),
    ("jammu", "Jammu", 74.9, 32.9, "KSH", 3),
    ("baltistan", "Baltistan", 75.6, 35.4, "KSH", 1, 2.6),
    ("ladakh", "Ladakh", 77.6, 34.1, "LDK", 2, 3.0),
    # Rajputana and Gwalior
    ("chittor", "Chittor", 74.6, 24.9, "MEW", 7),
    ("udaipur", "Kumbhalgarh", 73.6, 24.4, "MEW", 3),
    ("ajmer", "Ajmer", 74.6, 26.4, "MEW", 5),
    ("bundi", "Bundi", 75.8, 25.3, "MEW", 3),
    ("sirohi", "Sirohi", 72.9, 25.1, "MEW", 2),
    ("mandore", "Mandor", 73.0, 26.3, "MAW", 5),
    ("nagaur", "Nagaur", 73.8, 27.3, "MAW", 3),
    ("bikaner", "Dschangladesch", 73.3, 28.4, "MAW", 2, 2.6),
    ("jaisalmer", "Jaisalmer", 70.9, 26.9, "MAW", 2, 2.6),
    ("mallani", "Mallani", 71.6, 25.6, "MAW", 1, 2.6),
    ("dhundhar", "Dhundhar", 75.8, 26.9, "AMB", 4),
    ("gwalior", "Gwalior", 78.2, 26.2, "GWA", 5),
    ("narwar", "Narwar", 77.9, 25.4, "GWA", 2),
    # Malwa and Khandesh
    ("mandu", "Mandu", 75.4, 22.35, "MLW", 8),
    ("ujjain", "Ujjain", 75.8, 23.3, "MLW", 6),
    ("chanderi", "Chanderi", 78.1, 24.7, "MLW", 4),
    ("bhilsa", "Bhilsa", 77.8, 23.5, "MLW", 4),
    ("mandsaur", "Mandsaur", 75.1, 24.2, "MLW", 3),
    ("burhanpur", "Burhanpur", 76.2, 21.3, "KHD", 5),
    ("nandurbar", "Nandurbar", 74.3, 21.4, "KHD", 2),
    # Gujarat
    ("ahmedabad", "Ahmedabad", 72.6, 23.0, "GUJ", 10),
    ("patan", "Patan", 72.1, 23.9, "GUJ", 5),
    ("idar", "Idar", 73.1, 23.9, "GUJ", 2),
    ("cambay", "Khambhat", 72.6, 22.25, "GUJ", 7),
    ("champaner", "Champaner", 73.6, 22.5, "GUJ", 3),
    ("surat", "Surat", 72.9, 21.2, "GUJ", 6),
    ("junagadh", "Sorath", 70.6, 21.5, "GUJ", 4),
    ("halar", "Halar", 70.0, 22.4, "GUJ", 2),
    ("kutch", "Kachchh", 69.6, 23.3, "GUJ", 3),
    # the Bahmani sultanate
    ("bidar", "Bidar", 77.5, 17.9, "BAH", 9),
    ("gulbarga", "Gulbarga", 76.8, 17.2, "BAH", 7),
    ("daulatabad", "Daulatabad", 75.3, 19.9, "BAH", 7),
    ("berar", "Berar", 77.5, 21.0, "BAH", 5),
    ("mahur", "Mahur", 78.0, 19.7, "BAH", 3),
    ("warangal", "Warangal", 79.6, 18.0, "BAH", 5),
    ("golconda", "Golkonda", 78.4, 17.2, "BAH", 6),
    ("bijapur", "Bijapur", 75.7, 16.8, "BAH", 6),
    ("raichur", "Raichur", 77.4, 16.2, "BAH", 4),
    ("junnar", "Junnar", 74.0, 19.2, "BAH", 4),
    ("dabhol", "Dabhol", 73.3, 17.6, "BAH", 4),
    ("chaul", "Chaul", 73.0, 18.6, "BAH", 3),
    ("belgaum", "Belgaum", 74.6, 15.9, "BAH", 3),
    # Vijayanagara
    ("goa", "Goa", 74.0, 15.3, "VIJ", 5),
    ("vijayanagara", "Vijayanagara", 76.45, 15.3, "VIJ", 12),
    ("penukonda", "Penukonda", 77.6, 14.1, "VIJ", 5),
    ("chitradurga", "Chitradurga", 76.4, 14.2, "VIJ", 3),
    ("honavar", "Honavar", 74.5, 14.3, "VIJ", 4),
    ("mangalore", "Mangalore", 74.9, 12.9, "VIJ", 5),
    ("mysore", "Mysore", 76.6, 12.3, "VIJ", 4),
    ("bangalore", "Bangalore", 77.6, 13.0, "VIJ", 3),
    ("chandragiri", "Chandragiri", 79.3, 13.6, "VIJ", 5),
    ("kanchipuram", "Kanchipuram", 79.7, 12.6, "VIJ", 6),
    ("nellore", "Nellore", 79.9, 14.5, "VIJ", 4),
    ("cuddapah", "Gandikota", 78.6, 14.9, "VIJ", 3),
    ("kondavidu", "Kondavidu", 80.1, 16.3, "VIJ", 4),
    ("tanjore", "Thanjavur", 79.15, 10.8, "VIJ", 7),
    ("kongu", "Kongu", 77.7, 11.3, "VIJ", 4),
    ("madurai", "Madurai", 78.1, 9.9, "VIJ", 7),
    ("tirunelveli", "Tirunelveli", 77.7, 8.75, "VIJ", 4),
    # Kerala
    ("calicut", "Kalikut", 75.8, 11.25, "CLC", 6),
    ("cannanore", "Kannur", 75.4, 12.0, "CLC", 3),
    ("cochin", "Cochin", 76.3, 9.95, "KOC", 4),
    ("venad", "Venad", 76.9, 8.6, "VND", 4),
    # Orissa and the Gond lands
    ("cuttack", "Cuttack", 85.85, 20.4, "ORI", 7),
    ("ganjam", "Kalinga", 84.7, 19.3, "ORI", 4),
    ("balasore", "Balasore", 86.9, 21.5, "ORI", 3),
    ("sambalpur", "Sambalpur", 84.0, 21.4, "ORI", 3),
    ("rajahmundry", "Rajahmundry", 81.8, 17.0, "ORI", 5),
    ("vizag", "Simhachalam", 83.2, 18.0, "ORI", 3),
    ("garha", "Garha", 79.95, 23.1, "GND", 3),
    ("deogarh", "Deogarh", 79.0, 21.4, "GND", 2),
    ("chanda", "Chanda", 79.3, 19.9, "GND", 2),
    ("bastar", "Bastar", 81.9, 19.1, "GND", 1, 2.6),
    ("ratanpur", "Ratanpur", 82.2, 22.2, "GND", 2),
    ("chotanagpur", "Chota Nagpur", 85.3, 23.4, "NAG", 2),
    # Ceylon
    ("jaffna", "Jaffna", 80.0, 9.6, "JFN", 3),
    ("vanni", "Vanni", 80.5, 8.7, "JFN", 1),
    ("kotte", "Kotte", 79.95, 6.9, "KOT", 5),
    ("kandy", "Kandy", 80.7, 7.4, "KOT", 3),
    ("ruhuna", "Ruhuna", 81.2, 6.4, "KOT", 2),
]

# the people's faith where it is not the ruler's (default: the owner's religion)
_HINDU_UNDER_SULTANS = (
    "jhelum dipalpur sirhind hisar_firoza doab katehar mewat agra kanauj awadh kara jaunpur gorakhpur bihar tirhut kalinjar rewa "
    "varendra satgaon birbhum jessore mymensingh chittagong mandu ujjain chanderi bhilsa mandsaur burhanpur nandurbar patan idar "
    "cambay champaner surat junagadh halar kutch daulatabad berar mahur warangal golconda raichur junnar dabhol chaul belgaum "
    "gulbarga bijapur jammu").split()
RELIGION = {k: "hindu" for k in _HINDU_UNDER_SULTANS}
RELIGION.update({"baltistan": "shia", "chittagong": "buddhist"})

STRAITS = [("madurai", "vanni")]  # Adam's Bridge: Rameswaram to Mannar
LAND_LINKS = []

DESERT = {"jaisalmer", "bikaner", "mallani", "kutch"}
TERRAIN = {"ladakh": "mountains", "baltistan": "mountains", "kumaon": "mountains", "garhwal": "mountains", "jumla": "mountains",
           "kangra": "hills", "srinagar": "hills", "kathmandu": "hills", "palpa": "hills", "kandy": "hills",
           "bastar": "forest", "chanda": "forest", "ratanpur": "forest", "chotanagpur": "forest", "garha": "forest", "deogarh": "forest",
           "sambalpur": "forest", "garhgaon": "forest", "nagaon": "forest", "tripura": "forest", "jessore": "marsh", "sonargaon": "marsh",
           "vanni": "forest", "venad": "forest", "cochin": "forest", "calicut": "forest", "cannanore": "forest",
           "delhi": "plains", "doab": "plains", "agra": "plains", "jaunpur": "plains", "awadh": "plains", "gaur": "plains",
           "bihar": "plains", "lahore": "plains", "dipalpur": "plains", "sirhind": "plains", "ahmedabad": "plains", "cambay": "plains",
           "tanjore": "plains", "cuttack": "plains", "satgaon": "plains", "kanauj": "plains", "kara": "plains", "tirhut": "plains"}


def DEFAULT_TERRAIN(key, lat):
    return "desert" if key in DESERT else "plains"


RANGES = [
    (1.0, [(73.4, 35.0), (75.0, 34.6), (76.6, 33.8), (78.4, 32.6), (79.6, 31.0), (81.0, 30.2), (82.6, 29.4), (84.2, 28.6),
           (85.8, 28.0), (87.4, 27.8), (89.0, 27.8), (90.6, 27.9), (92.4, 27.8), (94.2, 28.2), (95.6, 28.6)]),  # Himalaya
    (0.55, [(73.8, 33.6), (75.4, 33.2), (76.8, 32.4), (78.0, 31.2)]),  # Pir Panjal / Dhauladhar
    (0.75, [(76.0, 35.6), (77.6, 35.2), (78.8, 34.4)]),  # Ladakh range
    (0.4, [(72.6, 32.6), (73.4, 32.7)]),  # Salt Range
    (0.4, [(72.6, 24.4), (73.4, 25.2), (74.0, 26.0), (74.8, 26.8), (75.6, 27.6), (76.4, 28.2)]),  # Aravalli
    (0.4, [(74.2, 22.6), (75.6, 22.8), (77.0, 23.0), (78.4, 23.2), (79.8, 23.4), (81.0, 23.6)]),  # Vindhya
    (0.4, [(74.4, 21.6), (75.8, 21.6), (77.4, 21.8), (78.8, 22.2), (80.6, 22.4)]),  # Satpura
    (0.55, [(73.6, 20.8), (73.6, 19.2), (73.6, 17.6), (73.9, 16.0), (74.4, 14.6), (75.0, 13.2), (75.6, 12.0), (76.4, 10.8),
            (77.0, 9.6), (77.3, 8.4)]),  # Western Ghats
    (0.75, [(76.4, 11.6), (76.9, 11.2)]),  # Nilgiri
    (0.3, [(79.0, 15.6), (79.2, 14.6), (79.4, 13.6), (79.8, 12.6), (78.6, 11.8)]),  # Eastern Ghats south
    (0.35, [(82.6, 18.0), (83.6, 18.8), (84.4, 19.6), (85.0, 20.4)]),  # Eastern Ghats north
    (0.3, [(90.6, 25.6), (91.8, 25.5), (93.0, 25.4)]),  # Khasi hills
    (0.45, [(93.2, 24.2), (94.0, 25.6), (94.8, 26.6)]),  # Naga / Patkai
    (0.35, [(92.2, 23.8), (92.4, 22.6)]),  # Chittagong hills
    (0.4, [(80.5, 7.2), (80.8, 6.8)]),  # Ceylon highlands
]

RIVERS = [
    ("Ganges", 3, [(78.9, 30.0), (78.4, 29.0), (79.6, 27.6), (80.4, 26.6), (81.8, 25.45), (83.0, 25.3), (84.8, 25.6),
                   (86.0, 25.4), (87.4, 25.2), (88.1, 24.6), (89.0, 23.8), (89.9, 23.0), (90.4, 22.4)]),
    ("Hugli", 1, [(88.1, 24.4), (88.3, 23.4), (88.2, 22.4), (88.1, 21.8)]),
    ("Yamuna", 2, [(77.6, 30.4), (77.3, 29.2), (77.3, 28.4), (78.0, 27.2), (79.2, 26.4), (80.6, 25.6), (81.8, 25.45)]),
    ("Brahmaputra", 3, [(95.2, 27.8), (94.4, 27.2), (93.0, 26.6), (91.7, 26.2), (90.2, 26.0), (89.8, 25.2), (90.0, 24.0), (90.4, 22.4)]),
    ("Chambal", 1, [(75.6, 22.6), (75.6, 24.2), (76.4, 25.4), (77.4, 26.2), (79.0, 26.4)]),
    ("Gomti", 1, [(80.4, 28.0), (81.0, 26.8), (82.6, 25.8), (83.2, 25.5)]),
    ("Ghaghara", 1, [(81.0, 28.6), (82.0, 27.2), (83.4, 26.4), (84.6, 25.7)]),
    ("Son", 1, [(81.8, 22.8), (82.4, 24.0), (83.6, 24.8), (84.8, 25.6)]),
    ("Narmada", 2, [(81.6, 22.7), (80.0, 23.1), (78.2, 22.8), (76.6, 22.2), (75.0, 22.2), (73.8, 21.8), (72.7, 21.6)]),
    ("Tapti", 1, [(78.2, 21.6), (76.4, 21.2), (74.8, 21.2), (73.2, 21.1), (72.7, 21.1)]),
    ("Godavari", 2, [(73.8, 19.9), (75.4, 19.5), (77.4, 18.9), (79.4, 18.8), (80.6, 18.0), (81.6, 17.0), (82.2, 16.6)]),
    ("Krishna", 2, [(73.7, 18.0), (74.6, 16.8), (76.2, 16.2), (77.8, 16.2), (79.2, 16.6), (80.6, 16.2), (81.0, 15.8)]),
    ("Tungabhadra", 1, [(75.4, 13.8), (76.0, 14.8), (76.45, 15.4), (77.4, 15.9), (78.2, 15.9)]),
    ("Kaveri", 1, [(75.8, 12.4), (76.6, 12.4), (77.6, 11.9), (78.6, 10.9), (79.4, 10.9), (79.8, 11.1)]),
    ("Mahanadi", 1, [(81.8, 20.4), (82.8, 21.6), (84.0, 21.4), (85.0, 20.6), (86.4, 20.2)]),
    ("Sutlej", 1, [(78.4, 31.8), (77.0, 31.4), (76.0, 31.2), (75.0, 31.0), (73.8, 30.0), (72.4, 29.2), (71.2, 29.0)]),
    ("Jhelum", 1, [(75.2, 33.8), (74.4, 34.2), (73.6, 33.4), (73.4, 32.6), (72.4, 31.6), (71.8, 31.2)]),
    ("Chenab", 1, [(76.4, 32.8), (75.2, 33.0), (74.4, 32.4), (73.4, 31.6), (71.8, 30.6), (71.2, 29.4)]),
]

NATIONS = {
    "DLH": {"religion": "sunni", "devout": True, "name": "Delhi", "color": "#3f7f4a", "emoji": "🕌", "capital": "delhi", "aggression": 1.0,
            "bonus": {"tax": 0.1, "manpower": 0.05}, "idea": "Thron von Delhi: +10 % Steuern, +5 % Mannschaften",
            "rulers": ["Muhammad Shah", "Alam Shah", "Bahlul Lodi", "Sikandar Lodi", "Ibrahim Lodi"]},
    "JNP": {"religion": "sunni", "devout": True, "name": "Jaunpur", "color": "#6aa05a", "emoji": "🏛️", "capital": "jaunpur", "aggression": 1.0,
            "bonus": {"production": 0.1}, "idea": "Shiraz des Ostens: +10 % Produktion",
            "rulers": ["Mahmud Shah Sharqi", "Muhammad Shah Sharqi", "Husain Shah Sharqi"]},
    "BNG": {"religion": "sunni", "devout": True, "name": "Bengalen", "color": "#2f9a7a", "emoji": "🐅", "capital": "gaur", "aggression": 0.8,
            "bonus": {"production": 0.1, "trade": 0.05}, "idea": "Musselin und Reis: +10 % Produktion, +5 % Handel",
            "rulers": ["Nasiruddin Mahmud", "Rukunuddin Barbak", "Alauddin Husain", "Nusrat Shah"]},
    "MLW": {"religion": "sunni", "devout": True, "name": "Malwa", "color": "#8a6aa8", "emoji": "🏰", "capital": "mandu", "aggression": 1.1,
            "bonus": {"defense": 0.1, "combat": 0.05}, "idea": "Festung Mandu: +10 % Verteidigung, +5 % Kampfkraft",
            "rulers": ["Mahmud Khalji", "Ghiyas Shah", "Nasir Shah", "Mahmud II."]},
    "GUJ": {"religion": "sunni", "devout": True, "name": "Gujarat", "color": "#c0904a", "emoji": "⛵", "capital": "ahmedabad", "aggression": 1.0,
            "bonus": {"trade": 0.15}, "idea": "Häfen von Khambhat: +15 % Handelseinnahmen",
            "rulers": ["Muhammad Shah II.", "Qutbuddin Ahmad", "Mahmud Begada", "Bahadur Shah"]},
    "KHD": {"religion": "sunni", "devout": True, "name": "Khandesch", "color": "#a0a85a", "emoji": "🛡️", "capital": "burhanpur", "aggression": 0.5,
            "bonus": {"defense": 0.15}, "idea": "Asirgarh, Schlüssel zum Dekkan: +15 % Verteidigung",
            "rulers": ["Nasir Khan", "Miran Adil Khan", "Mubarak Khan"]},
    "BAH": {"religion": "sunni", "devout": True, "name": "Bahmaniden", "color": "#4a8a3a", "emoji": "⚔️", "capital": "bidar", "aggression": 1.2,
            "bonus": {"combat": 0.1, "manpower": 0.05}, "idea": "Afaqis und Dakhnis: +10 % Kampfkraft, +5 % Mannschaften",
            "rulers": ["Alauddin Ahmad Shah", "Humayun Shah", "Muhammad Shah III.", "Mahmud Shah"]},
    "KSH": {"religion": "sunni", "devout": True, "name": "Kaschmir", "color": "#6a9ac0", "emoji": "🏔️", "capital": "srinagar", "aggression": 0.6,
            "bonus": {"production": 0.05, "defense": 0.1}, "idea": "Tal der Schals: +5 % Produktion, +10 % Verteidigung",
            "rulers": ["Zain-ul-Abidin", "Haidar Shah", "Hasan Shah"]},
    "VIJ": {"religion": "hindu", "devout": True, "name": "Vijayanagar", "color": "#c04a3a", "emoji": "🐗", "capital": "vijayanagara", "aggression": 1.1,
            "bonus": {"tax": 0.1, "manpower": 0.1}, "idea": "Stadt des Sieges: +10 % Steuern, +10 % Mannschaften",
            "rulers": ["Deva Raya II.", "Mallikarjuna", "Saluva Narasimha", "Krishnadevaraya", "Achyuta Raya"]},
    "ORI": {"religion": "hindu", "name": "Orissa", "color": "#d08a3a", "emoji": "🐘", "capital": "cuttack", "aggression": 1.1,
            "bonus": {"combat": 0.1}, "idea": "Gajapati, Herren der Elefanten: +10 % Kampfkraft",
            "rulers": ["Kapilendra Deva", "Purushottama Deva", "Prataparudra Deva"]},
    "MEW": {"religion": "hindu", "name": "Mewar", "color": "#e0b040", "emoji": "🗡️", "capital": "chittor", "aggression": 1.0,
            "bonus": {"defense": 0.1, "combat": 0.05}, "idea": "Die Ranas von Chittor: +10 % Verteidigung, +5 % Kampfkraft",
            "rulers": ["Rana Kumbha", "Udai Singh", "Rana Raimal", "Rana Sanga"]},
    "MAW": {"religion": "hindu", "name": "Marwar", "color": "#c07a8a", "emoji": "🐪", "capital": "mandore", "aggression": 0.9,
            "bonus": {"manpower": 0.1}, "idea": "Rathore-Reiter der Thar: +10 % Mannschaften",
            "rulers": ["Rao Jodha", "Rao Satal", "Rao Suja", "Rao Ganga"]},
    "AMB": {"religion": "hindu", "name": "Amber", "color": "#d07060", "emoji": "🏯", "capital": "dhundhar", "aggression": 0.6,
            "bonus": {"tax": 0.1}, "idea": "Kachwaha von Dhundhar: +10 % Steuern",
            "rulers": ["Udaykaran", "Chandrasen", "Prithviraj Singh"]},
    "GWA": {"religion": "hindu", "name": "Gwalior", "color": "#b0604a", "emoji": "🏰", "capital": "gwalior", "aggression": 0.6,
            "bonus": {"defense": 0.15}, "idea": "Felsenfestung der Tomar: +15 % Verteidigung",
            "rulers": ["Dungar Singh", "Kirti Singh", "Man Singh Tomar"]},
    "NPL": {"religion": "hindu", "name": "Nepal", "color": "#a04050", "emoji": "🛕", "capital": "kathmandu", "aggression": 0.5,
            "bonus": {"defense": 0.15}, "idea": "Täler des Himalaya: +15 % Verteidigung",
            "rulers": ["Yaksha Malla", "Ratna Malla", "Jaya Ranajit Malla"]},
    "KUM": {"religion": "hindu", "name": "Kumaon", "color": "#7a9a5a", "emoji": "⛰️", "capital": "kumaon", "aggression": 0.4,
            "bonus": {"defense": 0.15}, "idea": "Chand-Rajas der Berge: +15 % Verteidigung",
            "rulers": ["Bharati Chand", "Ratna Chand", "Kirti Chand"]},
    "KGR": {"religion": "hindu", "name": "Kangra", "color": "#9a7ab0", "emoji": "🏔️", "capital": "kangra", "aggression": 0.4,
            "bonus": {"defense": 0.15}, "idea": "Katoch von Kangra: +15 % Verteidigung",
            "rulers": ["Sansar Chand I.", "Dharam Chand"]},
    "LDK": {"religion": "buddhist", "name": "Ladakh", "color": "#b0a080", "emoji": "☸️", "capital": "ladakh", "aggression": 0.3,
            "bonus": {"defense": 0.15}, "idea": "Klöster am Indus: +15 % Verteidigung",
            "rulers": ["Lhachen Bhagan", "Tashi Namgyal", "Tsewang Namgyal"]},
    "KMT": {"religion": "hindu", "name": "Kamata", "color": "#5a8aa0", "emoji": "🌾", "capital": "kamata", "aggression": 0.5,
            "bonus": {"production": 0.1}, "idea": "Khen-Könige von Kamatapur: +10 % Produktion",
            "rulers": ["Niladhvaj", "Chakradhvaj", "Nilambar"]},
    "AHO": {"religion": "native", "name": "Ahom", "color": "#8ab04a", "emoji": "🐘", "capital": "garhgaon", "aggression": 0.8,
            "bonus": {"manpower": 0.1, "defense": 0.05}, "idea": "Paik-System: +10 % Mannschaften, +5 % Verteidigung",
            "rulers": ["Susenphaa", "Suhenphaa", "Supimphaa", "Suhungmung"]},
    "TRP": {"religion": "hindu", "name": "Tripura", "color": "#c0a0c0", "emoji": "🐘", "capital": "tripura", "aggression": 0.6,
            "bonus": {"manpower": 0.1}, "idea": "Manikya-Dynastie: +10 % Mannschaften",
            "rulers": ["Dharma Manikya", "Ratna Manikya", "Dhanya Manikya"]},
    "CLC": {"religion": "hindu", "name": "Kalikut", "color": "#d06a3a", "emoji": "🌶️", "capital": "calicut", "aggression": 0.6,
            "bonus": {"trade": 0.15}, "idea": "Der Zamorin und der Pfefferhandel: +15 % Handelseinnahmen",
            "rulers": ["Manavikraman", "Mana Vikrama", "Manavedan"]},
    "KOC": {"religion": "hindu", "name": "Cochin", "color": "#5a7ac0", "emoji": "⛵", "capital": "cochin", "aggression": 0.4,
            "bonus": {"trade": 0.1}, "idea": "Hafen von Kochi: +10 % Handelseinnahmen",
            "rulers": ["Unni Goda Varma", "Unni Rama Koil", "Vira Kerala Varma"]},
    "VND": {"religion": "hindu", "name": "Venad", "color": "#3a8a6a", "emoji": "🛕", "capital": "venad", "aggression": 0.4,
            "bonus": {"tax": 0.05, "defense": 0.05}, "idea": "Könige von Venad: +5 % Steuern, +5 % Verteidigung",
            "rulers": ["Chera Udaya Martanda", "Ravi Varma", "Aditya Varma"]},
    "GND": {"religion": "hindu", "name": "Gondwana", "color": "#6a8a4a", "emoji": "🌳", "capital": "garha", "aggression": 0.5,
            "bonus": {"defense": 0.1, "manpower": 0.05}, "idea": "Wälder der Gond: +10 % Verteidigung, +5 % Mannschaften",
            "rulers": ["Kharji", "Sangram Shah", "Dalpat Shah"]},
    "NAG": {"religion": "hindu", "name": "Chota Nagpur", "color": "#8a7a3a", "emoji": "🐍", "capital": "chotanagpur", "aggression": 0.3,
            "bonus": {"defense": 0.15}, "idea": "Nagvanshi des Hochlands: +15 % Verteidigung",
            "rulers": ["Shivdas Karn", "Pratap Karn", "Madhu Singh"]},
    "JFN": {"religion": "hindu", "name": "Jaffna", "color": "#4a6aa0", "emoji": "🐚", "capital": "jaffna", "aggression": 0.4,
            "bonus": {"trade": 0.1}, "idea": "Perlenfischer der Straße: +10 % Handelseinnahmen",
            "rulers": ["Kanakasooriya Cinkaiariyan", "Pararasasekaran", "Cankili I."]},
    "KOT": {"religion": "buddhist", "name": "Kotte", "color": "#d0a050", "emoji": "🦁", "capital": "kotte", "aggression": 0.6,
            "bonus": {"trade": 0.1, "production": 0.05}, "idea": "Zimtkönige von Ceylon: +10 % Handel, +5 % Produktion",
            "rulers": ["Parakramabahu VI.", "Bhuvanekabahu VI.", "Vira Parakramabahu VIII.", "Dharma Parakramabahu IX."]},
}

LOTUS = ["...G...", ".G.G.G.", "GGGGGGG", ".GGGGG.", "..DDD.."]
WHEEL = ["..GGG..", ".G.G.G.", "GGGGGGG", "G..G..G", "GGGGGGG", ".G.G.G.", "..GGG.."]
BOAR = ["..GGGG..", ".GGGGGGD", "GGkGGGGD", "wGGGGGG.", ".G.G.G.."]
ELEPHANT = [".GGGG...", "GGGGGG..", "GkGGGGG.", "G.GGGGG.", "G.G..G..", "D.D..D.."]
SWORD_SM = ["w", "w", "w", "w", "a", "G", "O"]


def flag_art(h):
    rc, cen, solid, field = h["recolor"], h["centred"], h["solid"], h["field"]
    W = h["TO_WHITE"]
    return {
        "DLH": (cen(solid("L"), rc(h["CRESCENT"], W), cy=3), "Delhi – white crescent on green (stylised)"),
        "JNP": (cen(field("L", "w", "L"), rc(h["CRESCENT"], {"G": "L", "D": "F"}), cy=3), "Jaunpur – green crescent, green and white (stylised)"),
        "BNG": (cen(solid("F"), rc(h["SUN"], h["TO_GOLD"]), cy=3), "Bengal – gold sun on dark green (stylised)"),
        "MLW": (cen(solid("P"), rc(h["CRESCENT"], W), cy=3), "Malwa – white crescent on purple (stylised)"),
        "GUJ": (cen(field("O", "L"), rc(h["CRESCENT"], W), cy=3), "Gujarat – white crescent on orange and green (stylised)"),
        "KHD": (cen(solid("L"), rc(h["CASTLE"], W), cy=4), "Khandesh – white castle on green (stylised)"),
        "BAH": (cen(field("L", "G", "L"), rc(h["CRESCENT"], {"G": "L", "D": "F"}), cy=3), "Bahmani – green crescent on gold band (stylised)"),
        "KSH": (cen(solid("B"), rc(h["CRESCENT"], W), cy=3), "Kashmir – white crescent on blue (stylised)"),
        "VIJ": (cen(solid("E"), BOAR, cy=4), "Vijayanagara – golden boar (varaha) on dark red (stylised)"),
        "ORI": (cen(solid("O"), rc(ELEPHANT, W), cy=4), "Gajapati – white elephant on orange (stylised)"),
        "MEW": (cen(solid("R"), h["SUN"], cy=3), "Mewar – golden sun on red (stylised)"),
        "MAW": (h["stripes"](["R", "O", "Y", "L", "B"], 5), "Marwar – five-coloured pachranga (stylised)"),
        "AMB": (h["stripes"](["w", "R", "Y", "L", "B"], 5), "Amber – five-coloured flag (stylised)"),
        "GWA": (cen(solid("O"), rc(h["CASTLE"], {"G": "E", "Y": "R", "D": "E", "E": "k"}), cy=4), "Gwalior – red fort on orange (stylised)"),
        "NPL": (cen(field("E", "B"), rc(h["SUN"], W), cy=3), "Nepal – white sun on crimson and blue (stylised)"),
        "KUM": (cen(solid("F"), rc(h["SUN"], W), cy=3), "Kumaon – white sun on dark green (stylised)"),
        "KGR": (cen(solid("P"), h["SUN"], cy=3), "Kangra – golden sun on purple (stylised)"),
        "LDK": (cen(solid("O"), rc(WHEEL, {"G": "E"}), cy=3), "Ladakh – red wheel on saffron (stylised)"),
        "KMT": (cen(solid("B"), LOTUS, cy=4), "Kamata – golden lotus on blue (stylised)"),
        "AHO": (cen(solid("L"), rc(ELEPHANT, h["TO_GOLD"]), cy=4), "Ahom – gold elephant on green (stylised)"),
        "TRP": (cen(field("w", "R"), rc(LOTUS, {"G": "R", "D": "E"}), cy=2), "Tripura – red lotus on white and red (stylised)"),
        "CLC": (cen(solid("E"), rc(h["SWORD"], {}), cy=3), "Calicut – sword on crimson (stylised)"),
        "KOC": (cen(solid("B"), rc(h["SUN"], W), cy=3), "Cochin – white conch-sun on blue (stylised)"),
        "VND": (cen(solid("L"), rc(LOTUS, W), cy=4), "Venad – white lotus on green (stylised)"),
        "GND": (cen(solid("F"), rc(ELEPHANT, h["TO_GOLD"]), cy=4), "Gond – gold elephant on dark green (stylised)"),
        "NAG": (cen(solid("D"), rc(h["SUN"], {"G": "E", "Y": "R", "D": "E"}), cy=3), "Chota Nagpur – red sun on dark gold (stylised)"),
        "JFN": (cen(solid("B"), rc(h["BULL"], W), cy=4), "Jaffna – white Nandi bull on blue (stylised)"),
        "KOT": (cen(solid("E"), rc(h["LION_SMALL"], {"U": "G"}), cy=4), "Kotte – golden lion on crimson (stylised)"),
    }


GOODS = """
cloth: lahore mandu ahmedabad cambay gaur sonargaon jaunpur kanauj patan surat satgaon dhundhar
cotton: dipalpur sirhind berar mahur mandsaur ujjain burhanpur nandurbar idar junagadh halar daulatabad gulbarga warangal kongu
grain: doab katehar agra awadh kara gorakhpur tirhut varendra mymensingh jessore birbhum kamata kamrup cuttack balasore rajahmundry tanjore jhelum mewat delhi bihar kangra
spices: calicut cannanore cochin venad mangalore honavar dabhol chaul kotte kandy ruhuna madurai
dyes: chanderi bhilsa bijapur kalinjar champaner
gems: golconda raichur vijayanagara penukonda chitradurga jaffna vanni tirunelveli
salt: kutch mallani jaisalmer bikaner
horses: nagaur mandore sirohi
livestock: hisar_firoza ajmer bundi udaipur narwar gwalior garhwal kumaon jumla palpa ladakh baltistan
silk: srinagar jammu
copper: chittor kathmandu bidar
iron: chotanagpur garha deogarh ratanpur
timber: morang bastar chanda sambalpur ganjam vizag nagaon garhgaon tripura rewa
ivory: sylhet chittagong
gold: mysore bangalore
sugar: goa belgaum junnar kondavidu nellore cuddapah kanchipuram chandragiri
"""
NEW_GOODS = {
    "gems": {"name": "Edelsteine", "price": 0.6, "bonus": {"prestige": 0.5, "income": 0.03}, "bonus_text": "+0,5 Prestige/Jahr, +3 % Einkommen",
             "emoji": "💎", "color": "#4fb0d8"},
}
MARKETS = ["delhi", "gaur", "cambay", "vijayanagara", "calicut"]

ALLIANCES = []
RIVALS = [["DLH", "JNP"], ["BAH", "VIJ"], ["GUJ", "MLW"], ["MEW", "MLW"], ["ORI", "BNG"], ["CLC", "KOC"], ["KOT", "JFN"], ["MAW", "MEW"]]
