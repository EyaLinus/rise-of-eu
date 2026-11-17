"""Rough value model for event options, used to find options that are clearly better than all others.

  python3 tools/event_value.py            # list events whose best option dominates (gap report)
  python3 tools/event_value.py --all      # every event with option values

Values are in "gold equivalents" and only meant for comparing options of the same event. An option is flagged
when it is worth much more than the second best one, or when it is at least as good as another option on every
single effect (Pareto dominance, ignoring flavour-only effects).
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# gold-equivalent per unit
W = {"gold": 1.0, "adm": 1.5, "dip": 1.5, "mil": 1.5, "prestige": 3.0, "regs": 12.0, "manpower": 10.0,
     "dev_random": 60.0, "dev_capital": 60.0, "ae": -4.0, "we": -15.0, "army_power": 100.0, "ships": 12.0,
     "monument_progress": 8.0, "power_proj": 3.0, "spouse_rel": 0.3, "rival_rel": 0.3, "loan": -40.0,
     "loan_forgiven": 80.0, "convert_random": 30.0, "urbanize": 50.0, "build": 60.0}
MOD_W = 1500.0       # per +1.0 of a permanent modifier (0.03 -> 45); negative-is-good keys flip below
NEG_GOOD = {"ae_gain", "unrest", "build_cost", "dev_cost", "core_cost", "inflation", "war_exhaustion",
            "we_gain", "maintenance", "regiment_cost", "upkeep", "tech_cost", "attrition", "advisor_cost"}
FLAT = {"claim": 15.0, "alliance": 25.0, "vassal": 120.0, "inherit": 250.0, "merc_ready": 20.0,
        "feast_ready": 10.0, "end_regency": 20.0, "heir_trait": 15.0, "ruler_trait": 0.0}


def dims(effects):
    """Effect -> {dimension: signed value} so options can be compared dimension by dimension."""
    d = {}
    for k, v in effects.items():
        if k in W and isinstance(v, (int, float)) and not isinstance(v, bool):
            d[k] = v * W[k]
        elif k == "mods":
            for mk, mv in v.items():
                d["mod:" + mk] = (-mv if mk in NEG_GOOD else mv) * MOD_W
        elif k == "estate":
            for ek, ev in v.items():
                d["estate:" + ek] = ev * 4.0
        elif k == "relations":
            # relations rarely matter much; count only the net sum
            d["relations"] = sum(v.values()) * 0.15
        elif k in ("ruler", "heir"):
            d[k] = sum(x for x in v.values() if isinstance(x, (int, float))) * 45.0
        elif k == "claim":
            d[k] = FLAT[k] * (len(v) if isinstance(v, list) else 1)
        elif k in FLAT:
            d[k] = FLAT[k]
        elif k == "war":
            d[k] = -30.0
    return d


def value(effects):
    return sum(dims(effects).values())


def pareto_dominates(a, b):
    """a is >= b on every dimension and > on one. Options with war/age_pick/flag/inherit are left out."""
    keys = set(a) | set(b)
    ge = all(a.get(k, 0) >= b.get(k, 0) - 1e-9 for k in keys)
    gt = any(a.get(k, 0) > b.get(k, 0) + 1e-9 for k in keys)
    return ge and gt


SPECIAL = {"war", "age_pick", "flag", "inherit", "isolate", "vassal", "alliance"}


def audit(events):
    out = []
    for e in events:
        opts = e["options"]
        if len(opts) < 2:
            continue
        vals = [value(o.get("effects", {})) for o in opts]
        ds = [dims(o.get("effects", {})) for o in opts]
        special = any(SPECIAL & set(o.get("effects", {})) for o in opts)
        best = max(range(len(opts)), key=lambda i: vals[i])
        rest = sorted(vals[:best] + vals[best + 1:], reverse=True)
        gap = vals[best] - rest[0]
        par = [] if special else [(i, j) for i in range(len(opts)) for j in range(len(opts))
                                  if i != j and pareto_dominates(ds[i], ds[j])]
        flag_gap = gap > max(45.0, 0.6 * abs(vals[best])) and not special
        if flag_gap or par:
            out.append({"id": e["id"], "vals": [round(v) for v in vals], "best": best, "gap": round(gap),
                        "pareto": par})
    return out


if __name__ == "__main__":
    ev = json.load(open(os.path.join(ROOT, "data/events.json"), encoding="utf-8"))
    if "--all" in sys.argv:
        for e in ev:
            print(e["id"], [round(value(o.get("effects", {}))) for o in e["options"]])
        sys.exit(0)
    res = audit(ev)
    for r in res:
        print(r)
    print("flagged %d of %d events" % (len(res), len(ev)))
