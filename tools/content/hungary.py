"""Hungary as a strong, independent kingdom (2026-11-17, Linus: "Ungarn soll eine starke unabhängige Nation sein,
nur 50/50 Chance auf Annexion, als Spieler ein Powerhouse, viel historischer Flavour").

Events "hu_*" (tag HUN, placed before the gov_ block via events_io.replace_block) and missions "hun_hu_*"
(appended to HUN in data/missions.json, idempotent).

The key event is hu_mohacs_crown: after the king's death the estates pick Zápolya (independent), Ferdinand of
Habsburg (sets flag hun_habsburg_king, the only way Habsburg's hab_mohacs inheritance can fire) or a regency.
AI weights there set the share of games in which Habsburg ends up inheriting Hungary (target ~50 % of games
counting conquests; measured with tools/nation_probe.gd).

Run: python3 tools/content/hungary.py
"""
import json
import os

import events_io

ROOT = events_io.ROOT


def ev(eid, title, text, image, trigger, options, **kw):
    e = {"id": "hu_" + eid, "tag": "HUN", "title": title, "text": text, "image": image, "trigger": trigger,
         "options": [dict(text=o[0], effects=o[1], **({"ai": o[2]} if len(o) > 2 else {})) for o in options]}
    e.update(kw)
    return e


EVENTS = [
    ev("mohacs_crown", "Zwei Könige für eine Krone",
       "Der junge König ist ohne Erben gestorben. Der Kleinadel ruft auf dem Rákosfeld Johann Zápolya aus, "
       "die Magnaten in Pressburg wollen Ferdinand von Habsburg, den Schwager des Toten. Beide lassen sich "
       "krönen, wenn wir nicht jetzt entscheiden.",
       "coronation", {"year_min": 1516, "year_max": 1545, "alive": "HAB"},
       [("Zápolya: Ein Ungar soll König von Ungarn sein.",
         {"prestige": 10, "estate": {"adel": 6}, "relations": {"HAB": -40}, "flag": "hun_national_king"}, 52),
        ("Ferdinand: Habsburg schützt uns vor dem Sultan.",
         {"flag": "hun_habsburg_king", "relations": {"HAB": 50}, "mil": 60, "estate": {"adel": -6}, "prestige": -10}, 45),
        ("Keinen König: Der Palatin regiert mit dem Reichstag.",
         {"adm": 60, "estate": {"adel": 8}, "prestige": -10}, 3)]),
    ev("varna", "Nach Warna",
       "König Wladislaw ist bei Warna gegen die Osmanen gefallen. Der Thronerbe ist ein Kind in Wien, im Gewahrsam "
       "des Kaisers. Der Reichstag muss einen Reichsverweser wählen.",
       "mourning", {"year_max": 1447},
       [("Johann Hunyadi wird Reichsverweser.", {"mil": 50, "estate": {"adel": -3}, "flag": "hun_hunyadi_regent"}, 60),
        ("Ein Rat der Magnaten regiert.", {"adm": 30, "estate": {"adel": 6}}),
        ("Das Kind aus Wien zurückfordern.", {"dip": 30, "relations": {"HAB": 30}, "prestige": 5})]),
    ev("noon_bell", "Das Mittagsläuten",
       "Belgrad hat gehalten. Der Papst befiehlt, dass in der ganzen Christenheit jeden Mittag die Glocken für den "
       "Sieg an der Donau läuten.",
       "procession", {"year_min": 1450, "year_max": 1475, "flag": "hun_hunyadi_regent"},
       [("Den Sieg in ganz Europa feiern.", {"prestige": 20, "relations": {"PAP": 30}}, 50),
        ("Gesandte an alle Höfe: Wir brauchen Geld für die Grenze.", {"gold": 60, "dip": 20}),
        ("Die Veteranen mit Land belohnen.", {"mods": {"manpower": 0.03}, "estate": {"adel": -3}})]),
    ev("szekely", "Die Székler an der Grenze",
       "Die Székler in den Ostkarpaten sind freie Grenzkrieger. Sie zahlen keine Steuern, dafür zieht jeder Mann "
       "in den Krieg. Die Kammer will sie endlich besteuern.",
       "border", {"year_min": 1450, "year_max": 1600, "owns": ["transylvania"]},
       [("Ihre Freiheiten bestätigen.", {"mods": {"manpower": 0.04}, "gold": -20}, 60),
        ("Ochsensteuer wie alle anderen.", {"gold": 90, "estate": {"adel": -4}}),
        ("Sie als Grenzer ausbilden lassen.", {"mil": 40, "regs": 1})]),
    ev("saxon_towns", "Die sieben Burgen",
       "Die Siebenbürger Sachsen halten Kronstadt, Hermannstadt und Bistritz. Ihr Handel reicht bis Venedig, "
       "und sie wollen ihre alten Rechte vom König bestätigt sehen.",
       "city", {"year_min": 1450, "year_max": 1620, "owns": ["transylvania"]},
       [("Den Goldenen Freibrief erneuern.", {"estate": {"buerger": 6}, "mods": {"trade": 0.02}, "gold": -30}, 60),
        ("Eine Sondersteuer auf die Städte.", {"gold": 100, "estate": {"buerger": -6}}),
        ("Die Städte sollen die Pässe befestigen.", {"mil": 30, "manpower": 1, "estate": {"buerger": -2}})]),
    ev("hussars", "Die ersten Husaren",
       "Serbische Flüchtlinge kämpfen als leichte Reiter an der Südgrenze. Man nennt sie Husaren, und sie sind "
       "schneller als jeder Akıncı.",
       "camp", {"year_min": 1458, "year_max": 1560},
       [("Husarenbanner für das ganze Heer.", {"gold": -50, "mods": {"army_power_regen": 0.1}}, 50),
        ("Die Flüchtlinge an der Grenze ansiedeln.", {"manpower": 2, "relations": {"SER": 30}, "adm": 20}),
        ("Sie als Söldner bezahlen, solange Krieg ist.", {"mil": 40, "regs": 2, "gold": -20})]),
    ev("kremnitz", "Die Dukaten von Kremnitz",
       "Die Bergstädte Oberungarns fördern mehr Gold und Silber als jedes andere Land Europas. Die Münze in "
       "Kremnitz prägt Dukaten, die man bis Florenz nimmt.",
       "mine", {"year_min": 1450, "year_max": 1600, "owns": ["kassa"]},
       [("Die Münze bleibt in der Hand der Krone.", {"gold": 120, "estate": {"buerger": -3}}, 50),
        ("Die Gruben an Thurzó und die Fugger verpachten.", {"mods": {"income": 0.03}, "gold": -30}),
        ("Den Bergleuten Rechte geben.", {"estate": {"buerger": 6}, "adm": 30, "dev_random": 1, "gold": -40})]),
    ev("tripartitum", "Das Tripartitum",
       "Der Jurist István Werbőczy hat das Gewohnheitsrecht des Königreichs in drei Bücher gefasst. Es macht "
       "jeden Adligen gleich und bindet die Bauern für immer an die Scholle.",
       "diet", {"year_min": 1505, "year_max": 1535},
       [("Das Gesetzbuch annehmen.", {"adm": 50, "estate": {"adel": 8, "buerger": -4}}, 60),
        ("Annehmen, aber die Leibeigenschaft streichen.", {"adm": 30, "dev_random": 1, "estate": {"adel": -6}}),
        ("Die Krone setzt eigenes Recht.", {"prestige": 10, "estate": {"adel": -4}, "dip": 30})]),
    ev("eger", "Die Sterne von Eger",
       "Ein Pascha belagert die Burg Eger mit zehnmal so vielen Männern. Hauptmann Dobó und die Frauen der Stadt "
       "gießen heißes Pech von den Mauern.",
       "siege", {"year_min": 1540, "year_max": 1580, "alive": "TUR", "at_war": True},
       [("Halten bis zum letzten Stein!", {"prestige": 20, "manpower": -2, "army_power": 0.1}, 50),
        ("Ein Entsatzheer schicken.", {"gold": -50, "regs": 3}),
        ("Die Burg gegen freien Abzug übergeben.", {"prestige": -10, "manpower": 2, "dip": 30})]),
    ev("szigetvar", "Der Ausfall von Szigetvár",
       "Nikolaus Zrínyi hält Szigetvár, bis der alte Sultan im Lager stirbt. Dann legt er seine besten Kleider "
       "an und reitet mit den letzten dreihundert Männern hinaus.",
       "battle", {"year_min": 1555, "year_max": 1590, "alive": "TUR"},
       [("Sein Name soll nie vergessen werden.", {"prestige": 25, "mil": 20}, 50),
        ("Die Grenzburgen neu befestigen.", {"gold": -60, "mods": {"manpower": 0.03}}),
        ("Den Zrínyis Kroatien als Lehen geben.", {"estate": {"adel": 8}, "mil": 40, "adm": -10})]),
    ev("reformation", "Die Reformation in Debrecen",
       "In Debrecen predigen sie Calvin, in den Bergstädten Luther. Die Bischöfe verlangen Härte, die Magnaten "
       "wollen ihre Prediger behalten.",
       "reformation", {"year_min": 1540, "year_max": 1610},
       [("Religionsfreiheit, wie in Siebenbürgen.", {"estate": {"adel": 5, "klerus": -6}, "dip": 30, "mods": {"religious_unrest": -0.2}}, 50),
        ("Die alte Kirche stärken.", {"estate": {"klerus": 8, "adel": -4}, "relations": {"PAP": 30}, "prestige": 5}),
        ("Klostergüter einziehen.", {"gold": 120, "estate": {"klerus": -8}})]),
    ev("bocskai", "Die Heiducken",
       "Viehtreiber und entlaufene Soldaten, die Heiducken, haben sich Stephan Bocskai angeschlossen. Sie wollen "
       "Land und Freiheit statt Sold.",
       "revolt", {"year_min": 1595, "year_max": 1630},
       [("Sie in eigenen Städten ansiedeln.", {"mods": {"manpower": 0.04}, "estate": {"adel": -4}}, 60),
        ("In die Armee übernehmen.", {"regs": 3, "gold": -40}),
        ("Zerschlagen.", {"mil": -30, "estate": {"adel": 6}, "prestige": 10})]),
    ev("pazmany", "Der Kardinal Pázmány",
       "Péter Pázmány predigt auf Ungarisch und gründet in Tyrnau eine Universität. Er will die Magnaten zurück "
       "zur alten Kirche holen, mit Büchern statt Soldaten.",
       "scholar", {"year_min": 1600, "year_max": 1644},
       [("Die Universität Tyrnau fördern.", {"gold": -60, "mods": {"tech_cost": -0.03}}, 50),
        ("Ungarische Bücher drucken lassen.", {"prestige": 15, "dip": 30}),
        ("Den Kardinal in den Rat holen.", {"adm": 50, "estate": {"klerus": 5}})]),
    # player-only: a powerhouse needs a few strong moments of its own
    ev("corvin_court", "Ein Hof wie in Florenz",
       "Italienische Baumeister, Humanisten und Buchmaler kommen nach Buda. Der König will einen Renaissancehof, "
       "der Wien und Prag in den Schatten stellt.",
       "artist", {"year_min": 1458, "year_max": 1500, "is_player": True},
       [("Visegrád und Buda prachtvoll ausbauen.", {"gold": -80, "dev_capital": 2, "prestige": 15}),
        ("Gelehrte an den Hof, Schulen ins Land.", {"adm": 60, "mods": {"tech_cost": -0.03}}),
        ("Alles Geld für die Schwarze Armee.", {"regs": 4, "mods": {"army_power": 0.05}, "mil": 30})]),
    ev("black_army_glory", "Die Schwarze Armee marschiert",
       "Dreißigtausend Söldner in schwarzen Rüstungen, Kanonen, Wagenburgen, Husaren: Kein Heer Europas ist "
       "stärker. Die Frage ist nur, wohin es zieht.",
       "camp", {"year_min": 1465, "year_max": 1520, "is_player": True, "regs": 12},
       [("Gegen den Sultan, die Donau hinab.", {"mods": {"combat": 0.04}, "relations": {"TUR": -40, "PAP": 40}, "prestige": 10}),
        ("Gegen den Kaiser: Wien soll ungarisch werden.", {"claim": ["wien"], "mil": 60, "relations": {"HAB": -30}}),
        ("Gegen Böhmen: die Wenzelskrone.", {"claim": ["moravia", "silesia"], "mil": 40, "relations": {"BOH": -30}})]),
    ev("golden_bull", "Die Goldene Bulle von 1222",
       "Die Stände berufen sich auf das Widerstandsrecht der Goldenen Bulle. Der König soll ihre Freiheiten "
       "beschwören oder um sein Recht kämpfen.",
       "diet", {"year_min": 1480, "year_max": 1640, "is_player": True, "min_dev": 90},
       [("Die Freiheiten beschwören.", {"estate": {"adel": 10}, "mods": {"manpower": 0.05}, "adm": -20}),
        ("Eine starke Krone: Steuern ohne Reichstag.", {"mods": {"income": 0.05}, "estate": {"adel": -8}}),
        ("Ein Kompromiss: Die Stände verwalten die Grenze.", {"mil": 60, "adm": 40, "estate": {"adel": 3}})]),
]


def m(mid, title, desc, require, reward, after=None):
    d = {"id": "hun_hu_" + mid}
    if after:
        d["after"] = "hun_hu_" + after
    d.update({"title": title, "desc": desc, "require": require, "reward": reward})
    return d


MISSIONS = [
    m("holy_crown", "Die Heilige Krone heimholen",
      "Kaiser Friedrich hält die Stephanskrone fest. Ohne sie ist jeder König Ungarns nur halb gekrönt.",
      {"year_min": 1455, "min_dev": 70}, {"prestige": 25, "dip": 50, "estate": {"adel": 5}}),
    m("black_army_full", "Das stehende Heer", "Ein Heer, das auch im Frieden bezahlt wird: der Schrecken der Nachbarn.",
      {"regs": 25, "tech": {"mil": 8}}, {"mods": {"combat": 0.03, "army_power": 0.1}}, after="holy_crown"),
    m("carpathians", "Der Karpatenbogen", "Siebenbürgen, die Walachei und die Moldau als Schild gegen den Osten.",
      {"owns": ["transylvania"], "owns_any": ["wallachia", "moldavia"]}, {"mods": {"manpower": 0.05}, "mil": 40}),
    m("adriatic", "Ein Hafen an der Adria", "Dalmatien gehörte einst zur Krone Kroatiens. Venedig hat es nur geliehen.",
      {"owns_any": ["dalmatia"]}, {"mods": {"trade": 0.04}, "prestige": 10}, after="carpathians"),
    m("three_crowns", "Drei Kronen", "Ungarn, Böhmen und Österreich unter einem König, wie unter Matthias.",
      {"owns_any": ["wien"], "min_dev": 150}, {"prestige": 30, "mods": {"income": 0.05}}, after="black_army_full"),
    m("bulwark", "Das Bollwerk der Christenheit", "Belgrad, Bosnien und Serbien in ungarischer Hand: die Donau ist sicher.",
      {"owns": ["serbia", "bosnia"], "year_min": 1480}, {"mods": {"combat": 0.03}, "prestige": 20, "relations": {"PAP": 40}}),
    m("great_kingdom", "Das Königreich Ungarn", "Ein Reich, das mit Frankreich und dem Sultan auf Augenhöhe spricht.",
      {"min_dev": 220}, {"mods": {"income": 0.05, "develop_cost": -0.1}, "prestige": 25}, after="three_crowns"),
]


def render_mission(mm):
    head = {k: mm[k] for k in ("id", "after", "title", "desc") if k in mm}
    return ("    " + json.dumps(head, ensure_ascii=False)[:-1] + ",\n"
            + '     "require": ' + json.dumps(mm["require"], ensure_ascii=False)
            + ', "reward": ' + json.dumps(mm["reward"], ensure_ascii=False) + "}")


def write_missions(tag, prefix, missions):
    path = os.path.join(ROOT, "data/missions.json")
    data = json.load(open(path, encoding="utf-8"))
    data[tag] = [x for x in data.get(tag, []) if not x["id"].startswith(prefix)] + missions
    out = "{\n" + ",\n".join(
        '  "%s": [\n' % t + ",\n".join(render_mission(x) for x in ms) + "\n  ]" for t, ms in data.items()) + "\n}\n"
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)


def main():
    data = events_io.replace_block("hu_", EVENTS)
    write_missions("HUN", "hun_hu_", MISSIONS)
    print("events.json: %d events (%d hu_), HUN missions +%d" % (len(data), len(EVENTS), len(MISSIONS)))


if __name__ == "__main__":
    main()
