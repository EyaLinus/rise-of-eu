#!/usr/bin/env python3
"""Writes the data of the world regions (tools/world/*.py) into the game data. Idempotent: run it again any
time after tools/gen_map.py.

    nations.json   one entry per tag (added at the end, existing entries replaced)
    goods.json     the good of every province of the regions, their market centres and new goods (NEW_GOODS;
                   each needs a pixel glyph for its emoji in tools/art/emoji_icons.py)
    diplomacy.json alliances and rivalries

Flags are drawn by tools/art/flags.py (it imports the regions' flag_art), then tools/build_art.sh.
Usage: python3 tools/world/apply.py
"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import world  # noqa: E402


def load(name):
    return json.load(open(os.path.join(ROOT, "data", name), encoding="utf-8"))


def main():
    m = load("map.json")
    keys = {p["key"] for p in m["provinces"]}
    owners = {p["key"]: p["owner"] for p in m["provinces"]}
    nations = load("nations.json")
    goods = load("goods.json")
    dip = load("diplomacy.json")
    for r in world.REGIONS:
        for good, gd in getattr(r, "NEW_GOODS", {}).items():
            goods["goods"][good] = gd
        for tag, nd in r.NATIONS.items():
            assert nd["capital"] in keys and owners[nd["capital"]] == tag, (tag, nd["capital"])
            nat = nations.pop("NAT", None)  # NAT (uncolonized land) stays last
            nations[tag] = nd
            if nat is not None:
                nations["NAT"] = nat
        for tag, upd in getattr(r, "NATION_UPDATES", {}).items():
            nations[tag].update(upd)
            assert nations[tag]["capital"] in keys, (tag, nations[tag]["capital"])
        seen = set()
        for line in r.GOODS.strip().splitlines():
            good, ks = line.split(":")
            assert good in goods["goods"], good
            for k in ks.split():
                assert k in keys and k not in seen, k
                seen.add(k)
                goods["provinces"][k] = good
        missing = sorted({p[0] for p in r.PROVINCES} - seen)
        assert not missing, "%s: provinces without a good: %s" % (r.BLOCK, missing)
        for k in r.MARKETS:
            if k not in goods["markets"]:
                goods["markets"].append(k)
        for kind in ("alliances", "rivals"):
            for pair in getattr(r, kind.upper()):
                if pair not in dip[kind] and pair[::-1] not in dip[kind]:
                    dip[kind].append(pair)
        for p in r.PROVINCES:
            assert p[4] in nations, (p[0], p[4])
    with open(os.path.join(ROOT, "data", "nations.json"), "w", encoding="utf-8") as f:
        f.write("{\n" + ",\n".join('  "%s": %s' % (k, json.dumps(v, ensure_ascii=False)) for k, v in nations.items()) + "\n}")
    json.dump(goods, open(os.path.join(ROOT, "data", "goods.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    json.dump(dip, open(os.path.join(ROOT, "data", "diplomacy.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    for f in ("nations.json", "goods.json", "diplomacy.json"):
        open(os.path.join(ROOT, "data", f), "a").write("\n")
    print(len(nations), "nations,", len(goods["provinces"]), "goods,", len(goods["markets"]), "markets")


if __name__ == "__main__":
    main()
