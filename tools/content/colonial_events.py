"""New World events ("col_" block, written into data/events.json before the gov_ block).

Conditions (Game.check_conditions): colonies_min (New World provinces owned), colonizing (a colony is growing).
col_new_world and col_first_colony are manual: Colonial fires them once per realm, after its first
successful expedition and when its first colony has grown.

Run: python3 tools/content/colonial_events.py (idempotent, see events_io.py).
Rules as in the other generators: first option gold-free and no war, gold-costing options AI weight <= 10,
repeatable random events player-only.
"""
import events_io
from ctx_events import ev

COL = [
    ev("col_new_world", "Eine neue Welt",
       "Die Expedition ist zurück, mit fremden Pflanzen, bunten Federn und Karten einer Küste, die auf keiner alten Karte steht. Die Gelehrten streiten, ob es Indien ist. Die Kaufleute fragen nur, was es dort zu holen gibt.", "exploration",
       {},
       [("Die Entdecker ehren.", {"prestige": 5}),
        ("Die Karten geheim halten.", {"dip": 30}),
        ("Kaufleute für die nächste Fahrt gewinnen.", {"gold": 40})], manual=True),
    ev("col_first_colony", "Die erste Kolonie",
       "Aus ein paar Hütten am fremden Strand ist eine Stadt geworden: mit Kirche, Hafen und eigenem Markt. Siedler schreiben nach Hause und locken Verwandte nach.", "city",
       {},
       [("Einen Statthalter ernennen.", {"adm": 25}),
        ("Die Siedler mit Privilegien belohnen.", {"prestige": 3, "estate": {"buerger": 3}}),
        ("Missionare hinüberschicken.", {"estate": {"klerus": 4}, "dip": 10})], manual=True),
    ev("col_settlers", "Siedler drängen an die Häfen",
       "In den Hafenstädten warten Bauernsöhne, Handwerker und Glücksritter auf ein Schiff in die Neue Welt.", "naval",
       {"colonizing": True, "is_player": True},
       [("Sie fahren lassen.", {"adm": 10}),
        ("Freie Überfahrt für Handwerker.", {"gold": -20, "dev_random": 1}, 8),
        ("Nur Soldaten an Bord nehmen.", {"manpower": -300, "mil": 15})], once=False),
    ev("col_natives_trade", "Handel mit den Ureinwohnern",
       "Ureinwohner aus dem Hinterland bringen Pelze und Mais an die Palisaden und wollen Messer, Kessel und Glasperlen dafür.", "market",
       {"colonizing": True, "is_player": True},
       [("Fair tauschen.", {"dip": 15}),
        ("Die Preise drücken.", {"gold": 25, "prestige": -1}),
        ("Geschenke machen und Bündnisse schließen.", {"gold": -15, "prestige": 2}, 8)], once=False),
    ev("col_treasure_fleet", "Die Silberflotte",
       "Schwer beladen kehrt die Flotte aus der Neuen Welt zurück. Die Kaufleute jubeln, die Preise in der Heimat steigen.", "naval",
       {"colonies_min": 3, "year_min": 1500, "is_player": True},
       [("In die Staatskasse damit.", {"gold": 60}),
        ("Die Schulden der Krone tilgen.", {"adm": 20, "prestige": 1}),
        ("Neue Schiffe bauen lassen.", {"ships": 2})], once=False),
    ev("col_smugglers", "Schmuggler in der Karibik",
       "Fremde Kapitäne verkaufen in unseren Kolonien Waren am Zoll vorbei. Die Siedler kaufen gern, die Zöllner schäumen.", "tavern",
       {"colonies_min": 2, "is_player": True},
       [("Ein Auge zudrücken.", {"dip": 10}),
        ("Die Küste bewachen lassen.", {"gold": -20, "prestige": 2}, 8),
        ("Die Schmuggler anheuern.", {"mil": 15, "prestige": -1})], once=False),
    ev("col_new_crops", "Pflanzen aus der Neuen Welt",
       "Kartoffeln, Mais und Bohnen aus den Kolonien wachsen auch in der Heimat. Die Bauern sind misstrauisch, die Gelehrten begeistert.", "harvest",
       {"colonies_min": 2, "year_min": 1520},
       [("Die Gelehrten forschen lassen.", {"adm": 20}),
        ("Den Anbau befehlen.", {"dev_random": 1}),
        ("Die Bauern selbst entscheiden lassen.", {"estate": {"adel": 2}, "prestige": 1})]),
    ev("col_rivals_at_sea", "Kaperfahrer",
       "Kaperschiffe einer fremden Krone lauern unseren Handelsschiffen vor den Kolonien auf. Die Kaufleute verlangen Geleitschutz.", "naval",
       {"colonies_min": 2, "is_player": True, "year_min": 1530},
       [("Geleitzüge einrichten.", {"mil": 10}),
        ("Eigene Kaperbriefe ausstellen.", {"gold": 30, "prestige": -1}),
        ("Kriegsschiffe bauen.", {"gold": -30, "ships": 2}, 8)], once=False),
]

if __name__ == "__main__":
    data = events_io.replace_block("col_", COL)
    print(len(COL), "col_ events,", len(data), "events total")
