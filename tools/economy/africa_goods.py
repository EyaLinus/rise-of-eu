"""Goods and market centres for Africa south of the Sahara (idempotent: run it again any time).

Run after tools/gen_map.py has the "af" provinces. Keys missing from the map are an error.
Usage: python3 tools/economy/africa_goods.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
PATH = os.path.join(ROOT, "data", "goods.json")

ASSIGN = """
gold: mutapa zimbabwe sofala kilwa
ivory: kenya maasai unyamwezi yao azande ubangi ituri luangwa limpopo bagamoyo juba
copper: katanga luba damaraland tio
iron: maravi
salt: fezzan air tibesti ndongo lunda
horses: bornu darfur
cotton: kordofan
cloth: mogadishu kongo kuba
dyes: loango
spices: zanzibar betsimisaraka
coffee: kaffa
incense: majerteen
fish: malindi mombasa mozambique inhambane delagoa cape okavango boina
timber: cameroon ogowe congo_basin maniema
grain: yaka imerina buganda
livestock: kanem bagirmi wadai adamawa hobyo borana bale bunyoro rwanda sudd benguela lozi ovambo kalahari namaqua karoo xhosa natal highveld menabe androy
"""
MARKETS = ["bornu", "kilwa", "kongo"]

if __name__ == "__main__":
    d = json.load(open(PATH, encoding="utf-8"))
    m = json.load(open(os.path.join(ROOT, "data", "map.json"), encoding="utf-8"))
    keys = {p["key"] for p in m["provinces"]}
    af = {p["key"] for p in m["provinces"] if p.get("af")}
    seen = set()
    for line in ASSIGN.strip().splitlines():
        good, ks = line.split(":")
        assert good in d["goods"], good
        for k in ks.split():
            assert k in keys and k not in seen, k
            seen.add(k)
            d["provinces"][k] = good
    missing = sorted(af - seen)
    assert not missing, missing
    for k in MARKETS:
        if k not in d["markets"]:
            d["markets"].append(k)
    json.dump(d, open(PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(PATH, "a").write("\n")
    print(len(seen), "African provinces, markets:", len(d["markets"]))
