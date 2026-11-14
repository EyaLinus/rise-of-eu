"""City and countryside events ("urb_" block, written into data/events.json before the gov_ block).

Conditions (Game.check_conditions): cities_min, cities_max. Effects (Game.apply_effects): urbanize (n free cities).
urb_city_founded / urb_back_to_land are manual: Urban.tick fires them once per realm when a change finishes.

Run: python3 tools/content/urban_events.py (idempotent, see events_io.py).
Rules as in the other generators: first option gold-free and no war, gold-costing options AI weight <= 10,
mods <= 0.03, repeatable random events player-only (they would only dilute the AI's event pool).
"""
import events_io
from ctx_events import check, ev

URB = [
    ev("urb_city_founded", "Stadtrecht",
       "Mauern, Markt und Rathaus stehen: Eine deiner Provinzen ist zur Stadt geworden. Zünfte bilden sich, Händler ziehen zu, und der Rat bittet um ein Privileg.", "city",
       {},
       [("Marktrecht verleihen.", {"dip": 15, "prestige": 2}),
        ("Die Zünfte besteuern.", {"gold": 40, "prestige": -1}),
        ("Ein Fest für die Bürger.", {"gold": -25, "prestige": 4}, 8)], manual=True),
    ev("urb_back_to_land", "Verlassene Gassen",
       "Die Stadt ist aufgegeben: Die Bürger ziehen aufs Land, die Werkstätten verfallen, doch die Dörfer ringsum stellen wieder mehr Männer.", "harvest",
       {},
       [("Die Bauern entlasten.", {"manpower": 400}),
        ("Die Steine für Straßen nutzen.", {"adm": 10}),
        ("Die Zünfte entschädigen.", {"gold": -20, "prestige": 1}, 8)], manual=True),
    ev("urb_guild_dispute", "Zunftstreit",
       "In einer deiner Städte liegen Weber und Färber im Streit um die Preise. Beide Seiten verlangen ein Urteil des Hofes.", "court",
       {"cities_min": 1, "is_player": True},
       [("Zugunsten der Weber entscheiden.", {"adm": 10}),
        ("Zugunsten der Färber entscheiden.", {"dip": 10}),
        ("Beide Seiten mit Gold besänftigen.", {"gold": -20, "prestige": 1}, 8)], once=False),
    ev("urb_market_boom", "Markttag",
       "Der Jahrmarkt in deiner größten Stadt zieht Händler aus fernen Ländern an. Die Zölle klingeln, die Wirte jubeln.", "market",
       {"cities_min": 2, "at_peace": True, "is_player": True},
       [("Die Zölle einstreichen.", {"gold": 35}),
        ("Die Händler mit Privilegien locken.", {"dip": 15, "gold": 10}),
        ("Ein Turnier ausrichten.", {"gold": -15, "prestige": 3}, 8)], once=False),
    ev("urb_city_fever", "Fieber in der Stadt",
       "In den engen Gassen einer deiner Städte grassiert ein Fieber. Die Ratsherren wollen die Tore schließen, die Händler nicht.", "plague",
       {"cities_min": 2, "year_min": 1460, "is_player": True},
       [("Die Tore schließen.", {"adm": 10, "manpower": -200}),
        ("Ärzte bezahlen.", {"gold": -30, "prestige": 2}, 8),
        ("Es Gottes Hand überlassen.", {"prestige": -2, "manpower": -400})], once=False),
    ev("urb_charter", "Ein Freibrief",
       "Ein wohlhabender Flecken bittet um das Stadtrecht und bietet eine stattliche Summe für Mauern und Markt. Der Adel ringsum murrt.", "diet",
       {"cities_min": 1, "cities_max": 6, "year_min": 1470},
       [("Das Stadtrecht verleihen.", {"urbanize": 1, "prestige": 1}),
        ("Dem Adel nachgeben.", {"mil": 20}),
        ("Verleihen und den Adel entschädigen.", {"urbanize": 1, "gold": -40}, 8)]),
    ev("urb_country_fair", "Erntedank",
       "Auf dem Land wird die Ernte gefeiert. Die Dörfer schicken Gesandte mit Garben und der Bitte um eine Steuerpause.", "harvest",
       {"cities_max": 3, "at_peace": True, "is_player": True},
       [("Die Bitte gewähren.", {"manpower": 300, "prestige": 1}),
        ("Die Garben annehmen, die Steuer bleibt.", {"gold": 20, "prestige": -1}),
        ("Ein Fest mit den Bauern feiern.", {"gold": -15, "mil": 10, "prestige": 1}, 8)], once=False),
    ev("urb_walls_needed", "Die Stadt will Mauern",
       "Die Bürger deiner Städte fürchten Plünderer und bitten um Festungswerke. Die Zünfte sind bereit, einen Teil zu zahlen.", "siege",
       {"cities_min": 3, "year_min": 1480, "is_player": True},
       [("Die Bürger selbst bauen lassen.", {"mil": 15}),
        ("Mitzahlen: eine Festung entsteht.", {"gold": -40, "build": "fortress"}, 8),
        ("Lieber ein stehendes Heer.", {"manpower": 300})]),
]


def main():
    for e in URB:
        check(e)
        assert "war" not in e["options"][0]["effects"], e["id"]
    data = events_io.replace_block("urb_", URB)
    print("events %d (urb %d)" % (len(data), len(URB)))


if __name__ == "__main__":
    main()
