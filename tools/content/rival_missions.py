"""Rivalry missions: two per playable nation ("<tag>_riv_declare" -> "<tag>_riv_power").

Written into data/missions.json after the existing missions of each tag (idempotent: earlier _riv_ missions
are replaced). Conditions come from Game.check_conditions (rivals_min, power_proj_min, rival_at_war),
rewards from Game.apply_effects. Rewards stay small so the AI (which auto-completes ready missions) is not
pushed: mana + prestige, and a 2-3 % permanent mod on the second mission only.

Run: python3 tools/content/rival_missions.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# tag: (noun for "the realm", rival flavour, second-mission mod)
STYLE = {
    "FRA": ("die Krone Frankreichs", "Englands Könige und die Herzöge im Osten", {"combat": 0.02}),
    "ENG": ("England", "die Franzosen und die Schotten", {"naval": 0.03}),
    "SPA": ("Kastilien", "Portugal, Aragon und die Mauren", {"combat": 0.02}),
    "BOH": ("Böhmen", "die Habsburger und die ungarischen Könige", {"adm": 1}),
    "HAB": ("das Haus Habsburg", "Böhmen, Ungarn und die Eidgenossen", {"ae_decay": 0.05}),
    "RUS": ("Moskau", "Litauen, Nowgorod und die Tataren", {"manpower": 0.05}),
    "NAP": ("Neapel", "der Papst und die Aragonesen", {"trade": 0.03}),
    "TUR": ("das Haus Osman", "Byzanz, Venedig und die Mamluken", {"siege": 0.05}),
    "POL": ("Polen", "der Deutsche Orden und Moskau", {"manpower": 0.05}),
    "BUR": ("Burgund", "Frankreich und die Reichsfürsten", {"trade": 0.03}),
    "VEN": ("die Serenissima", "Genua und die Osmanen", {"naval": 0.03}),
    "MLO": ("Mailand", "Venedig und Florenz", {"production": 0.03}),
    "PAP": ("der Kirchenstaat", "Neapel und die Fürsten der Romagna", {"adm": 1}),
    "TUS": ("Florenz", "Siena, Mailand und Venedig", {"trade": 0.03}),
    "DAN": ("Dänemark", "Schweden, die Hanse und Holstein", {"naval": 0.03}),
    "SCO": ("Schottland", "die Engländer", {"combat": 0.02}),
    "POR": ("Portugal", "Kastilien und die Mauren", {"naval": 0.03}),
    "HUN": ("Ungarn", "die Osmanen und die Habsburger", {"combat": 0.02}),
    "LIT": ("Litauen", "Moskau und der Deutsche Orden", {"manpower": 0.05}),
    "SAV": ("Savoyen", "Mailand und die Franzosen", {"adm": 1}),
    "GEN": ("Genua", "Venedig und Mailand", {"trade": 0.03}),
    "LIV": ("der Orden", "Nowgorod, Litauen und Dänemark", {"combat": 0.02}),
    "MAM": ("Kairo", "die Osmanen und die Beduinenfürsten", {"trade": 0.03}),
    "MOR": ("Fes", "Kastilien, Portugal und die Berber der Wüste", {"combat": 0.02}),
    "QAR": ("die Schwarzen Hammel", "die Weißen Hammel, die Timuriden und die Osmanen", {"manpower": 0.05}),
    "ETH": ("der Kaiser von Äthiopien", "Adal, die Osmanen und die Herren des Roten Meeres", {"combat": 0.02}),
}


def missions(tag):
    realm, foes, mod = STYLE[tag]
    t = tag.lower()
    return [
        {"id": "%s_riv_declare" % t, "title": "Ein würdiger Rivale",
         "desc": "Jede Macht braucht einen Gegner, an dem sie sich misst. Für %s sind das %s. Erkläre einen Rivalen (Diplomatie)." % (realm, foes),
         "require": {"rivals_min": 1},
         "reward": {"mil": 25, "dip": 25, "prestige": 5}},
        {"id": "%s_riv_power" % t, "after": "%s_riv_declare" % t, "title": "Die Macht gezeigt",
         "desc": "Schlachten gegen den Rivalen und eroberte Provinzen bauen Machtprojektion auf. Zeige ganz Europa, dass %s gegen %s besteht." % (realm, foes),
         "require": {"power_proj_min": 50},
         "reward": {"prestige": 15, "mil": 50, "mods": mod}},
    ]


def render_mission(m):
    head = {k: m[k] for k in ("id", "after", "title", "desc") if k in m}
    s = "    " + json.dumps(head, ensure_ascii=False)[:-1] + ",\n"
    return s + '     "require": ' + json.dumps(m["require"], ensure_ascii=False) + ', "reward": ' + json.dumps(m["reward"], ensure_ascii=False) + "}"


def main():
    path = os.path.join(ROOT, "data/missions.json")
    data = json.load(open(path, encoding="utf-8"))
    for tag in STYLE:
        assert tag in data, tag
        data[tag] = [m for m in data[tag] if "_riv_" not in m["id"]] + missions(tag)
    out = "{\n" + ",\n".join(
        '  "%s": [\n' % tag + ",\n".join(render_mission(m) for m in ms) + "\n  ]" for tag, ms in data.items()) + "\n}\n"
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)
    print("missions", {t: len(v) for t, v in data.items()})


if __name__ == "__main__":
    main()
