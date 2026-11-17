"""Event option balance pass (2026-11-17, Linus: "bei einigen Events ist eine Option viel besser als alle anderen").

Applied on top of every generator: events_io.replace_block() calls apply() after writing, so re-running any
generator keeps these fixes. Run directly to apply them to data/events.json and data/missions.json:

  python3 tools/content/event_balance.py

1. Manpower scale: n.manpower counts regiments (max ~3-40), but ~50 events/missions gave "manpower": 1500 or
   -800 as if it were men. That filled or emptied the pool in one click. Values >= 100 are converted to
   regiments (/500, at least 1).
2. PATCHES: hand-tuned options for events where one choice was clearly the best (found with
   tools/event_value.py: a permanent +1 monthly mana or +10 % income next to a one-off +40, or options that were
   worse on every count). Each entry replaces the effects (and optionally the AI weight) of single options.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# event id -> {option index: effects} (or {option index: (effects, ai weight)})
PATCHES = {
    # permanent +1 monthly mana must cost something real; the one-off options roughly double
    "fra_richelieu": {0: {"mods": {"adm": 1}, "gold": -120, "estate": {"adel": -6}},
                      1: {"claim": ["luxembourg", "franchecomte"], "dip": 80},
                      2: {"gold": 200}},
    "rus_third_rome": {0: {"prestige": 10, "mods": {"adm": 1}, "gold": -120, "estate": {"adel": -5}},
                       1: {"adm": 70, "dip": 70},
                       2: {"gold": 180, "prestige": 5}},
    "fra_estates": {0: {"gold": 180, "prestige": -5},
                    1: {"mods": {"adm": 1}, "dip": -60, "estate": {"adel": -6, "buerger": -4}},
                    2: {"dip": 70, "prestige": 5, "estate": {"buerger": 4}}},
    "hab_worms": {0: {"mods": {"dip": 1}, "gold": -100, "estate": {"adel": -5}},
                  1: {"gold": 160},
                  2: {"adm": 80}},
    "rus_sudebnik": {0: {"adm": 90},
                     1: {"mods": {"adm": 1}, "gold": -150, "estate": {"adel": -5}},
                     2: {"prestige": 10, "dip": 50, "estate": {"adel": 5}}},
    "gen_university": {0: {"gold": -140, "mods": {"adm": 1}},
                       1: {"adm": 60, "prestige": 3},
                       2: {"gold": 60, "estate": {"buerger": 3}}},
    # +10 % income forever for 50 gold was the best deal in the game
    "spa_columbus": {0: {"gold": -80, "mods": {"income": 0.04}, "prestige": 10},
                     1: {"gold": 60, "dip": 20},
                     2: {"adm": 60, "prestige": 3}},
    "hab_frederick": {0: {"dip": 30, "mods": {"ae_decay": 0.1}, "prestige": -5},
                      1: {"adm": 80},
                      2: {"prestige": 25, "dip": 30, "gold": -30}},
    "rus_ugra": {0: {"prestige": 15, "mods": {"manpower": 0.05}, "mil": -20},
                 1: {"gold": -40, "adm": 60, "dip": 30},
                 2: {"mil": 60, "manpower": -2, "prestige": 15}},
    "gen_military_revolution": {0: {"mil": -100, "mods": {"combat": 0.03}},
                                1: {"gold": -40, "manpower": 4, "mil": 20},
                                2: {"mil": 60}},
    # tolerance used to be free development; persecution now at least pleases the clergy
    "spa_inquisition": {0: {"prestige": 10, "dev_random": -1, "adm": 40, "estate": {"klerus": 6}},
                        1: {"dev_random": 1, "prestige": -10, "estate": {"klerus": -8}, "relations": {"PAP": -30}},
                        2: {"gold": 150, "dev_random": -2, "estate": {"klerus": 3}}},
    "boh_brethren": {0: {"adm": 30, "dev_random": 1, "estate": {"klerus": -5}},
                     1: {"prestige": 10, "relations": {"PAP": 30}, "estate": {"klerus": 6}},
                     2: {"dip": 50, "gold": -20}},
    "hab_vienna_siege": {2: {"gold": -60, "relations": {"TUR": 80}, "mil": 30}},
    "nap_vesuvius": {2: {"dev_capital": -1, "gold": 60}},
    "spa_lepanto": {0: {"mil": -20, "ships": -2, "prestige": 25, "relations": {"PAP": 40, "VEN": 40, "TUR": -50}},
                    1: {"gold": -60, "relations": {"PAP": 30}, "ships": 2}},
    "hab_eger": {0: {"prestige": -5, "mil": 40},
                 1: {"adm": -20, "mods": {"combat": 0.02}, "prestige": 5},
                 2: {"regs": 3, "prestige": -5}},
    "gen_fugger": {1: {"gold": 70, "dip": -20},
                   2: {"prestige": 10, "estate": {"buerger": 4}}},
    "gen_minor_neutrality": {2: {"dip": 20, "prestige": -5, "ae": -10}},
    "gen_vassal_court": {1: {"prestige": 10, "dip": -10, "estate": {"adel": 4}},
                         2: {"adm": 40}},
    "pap_julius": {0: {"mil": 20, "prestige": 10, "regs": 2},
                   2: {"prestige": 25, "gold": -40}},
    "pap_trent": {0: {"adm": 40, "prestige": 10},
                  1: {"mil": 40, "prestige": 5, "estate": {"klerus": 6}},
                  2: {"dip": 60, "prestige": -5}},
    "ara_remensa": {0: {"dev_random": 1, "relations": {"SPA": 10}, "estate": {"adel": -5}},
                    1: {"mil": 30, "estate": {"adel": 5}},
                    2: {"gold": 80, "adm": -10}},
    "lit_grunwald_legacy": {0: {"dip": 20, "mods": {"manpower": 0.03}, "relations": {"PAP": -20}},
                            1: {"relations": {"PAP": 30, "POL": 20}, "prestige": 10, "dip": 20},
                            2: {"gold": -20, "manpower": 3}},
    "wal_dracula": {1: {"gold": -20, "relations": {"TUR": 30}, "adm": 20},
                    2: {"relations": {"HUN": 50}, "dip": 20}},
    "kaz_volga_trade": {1: {"mods": {"income": 0.03}, "mil": -20},
                        2: {"relations": {"RUS": -30}, "prestige": 10, "mil": 30}},
    "wur_poor_conrad": {1: {"mil": -10, "prestige": 5, "estate": {"adel": 4}},
                        2: {"gold": -30, "prestige": 5, "estate": {"buerger": 5}}},
    "pom_bogislaw": {1: {"prestige": 20, "gold": -20},
                     2: {"relations": {"BRA": 50}, "dip": 30}},
    "tur_istanbul": {0: {"dev_random": 2, "gold": -80},
                     1: {"mods": {"income": 0.03}, "prestige": -5},
                     2: {"prestige": 20, "gold": -30}},
    "pol_warsaw_confederation": {0: {"dip": 30, "dev_random": 1, "relations": {"PAP": -30}},
                                 1: {"prestige": 5, "adm": 40},
                                 2: {"relations": {"PAP": 40}, "estate": {"klerus": 6}}},
    "eco_toll_barons": {2: {"adm": -10, "estate": {"adel": 2}, "prestige": 2}},
    "south_mam_selim": {0: {"mil": 20, "manpower": 2},
                        1: {"mods": {"combat": 0.03}, "gold": -50}},
    "court_palace_envy": {0: {"dip": 25, "prestige": 3}, 2: {"prestige": 10, "dip": -10}},
    "heir_spendthrift_ruler": {1: {"estate": {"adel": -5}, "adm": -10, "ruler_trait": "sparsam"}},
    "rel_peasant_war": {0: {"estate": {"adel": -6}, "adm": 10, "dev_random": 1}},
    "np_ven_cambrai": {0: {"mil": 20, "regs": 3}, 1: {"gold": -80, "dip": 50}},
    # the paid volunteers were the same as the slave market plus prestige: now they also cost more
    "np_ven_galley_slaves": {1: {"gold": -80, "prestige": 10, "mods": {"naval": 0.02}},
                             2: {"mods": {"naval": 0.02}, "dip": -10, "gold": 30}},
    "np_hun_dozsa": {0: {"mil": 30, "mods": {"tax": 0.03, "manpower": -0.03}},
                     1: {"prestige": 10, "mods": {"manpower": 0.03}, "gold": -60},
                     2: {"prestige": -10, "adm": 40}},
    "np_eth_zara_yaqob": {0: {"adm": 60, "prestige": 10, "mods": {"unrest": 0.25}},
                          1: {"dip": 20, "mods": {"unrest": -0.25}, "estate": {"klerus": -5}}},
    "np_eth_succession": {0: {"mods": {"unrest": -0.25}, "ruler": {"adm": -1}},
                          1: {"adm": 60, "mods": {"unrest": 0.25}},
                          2: {"prestige": 10, "dip": 40}},
    "age_porzellan": {1: {"gold": 100}},
    "age_fun_tulpen": {1: {"gold": 70, "prestige": -2}},
    "age_fun_kartoffel": {0: {"dev_random": 1, "prestige": 2}, 1: {"dev_random": 1, "estate": {"adel": -2}, "adm": 10},
                          2: {"prestige": 5, "dip": 20}},
    "pf_por_sugar": {0: {"gold": 80, "prestige": -15, "estate": {"adel": 3}}},
    "pf_hun_mohacs": {1: {"prestige": 10, "manpower": -3, "army_power": 0.15, "mil": 20},
                      2: {"relations": {"HAB": 40}, "dip": 30, "gold": -30, "regs": 2}},
    "gen_newspapers": {2: {"prestige": -5, "adm": 30}},
    "mon_exchange_start": {1: {"gold": 40, "estate": {"buerger": 3}, "prestige": -1}},
    "urb_charter": {1: {"mil": 20, "estate": {"adel": 5}}},
    "era_fortress_cities": {1: {"build": "fortress", "mil": -10}},
    "urb_walls_needed": {0: {"mil": 15, "estate": {"buerger": 3}}},
    "nav_first_loss": {1: {"prestige": -1, "estate": {"adel": -3}, "mil": 30}},
    "war_first_loss": {1: {"prestige": -1, "mil": 15, "army_power": 0.1}},
    "form_rom": {0: {"prestige": 20, "ae": 10}},
    "gds_glass_secret": {1: {"adm": -15, "estate": {"buerger": 4}, "prestige": 3}},
    # Hungary is only inherited by Habsburg when its own nobles chose Ferdinand (hu_mohacs_crown)
    "hab_mohacs": {"trigger": {"year_min": 1520, "alive": "HUN", "at_peace": True,
                               "nation_flag": {"HUN": "hun_habsburg_king"}},
                   # repeatable: a draw while either side is at war used to waste the only chance
                   "once": False,
                   0: ({"inherit": "HUN", "ae": 10}, 90)},
}


def _scale_manpower(effects):
    v = effects.get("manpower")
    if isinstance(v, (int, float)) and abs(v) >= 100:
        effects["manpower"] = (1 if v > 0 else -1) * max(1, int(round(abs(v) / 500.0)))


def apply_events(events):
    by_id = {e["id"]: e for e in events}
    for e in events:
        for o in e["options"]:
            _scale_manpower(o.get("effects", {}))
    for eid, patch in PATCHES.items():
        e = by_id.get(eid)
        if e is None:
            continue
        for k, v in patch.items():
            if isinstance(k, str):
                e[k] = v
                continue
            if isinstance(v, tuple):
                e["options"][k]["effects"] = dict(v[0])
                e["options"][k]["ai"] = v[1]
            else:
                e["options"][k]["effects"] = dict(v)
    return events


def apply():
    """Patch data/events.json and data/missions.json in place."""
    import re
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from events_io import render_event
    path = os.path.join(ROOT, "data/events.json")
    txt = open(path, encoding="utf-8").read().strip()
    chunks = [c for c in re.split(r',\n(?=  \{"id": ")', txt[1:-1].strip("\n")) if c.strip()]
    out = []
    for c in chunks:
        e = json.loads(c)
        before = json.dumps(e, sort_keys=True)
        apply_events([e])
        out.append(c if json.dumps(e, sort_keys=True) == before else render_event(e))
    new = "[\n" + ",\n".join(out) + "\n]\n"
    json.loads(new)
    open(path, "w", encoding="utf-8").write(new)
    # missions: same manpower scale
    mpath = os.path.join(ROOT, "data/missions.json")
    mtxt = open(mpath, encoding="utf-8").read()

    def fix(m):
        v = int(m.group(1))
        return '"manpower": %d' % ((1 if v > 0 else -1) * max(1, int(round(abs(v) / 500.0))))
    mtxt = re.sub(r'"manpower": (-?\d{3,})', fix, mtxt)
    json.loads(mtxt)
    open(mpath, "w", encoding="utf-8").write(mtxt)


if __name__ == "__main__":
    apply()
    print("event balance applied")
