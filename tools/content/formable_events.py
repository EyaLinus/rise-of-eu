"""Events for proclaiming a new realm ("form_" block, written into data/events.json before the gov_ block).

All manual: Formables.form fires form_<id lower> once when the realm is proclaimed (scripts/core/formables.gd).
Every option is a small flavour choice on top of the formation bonus; no war, AI weight <= 10 on gold costs.

Run: python3 tools/content/formable_events.py (idempotent, see events_io.py).
"""
import json, os
import events_io
from ctx_events import check, ev

M = 0.02  # mods stay small: the formation already gives a lasting bonus

FORM = [
    ev("form_ita", "Italia unita",
       "Von den Alpen bis Sizilien weht ein Banner. In Rom, Florenz und Venedig streiten die Gelehrten, wessen Dialekt die Sprache des neuen Reiches sein soll.", "coronation",
       {},
       [("Florenz gibt die Sprache vor.", {"adm": 25, "prestige": 3}),
        ("Venedigs Kaufleute führen den Rat.", {"mods": {"trade": M}}),
        ("Eine Krönung in Rom.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_ger", "Ein Reich der Deutschen",
       "Die Fürsten huldigen dem neuen Herrscher. Doch in den Städten fragen die Bürger, ob ihre alten Freiheiten unter der neuen Krone gelten.", "diet",
       {},
       [("Die Freiheiten der Städte bestätigen.", {"dip": 25, "prestige": 2}),
        ("Ein Reichsheer aufstellen.", {"manpower": 1000, "mil": 15}),
        ("Ein Reichstag mit Pomp.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_gbr", "Zwei Kronen, ein Reich",
       "England und Schottland sind vereint. In Edinburgh wehen neue Banner, in London streitet das Parlament über die neuen Abgeordneten aus dem Norden.", "treaty",
       {},
       [("Die Schotten in den Rat holen.", {"dip": 25, "prestige": 2}),
        ("Eine gemeinsame Flotte.", {"mods": {"naval": M}}),
        ("Krönung in Westminster.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_plc", "Die Republik beider Völker",
       "Krone und Großfürstentum sind eins. Der Adel beider Länder versammelt sich zum ersten gemeinsamen Sejm und verlangt seine Rechte.", "diet",
       {},
       [("Dem Adel die freie Wahl versprechen.", {"estate": {"adel": 5}, "prestige": 2}),
        ("Eine starke Krone durchsetzen.", {"adm": 25, "estate": {"adel": -3}}),
        ("Ein Fest in Krakau und Vilnius.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_ibe", "Die Iberische Krone",
       "Kastilien, Aragón und Portugal gehorchen einem Herrscher. Die Cortes der drei Länder fürchten um ihre alten Fueros.", "court",
       {},
       [("Die Fueros achten.", {"dip": 25, "prestige": 2}),
        ("Die Häfen öffnen.", {"mods": {"trade": M}}),
        ("Eine Krönung in Toledo.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_rom", "Roma renata",
       "Rom und Konstantinopel in einer Hand: Gesandte aus ganz Europa staunen, die Gelehrten graben alte Titel aus, und der Hof will Purpur tragen.", "coronation",
       {},
       [("Den Titel der Caesaren annehmen.", {"prestige": 10, "ae": 10}),
        ("Die Legionen neu ordnen.", {"mil": 30, "manpower": 1000}),
        ("Ein Triumphzug durch die Stadt.", {"gold": -60, "prestige": 12}, 8)], manual=True),
    ev("form_per", "Der Schah der Schahs",
       "Von Täbris bis Mossul huldigen die Stammesfürsten dem neuen Schah. Dichter preisen ihn als Erben der alten Könige.", "court",
       {},
       [("Die Stämme mit Land belohnen.", {"manpower": 1000, "prestige": 2}),
        ("Die Karawanenstraßen sichern.", {"mods": {"trade": M}}),
        ("Ein Hof voll Dichter.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_mgb", "Ein Sultan für den Westen",
       "Von Fès bis Tunis gilt ein Wort. Die Korsaren der Küste fragen, ob der neue Sultan ihre Fahrten duldet.", "naval",
       {},
       [("Die Korsaren in Dienst nehmen.", {"mods": {"naval": M}}),
        ("Den Handel mit Europa suchen.", {"dip": 25, "prestige": 2}),
        ("Eine Moschee zur Feier stiften.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_jpn", "Ein Land, ein Herr",
       "Die Burgen der Kriegsfürsten öffnen ihre Tore. In Kyōto fragt der Hof, wer nun regiert: der Kaiser, der Feldherr oder die Großen des Landes.", "court",
       {},
       [("Die Fürsten als Vasallen bestätigen.", {"dip": 25, "estate": {"adel": 4}}),
        ("Die Schwerter einsammeln lassen.", {"adm": 30, "estate": {"adel": -3}}),
        ("Eine Teezeremonie für den ganzen Hof.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_hin", "Der Thron von Hindustan",
       "Rajas und Sultane schicken Elefanten und Gesandte. Der neue Herrscher muss entscheiden, wie viele Glaubensrichtungen sein Hof verträgt.", "court",
       {},
       [("Alle Glauben am Hof dulden.", {"prestige": 4, "dip": 15}),
        ("Die Steuerbücher neu schreiben.", {"mods": {"tax": M}}),
        ("Ein Durbar mit tausend Elefanten.", {"gold": -60, "prestige": 10}, 8)], manual=True),
    ev("form_arb", "Die Halbinsel vereint",
       "Von den heiligen Städten bis an den Golf gilt ein Siegel. Pilger, Händler und Beduinen erwarten vom neuen Herrscher Schutz auf den Straßen.", "market",
       {},
       [("Die Pilgerwege schützen.", {"prestige": 5, "stability": 5}),
        ("Die Häfen am Roten Meer öffnen.", {"mods": {"trade": M}}),
        ("Die Stämme mit Gold binden.", {"gold": -50, "manpower": 2}, 8)], manual=True),
    ev("form_usa", "Eine Union freier Staaten",
       "In einem Versammlungshaus an der Küste unterzeichnen die Abgesandten der Kolonien eine Erklärung: Sie wollen ihr Schicksal selbst bestimmen.", "treaty",
       {},
       [("Eine geschriebene Verfassung.", {"adm": 30, "stability": 5}),
        ("Land im Westen für Siedler.", {"mods": {"manpower": M}}),
        ("Ein Fest mit Glocken und Kanonen.", {"gold": -50, "prestige": 8}, 8)], manual=True),
    ev("form_tta", "Der Khagan der Steppe",
       "Von der Krim bis zum Altai reiten die Boten mit einem Befehl. Die Fürsten der Horden fragen, ob der neue Khagan in der Jurte oder im Palast regiert.", "coronation",
       {},
       [("Nach dem Brauch der Steppe herrschen.", {"mil": 30, "manpower": 3}),
        ("Städte und Karawanen fördern.", {"mods": {"trade": M}}),
        ("Ein Kurultai mit allen Horden.", {"gold": -60, "prestige": 12}, 8)], manual=True),
    ev("form_eur", "Imperium Europa",
       "Zum ersten Mal seit den Caesaren gehorchen Paris, London, Wien und Rom einem Herrscher. Gesandte aus der ganzen Welt fragen, was dieses Reich sein will.", "coronation",
       {},
       [("Ein Reich der Gesetze für alle Völker.", {"adm": 40, "stability": 10}),
        ("Ein Reich der Händler und Häfen.", {"mods": {"trade": M}}),
        ("Eine Krönung, die die Welt nicht vergisst.", {"gold": -100, "prestige": 20}, 8)], manual=True),
]


def main():
    defs = json.load(open(os.path.join(events_io.ROOT, "data/formables.json"), encoding="utf-8"))
    assert {"form_" + k.lower() for k in defs} == {e["id"] for e in FORM}
    for e in FORM:
        check(e)
        assert "war" not in str(e["options"])
    data = events_io.replace_block("form_", FORM)
    print("events %d (form %d)" % (len(data), len(FORM)))


if __name__ == "__main__":
    main()
