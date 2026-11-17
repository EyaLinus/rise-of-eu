"""Goods and market centres for South America and the finer North American east coast (idempotent: run it
again any time).

Run after tools/gen_map.py has the "sa" provinces. Keys missing from the map are an error.
Usage: python3 tools/economy/sa_goods.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
PATH = os.path.join(ROOT, "data", "goods.json")

ASSIGN = """
gold: antioquia zenu cauca hunza canari minas goias copiapo
silver: charcas chucuito
copper: atacama coquimbo
salt: bacata cumana
sugar: pernambuco bahia sao_vicente guanabara potiguara suriname guayana cayenne calamari
cocoa: caracas guayaquil para
tobacco: orinoco tuscarora nanticoke
dyes: porto_seguro espirito_santo ceara
cotton: nazca lambayeque maranhao sertao
cloth: cusco chan_chan quito
wool: collao arequipa
spices: antisuyu tapajos
grain: apurimac jauja huanuco cajamarca chachapoyas chincha mapocho maule araucania tucuman guarani timucua guale pequot tairona
livestock: llanos pampa rio_plata charrua parana tape chaco cuyo cordoba patagonia santa_cruz magallanes malvinas pantanal mato_grosso
fish: tumbes pachacamac huilliche aysen coquivacoa calusa wampanoag carijo
furs: munsee wolastoqiyik
timber: amazonas madeira rio_negro solimoes maynas ucayali tocantins roraima moxos chiquitos guaira amapa penobscot
"""
MARKETS = ["cusco", "bahia"]

if __name__ == "__main__":
    d = json.load(open(PATH, encoding="utf-8"))
    m = json.load(open(os.path.join(ROOT, "data", "map.json"), encoding="utf-8"))
    keys = {p["key"] for p in m["provinces"]}
    sa = {p["key"] for p in m["provinces"] if p.get("sa")}
    seen = set()
    for line in ASSIGN.strip().splitlines():
        good, ks = line.split(":")
        assert good in d["goods"], good
        for k in ks.split():
            assert k in keys and k not in seen, k
            seen.add(k)
            d["provinces"][k] = good
    missing = sorted(sa - seen)
    assert not missing, missing
    for k in MARKETS:
        if k not in d["markets"]:
            d["markets"].append(k)
    json.dump(d, open(PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    open(PATH, "a").write("\n")
    print(len(seen), "South American / east coast provinces, markets:", len(d["markets"]))
