"""Adds the trade goods of the v1.0 goods update to data/goods.json (idempotent: run it again any time).

Each good: name, base price, leader bonus (Game.mod keys), map colour, emoji (pixel glyph in
tools/art/emoji_icons.py). PROVINCES reassigns existing province keys to the new goods; keys that are
not on the map yet (new regions) are skipped, so coffee/incense can wait for their region.
Usage: python3 tools/economy/add_goods.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
PATH = os.path.join(ROOT, "data", "goods.json")

GOODS = {
    "silk": {"name": "Seide", "price": 0.5, "bonus": {"diplo_cap": 1.0}, "bonus_text": "+1 diplomatische Kapazität", "emoji": "🧶", "color": "#d94f8a"},
    "spices": {"name": "Gewürze", "price": 0.55, "bonus": {"prestige": 1.0}, "bonus_text": "+1 Prestige/Jahr", "emoji": "🌶", "color": "#c7361f"},
    "cotton": {"name": "Baumwolle", "price": 0.25, "bonus": {"city_growth": 0.15}, "bonus_text": "+15 % Stadtwachstum", "emoji": "☁", "color": "#f6f0ff"},
    "glass": {"name": "Glas", "price": 0.45, "bonus": {"ae_decay": 0.15}, "bonus_text": "+15 % Abbau aggressiver Expansion", "emoji": "🔮", "color": "#7fd6d0"},
    "paper": {"name": "Papier", "price": 0.35, "bonus": {"coring": -0.1}, "bonus_text": "-10 % Zeit bis zur Kernprovinz", "emoji": "📃", "color": "#e9dfb0"},
    "horses": {"name": "Pferde", "price": 0.3, "bonus": {"move_speed": 0.05}, "bonus_text": "+5 % Marschtempo", "emoji": "🐎", "color": "#6e4a2c"},
    "olive_oil": {"name": "Olivenöl", "price": 0.3, "bonus": {"army_power_regen": 0.1}, "bonus_text": "+10 % Moral-Erholung der Armeen", "emoji": "🫒", "color": "#8a9a2c"},
    "amber": {"name": "Bernstein", "price": 0.4, "bonus": {"conversion": 0.15}, "bonus_text": "+15 % Bekehrungstempo", "emoji": "🔶", "color": "#e8902a"},
    "naval_supplies": {"name": "Schiffsbedarf", "price": 0.3, "bonus": {"naval_limit": 0.15}, "bonus_text": "+15 % Flottenlimit", "emoji": "🪢", "color": "#3c5a6e"},
    "ivory": {"name": "Elfenbein", "price": 0.45, "bonus": {"colony_cost": -0.1}, "bonus_text": "-10 % Kolonisierungskosten", "emoji": "🦷", "color": "#fff6d8"},
    "dyes": {"name": "Farbstoffe", "price": 0.4, "bonus": {"unrest": -0.5}, "bonus_text": "-0,5 Unruhe", "emoji": "🎨", "color": "#5b2fa0"},
    "coffee": {"name": "Kaffee", "price": 0.45, "bonus": {"advisor_slots": 1.0}, "bonus_text": "+1 Berater-Platz", "emoji": "☕", "color": "#4a2a18"},
    "incense": {"name": "Weihrauch", "price": 0.5, "bonus": {"religious_unrest": -0.25}, "bonus_text": "-25 % religiöse Unruhe", "emoji": "🪔", "color": "#c9b08a"},
}

PROVINCES = {
    "silk": "bursa shamakhi calabria valencia lyon gilan mazandaran",
    "spices": "pepper_coast alexandria benin hormuz hasa",
    "cotton": "adana urfa upper_egypt aydin segu",
    "glass": "venice pilsen",
    "paper": "ancona regensburg genoa",
    "horses": "zaporozhia kabarda circassia temes kayseri",
    "olive_oil": "apulia kairouan tripoli_sy crete malaga",
    "amber": "prussia marienburg",
    "naval_supplies": "riga turku reval",
    "ivory": "ivory_coast borgu",
    "dyes": "toulouse languedoc oaxaca",
    "coffee": "sanaa tihama",
    "incense": "hadramaut",
}

if __name__ == "__main__":
    d = json.load(open(PATH, encoding="utf-8"))
    for k, v in GOODS.items():
        d["goods"][k] = v
    moved = 0
    for good, keys in PROVINCES.items():
        for key in keys.split():
            if key in d["provinces"]:
                d["provinces"][key] = good
                moved += 1
    json.dump(d, open(PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(PATH, "a").write("\n")
    print(len(d["goods"]), "goods,", moved, "provinces reassigned")
