"""Events for the 13 goods of the v1.0 goods update (silk, spices, cotton, glass, paper, horses, olive oil,
amber, naval supplies, ivory, dyes, coffee, incense): one story per good, fired for realms that produce it.

Events: generic, id prefix "gds_", placed right before the "gov_" block (events_io.replace_block).
Run: python3 tools/content/goods_events.py (idempotent).

Rules as in eco_events.py: every option is a trade-off, the AI-favoured first option never costs gold,
permanent mods stay at 0.01-0.03 (generic events fire for many realms).
"""
import events_io


def _ai(o):
    if o[1].get("gold", 0) < 0:
        return {"ai": min(o[2] if len(o) > 2 else 10, 10)}
    return {"ai": o[2]} if len(o) > 2 else {}


def ev(id, title, text, image, trigger, options, once=True):
    e = {"id": "gds_" + id}
    if not once:
        e["once"] = False
    e.update({"tag": "*", "title": title, "text": text, "image": image, "trigger": trigger,
              "options": [dict(text=o[0], effects=o[1], **_ai(o)) for o in options]})
    return e


EVENTS = [
    ev("silk_road", "Seidenraupen im Garten des Bischofs",
       "Ein Mönch hat Seidenraupen aus dem Osten eingeschmuggelt. Die Weber wollen ein Monopol, der Bischof will einen Anteil.", "market",
       {"produces": "silk", "year_min": 1450},
       [("Den Webern das Monopol geben.", {"gold": 35, "estate": {"buerger": 4, "klerus": -3}}),
        ("Die Seide als Geschenk an fremde Höfe schicken.", {"dip": 30, "prestige": 2}, 20),
        ("Eine königliche Seidenmanufaktur gründen.", {"adm": -35, "mods": {"production": 0.02}}, 20)]),
    ev("spice_ship", "Ein Schiff voller Pfeffer",
       "Ein Händler hat eine ganze Ladung Pfeffer und Zimt gebracht. Am Hof riecht jedes Gericht nach Reichtum.", "naval",
       {"produces": "spices", "year_min": 1460},
       [("Die Ladung teuer weiterverkaufen.", {"gold": 50, "prestige": -1}),
        ("Ein Festmahl für den Adel.", {"prestige": 4, "estate": {"adel": 5}}),
        ("Gewürzkontore an der Küste einrichten.", {"dip": -30, "mods": {"trade": 0.02}}, 20)]),
    ev("cotton_mills", "Baumwolle für die Städte",
       "Die Baumwollernte war riesig. In den Städten entstehen Spinnstuben, die Landbevölkerung zieht hinterher.", "harvest",
       {"produces": "cotton", "year_min": 1460},
       [("Die Bauern in die Städte ziehen lassen.", {"gold": 30, "estate": {"adel": -3, "buerger": 3}}),
        ("Die Bauern bleiben, wo sie sind.", {"estate": {"adel": 5}, "adm": 10}),
        ("Spinnstuben mit Krongeld fördern.", {"gold": -40, "mods": {"production": 0.02}}, 10)]),
    ev("glass_secret", "Das Geheimnis der Glasbläser",
       "Ein Glasbläser will mit seinem Geheimrezept ins Ausland fliehen. Fremde Fürsten bieten ihm ein Vermögen.", "artist",
       {"produces": "glass", "year_min": 1450},
       [("Er bleibt. Notfalls mit Gewalt.", {"prestige": -2, "mods": {"production": 0.01}}),
        ("Ihn mit einem Adelstitel halten.", {"adm": -25, "estate": {"buerger": 4}, "prestige": 2}, 25),
        ("Das Rezept an einen Verbündeten verkaufen.", {"gold": 60, "dip": 15, "estate": {"buerger": -6}}, 15)]),
    ev("paper_mill", "Eine Papiermühle am Fluss",
       "Die neue Papiermühle liefert so viel Papier, dass die Schreiber nicht mehr hinterherkommen. Die Kanzlei will mehr Beamte.", "printing",
       {"produces": "paper", "year_min": 1460},
       [("Mehr Schreiber einstellen.", {"adm": 30, "estate": {"klerus": -2}}),
        ("Das Papier an die Universitäten geben.", {"prestige": 3, "estate": {"klerus": 3}}, 20),
        ("Flugblätter gegen die Feinde drucken.", {"dip": 20, "prestige": 1}, 15)]),
    ev("horse_fair", "Der große Pferdemarkt",
       "Auf dem Pferdemarkt drängen sich Händler aus drei Ländern. Die Reiterei will die besten Tiere, die Bauern die billigsten.", "steppe",
       {"produces": "horses", "year_min": 1450},
       [("Die Armee kauft zuerst.", {"mil": 30, "estate": {"buerger": -2}}),
        ("Freier Handel für alle.", {"gold": 35, "estate": {"buerger": 3}}),
        ("Ein königliches Gestüt gründen.", {"mil": -30, "mods": {"combat": 0.02}}, 20)]),
    ev("olive_harvest", "Ein Jahrhundertjahr für Oliven",
       "Die Olivenbäume tragen wie nie. Das Öl reicht für die Lampen der Kirchen, die Küchen und die Feldlager.", "harvest",
       {"produces": "olive_oil", "year_min": 1450},
       [("Öl für die Feldlager einlagern.", {"mil": 20, "mods": {"army_power_regen": 0.02}}),
        ("Öl für die Kirchen stiften.", {"estate": {"klerus": 6}, "prestige": 2}),
        ("Alles verkaufen.", {"gold": 45, "estate": {"adel": -2}})]),
    ev("amber_relic", "Ein Insekt im Bernstein",
       "Fischer haben einen Bernstein mit einem eingeschlossenen Käfer gefunden. Der Klerus nennt es ein Wunder, die Gelehrten ein Rätsel.", "alchemy",
       {"produces": "amber", "year_min": 1450},
       [("Ein Wunder! Ab in die Kathedrale.", {"estate": {"klerus": 6}, "prestige": 2}),
        ("Die Gelehrten sollen es untersuchen.", {"adm": 25, "estate": {"klerus": -4}}),
        ("An einen reichen Sammler verkaufen.", {"gold": 55, "prestige": -2})]),
    ev("tar_pits", "Teer, Hanf und Masten",
       "Die Wälder liefern mehr Teer, Hanf und Mastholz, als die eigenen Werften brauchen. Fremde Admiräle klopfen an.", "naval",
       {"produces": "naval_supplies", "year_min": 1460},
       [("Nur für die eigene Flotte.", {"mil": 20, "mods": {"naval": 0.02}}),
        ("An jeden verkaufen, der zahlt.", {"gold": 50, "prestige": -1}),
        ("Nur an Verbündete liefern.", {"dip": 30, "gold": 15}, 20)]),
    ev("ivory_tusks", "Elfenbein vom Fluss",
       "Händler bringen Elfenbein aus dem Landesinneren. Die Schnitzer jubeln, aber die Jäger dringen immer tiefer in fremdes Land vor.", "exploration",
       {"produces": "ivory", "year_min": 1460},
       [("Die Jagd ausweiten.", {"gold": 45, "prestige": -2}),
        ("Die Jagd begrenzen, die Stämme schonen.", {"prestige": 4, "dip": 15}),
        ("Eine Schnitzerzunft gründen.", {"adm": -25, "mods": {"production": 0.02}}, 20)]),
    ev("purple_dye", "Purpur für den Hof",
       "Die Färber haben ein Rot gefunden, das so leuchtet wie der Purpur der alten Kaiser. Jeder will es tragen.", "court",
       {"produces": "dyes", "year_min": 1450},
       [("Nur der Hof darf es tragen.", {"prestige": 5, "estate": {"buerger": -3}}),
        ("Die Bürger dürfen es kaufen.", {"gold": 40, "estate": {"buerger": 4, "adel": -3}}),
        ("Die Färber zu einer Gilde vereinen.", {"adm": -30, "mods": {"production": 0.02}}, 20)]),
    ev("coffee_house", "Das erste Kaffeehaus",
       "In der Hauptstadt hat ein Kaffeehaus eröffnet. Gelehrte, Händler und Spione diskutieren dort bis tief in die Nacht.", "tavern",
       {"produces": "coffee", "year_min": 1520},
       [("Wunderbar, mehr davon!", {"adm": 20, "dip": 20, "estate": {"klerus": -3}}),
        ("Spitzel hineinsetzen.", {"dip": 30, "prestige": -1}, 20),
        ("Verbieten, das ist Teufelszeug.", {"estate": {"klerus": 6}, "adm": -10}, 10)]),
    ev("incense_route", "Weihrauch für die Kirchen",
       "Die Weihrauchhändler verlangen Geleitschutz durch die Wüste. Ohne ihn bleiben die Altäre bald kalt.", "procession",
       {"produces": "incense", "year_min": 1450},
       [("Geleitschutz stellen.", {"mil": -20, "estate": {"klerus": 5}, "mods": {"trade": 0.01}}),
        ("Die Händler zahlen selbst.", {"gold": 30, "estate": {"klerus": -3}}),
        ("Weihrauch nur für die eigenen Kirchen.", {"prestige": 3, "estate": {"klerus": 3}})]),
    # --- funny side stories, player only (they must not dilute the AI event pool)
    ev("parrot", "Ein Papagei am Hof",
       "Ein Händler schenkt dem Herrscher einen Papagei. Er hat schon drei Wörter gelernt, leider alle aus der Wachstube.", "court",
       {"is_player": True, "year_min": 1460},
       [("Er bleibt. Der Hof soll lachen.", {"prestige": 1, "estate": {"adel": 2}}),
        ("Dem Gesandten Venedigs schenken.", {"dip": 25, "prestige": -1}),
        ("Dem Beichtvater übergeben.", {"estate": {"klerus": 4}, "prestige": -1})]),
    ev("pepper_tax", "Die Pfeffersteuer",
       "Ein Kämmerer schlägt vor, Pfeffer zu besteuern. Die Köche drohen mit Streik, die Ärzte loben den Plan.", "market",
       {"is_player": True, "year_min": 1470},
       [("Pfeffer wird besteuert.", {"gold": 35, "estate": {"buerger": -4}}),
        ("Wer würde so etwas tun?", {"estate": {"buerger": 3}, "prestige": 1}),
        ("Nur Salz besteuern, wie immer.", {"gold": 15, "adm": 10})]),
]


if __name__ == "__main__":
    data = events_io.replace_block("gds_", EVENTS)
    print("events.json: %d events (%d gds_)" % (len(data), len(EVENTS)))
