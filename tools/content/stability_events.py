"""Stability and realm rank events ("stab_" block, written into data/events.json before the gov_ block).

Conditions (Game.check_conditions): stability_min, stability_max, rank_min, rank_max.
Effect (Game.apply_effects): stability (instant change, clamped to -100..100).
stab_crowned is manual: Progression.upgrade fires it for the player on reaching Königreich or higher.

Run: python3 tools/content/stability_events.py (idempotent, see events_io.py).
Rules as in the other generators: first option gold-free and no war, gold-costing options AI weight <= 10,
mods <= 0.03, repeatable random events player-only.
"""
import events_io
from ctx_events import check, ev

STAB = [
    ev("stab_crowned", "Die Krönung",
       "Unter dem Läuten aller Glocken wird der neue Titel verkündet. Gesandte aus halb Europa drängen sich in der Kathedrale, das Volk feiert auf den Plätzen.", "coronation",
       {},
       [("Die Feier dem Volk schenken.", {"stability": 5, "prestige": 2}),
        ("Die Gesandten umwerben.", {"dip": 30}),
        ("Ein prächtiges Bankett für den Adel.", {"gold": -40, "prestige": 5, "estate": {"adel": 4}}, 8)], manual=True),
    ev("stab_barons_grumble", "Die Barone murren",
       "Die großen Familien des Landes treffen sich ohne dich. Man spricht von alten Rechten, von schwacher Hand und von einem Bruder des Herrschers, der es besser könnte.", "conspiracy",
       {"stability_max": -30, "is_player": True},
       [("Ihnen ihre alten Rechte bestätigen.", {"stability": 10, "estate": {"adel": 5}, "adm": -15}),
        ("Die Rädelsführer verhaften.", {"stability": 6, "mil": -20, "estate": {"adel": -5}}),
        ("Mit Gold die Treue erkaufen.", {"gold": -40, "stability": 12}, 8)], once=False),
    ev("stab_bread_riots", "Brotunruhen",
       "Der Brotpreis hat sich verdoppelt. In der Hauptstadt stürmen Frauen die Bäckereien, Gesellen werfen Steine auf die Stadtwache.", "famine",
       {"stability_max": -10, "year_min": 1450, "is_player": True},
       [("Die Wache räumt die Straßen.", {"stability": 3, "prestige": -1}),
        ("Die Kornspeicher öffnen.", {"gold": -25, "stability": 8, "estate": {"buerger": 3}}, 8),
        ("Den Bäckern die Schuld geben.", {"adm": 10, "stability": -3})], once=False),
    ev("stab_golden_age", "Ein goldenes Zeitalter",
       "Die Ernten sind gut, die Straßen sicher, die Kassen voll. Dichter nennen diese Jahre schon jetzt ein goldenes Zeitalter.", "harvest",
       {"stability_min": 60, "year_min": 1455},
       [("Die Gelehrten fördern.", {"adm": 40}),
        ("Den Ruhm mehren.", {"prestige": 8}),
        ("Die Steuern behutsam anheben.", {"mods": {"tax": 0.02}, "stability": -5})]),
    ev("stab_loyal_cities", "Treue Städte",
       "Die Städte des Reiches senden Abgesandte mit Geschenken. Sie danken für Ruhe und Recht und bitten um neue Privilegien.", "city",
       {"stability_min": 40, "year_min": 1460, "is_player": True},
       [("Die Geschenke annehmen.", {"gold": 30}),
        ("Neue Marktrechte gewähren.", {"dev_random": 1, "estate": {"buerger": 3}}),
        ("Sie zur Krönungsfeier laden.", {"prestige": 3, "stability": 3})], once=False),
    ev("stab_reform_council", "Ein Reformrat",
       "Juristen und Kämmerer legen einen Plan vor: neue Ämter, klare Gesetze, ein Rat, der die Beschwerden des Landes hört. Er würde Ordnung bringen und kostet Zeit und Kraft.", "diet",
       {"stability_max": 0, "year_min": 1480},
       [("Den Rat einsetzen.", {"adm": -40, "stability": 15}),
        ("Nur die Gesetze sammeln lassen.", {"adm": -15, "stability": 6}),
        ("Die Pläne ablegen.", {"adm": 10})]),
    ev("stab_overstretched", "Zu groß, um zu regieren",
       "Boten brauchen Wochen bis in die fernen Provinzen, Statthalter regieren dort wie Könige. Die Kanzlei warnt: Das Reich wächst schneller als seine Verwaltung.", "court",
       {"rank_min": 4, "stability_max": 20, "is_player": True},
       [("Statthalter mit Vollmachten.", {"stability": 6, "prestige": -2}),
        ("Eine Reise des Herrschers durch die Provinzen.", {"gold": -50, "stability": 12, "prestige": 2}, 8),
        ("Die Kanzlei vergrößern.", {"adm": -30, "stability": 10})], once=False),
    ev("stab_rumours", "Gerüchte am Hof",
       "Man flüstert, der Herrscher sei krank, die Erbfolge ungewiss, die Kasse leer. Nichts davon ist bewiesen, aber alles wird geglaubt.", "court",
       {"year_min": 1450, "stability_max": 50, "is_player": True},
       [("Sich öffentlich zeigen.", {"stability": 3, "prestige": 1}),
        ("Die Schwätzer suchen lassen.", {"mil": -10, "stability": 5}),
        ("Gegengerüchte streuen.", {"dip": -10, "stability": 4})], once=False),
]


def main():
    for e in STAB:
        check(e)
        assert "war" not in e["options"][0]["effects"], e["id"]
    data = events_io.replace_block("stab_", STAB)
    print("events %d (stab %d)" % (len(data), len(STAB)))


if __name__ == "__main__":
    main()
