"""Phase D1 of the world map: Ming China, Tibet, Bhutan, Mongolia, Hami, Manchuria, the Amur and Taiwan.

1444: the Zhengtong emperor rules Ming China from Beijing; the treasure fleets have stopped sailing. On the
steppe Esen Taishi's Oirats overshadow the Northern Yuan khan Taisun; five years later Esen will capture
the emperor at Tumu. Tibet: the Phagmodrupa in U, the Rinpungpa rising in Tsang, Guge in the far west, the
Drukpa lamas in Bhutan. Hami is a Ming client oasis. In Manchuria the Jianzhou and Haixi Jurchen are Ming
guards on paper; on the Amur and Ussuri live Daur, Evenk and Nivkh clans, on Taiwan its own peoples.
"""

BLOCK = "cn"
FLAGS = {}

PROVINCES = [
    # North Zhili and Shanxi
    ("beijing", "Peking", 116.4, 39.9, "MNG", 14),
    ("baoding", "Baoding", 115.5, 38.85, "MNG", 6),
    ("daming", "Daming", 115.1, 36.3, "MNG", 5),
    ("yongping", "Yongping", 118.9, 40.0, "MNG", 4),
    ("xuanfu", "Xuanfu", 115.0, 40.6, "MNG", 3),
    ("datong", "Datong", 113.3, 40.1, "MNG", 5),
    ("taiyuan", "Taiyuan", 112.55, 37.85, "MNG", 7),
    ("pingyang", "Pingyang", 111.5, 36.1, "MNG", 6),
    # Shaanxi and Gansu
    ("xian", "Xi'an", 108.9, 34.3, "MNG", 9),
    ("yanan", "Yan'an", 109.5, 36.6, "MNG", 3),
    ("hanzhong", "Hanzhong", 107.0, 33.1, "MNG", 4),
    ("pingliang", "Pingliang", 106.7, 35.5, "MNG", 3),
    ("lanzhou", "Lanzhou", 103.8, 36.05, "MNG", 4),
    ("ningxia", "Ningxia", 106.25, 38.5, "MNG", 3),
    ("liangzhou", "Liangzhou", 102.6, 37.9, "MNG", 3),
    ("jiuquan", "Suzhou (Jiuquan)", 98.5, 39.7, "MNG", 2, 2.6),
    ("xining", "Xining", 101.8, 36.6, "MNG", 2),
    # Henan and Shandong
    ("kaifeng", "Kaifeng", 114.3, 34.8, "MNG", 9),
    ("luoyang", "Luoyang", 112.45, 34.6, "MNG", 6),
    ("nanyang", "Nanyang", 112.5, 33.0, "MNG", 5),
    ("runing", "Runing", 114.4, 33.0, "MNG", 5),
    ("jinan", "Jinan", 117.0, 36.65, "MNG", 8),
    ("yanzhou", "Yanzhou", 116.8, 35.5, "MNG", 6),
    ("qingzhou", "Qingzhou", 118.5, 36.7, "MNG", 5),
    ("dengzhou", "Dengzhou", 120.8, 37.4, "MNG", 4),
    # South Zhili (Nanjing)
    ("nanjing", "Nanjing", 118.8, 32.05, "MNG", 13),
    ("suzhou", "Suzhou", 120.6, 31.3, "MNG", 10),
    ("yangzhou", "Yangzhou", 119.6, 32.6, "MNG", 8),
    ("huaian", "Huai'an", 119.0, 33.6, "MNG", 5),
    ("fengyang", "Fengyang", 117.5, 32.9, "MNG", 6),
    ("anqing", "Anqing", 117.0, 30.5, "MNG", 5),
    ("huizhou", "Huizhou", 118.3, 29.9, "MNG", 6),
    ("xuzhou", "Xuzhou", 117.2, 34.25, "MNG", 5),
    # Zhejiang, Jiangxi, Fujian
    ("hangzhou", "Hangzhou", 120.15, 30.25, "MNG", 12),
    ("ningbo", "Ningbo", 121.55, 29.85, "MNG", 7),
    ("jinhua", "Jinhua", 119.65, 29.1, "MNG", 5),
    ("wenzhou", "Wenzhou", 120.65, 28.0, "MNG", 5),
    ("nanchang", "Nanchang", 115.9, 28.7, "MNG", 8),
    ("jingdezhen", "Jingdezhen", 117.2, 29.3, "MNG", 6),
    ("jian", "Ji'an", 115.0, 27.1, "MNG", 5),
    ("ganzhou", "Ganzhou", 114.9, 25.85, "MNG", 4),
    ("fuzhou", "Fuzhou", 119.3, 26.1, "MNG", 8),
    ("quanzhou", "Quanzhou", 118.6, 24.9, "MNG", 7),
    ("jianning", "Jianning", 118.3, 27.05, "MNG", 4),
    ("tingzhou", "Tingzhou", 116.4, 25.6, "MNG", 3),
    # Huguang
    ("wuchang", "Wuchang", 114.3, 30.55, "MNG", 9),
    ("xiangyang", "Xiangyang", 112.1, 32.0, "MNG", 6),
    ("jingzhou", "Jingzhou", 112.2, 30.35, "MNG", 6),
    ("changsha", "Changsha", 112.95, 28.2, "MNG", 7),
    ("hengzhou", "Hengzhou", 112.6, 26.9, "MNG", 5),
    ("changde", "Changde", 111.7, 29.0, "MNG", 4),
    ("chenzhou", "Chenzhou", 110.0, 28.0, "MNG", 3),
    # Sichuan
    ("chengdu", "Chengdu", 104.05, 30.65, "MNG", 10),
    ("chongqing", "Chongqing", 106.55, 29.55, "MNG", 7),
    ("kuizhou", "Kuizhou", 109.5, 31.0, "MNG", 4),
    ("baoning", "Baoning", 106.0, 31.6, "MNG", 4),
    ("yibin", "Xuzhou (Yibin)", 104.6, 28.8, "MNG", 4),
    ("songpan", "Songpan", 103.6, 32.65, "MNG", 2),
    ("jianchang", "Jianchang", 102.25, 27.9, "MNG", 2),
    # Guangdong and Guangxi
    ("guangzhou", "Kanton", 113.25, 23.1, "MNG", 12),
    ("chaozhou", "Chaozhou", 116.6, 23.65, "MNG", 6),
    ("shaozhou", "Shaozhou", 113.6, 24.8, "MNG", 4),
    ("gaozhou", "Gaozhou", 110.9, 21.9, "MNG", 4),
    ("leizhou", "Leizhou", 110.1, 20.9, "MNG", 3),
    ("hainan", "Hainan", 109.8, 19.2, "MNG", 3),
    ("guilin", "Guilin", 110.3, 25.3, "MNG", 6),
    ("liuzhou", "Liuzhou", 109.4, 24.3, "MNG", 4),
    ("wuzhou", "Wuzhou", 111.3, 23.5, "MNG", 4),
    ("nanning", "Nanning", 108.3, 22.8, "MNG", 4),
    ("sien", "Si'en", 106.6, 23.9, "MNG", 2),
    # Guizhou and Yunnan
    ("guiyang", "Guiyang", 106.7, 26.6, "MNG", 4),
    ("bozhou", "Bozhou", 106.9, 27.8, "MNG", 3),
    ("puan", "Pu'an", 104.9, 25.8, "MNG", 2),
    ("kunming", "Kunming", 102.7, 25.05, "MNG", 6),
    ("qujing", "Qujing", 103.8, 25.5, "MNG", 3),
    ("linan", "Lin'an", 102.8, 23.6, "MNG", 3),
    ("dali", "Dali", 100.2, 25.6, "MNG", 6),
    ("lijiang", "Lijiang", 100.2, 26.9, "MNG", 3),
    ("yongchang", "Yongchang", 99.15, 25.1, "MNG", 3),
    # Liaodong
    ("liaoyang", "Liaoyang", 123.2, 41.25, "MNG", 6),
    ("guangning", "Guangning", 121.8, 41.6, "MNG", 4),
    ("lushun", "Lüshun", 121.6, 39.1, "MNG", 3),
    ("kaiyuan", "Kaiyuan", 124.0, 42.5, "MNG", 3),
    # Tibet and Bhutan
    ("lhasa", "Lhasa", 91.1, 29.65, "TIB", 6),
    ("kongpo", "Kongpo", 94.4, 29.6, "TIB", 2, 2.6),
    ("nagqu", "Nagqu", 92.05, 31.5, "TIB", 1, 3.0),
    ("chamdo", "Chamdo", 97.2, 31.15, "TIB", 3, 2.6),
    ("derge", "Derge", 98.6, 32.2, "TIB", 2, 2.6),
    ("litang", "Litang", 100.3, 30.0, "TIB", 2, 2.6),
    ("golog", "Golog", 100.2, 34.0, "TIB", 1, 3.0),
    ("kokonor", "Kökenuur", 99.5, 36.9, "TIB", 1, 3.0),
    ("shigatse", "Shigatse", 88.9, 29.25, "TSA", 4),
    ("lhatse", "Lhatse", 87.4, 29.6, "TSA", 2, 2.6),
    ("guge", "Guge", 80.2, 31.5, "GUG", 2, 3.0),
    ("rutog", "Rutog", 79.8, 33.4, "GUG", 1, 3.0),
    ("paro", "Paro", 89.6, 27.4, "BHU", 2),
    ("bumthang", "Bumthang", 90.8, 27.6, "BHU", 1),
    # Mongolia and the Oirats
    ("karakorum", "Karakorum", 102.8, 47.2, "MGL", 3, 4.0),
    ("tuul", "Tuul", 106.9, 47.9, "MGL", 2, 3.5),
    ("selenge", "Selenge", 105.5, 49.8, "MGL", 1, 3.0),
    ("kherlen", "Kherlen", 110.5, 47.4, "MGL", 2, 4.0),
    ("hulunbuir", "Hulunbuir", 118.5, 48.5, "MGL", 1, 4.0),
    ("chahar", "Tschachar", 114.5, 42.8, "MGL", 3, 3.5),
    ("tumed", "Tümed", 111.6, 40.9, "MGL", 3),
    ("ordos", "Ordos", 108.8, 39.4, "MGL", 2, 3.0),
    ("gobi", "Gobi", 105.0, 43.5, "MGL", 1, 4.5),
    ("khorchin", "Chortschin", 122.0, 44.5, "MGL", 2, 3.5),
    ("uriankhai", "Urianchai", 119.4, 42.0, "MGL", 2),
    ("khovd", "Chowd", 91.6, 48.0, "OIR", 2, 4.0),
    ("uvs", "Uws", 93.0, 50.2, "OIR", 1, 3.5),
    ("zavkhan", "Dsawchan", 97.0, 47.6, "OIR", 1, 4.0),
    ("dzungaria", "Dsungarei", 85.5, 45.4, "OIR", 2, 4.0),
    ("tarbagatai", "Tarbagatai", 83.2, 47.2, "OIR", 1, 3.5),
    ("tsaidam", "Tsaidam", 95.0, 37.2, "OIR", 1, 4.0),
    ("hami", "Hami", 93.5, 42.8, "HAM", 3, 3.0),
    ("dunhuang", "Shazhou", 94.7, 40.1, "HAM", 2, 3.0),
    # Manchuria and the Amur
    ("jianzhou", "Jianzhou", 125.0, 41.7, "JIA", 2),
    ("ula", "Ula", 126.5, 44.0, "HXI", 2, 3.0),
    ("nonni", "Nonni", 124.0, 47.3, "HXI", 1, 3.5),
    ("mudan", "Mudan", 129.6, 44.6, "YRN", 1, 3.0),
    ("ussuri", "Ussuri", 133.8, 46.0, "YRN", 1, 3.5),
    ("primorye", "Primorje", 133.5, 43.6, "YRN", 1, 3.0),
    ("zeya", "Seja", 127.5, 51.0, "DAU", 1, 4.0),
    ("albazin", "Albasin", 123.8, 53.4, "DAU", 1, 4.0),
    ("heilong", "Heilong", 130.5, 48.4, "DAU", 1, 3.5),
    ("amur_mouth", "Amurmündung", 138.6, 52.2, "NIV", 1, 4.0),
    ("sakhalin", "Sachalin", 142.8, 50.0, "NIV", 1, 4.0),
    # Taiwan
    ("taiwan", "Formosa", 120.9, 23.6, "TAW", 1, 2.6),
]

RELIGION = {"xining": "buddhist", "songpan": "buddhist", "lijiang": "buddhist", "kokonor": "buddhist", "tsaidam": "buddhist",
            "jianchang": "native", "chenzhou": "native", "sien": "native", "bozhou": "native", "puan": "native"}

STRAITS = [("leizhou", "hainan"), ("amur_mouth", "sakhalin"), ("quanzhou", "taiwan"), ("dengzhou", "lushun")]
LAND_LINKS = []

DESERT = {"jiuquan", "dunhuang", "hami", "gobi", "ordos", "tsaidam", "ningxia"}
TERRAIN = {"nagqu": "mountains", "golog": "mountains", "chamdo": "mountains", "derge": "mountains", "litang": "mountains",
           "rutog": "mountains", "guge": "mountains", "lhatse": "mountains", "shigatse": "hills", "lhasa": "hills",
           "kongpo": "forest", "paro": "mountains", "bumthang": "mountains", "songpan": "mountains", "jianchang": "mountains",
           "kokonor": "plains", "beijing": "plains", "baoding": "plains", "daming": "plains", "kaifeng": "plains", "jinan": "plains",
           "nanjing": "plains", "suzhou": "marsh", "yangzhou": "plains", "huaian": "marsh", "hangzhou": "plains", "xian": "plains",
           "chengdu": "plains", "wuchang": "marsh", "changsha": "plains", "guangzhou": "plains", "yanzhou": "plains",
           "fengyang": "plains", "xuzhou": "plains", "runing": "plains", "jingzhou": "marsh", "nanchang": "plains",
           "guilin": "hills", "liuzhou": "hills", "guiyang": "hills", "bozhou": "hills", "puan": "hills", "kunming": "hills",
           "dali": "hills", "lijiang": "mountains", "yongchang": "mountains", "hainan": "forest", "taiwan": "forest",
           "mudan": "forest", "ussuri": "forest", "primorye": "forest", "zeya": "forest", "albazin": "forest",
           "heilong": "forest", "amur_mouth": "forest", "sakhalin": "forest", "jianzhou": "forest", "ula": "forest",
           "nonni": "plains", "khorchin": "plains", "hulunbuir": "plains", "kherlen": "plains", "tuul": "plains",
           "karakorum": "plains", "selenge": "forest", "uvs": "hills", "khovd": "mountains", "zavkhan": "hills"}


def DEFAULT_TERRAIN(key, lat):
    if key in DESERT:
        return "desert"
    return "hills" if lat < 28.0 else "plains"


RANGES = [
    (1.0, [(79.0, 33.6), (81.0, 32.2), (83.0, 31.2), (85.0, 30.4), (87.0, 29.8), (89.0, 30.0), (91.0, 30.6), (93.0, 30.6)]),  # Transhimalaya
    (0.65, [(84.0, 33.6), (87.0, 33.2), (90.0, 33.0), (93.0, 33.4), (96.0, 33.8)]),  # Tanggula / plateau
    (0.95, [(97.0, 29.0), (98.4, 30.6), (99.2, 32.0), (100.6, 33.6)]),  # Hengduan north
    (0.9, [(98.6, 25.6), (99.0, 27.4), (99.6, 28.8), (100.6, 29.8), (101.8, 30.4), (102.4, 31.4)]),  # Hengduan / Daxue
    (0.85, [(91.0, 37.4), (94.0, 36.6), (97.0, 36.0), (99.6, 35.4), (101.6, 34.6)]),  # Kunlun east / Bayan Har
    (0.75, [(94.0, 39.0), (97.0, 38.6), (99.6, 38.2), (101.6, 37.6), (103.0, 37.0)]),  # Qilian
    (0.5, [(104.0, 34.4), (106.0, 34.0), (108.0, 33.8), (110.0, 33.6), (111.6, 33.4)]),  # Qinling
    (0.4, [(106.0, 32.4), (108.0, 32.0), (110.0, 31.6)]),  # Daba
    (0.45, [(111.0, 36.0), (112.0, 37.4), (113.0, 39.0), (114.0, 40.2)]),  # Taihang / Lüliang
    (0.4, [(114.0, 41.0), (116.0, 41.4), (118.0, 41.0), (119.6, 40.6)]),  # Yan mountains (the Great Wall)
    (0.45, [(117.0, 40.2), (119.0, 42.8), (120.6, 45.0), (121.8, 47.4), (122.4, 49.6), (122.0, 52.0)]),  # Greater Khingan
    (0.35, [(126.0, 48.4), (127.6, 49.6), (129.0, 50.6)]),  # Lesser Khingan
    (0.45, [(126.6, 41.4), (127.8, 42.0), (128.8, 42.4)]),  # Changbai
    (0.35, [(133.0, 43.0), (135.0, 44.6), (136.6, 46.4), (138.0, 48.0)]),  # Sikhote-Alin
    (0.3, [(116.0, 28.0), (117.0, 26.6), (118.0, 26.0)]),  # Wuyi
    (0.3, [(110.0, 25.6), (112.0, 25.4), (114.0, 25.2)]),  # Nanling
    (0.3, [(108.0, 28.4), (109.0, 27.0), (110.0, 26.0)]),  # Wuling / Miao
    (0.35, [(120.9, 22.4), (121.0, 23.6), (121.3, 24.6)]),  # Taiwan central range
    (0.8, [(88.0, 48.6), (90.0, 48.2), (92.0, 47.2), (94.0, 46.0), (96.0, 45.4)]),  # Mongolian Altai
    (0.6, [(96.0, 47.2), (98.0, 47.4), (100.0, 47.6), (102.0, 47.6)]),  # Khangai
    (0.4, [(107.6, 48.2), (109.0, 48.6), (110.0, 49.2)]),  # Khentii
    (0.4, [(105.0, 39.0), (106.0, 38.6), (106.6, 37.8)]),  # Helan
    (0.35, [(142.6, 47.6), (142.8, 49.6), (143.0, 51.6)]),  # Sakhalin
]

RIVERS = [
    ("Jangtse", 3, [(97.0, 33.0), (98.6, 30.6), (99.6, 27.6), (100.6, 26.6), (102.0, 26.4), (103.6, 28.4), (104.6, 28.8), (106.0, 29.0),
                    (106.6, 29.6), (108.4, 30.8), (110.0, 30.9), (111.4, 30.4), (112.4, 30.0), (113.6, 29.8), (114.3, 30.55), (115.8, 29.8),
                    (117.0, 30.5), (118.0, 31.3), (118.8, 32.1), (119.8, 32.2), (120.8, 31.8), (121.8, 31.4)]),
    ("Gelber Fluss", 3, [(97.0, 34.6), (99.6, 34.6), (101.4, 35.8), (103.8, 36.1), (105.2, 37.4), (106.4, 38.8), (107.0, 40.2), (109.0, 40.6),
                         (110.6, 40.4), (111.0, 39.0), (110.6, 37.0), (110.4, 35.4), (110.6, 34.6), (112.0, 34.8), (113.6, 34.9),
                         (114.6, 34.8), (116.0, 35.4), (117.4, 36.6), (118.6, 37.4)]),
    ("Kaiserkanal", 1, [(116.6, 39.8), (116.4, 38.0), (116.2, 36.8), (116.6, 35.4), (117.6, 34.2), (119.0, 33.5), (119.4, 32.4), (120.3, 31.6),
                        (120.6, 31.0), (120.15, 30.3)]),
    ("Han", 1, [(106.8, 33.0), (108.6, 32.8), (110.6, 32.6), (112.1, 32.0), (113.0, 31.0), (114.2, 30.6)]),
    ("Wei", 1, [(104.6, 34.8), (106.6, 34.4), (108.0, 34.3), (109.6, 34.5), (110.3, 34.6)]),
    ("Fen", 1, [(111.8, 38.6), (112.4, 37.6), (111.6, 36.2), (110.6, 35.6)]),
    ("Huai", 1, [(113.6, 32.4), (115.0, 32.4), (116.4, 32.6), (117.6, 33.0), (118.6, 33.2), (119.2, 33.3)]),
    ("Gan", 1, [(115.0, 25.9), (115.0, 27.0), (115.6, 28.0), (115.9, 28.8), (116.2, 29.4)]),
    ("Xiang", 1, [(111.0, 25.6), (112.2, 26.6), (112.8, 27.6), (112.9, 28.4), (113.0, 29.2)]),
    ("Perlfluss", 2, [(104.2, 25.0), (106.0, 24.6), (108.0, 23.6), (109.6, 23.4), (111.3, 23.5), (112.6, 23.0), (113.4, 22.6), (113.6, 22.2)]),
    ("Min", 1, [(103.6, 32.4), (103.8, 31.2), (104.0, 30.4), (104.0, 29.4), (104.6, 28.8)]),
    ("Liao", 1, [(118.6, 42.6), (120.6, 43.4), (122.6, 43.0), (123.4, 42.0), (122.4, 40.8), (122.2, 40.6)]),
    ("Sungari", 2, [(127.6, 42.6), (126.6, 43.8), (125.4, 45.4), (126.6, 45.8), (128.6, 46.0), (130.6, 46.8), (132.4, 47.8)]),
    ("Amur", 3, [(120.4, 53.2), (123.8, 53.4), (126.6, 52.2), (127.6, 49.8), (130.0, 48.8), (132.4, 47.8), (135.0, 48.4), (136.6, 49.8),
                 (137.2, 51.0), (139.2, 52.0), (140.6, 52.6)]),
    ("Ussuri", 1, [(133.6, 44.0), (133.6, 45.6), (134.0, 46.8), (135.0, 48.4)]),
    ("Tsangpo", 2, [(82.6, 30.4), (85.6, 29.4), (88.4, 29.3), (90.6, 29.3), (92.6, 29.3), (94.4, 29.6), (95.2, 29.2), (95.4, 28.2)]),
    ("Selenge", 1, [(98.0, 49.6), (101.6, 49.4), (104.0, 49.8), (106.2, 50.4), (106.8, 51.6), (106.6, 52.2)]),
    ("Kherlen", 1, [(108.0, 48.4), (110.6, 47.4), (113.0, 47.6), (115.4, 48.0), (117.4, 48.8)]),
]

NATIONS = {
    "MNG": {"religion": "confucian", "devout": True, "name": "Ming", "color": "#c8a040", "emoji": "🐉", "capital": "beijing", "aggression": 0.4,
            "bonus": {"tax": 0.1, "production": 0.1, "tech_cost": -0.05}, "idea": "Das Mandat des Himmels: +10 % Steuern, +10 % Produktion, Technik −5 %",
            "rulers": ["Zhengtong", "Jingtai", "Chenghua", "Hongzhi", "Zhengde", "Jiajing"]},
    "TIB": {"religion": "buddhist", "devout": True, "name": "Tibet", "color": "#b05a8a", "emoji": "🏔️", "capital": "lhasa", "aggression": 0.4,
            "bonus": {"defense": 0.15, "stability": 0.05}, "idea": "Die Phagmodrupa von Ü: +15 % Verteidigung, +5 Stabilitätsziel",
            "rulers": ["Drakpa Gyaltsen", "Drakpa Jungne", "Kunga Lekpa", "Ngagi Wangpo"]},
    "TSA": {"religion": "buddhist", "name": "Tsang", "color": "#8a4a6a", "emoji": "🛕", "capital": "shigatse", "aggression": 0.7,
            "bonus": {"combat": 0.05, "defense": 0.1}, "idea": "Die Rinpungpa von Tsang: +5 % Kampfkraft, +10 % Verteidigung",
            "rulers": ["Norzang", "Kunzang", "Donyo Dorje", "Ngawang Namgyal"]},
    "GUG": {"religion": "buddhist", "name": "Guge", "color": "#a08a5a", "emoji": "☸️", "capital": "guge", "aggression": 0.3,
            "bonus": {"defense": 0.15}, "idea": "Klosterburgen von Tsaparang: +15 % Verteidigung",
            "rulers": ["Namgyal De", "Lobsang Rabten", "Jigten Wangchuk"]},
    "BHU": {"religion": "buddhist", "name": "Bhutan", "color": "#e08a3a", "emoji": "🐉", "capital": "paro", "aggression": 0.3,
            "bonus": {"defense": 0.2}, "idea": "Burgen der Drukpa: +20 % Verteidigung",
            "rulers": ["Lama Drukpa Kunley", "Ngawang Chogyal", "Tenzin Rabgye"]},
    "MGL": {"religion": "native", "name": "Mongolen", "color": "#5a7ab0", "emoji": "🏹", "capital": "karakorum", "aggression": 1.1,
            "bonus": {"manpower": 0.2, "combat": 0.05}, "idea": "Erben Dschingis Khans: +20 % Mannschaften, +5 % Kampfkraft",
            "rulers": ["Taisun Khan", "Mandaghol", "Bayan Möngke", "Dayan Khan", "Altan Khan"]},
    "OIR": {"religion": "native", "name": "Oiraten", "color": "#7a5ab0", "emoji": "🐎", "capital": "khovd", "aggression": 1.3,
            "bonus": {"manpower": 0.15, "combat": 0.1}, "idea": "Esen Taischis Reiterheer: +15 % Mannschaften, +10 % Kampfkraft",
            "rulers": ["Esen Taischi", "Amasandsch", "Ishi Temür", "Abulai"]},
    "HAM": {"religion": "sunni", "name": "Hami", "color": "#a0b06a", "emoji": "🍈", "capital": "hami", "aggression": 0.3,
            "bonus": {"trade": 0.15}, "idea": "Tor zur Seidenstraße: +15 % Handelseinnahmen",
            "rulers": ["Buda Shiri", "Bek Temür", "Shan Ba"]},
    "JIA": {"religion": "native", "name": "Jianzhou", "color": "#4a7a5a", "emoji": "🏹", "capital": "jianzhou", "aggression": 0.9,
            "bonus": {"manpower": 0.1, "combat": 0.05}, "idea": "Jurchen-Wachen der Ming: +10 % Mannschaften, +5 % Kampfkraft",
            "rulers": ["Li Manzhu", "Dong Shan", "Wang Gao", "Giocangga"]},
    "HXI": {"religion": "native", "name": "Haixi", "color": "#6a6a3a", "emoji": "🦅", "capital": "ula", "aggression": 0.7,
            "bonus": {"manpower": 0.1}, "idea": "Die Hūlun-Bünde: +10 % Mannschaften",
            "rulers": ["Wangju", "Buyan", "Mantai"]},
    "YRN": {"religion": "native", "name": "Wilde Jurchen", "color": "#5a8a8a", "emoji": "🐻", "capital": "mudan", "aggression": 0.5, "native": True,
            "bonus": {"defense": 0.1, "tech_cost": 0.3}, "idea": "Jäger der Wälder am Ussuri: +10 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Uyangga", "Fiyanggu", "Sahaliyan"]},
    "DAU": {"religion": "native", "name": "Dauren", "color": "#8a6a4a", "emoji": "🦌", "capital": "zeya", "aggression": 0.4, "native": True,
            "bonus": {"production": 0.05, "tech_cost": 0.3}, "idea": "Bauern und Jäger am Amur: +5 % Produktion (Technik +30 % teurer)",
            "rulers": ["Bombogor", "Lavkai", "Albaza"]},
    "NIV": {"religion": "native", "name": "Niwchen", "color": "#4a5a7a", "emoji": "🐟", "capital": "amur_mouth", "aggression": 0.3, "native": True,
            "bonus": {"production": 0.05, "tech_cost": 0.3}, "idea": "Fischer an Amur und Sachalin: +5 % Produktion (Technik +30 % teurer)",
            "rulers": ["Chkhyf", "Lanuk", "Pila"]},
    "TAW": {"religion": "native", "name": "Formosa", "color": "#3a8a5a", "emoji": "🌿", "capital": "taiwan", "aggression": 0.3, "native": True,
            "bonus": {"defense": 0.15, "tech_cost": 0.3}, "idea": "Dörfer der Bergvölker: +15 % Verteidigung (Technik +30 % teurer)",
            "rulers": ["Kamachat", "Ataiyal", "Kavalan"]},
}

NEW_GOODS = {
    "tea": {"name": "Tee", "price": 0.4, "bonus": {"stability": 0.05}, "bonus_text": "+5 Stabilitätsziel", "emoji": "🍵", "color": "#6f9a4a"},
    "porcelain": {"name": "Porzellan", "price": 0.55, "bonus": {"prestige": 0.5, "trade": 0.05}, "bonus_text": "+0,5 Prestige/Jahr, +5 % Handel",
                  "emoji": "🏺", "color": "#5a7fc8"},
}

SUN_DISC = ["..GGG..", ".GGGGG.", "GGGGGGG", "GGGGGGG", "GGGGGGG", ".GGGGG.", "..GGG.."]
MOUNT = ["....w....", "...www...", "..wwaww..", ".wwaaaww.", "wwaaaaaww"]
SOYOMBO = ["...G...", "..GGG..", "...G...", "GGGGGGG", ".G.G.G.", ".GGGGG.", "...G..."]


def flag_art(h):
    rc, cen, solid, field = h["recolor"], h["centred"], h["solid"], h["field"]
    W = h["TO_WHITE"]
    return {
        "MNG": (cen(solid("R"), SUN_DISC, cy=3), "Ming – golden sun on red (stylised)"),
        "TIB": (cen(field("B", "w"), rc(h["SUN"], {}), cy=1), "Tibet – sun over the snows (stylised)"),
        "TSA": (cen(solid("E"), MOUNT, cy=5), "Tsang – white mountain on crimson (stylised)"),
        "GUG": (cen(solid("D"), rc(SOYOMBO, {"G": "E"}), cy=3), "Guge – red emblem on dark gold (stylised)"),
        "BHU": (h["bend"](field("Y", "O"), "w"), "Bhutan – yellow and orange (stylised)"),
        "MGL": (cen(solid("B"), SOYOMBO, cy=3), "Mongols – golden emblem on blue (stylised)"),
        "OIR": (cen(solid("P"), rc(h["TAMGA"], W), cy=4), "Oirats – white tamga on purple (stylised)"),
        "HAM": (cen(solid("L"), rc(h["CRESCENT"], h["TO_GOLD"]), cy=3), "Hami – gold crescent on green (stylised)"),
        "JIA": (cen(solid("F"), rc(h["BIRD"], W), cy=3), "Jianzhou – white falcon on dark green (stylised)"),
        "HXI": (cen(solid("D"), rc(h["BIRD"], {"G": "k", "D": "k"}), cy=3), "Haixi – black eagle on dark gold (stylised)"),
        "YRN": (cen(solid("L"), rc(h["KNOT"], {}), cy=3), "Wild Jurchen – white knot on green (stylised)"),
        "DAU": (cen(solid("O"), rc(h["KNOT"], {"w": "k"}), cy=3), "Daur – black knot on orange (stylised)"),
        "NIV": (cen(solid("B"), h["WAVES"], cy=4), "Nivkh – waves on blue (stylised)"),
        "TAW": (cen(solid("F"), rc(h["SUN"], W), cy=3), "Formosa – white sun on dark green (stylised)"),
    }


GOODS = """
silk: suzhou hangzhou chengdu
porcelain: jingdezhen quanzhou huizhou
tea: jianning fuzhou jinhua anqing yibin hanzhong lijiang puan
cloth: nanjing beijing ningbo yangzhou guangzhou wuchang kaifeng
grain: baoding daming taiyuan pingyang xian  luoyang nanyang runing jinan yanzhou qingzhou huaian fengyang xuzhou nanchang jian changsha hengzhou changde jingzhou xiangyang chongqing baoning guilin wuzhou gaozhou liaoyang kaiyuan jianzhou
salt: yongping ningxia dengzhou lushun chaozhou leizhou
iron: datong guangning qujing
copper: kunming linan dali
silver: yongchang ganzhou
horses: xuanfu jiuquan liangzhou xining kokonor karakorum tuul kherlen hulunbuir chahar tumed ordos khovd zavkhan dzungaria tarbagatai khorchin uriankhai
livestock: yanan pingliang lanzhou golog derge litang nagqu chamdo tsaidam gobi uvs selenge rutog guge
spices: wenzhou hainan nanning liuzhou
dyes: shaozhou tingzhou
paper: kuizhou
timber: chenzhou bozhou guiyang sien jianchang songpan kongpo bumthang taiwan mudan primorye
furs: nonni ula ussuri zeya albazin heilong amur_mouth sakhalin
fish:
gold: lhatse
wool: shigatse lhasa paro
glass: hami dunhuang
"""
MARKETS = ["beijing", "nanjing", "guangzhou", "chengdu", "lhasa", "karakorum"]

ALLIANCES = []
RIVALS = [["MNG", "OIR"], ["MNG", "MGL"], ["OIR", "MGL"], ["TIB", "TSA"], ["JIA", "HXI"]]
