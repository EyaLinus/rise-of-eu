"""Goods for the North American west ("pac" provinces) and the Low Countries (idempotent: run it again any time).

Run after tools/gen_map.py has the "pac" provinces. Keys missing from the map are an error.
Usage: python3 tools/economy/pac_goods.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
PATH = os.path.join(ROOT, "data", "goods.json")

ASSIGN = """
silver: durango chihuahua conchos
copper: gila
gold: yaqui
salt: baja_sur
cotton: tohono pueblo hopi
dyes: zuni sinaloa
cocoa: nayarit
grain: maidu yokuts kalapuya
livestock: dine ute arapaho crow wind_river snake blackfoot cree_plains great_basin n_paiute timpanogos paiute
fish: chumash tongva kumeyaay ohlone pomo yurok chinook salish nuu_chah_nulth baja_norte yuma
furs: dakelh sekani athabasca secwepemc ktunaxa nez_perce yakama sonora
timber: klamath mojave
cloth: zeeland
naval_supplies: friesland
glass: utrecht
"""
MARKETS = []
NEW_KEYS = {"zeeland", "utrecht", "friesland"}

if __name__ == "__main__":
    d = json.load(open(PATH, encoding="utf-8"))
    m = json.load(open(os.path.join(ROOT, "data", "map.json"), encoding="utf-8"))
    keys = {p["key"] for p in m["provinces"]}
    want = {p["key"] for p in m["provinces"] if p.get("pac")} | NEW_KEYS
    seen = set()
    for line in ASSIGN.strip().splitlines():
        good, ks = line.split(":")
        assert good in d["goods"], good
        for k in ks.split():
            assert k in keys and k not in seen, k
            seen.add(k)
            d["provinces"][k] = good
    missing = sorted(want - seen)
    assert not missing, missing
    for k in MARKETS:
        if k not in d["markets"]:
            d["markets"].append(k)
    json.dump(d, open(PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(PATH, "a").write("\n")
    print(len(seen), "western / Low Countries provinces, markets:", len(d["markets"]))
