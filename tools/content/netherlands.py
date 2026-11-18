"""The Netherlands (NED): a playable merchant republic of Holland, Zeeland, Utrecht and Friesland.

Adds the nation to data/nations.json (after Burgundy), makes it a member of the Holy Roman Empire and
a trade rival of the Hanse (data/diplomacy.json), adds its national missions ("ned_np_*", before the
rivalry missions in data/missions.json) and national events (block "ned_" in data/events.json).
Government form, special techs, advisors and the company live in tools/content/tech_gov.py; rivalry
missions in tools/content/rival_missions.py; the flag in tools/art/flags.py.
Idempotent: rerunning replaces its own entries.

Run: python3 tools/content/netherlands.py && python3 tools/content/rival_missions.py && python3 tools/content/tech_gov.py
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from events_io import replace_block  # noqa: E402
from rival_missions import render_mission  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

NATION = {"name": "Niederlande", "color": "#e8812a", "emoji": "🌷", "playable": True, "capital": "holland", "aggression": 0.8,
          "bonus": {"trade": 0.15, "naval": 0.1},
          "idea": "Generalstaaten und Amsterdamer Börse: +15 % Handel, +10 % Flottenstärke",
          "rulers": ["Wilhelm", "Moritz", "Johan", "Friedrich Heinrich", "Jan"], "colonial": 1.3}


def m(mid, title, desc, require, reward, after=None):
    d = {"id": mid, "title": title, "desc": desc, "require": require, "reward": reward}
    if after:
        d["after"] = after
    return d


MISSIONS = [
    m("ned_np_herring", "Die Heringsflotte", "Hunderte Buisen fahren auf die Doggerbank. Der Fisch ernährt Holland und baut seine Seeleute aus.",
      {"ships_min": 8}, {"dip": 40, "mods": {"naval": 0.03}}),
    m("ned_np_polder", "Land aus dem Meer", "Deiche, Windmühlen und Polder: jeder Acker in Holland ist dem Wasser abgerungen.",
      {"min_dev": 45}, {"adm": 40, "dev_capital": 1}),
    m("ned_np_bourse", "Die Börse von Amsterdam", "Wechsel, Aktien und Termingeschäfte: die erste Börse der Welt.",
      {"building": {"marketplace": 2}, "trade_pacts_min": 1}, {"gold": 120, "mods": {"trade": 0.03}}, "ned_np_herring"),
    m("ned_np_baltic", "Der Ostseehandel", "Korn aus Danzig und Holz aus Riga: die Mutter aller Handelszweige. Die Hanse muss weichen.",
      {"trade_pacts_min": 2, "ships_min": 15}, {"prestige": 15, "mods": {"trade": 0.04}}, "ned_np_bourse"),
    m("ned_np_flanders", "Die Siebzehn Provinzen", "Flandern und Brabant gehören zu den Niederlanden, nicht zu einem fernen Herzog.",
      {"owns": ["flanders", "brabant"]}, {"mil": 50, "prestige": 15, "mods": {"production": 0.03}}, "ned_np_polder"),
    m("ned_np_new_world", "Nieuw Amsterdam", "Ein Kontor in der Neuen Welt: Pelze vom Hudson, Zucker von der wilden Küste.",
      {"owns_any": ["munsee", "suriname", "guayana", "lenape", "mahican"]}, {"dip": 50, "mods": {"income": 0.03}}, "ned_np_herring"),
    m("ned_np_cape", "Die Kapkolonie", "Eine Station am Kap der Guten Hoffnung versorgt die Schiffe nach Indien.",
      {"owns_any": ["cape", "xhosa"]}, {"gold": 150, "mods": {"naval": 0.03}}, "ned_np_new_world"),
    m("ned_np_golden_age", "Das Goldene Zeitalter", "Rembrandt malt, Spinoza denkt, Grotius schreibt das Recht der Meere.",
      {"min_dev": 90, "monuments_min": 1}, {"prestige": 25, "mods": {"tech_cost": -0.03}}, "ned_np_baltic"),
]


def ev(eid, title, text, trigger, options):
    return {"id": eid, "tag": "NED", "title": title, "text": text, "trigger": trigger, "options": options}


def opt(text, effects, ai=None):
    o = {"text": text, "effects": effects}
    if ai is not None:
        o["ai"] = ai
    return o


EVENTS = [
    ev("ned_hanse_war", "Krieg um die Ostsee",
       "Die Hansestädte sperren den Sund für holländische Schiffe. Unsere Kapitäne verlangen Geleitschutz.",
       {"year_min": 1444, "year_max": 1520, "alive": "HSA"},
       [opt("Kaperbriefe ausstellen und den Sund freikämpfen.", {"mil": 30, "relations": {"HSA": -40}, "mods": {"naval": 0.02}}),
        opt("Mit Dänemark verhandeln: Zoll statt Krieg.", {"gold": -50, "relations": {"DAN": 30}, "mods": {"trade": 0.03}}, 70),
        opt("Den Kontoren der Hanse Rechte in Amsterdam anbieten.", {"relations": {"HSA": 40}, "dip": 20})]),
    ev("ned_flood", "Die Sankt-Elisabeth-Flut",
       "Ein Sturm drückt das Meer über die Deiche. Dutzende Dörfer stehen unter Wasser.",
       {"year_min": 1444, "year_max": 1600},
       [opt("Die Deiche höher und stärker wieder aufbauen.", {"gold": -80, "adm": 20}, 70),
        opt("Das Land dem Meer überlassen, die Bauern umsiedeln.", {"manpower": -3, "prestige": -5}),
        opt("Die Deichgrafen sollen es selbst bezahlen.", {"gold": 20, "mods": {"unrest": 0.25}})]),
    ev("ned_burgundy", "Der Herzog will Steuern",
       "Der Herzog von Burgund verlangt von den Städten Hollands eine Bede für seine Kriege.",
       {"year_min": 1444, "year_max": 1500, "alive": "BUR"},
       [opt("Zahlen, um den Frieden zu wahren.", {"gold": -60, "relations": {"BUR": 30}}),
        opt("Die Generalstaaten verweigern jede Bede.", {"prestige": 10, "relations": {"BUR": -30}, "mil": 20}, 60),
        opt("Gegen Handelsprivilegien in Flandern zahlen.", {"gold": -40, "mods": {"trade": 0.03}})]),
    ev("ned_windmills", "Sägemühlen am Zaan",
       "Ein Müller hat eine Windmühle gebaut, die Baumstämme zersägt. Die Werften könnten dreimal schneller bauen.",
       {"year_min": 1590, "year_max": 1640},
       [opt("Werften und Mühlen fördern.", {"gold": -60, "mods": {"naval": 0.03, "build_cost": -0.03}}, 70),
        opt("Die Zunft der Säger schützen.", {"prestige": 5, "mods": {"unrest": -0.25}}),
        opt("Patente verkaufen.", {"gold": 80})]),
    ev("ned_iconoclasm", "Der Bildersturm",
       "Calvinistische Prediger stürmen Kirchen und zerschlagen die Heiligenbilder. Die Statthalter sind ratlos.",
       {"year_min": 1550, "year_max": 1600},
       [opt("Die Ordnung mit Soldaten wiederherstellen.", {"mil": -20, "mods": {"unrest": -0.5}, "prestige": -5}),
        opt("Gewissensfreiheit: jeder glaubt, was er will.", {"prestige": 10, "dip": 30, "mods": {"production": 0.02}}, 70),
        opt("Die Kirchengüter einziehen.", {"gold": 120, "mods": {"unrest": 0.5}})]),
    ev("ned_tulips", "Das Tulpenfieber",
       "In den Wirtshäusern von Haarlem wechselt eine einzige Tulpenzwiebel für den Preis eines Hauses den Besitzer.",
       {"year_min": 1600, "year_max": 1640, "at_peace": True},
       [opt("Mitspekulieren: die Staatskasse kauft Zwiebeln.", {"gold": 150, "mods": {"income": -0.03}}),
        opt("Die Verträge für ungültig erklären, bevor die Blase platzt.", {"prestige": 10, "adm": 30}, 70),
        opt("Nichts tun, der Markt regelt das.", {"gold": -80, "mods": {"trade": 0.02}})]),
    ev("ned_slave_ships", "Fracht für die Zuckerinseln",
       "Kaufleute aus Vlissingen wollen Gefangene von der Goldküste zu den Zuckerplantagen bringen. Die Prediger sind empört.",
       {"year_min": 1590, "year_max": 1640},
       [opt("Erlauben: der Profit ist zu groß.", {"gold": 120, "prestige": -15}),
        opt("Verbieten: Gewürze und Tuch reichen uns.", {"prestige": 15, "dip": 20}, 70),
        opt("Freie Siedler für die Plantagen anwerben.", {"gold": -50, "mods": {"production": 0.02}})]),
    ev("ned_stadtholder", "Ein Statthalter für die Republik",
       "Die Generalstaaten streiten: braucht die Republik einen Statthalter aus dem Haus Oranien, der Heer und Flotte führt?",
       {"year_min": 1480, "year_max": 1640},
       [opt("Einen Oranier zum Statthalter wählen.", {"mil": 40, "mods": {"combat": 0.02}, "prestige": 5}),
        opt("Die Regenten der Städte regieren allein.", {"adm": 30, "mods": {"trade": 0.02}}, 70),
        opt("Die Entscheidung vertagen.", {"dip": 20})]),
    ev("ned_printers", "Die Drucker von Leiden",
       "Was anderswo verboten ist, wird in Holland gedruckt. Gelehrte aus ganz Europa schicken ihre Manuskripte.",
       {"year_min": 1470, "year_max": 1640},
       [opt("Pressefreiheit: lasst sie drucken.", {"mods": {"tech_cost": -0.03}, "prestige": 5}, 70),
        opt("Eine Universität in Leiden gründen.", {"gold": -80, "adm": 50}),
        opt("Nur fromme Bücher erlauben.", {"mods": {"unrest": -0.25}})]),
    ev("ned_spice_fleet", "Die Retourflotte",
       "Vier Schiffe kehren aus Ostindien zurück, die Laderäume voller Pfeffer und Muskat. Die Aktionäre jubeln.",
       {"year_min": 1500, "year_max": 1640, "ships_min": 10},
       [opt("Die Gewinne neu investieren: mehr Schiffe.", {"ships": 3, "mods": {"trade": 0.02}}, 60),
        opt("Eine Dividende auszahlen.", {"gold": 150}),
        opt("Den Pfefferpreis hochhalten und Ware zurückhalten.", {"gold": 80, "prestige": -5})]),
    ev("ned_refugees", "Flüchtlinge aus dem Süden",
       "Kaufleute, Weber und Juden aus Antwerpen, Lissabon und Sevilla suchen Zuflucht in den Städten Hollands.",
       {"year_min": 1490, "year_max": 1640},
       [opt("Willkommen heißen: Kapital und Können.", {"dev_capital": 1, "mods": {"production": 0.02}}, 70),
        opt("Nur Glaubensbrüder aufnehmen.", {"prestige": 5, "mods": {"unrest": -0.25}}),
        opt("Abweisen.", {"relations": {"SPA": 20}})]),
]

DIPLO_RIVALS = [["NED", "HSA"]]


def _nations():
    path = os.path.join(ROOT, "data/nations.json")
    lines = open(path, encoding="utf-8").read().rstrip("\n").split("\n")
    lines = [l for l in lines if not l.startswith('  "NED": ')]
    line = '  "NED": ' + json.dumps(NATION, ensure_ascii=False) + ","
    i = next(i for i, l in enumerate(lines) if l.startswith('  "BUR": '))
    lines.insert(i + 1, line)
    out = "\n".join(lines) + "\n"
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)


def _diplomacy():
    path = os.path.join(ROOT, "data/diplomacy.json")
    raw = open(path, encoding="utf-8").read()
    d = json.loads(raw)
    if "NED" not in d["hre"]:
        d["hre"].append("NED")
    for r in DIPLO_RIVALS:
        if r not in d["rivals"]:
            d["rivals"].append(r)
    out = json.dumps(d, ensure_ascii=False, indent=2) + "\n"
    open(path, "w", encoding="utf-8").write(out)


def main():
    _nations()
    _diplomacy()
    path = os.path.join(ROOT, "data/missions.json")
    data = json.load(open(path, encoding="utf-8"))
    old = [x for x in data.get("NED", []) if "_np_" not in x["id"]]
    data["NED"] = [x for x in old if "_riv_" not in x["id"]] + MISSIONS + [x for x in old if "_riv_" in x["id"]]
    ids = [x["id"] for v in data.values() for x in v]
    assert len(ids) == len(set(ids))
    out = "{\n" + ",\n".join('  "%s": [\n' % tag + ",\n".join(render_mission(x) for x in ms) + "\n  ]" for tag, ms in data.items()) + "\n}\n"
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)
    replace_block("ned_", EVENTS)
    print("NED: missions", len(MISSIONS), "events", len(EVENTS))


if __name__ == "__main__":
    main()
