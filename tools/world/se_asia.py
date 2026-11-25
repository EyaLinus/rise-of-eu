"""Phase E of the world map: mainland Southeast Asia, the Malay world, Indonesia and the Philippines.

1444: Ava rules upper Burma, Hanthawaddy the Mon delta (Pegu), Mrauk U Arakan; the Shan states hold the
hills. Ayutthaya has just absorbed Sukhothai and sacked Angkor (1431); the Khmer court moves to the Mekong.
Lan Na under Tilokaraj, Lan Xang on the middle Mekong. Dai Viet under the Le dynasty presses Champa. Malacca,
newly Muslim, controls the strait; Samudera Pasai and Aru on Sumatra, Pagaruyung in the Minangkabau
highlands. Majapahit still reigns from Trowulan over Java, Bali and the coasts, Sunda in the west. Brunei
on Borneo, Ternate in the clove islands, Sulu; on Luzon and the Visayas the rajahnates of Tondo and Cebu.
"""

BLOCK = "se"
FLAGS = {}

PROVINCES = [
    # Burma, Arakan, the Shan hills, Manipur
    ("ava", "Ava", 96.0, 21.9, "AVA", 6),
    ("prome", "Prome", 95.2, 18.8, "AVA", 3),
    ("taungoo", "Taungoo", 96.4, 18.9, "AVA", 3),
    ("mohnyin", "Mohnyin", 96.9, 24.9, "SHN", 2, 2.6),
    ("hsenwi", "Hsenwi", 97.9, 22.9, "SHN", 2, 2.6),
    ("pegu", "Pegu", 96.5, 17.3, "HAN", 6),
    ("martaban", "Martaban", 97.6, 16.5, "HAN", 4),
    ("bassein", "Bassein", 94.7, 16.8, "HAN", 3),
    ("mrauk_u", "Mrauk U", 93.2, 20.6, "ARK", 4, 2.6),
    ("manipur", "Manipur", 93.9, 24.8, "MNP", 2),
    # Siam, Lan Na, Lan Xang, Cambodia
    ("ayutthaya", "Ayutthaya", 100.55, 14.35, "AYU", 8),
    ("sukhothai", "Sukhothai", 99.8, 17.0, "AYU", 4),
    ("korat", "Korat", 102.1, 15.0, "AYU", 3),
    ("chanthaburi", "Chanthaburi", 102.1, 12.6, "AYU", 3),
    ("tenasserim", "Tenasserim", 98.9, 12.1, "AYU", 3),
    ("nakhon_si", "Nakhon Si Thammarat", 99.95, 8.4, "AYU", 4),
    ("chiang_mai", "Chiang Mai", 98.98, 18.79, "LNA", 5),
    ("chiang_rai", "Chiang Rai", 99.8, 20.0, "LNA", 2),
    ("nan", "Nan", 100.8, 18.8, "LNA", 2),
    ("cheli", "Sipsongpanna", 100.8, 22.0, "MNG", 2),
    ("luang_prabang", "Luang Prabang", 102.1, 19.9, "LXA", 4),
    ("vientiane", "Vientiane", 102.6, 17.97, "LXA", 4),
    ("champasak", "Champasak", 105.8, 15.1, "LXA", 2, 2.6),
    ("srey_santhor", "Srei Santhor", 104.9, 11.7, "KHM", 5),
    ("angkor", "Angkor", 103.86, 13.4, "KHM", 3),
    # Dai Viet and Champa
    ("thang_long", "Thăng Long", 105.85, 21.0, "DAI", 9),
    ("thanh_hoa", "Thanh Hóa", 105.8, 19.8, "DAI", 5),
    ("nghe_an", "Nghệ An", 105.7, 18.6, "DAI", 4),
    ("lang_son", "Lạng Sơn", 106.7, 21.85, "DAI", 2),
    ("hung_hoa", "Hưng Hóa", 104.2, 21.5, "DAI", 2),
    ("thuan_hoa", "Thuận Hóa", 107.6, 16.5, "DAI", 3),
    ("amaravati", "Amaravati", 108.3, 15.6, "CHA", 3),
    ("vijaya", "Vijaya", 109.1, 13.85, "CHA", 4),
    ("kauthara", "Kauthara", 109.2, 12.3, "CHA", 3),
    ("panduranga", "Panduranga", 108.6, 11.3, "CHA", 2),
    # the Malay peninsula and Sumatra
    ("malacca", "Malakka", 102.25, 2.2, "MLC", 6),
    ("pahang", "Pahang", 103.3, 3.8, "MLC", 2, 2.6),
    ("perak", "Perak", 101.0, 4.6, "MLC", 2),
    ("johor", "Johor", 103.6, 1.6, "MLC", 1),
    ("kedah", "Kedah", 100.4, 6.1, "KED", 2),
    ("pasai", "Samudera Pasai", 97.2, 5.1, "PAS", 4),
    ("aceh", "Lamuri", 95.4, 5.4, "PAS", 2),
    ("deli", "Aru", 98.7, 3.6, "ARU", 2),
    ("batak", "Batakland", 99.0, 2.2, "BTK", 1, 2.6),
    ("pagaruyung", "Pagaruyung", 100.6, -0.5, "MIN", 3, 2.6),
    ("jambi", "Jambi", 103.6, -1.6, "MIN", 2, 2.6),
    ("bengkulu", "Bengkulu", 102.3, -3.8, "MIN", 1, 2.6),
    ("palembang", "Palembang", 104.75, -3.0, "MJP", 3, 2.6),
    ("lampung", "Lampung", 105.0, -5.0, "SUN", 1, 2.6),
    # Java, Bali and the lesser islands
    ("pakuan", "Pakuan", 106.8, -6.6, "SUN", 4),
    ("cirebon", "Cirebon", 108.55, -6.8, "SUN", 2),
    ("mataram", "Mataram", 110.4, -7.6, "MJP", 3),
    ("demak", "Demak", 110.7, -6.6, "MJP", 3),
    ("trowulan", "Trowulan", 112.4, -7.55, "MJP", 7),
    ("madura", "Madura", 113.3, -7.0, "MJP", 2),
    ("blambangan", "Blambangan", 114.2, -8.2, "MJP", 2),
    ("bali", "Bali", 115.2, -8.4, "MJP", 3),
    ("nusa_tenggara", "Nusa Tenggara", 117.5, -8.6, "MJP", 1, 2.6),
    ("timor", "Timor", 125.0, -9.3, "TMR", 1, 2.6),
    # Borneo, Sulawesi, the Moluccas
    ("brunei", "Brunei", 114.9, 4.9, "BRU", 3),
    ("sarawak", "Sarawak", 111.0, 1.8, "BRU", 1, 3.0),
    ("sabah", "Sabah", 116.9, 5.9, "BRU", 1, 2.6),
    ("tanjungpura", "Tanjungpura", 109.8, -0.6, "MJP", 1, 3.0),
    ("banjar", "Banjar", 114.6, -3.3, "MJP", 2, 3.0),
    ("dayak", "Dayakland", 113.5, 0.8, "DYK", 1, 3.5),
    ("kutai", "Kutai", 117.0, -0.5, "DYK", 1, 3.0),
    ("makassar", "Makassar", 119.4, -5.15, "SUL", 2, 2.6),
    ("minahasa", "Minahasa", 124.8, 1.2, "TER", 1, 2.6),
    ("ternate", "Ternate", 127.4, 0.8, "TER", 3, 2.0),
    ("ambon", "Ambon", 128.2, -3.6, "TER", 2, 2.6),
    # the Philippines
    ("tondo", "Tondo", 121.0, 14.6, "TON", 2, 2.6),
    ("cagayan", "Cagayan", 121.6, 17.4, "TON", 1, 3.0),
    ("bicol", "Bikol", 123.5, 13.4, "TON", 1, 2.6),
    ("cebu", "Cebu", 123.9, 10.3, "CEB", 2, 2.6),
    ("butuan", "Butuan", 125.5, 8.9, "CEB", 1, 2.6),
    ("maguindanao", "Maguindanao", 124.3, 7.2, "MAG", 2, 2.6),
    ("sulu", "Sulu", 121.0, 6.05, "SLU", 2, 2.0),
]

RELIGION = {"cheli": "buddhist", "demak": "sunni", "palembang": "buddhist", "bassein": "buddhist"}

STRAITS = [("malacca", "pagaruyung"), ("johor", "pagaruyung"), ("lampung", "pakuan"), ("blambangan", "bali"),
           ("bali", "nusa_tenggara"), ("trowulan", "madura"), ("sabah", "sulu"), ("sulu", "maguindanao"), ("bicol", "cebu"),
           ("cebu", "butuan"), ("nakhon_si", "kedah"), ("nusa_tenggara", "timor"),
           ("ternate", "ambon"), ("ternate", "minahasa"), ("makassar", "kutai"), ("banjar", "madura"), ("tanjungpura", "jambi")]
LAND_LINKS = [("makassar", "minahasa")]  # across the arms of Sulawesi

TERRAIN = {"ava": "plains", "pegu": "marsh", "bassein": "marsh", "prome": "plains", "ayutthaya": "plains", "sukhothai": "plains",
           "srey_santhor": "marsh", "thang_long": "plains", "thanh_hoa": "plains", "korat": "plains", "vientiane": "plains",
           "trowulan": "plains", "demak": "plains", "madura": "plains", "bali": "hills", "mohnyin": "mountains",
           "hsenwi": "hills", "chiang_mai": "hills", "chiang_rai": "hills", "nan": "hills", "luang_prabang": "mountains",
           "hung_hoa": "mountains", "lang_son": "hills", "cheli": "hills", "manipur": "hills", "pagaruyung": "hills",
           "batak": "hills", "mataram": "hills", "pakuan": "hills"}


def DEFAULT_TERRAIN(key, lat):
    return "forest"


RANGES = [
    (0.6, [(94.4, 23.6), (94.0, 22.0), (93.8, 20.4), (94.4, 18.6), (94.8, 17.0)]),  # Arakan Yoma
    (0.45, [(96.6, 25.6), (97.6, 23.6), (98.4, 21.4), (98.6, 19.6), (98.8, 17.6), (98.8, 15.6), (99.0, 13.6), (99.2, 11.6)]),  # Shan / Tenasserim
    (0.5, [(103.6, 22.2), (104.4, 20.4), (105.6, 18.8), (106.6, 17.4), (107.6, 16.0), (108.0, 14.4), (108.2, 12.8)]),  # Annamite
    (0.35, [(101.6, 19.6), (102.0, 18.6)]),  # Laos hills
    (0.5, [(95.6, 4.8), (97.4, 3.0), (99.0, 1.4), (100.4, -0.6), (101.6, -2.6), (103.0, -4.0), (104.4, -5.2)]),  # Barisan
    (0.4, [(101.4, 6.0), (101.6, 4.6), (101.8, 3.4)]),  # Titiwangsa
    (0.45, [(107.0, -7.0), (108.6, -7.2), (110.4, -7.5), (112.0, -7.9), (113.4, -7.9), (114.2, -8.0)]),  # Java volcanoes
    (0.45, [(112.0, 1.4), (114.0, 2.0), (115.6, 3.4), (116.6, 5.6)]),  # Borneo highlands (Kinabalu)
    (0.4, [(120.0, -2.0), (120.4, -3.6), (121.4, -1.6)]),  # Sulawesi
    (0.35, [(121.0, 16.4), (121.0, 17.8)]),  # Cordillera
    (0.3, [(124.8, 7.6), (125.4, 8.2)]),  # Mindanao
]

RIVERS = [
    ("Irrawaddy", 2, [(97.4, 25.4), (96.4, 23.6), (96.0, 22.0), (95.0, 21.2), (95.2, 19.4), (95.2, 18.2), (95.4, 17.0), (95.2, 16.0)]),
    ("Salween", 1, [(98.6, 25.6), (98.6, 23.0), (97.8, 20.6), (97.6, 18.4), (97.6, 16.6)]),
    ("Chao Phraya", 1, [(99.8, 17.6), (100.1, 15.8), (100.55, 14.4), (100.6, 13.6)]),
    ("Mekong", 3, [(99.6, 24.6), (100.4, 22.4), (101.0, 20.4), (102.1, 19.9), (101.8, 18.4), (102.6, 18.0), (104.0, 17.4), (104.8, 16.4),
                   (105.8, 15.2), (105.9, 13.6), (105.0, 11.6), (105.6, 10.6), (106.6, 9.8)]),
    ("Roter Fluss", 2, [(102.4, 23.2), (103.8, 22.2), (105.0, 21.4), (105.85, 21.0), (106.6, 20.4)]),
    ("Brantas", 1, [(112.0, -8.0), (112.4, -7.6), (112.8, -7.4)]),
    ("Kapuas", 1, [(113.0, 0.8), (111.4, 0.2), (109.4, -0.2)]),
]

NATIONS = {
    "AVA": {"religion": "buddhist", "name": "Ava", "color": "#b07a3a", "emoji": "🐘", "capital": "ava", "aggression": 1.0,
            "bonus": {"manpower": 0.1, "combat": 0.05}, "idea": "Reisebene von Kyaukse: +10 % Mannschaften, +5 % Kampfkraft",
            "rulers": ["Narapati I.", "Thihathura", "Minkhaung II.", "Shwenankyawshin"]},
    "SHN": {"religion": "buddhist", "name": "Shan-Staaten", "color": "#8ab06a", "emoji": "⛰️", "capital": "hsenwi", "aggression": 0.8,
            "bonus": {"defense": 0.15}, "idea": "Saophas der Berge: +15 % Verteidigung",
            "rulers": ["Hkam Ngai Hpa", "Sao Hkun Kyaw", "Sawlon"]},
    "HAN": {"religion": "buddhist", "name": "Hanthawaddy", "color": "#d0b04a", "emoji": "🦢", "capital": "pegu", "aggression": 0.7,
            "bonus": {"trade": 0.15}, "idea": "Häfen der Mon: +15 % Handelseinnahmen",
            "rulers": ["Binnya Ran I.", "Binnya Waru", "Shin Sawbu", "Dhammazedi"]},
    "ARK": {"religion": "buddhist", "name": "Arakan", "color": "#6a8ab0", "emoji": "⛵", "capital": "mrauk_u", "aggression": 0.6,
            "bonus": {"trade": 0.05, "defense": 0.1}, "idea": "Mrauk U zwischen Bengalen und Burma: +5 % Handel, +10 % Verteidigung",
            "rulers": ["Min Saw Mon", "Min Khayi", "Ba Saw Phyu", "Min Bin"]},
    "MNP": {"religion": "native", "name": "Manipur", "color": "#a06a8a", "emoji": "🐎", "capital": "manipur", "aggression": 0.5,
            "bonus": {"combat": 0.1}, "idea": "Reiter von Kangleipak: +10 % Kampfkraft",
            "rulers": ["Kyamba", "Koiremba", "Lamkyamba"]},
    "AYU": {"religion": "buddhist", "devout": True, "name": "Ayutthaya", "color": "#c8506a", "emoji": "🐘", "capital": "ayutthaya", "aggression": 1.0,
            "bonus": {"tax": 0.1, "trade": 0.1}, "idea": "Krung Si, Hafen der Reishändler: +10 % Steuern, +10 % Handel",
            "rulers": ["Borommaracha II.", "Trailokanat", "Borommaracha III.", "Ramathibodi II."]},
    "LNA": {"religion": "buddhist", "name": "Lan Na", "color": "#5a9a7a", "emoji": "🛕", "capital": "chiang_mai", "aggression": 0.8,
            "bonus": {"defense": 0.1, "stability": 0.05}, "idea": "Tilokarajs Klöster: +10 % Verteidigung, +5 Stabilitätsziel",
            "rulers": ["Tilokaraj", "Yot Chiang Rai", "Phaya Kaeo"]},
    "LXA": {"religion": "buddhist", "name": "Lan Xang", "color": "#c0c04a", "emoji": "🐘", "capital": "luang_prabang", "aggression": 0.6,
            "bonus": {"manpower": 0.1, "defense": 0.05}, "idea": "Land der Millionen Elefanten: +10 % Mannschaften, +5 % Verteidigung",
            "rulers": ["Chakkaphat Phaen Phaeo", "Suvarna Banlang", "Visunarat"]},
    "KHM": {"religion": "buddhist", "name": "Kambodscha", "color": "#4a6a9a", "emoji": "🛕", "capital": "srey_santhor", "aggression": 0.5,
            "bonus": {"production": 0.1}, "idea": "Erben Angkors: +10 % Produktion",
            "rulers": ["Ponhea Yat", "Noreay Ramathipadi", "Srey Reachea", "Ang Chan"]},
    "DAI": {"religion": "confucian", "devout": True, "name": "Đại Việt", "color": "#c04040", "emoji": "🐉", "capital": "thang_long", "aggression": 1.2,
            "bonus": {"combat": 0.1, "tax": 0.05}, "idea": "Lê-Dynastie, Sieger über die Ming: +10 % Kampfkraft, +5 % Steuern",
            "rulers": ["Lê Nhân Tông", "Lê Thánh Tông", "Lê Hiến Tông", "Lê Uy Mục"]},
    "CHA": {"religion": "hindu", "name": "Champa", "color": "#d08a6a", "emoji": "🛕", "capital": "vijaya", "aggression": 0.6,
            "bonus": {"trade": 0.1, "defense": 0.05}, "idea": "Seefahrer von Vijaya: +10 % Handel, +5 % Verteidigung",
            "rulers": ["Maha Vijaya", "Maha Quy Lai", "Bàn La Trà Toàn"]},
    "MLC": {"religion": "sunni", "name": "Malakka", "color": "#3a8a4a", "emoji": "⛵", "capital": "malacca", "aggression": 0.8,
            "bonus": {"trade": 0.2}, "idea": "Herr der Meerenge: +20 % Handelseinnahmen",
            "rulers": ["Muzaffar Shah", "Mansur Shah", "Alauddin Riayat Shah", "Mahmud Shah"]},
    "KED": {"religion": "sunni", "name": "Kedah", "color": "#a0c06a", "emoji": "🌾", "capital": "kedah", "aggression": 0.3,
            "bonus": {"production": 0.1}, "idea": "Reisfelder von Kedah: +10 % Produktion",
            "rulers": ["Muhammad Jiwa", "Mahmud Shah", "Sulaiman Shah"]},
    "PAS": {"religion": "sunni", "name": "Samudera Pasai", "color": "#2a7a5a", "emoji": "🌶️", "capital": "pasai", "aggression": 0.5,
            "bonus": {"trade": 0.15}, "idea": "Pfeffer und Pilger: +15 % Handelseinnahmen",
            "rulers": ["Zainal Abidin", "Shalahuddin", "Abu Zaid"]},
    "ARU": {"religion": "sunni", "name": "Aru", "color": "#6a7a3a", "emoji": "⛵", "capital": "deli", "aggression": 0.6,
            "bonus": {"combat": 0.05, "trade": 0.05}, "idea": "Seeräuber der Meerenge: +5 % Kampfkraft, +5 % Handel",
            "rulers": ["Sultan Husin", "Sultan Abdul", "Raja Aru"]},
    "BTK": {"religion": "native", "name": "Batak", "color": "#8a5a4a", "emoji": "🏠", "capital": "batak", "aggression": 0.3, "native": True,
            "bonus": {"defense": 0.15, "tech_cost": 0.3}, "idea": "Dörfer am Tobasee: +15 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Sisingamangaraja I.", "Raja Uti", "Raja Silahi"]},
    "MIN": {"religion": "buddhist", "name": "Pagaruyung", "color": "#c0904a", "emoji": "🐃", "capital": "pagaruyung", "aggression": 0.4,
            "bonus": {"production": 0.1}, "idea": "Gold der Minangkabau: +10 % Produktion",
            "rulers": ["Vijayavarman", "Raja Alam", "Ananggawarman"]},
    "MJP": {"religion": "hindu", "devout": True, "name": "Majapahit", "color": "#b0402a", "emoji": "🏯", "capital": "trowulan", "aggression": 0.7,
            "bonus": {"tax": 0.1, "trade": 0.05}, "idea": "Nusantara, das Reich der Inseln: +10 % Steuern, +5 % Handel",
            "rulers": ["Kertawijaya", "Rajasawardhana", "Girishawardhana", "Singhawikramawardhana", "Girindrawardhana"]},
    "SUN": {"religion": "hindu", "name": "Sunda", "color": "#4a9ab0", "emoji": "🌶️", "capital": "pakuan", "aggression": 0.5,
            "bonus": {"trade": 0.1}, "idea": "Pfefferhafen Banten: +10 % Handelseinnahmen",
            "rulers": ["Niskala Wastu Kancana", "Dewa Niskala", "Sri Baduga Maharaja"]},
    "BRU": {"religion": "sunni", "name": "Brunei", "color": "#e0c050", "emoji": "⛵", "capital": "brunei", "aggression": 0.6,
            "bonus": {"trade": 0.15}, "idea": "Wasserstadt am Südchinesischen Meer: +15 % Handelseinnahmen",
            "rulers": ["Sharif Ali", "Sulaiman", "Bolkiah"]},
    "DYK": {"religion": "native", "name": "Dayak", "color": "#5a7a4a", "emoji": "🌳", "capital": "dayak", "aggression": 0.4, "native": True,
            "bonus": {"defense": 0.15, "tech_cost": 0.3}, "idea": "Langhäuser im Regenwald: +15 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Temenggung Jalan", "Panglima Burung", "Tamanggung"]},
    "SUL": {"religion": "native", "name": "Gowa", "color": "#9a6a5a", "emoji": "⛵", "capital": "makassar", "aggression": 0.5, "native": True,
            "bonus": {"trade": 0.1, "tech_cost": 0.3}, "idea": "Seefahrer der Bugis und Makassaren: +10 % Handel (Technik +30 % teurer)",
            "rulers": ["Karaeng Tumapakrisik", "Karaeng Bayo", "Tunipalangga"]},
    "TER": {"religion": "sunni", "name": "Ternate", "color": "#8a3a5a", "emoji": "🌰", "capital": "ternate", "aggression": 0.5,
            "bonus": {"trade": 0.2}, "idea": "Inseln der Gewürznelken: +20 % Handelseinnahmen",
            "rulers": ["Gapi Baguna", "Zainal Abidin", "Bayan Sirrullah", "Hairun", "Babullah"]},
    "TMR": {"religion": "native", "name": "Timor", "color": "#7a6a3a", "emoji": "🌳", "capital": "timor", "aggression": 0.3, "native": True,
            "bonus": {"production": 0.05, "tech_cost": 0.3}, "idea": "Sandelholz von Wehali: +5 % Produktion (Technik +30 % teurer)",
            "rulers": ["Liurai Wehali", "Liurai Sonbai", "Liurai Likusaen"]},
    "TON": {"religion": "native", "name": "Tondo", "color": "#5a6aa0", "emoji": "⛵", "capital": "tondo", "aggression": 0.4, "native": True,
            "bonus": {"trade": 0.1, "tech_cost": 0.3}, "idea": "Lakan von Tondo: +10 % Handel (Technik +30 % teurer)",
            "rulers": ["Lakan Gat Lontok", "Lakan Dula", "Rajah Sulayman"]},
    "CEB": {"religion": "native", "name": "Cebu", "color": "#4a8a8a", "emoji": "⛵", "capital": "cebu", "aggression": 0.4, "native": True,
            "bonus": {"trade": 0.1, "tech_cost": 0.3}, "idea": "Rajahnat von Sugbu: +10 % Handel (Technik +30 % teurer)",
            "rulers": ["Sri Lumay", "Sri Bantug", "Rajah Humabon"]},
    "MAG": {"religion": "native", "name": "Maguindanao", "color": "#6a4a7a", "emoji": "🌊", "capital": "maguindanao", "aggression": 0.5, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Datus am Pulangi: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Datu Mamalu", "Datu Tabunaway", "Kabungsuwan"]},
    "SLU": {"religion": "sunni", "name": "Sulu", "color": "#3a6a4a", "emoji": "🐚", "capital": "sulu", "aggression": 0.6,
            "bonus": {"trade": 0.1, "combat": 0.05}, "idea": "Perlentaucher und Seefahrer: +10 % Handel, +5 % Kampfkraft",
            "rulers": ["Sharif ul-Hashim", "Kamal ud-Din", "Ala ud-Din", "Amir ul-Umara"]},
}

PAGODA = ["...G...", "..GGG..", ".GGGGG.", "...G...", "..GGG..", ".GGGGG.", "GGGGGGG"]
STAR = ["...G...", "...G...", "GGGGGGG", ".GGGGG.", "..GGG..", ".GG.GG.", "G.....G"]
KRIS = ["....w", "...w.", "..w..", "...w.", "..w..", ".w...", "G....", "D...."]


def flag_art(h):
    rc, cen, solid, field = h["recolor"], h["centred"], h["solid"], h["field"]
    W = h["TO_WHITE"]
    return {
        "AVA": (cen(solid("E"), PAGODA, cy=3), "Ava – golden pagoda on crimson (stylised)"),
        "SHN": (field("Y", "L", "R"), "Shan – yellow, green, red (stylised)"),
        "HAN": (cen(solid("B"), rc(h["BIRD"], h["TO_GOLD"]), cy=3), "Hanthawaddy – golden hamsa on blue (stylised)"),
        "ARK": (cen(solid("w"), rc(PAGODA, {"G": "R"}), cy=3), "Arakan – red pagoda on white (stylised)"),
        "MNP": (cen(solid("P"), rc(h["KNOT"], {}), cy=3), "Manipur – white knot on purple (stylised)"),
        "AYU": (cen(solid("R"), rc(PAGODA, W), cy=3), "Ayutthaya – white pagoda on red (stylised)"),
        "LNA": (cen(solid("L"), PAGODA, cy=3), "Lan Na – golden pagoda on green (stylised)"),
        "LXA": (cen(solid("E"), rc(PAGODA, W), cy=3), "Lan Xang – white pagoda on crimson (stylised)"),
        "KHM": (cen(field("B", "R", "B"), rc(PAGODA, W), cy=3), "Cambodia – white temple on blue and red (stylised)"),
        "DAI": (cen(solid("Y"), rc(STAR, {"G": "R"}), cy=3), "Dai Viet – red star on yellow (stylised)"),
        "CHA": (cen(solid("D"), rc(h["SUN"], {"G": "R", "Y": "r", "D": "E"}), cy=3), "Champa – red sun on dark gold (stylised)"),
        "MLC": (cen(solid("L"), rc(KRIS, {}), cy=3), "Malacca – kris on green (stylised)"),
        "KED": (cen(solid("R"), rc(h["CRESCENT"], h["TO_GOLD"]), cy=3), "Kedah – gold crescent on red (stylised)"),
        "PAS": (cen(solid("F"), rc(h["CRESCENT"], W), cy=3), "Pasai – white crescent on dark green (stylised)"),
        "ARU": (cen(solid("k"), rc(h["CRESCENT"], W), cy=3), "Aru – white crescent on black (stylised)"),
        "BTK": (field("R", "w", "k"), "Batak – red, white, black (stylised)"),
        "MIN": (field("k", "R", "Y"), "Minangkabau – black, red, gold (stylised)"),
        "MJP": (h["stripes"](["R", "w"], 9), "Majapahit – nine red and white stripes (stylised)"),
        "SUN": (cen(solid("B"), rc(KRIS, {}), cy=3), "Sunda – kris on blue (stylised)"),
        "BRU": (cen(solid("Y"), rc(h["CRESCENT"], {"G": "k", "D": "k"}), cy=3), "Brunei – black crescent on yellow (stylised)"),
        "DYK": (cen(solid("F"), rc(h["BIRD"], W), cy=3), "Dayak – white hornbill on dark green (stylised)"),
        "SUL": (cen(solid("O"), rc(h["KNOT"], {"w": "k"}), cy=3), "Gowa – black pattern on orange (stylised)"),
        "TER": (cen(solid("E"), rc(h["CRESCENT"], h["TO_GOLD"]), cy=3), "Ternate – gold crescent on crimson (stylised)"),
        "TMR": (field("R", "Y", "k"), "Timor – red, gold, black (stylised)"),
        "TON": (cen(solid("B"), rc(h["SUN"], h["TO_GOLD"]), cy=3), "Tondo – gold sun on blue (stylised)"),
        "CEB": (cen(solid("L"), rc(h["SUN"], W), cy=3), "Cebu – white sun on green (stylised)"),
        "MAG": (cen(solid("P"), rc(h["CRESCENT"], W), cy=3), "Maguindanao – white crescent on purple (stylised)"),
        "SLU": (cen(solid("L"), rc(KRIS, {"w": "Y"}), cy=3), "Sulu – golden kris on green (stylised)"),
    }


GOODS = """
grain: ava prome taungoo ayutthaya sukhothai korat vientiane srey_santhor thang_long thanh_hoa nghe_an kedah trowulan mataram demak madura cirebon
gems: mohnyin chanthaburi
tea: hsenwi cheli
cloth: pegu
timber: martaban bassein tenasserim chiang_mai nan luang_prabang champasak angkor hung_hoa sarawak dayak tanjungpura
silk: thuan_hoa lang_son
ivory: banjar
spices: pasai aceh deli bengkulu jambi lampung pakuan ternate ambon minahasa bali
gold: pagaruyung butuan
salt: palembang panduranga
dyes: nakhon_si vijaya kauthara amaravati
sugar: blambangan nusa_tenggara bicol
naval_supplies: brunei sabah johor
iron: makassar kutai
livestock: manipur chiang_rai batak tondo cagayan
copper: mrauk_u
incense: timor
fish: sulu cebu maguindanao perak pahang
glass: malacca
"""
MARKETS = ["malacca", "ayutthaya", "pegu", "thang_long", "trowulan", "ternate"]

ALLIANCES = []
RIVALS = [["AVA", "HAN"], ["AYU", "KHM"], ["DAI", "CHA"], ["AYU", "LNA"], ["MLC", "AYU"], ["MJP", "MLC"], ["TER", "SLU"]]
