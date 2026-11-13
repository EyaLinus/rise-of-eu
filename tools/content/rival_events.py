"""Rivalry events ("riv_" block, written into data/events.json before the gov_ block).

Conditions (Game.check_conditions): rivals_min, rivaled, power_proj_min, rival_at_war.
Effects (Game.apply_effects): power_proj, rival_rel. riv_power_shown is manual: Game.add_power_proj fires it
once when power projection first reaches half of pp_max.

Run: python3 tools/content/rival_events.py (idempotent, see events_io.py).
Rules as in the other generators: first option gold-free and no war, gold-costing options AI weight <= 10,
mods <= 0.03, repeatable random events player-only (they would only dilute the AI's event pool).
"""
import events_io
from ctx_events import check, ev

RIV = [
    ev("riv_first_rival", "Der erklärte Rivale",
       "Herolde verkünden es auf den Marktplätzen: Ein Nachbar ist von nun an unser Rivale. Der Adel schärft die Klingen, die Diplomaten ihre Zungen.", "diet",
       {"rivals_min": 1},
       [("Die Grenzgarnisonen verstärken.", {"mil": 15}),
        ("Gesandte an seine Nachbarn schicken.", {"dip": 15}),
        ("Ein Fest zur Einigung des Hofes.", {"gold": -25, "prestige": 3}, 8)]),
    ev("riv_rivaled", "Spott am fremden Hof",
       "An einem fremden Hof wird dein Name mit Hohn genannt: Du bist dort zum Rivalen erklärt. Die eigenen Gesandten fragen, wie du antworten willst.", "court",
       {"rivaled": True},
       [("Mit Würde schweigen.", {"prestige": 2}),
        ("Die eigenen Spione aussenden.", {"dip": 10, "mil": 10}),
        ("Die Truppen an der Grenze zeigen.", {"mil": 20, "prestige": -1})]),
    ev("riv_power_shown", "Die Macht gezeigt",
       "Siege über den Rivalen haben es allen gezeigt: Mit uns ist zu rechnen. Fremde Fürsten suchen unsere Gunst, die Generäle fordern Ehrungen.", "procession",
       {},
       [("Den Ruhm genießen.", {"prestige": 5}),
        ("Die Offiziere belohnen.", {"mil": 30}),
        ("Gesandtschaften empfangen.", {"dip": 25})], manual=True),
    ev("riv_border_incident", "Zwischenfall an der Grenze",
       "Reiter des Rivalen haben ein Grenzdorf geplündert. Die Bauern verlangen Schutz, der Adel Vergeltung.", "border",
       {"rivals_min": 1, "at_peace": True, "year_min": 1450, "is_player": True},
       [("Beschwerde einreichen.", {"dip": 10}),
        ("Mit eigenen Reitern antworten.", {"power_proj": 5, "rival_rel": -10}),
        ("Die Garnison verstärken.", {"gold": -20, "mil": 15}, 8)], once=False),
    ev("riv_spy", "Ein Spion des Rivalen",
       "Ein Schreiber in deiner Kanzlei stand im Sold des Rivalen. Was er verraten hat, weiß niemand genau.", "conspiracy",
       {"rivals_min": 1, "year_min": 1450, "is_player": True},
       [("Ihn still verschwinden lassen.", {"adm": 10}),
        ("Ihn öffentlich anklagen.", {"dip": 10, "rival_rel": -10, "prestige": 1}),
        ("Ihn als Doppelagenten nutzen.", {"gold": -15, "mil": 15}, 8)], once=False),
    ev("riv_defector", "Überläufer",
       "Ein Hauptmann des Rivalen bietet dir seine Kompanie und Pläne der feindlichen Stellungen an.", "camp",
       {"rival_at_war": True, "is_player": True},
       [("Ihn aufnehmen.", {"army_power": 0.1}),
        ("Seine Männer einreihen.", {"manpower": 500}),
        ("Ihn zurückschicken, mit falschen Plänen.", {"dip": 10, "power_proj": 3})], once=False),
    ev("riv_pamphlets", "Schmähschriften",
       "In den Städten kursieren Flugblätter aus der Druckerei des Rivalen: dein Haus als Narren, dein Herrscher als Tyrann.", "printing",
       {"rivaled": True, "year_min": 1470, "is_player": True},
       [("Ignorieren.", {"adm": 10, "prestige": -1}),
        ("Eigene Schriften drucken lassen.", {"dip": 15, "prestige": 1}),
        ("Die Drucker aufkaufen.", {"gold": -15, "prestige": 2}, 8)], once=False),
    ev("riv_fame_fades", "Ruhm will gepflegt sein",
       "Lange ist kein Sieg über den Rivalen mehr gefeiert worden. Die Barden singen von alten Taten, die Nachbarn zählen nach.", "tavern",
       {"power_proj_min": 60, "at_peace": True, "is_player": True},
       [("Eine Parade abhalten.", {"mil": 10, "prestige": 1}),
        ("Die Chronisten beschäftigen.", {"adm": 10, "power_proj": 2}),
        ("Es ist, wie es ist.", {"dip": 10, "power_proj": -5})], once=False),
]


def main():
    for e in RIV:
        check(e)
        assert "war" not in e["options"][0]["effects"], e["id"]
    data = events_io.replace_block("riv_", RIV)
    print("events %d (riv %d)" % (len(data), len(RIV)))


if __name__ == "__main__":
    main()
