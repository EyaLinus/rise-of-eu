"""Six more playable nations (v1.0): Portugal, Venice, Hungary, the Mamluks, Qara Qoyunlu and Ethiopia.

Sets "playable" in data/nations.json, adds national missions ("<tag>_np_*", appended to data/missions.json
before the rivalry missions) and national events (block "np_" in data/events.json). Special techs, advisors
and companies live in tools/content/tech_gov.py; rivalry missions in tools/content/rival_missions.py.
Idempotent: rerunning replaces its own missions and events.

Run: python3 tools/content/new_playables.py && python3 tools/content/rival_missions.py && python3 tools/content/tech_gov.py
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from events_io import replace_block  # noqa: E402
from rival_missions import render_mission  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLAYABLE = ["POR", "VEN", "HUN", "MAM", "QAR", "ETH"]


def m(mid, title, desc, require, reward, after=None):
    d = {"id": mid, "title": title, "desc": desc, "require": require, "reward": reward}
    if after:
        d["after"] = after
    return d


MISSIONS = {
    "POR": [
        m("por_np_ceuta", "Ceuta halten", "Der Brückenkopf in Afrika ist der Anfang aller Fahrten.",
          {"owns_any": ["tangier", "rif"]}, {"mil": 40, "prestige": 10}),
        m("por_np_fleet", "Die Flotte des Infanten", "Karavellen für die Küsten Afrikas.",
          {"ships_min": 8, "building": {"harbor": 2}}, {"dip": 40, "mods": {"naval": 0.03}}),
        m("por_np_guinea", "Gold aus Guinea", "Ein Handelsposten an der Goldküste füllt die Schatzkammer.",
          {"owns_any": ["gold_coast", "arguin", "gambia", "sierra_leone"]}, {"gold": 150, "prestige": 10}, "por_np_fleet"),
        m("por_np_atlantic", "Die Inseln im Atlantik", "Jenseits des Ozeans warten Inseln auf Siedler und Fischer.",
          {"owns_any": ["quisqueya", "boriken", "antilles", "lucayas", "newfoundland", "camaguey"]}, {"dip": 50, "mods": {"income": 0.03}}, "por_np_fleet"),
        m("por_np_morocco", "Die Häfen Marokkos", "Von Tanger bis Agadir: Festungen an der Küste schützen die Seewege.",
          {"owns_any": ["rabat", "sous", "marrakesh"]}, {"mil": 50, "mods": {"manpower": 0.05}}, "por_np_ceuta"),
        m("por_np_manueline", "Der manuelinische Stil", "Gewürzgeld wird zu Stein: ein Kloster für die Seefahrer.",
          {"monuments_min": 1, "min_dev": 120}, {"prestige": 20, "adm": 40}, "por_np_guinea"),
    ],
    "VEN": [
        m("ven_np_stato_mar", "Stato da Mar", "Kreta, Zypern und die Inseln der Ägäis sind die Stützpunkte der Galeeren.",
          {"owns_any": ["crete", "cyprus", "rhodes"]}, {"dip": 40, "mods": {"naval": 0.03}}),
        m("ven_np_galleys", "Die Galeeren der Republik", "Eine Flotte, die das Mittelmeer beherrscht.",
          {"ships_min": 12}, {"prestige": 15, "mods": {"trade": 0.03}}),
        m("ven_np_alexandria", "Der Pfeffer von Alexandria", "Ein Handelsvertrag mit Kairo bringt die Gewürze nach Venedig.",
          {"trade_pacts_min": 2}, {"gold": 120, "mods": {"trade": 0.03}}, "ven_np_galleys"),
        m("ven_np_morea", "Die Häfen der Morea", "Modon und Koron, die Augen der Republik.",
          {"owns_any": ["morea", "albania"]}, {"mil": 40, "prestige": 10}, "ven_np_stato_mar"),
        m("ven_np_basilica", "Pracht der Serenissima", "Paläste am Canal Grande zeigen der Welt, wer reich ist.",
          {"monuments_min": 1, "building": {"marketplace": 3}}, {"prestige": 20, "adm": 40}),
    ],
    "HUN": [
        m("hun_np_belgrade", "Das Bollwerk Belgrad", "Wer Belgrad hält, hält die Osmanen auf.",
          {"owns_any": ["serbia", "bosnia"], "regs": 12}, {"mil": 50, "prestige": 15}),
        m("hun_np_croatia", "Krone Kroatiens", "Kroatien und Slawonien gehören zur Stephanskrone.",
          {"owns": ["croatia", "slavonia"]}, {"adm": 40, "mods": {"manpower": 0.05}}),
        m("hun_np_wallachia", "Die Woiwoden an der Donau", "Die Walachei und die Moldau sollen der Krone dienen.",
          {"owns_any": ["wallachia", "moldavia"]}, {"dip": 40, "prestige": 10}, "hun_np_belgrade"),
        m("hun_np_buda", "Die Renaissance in Buda", "Italienische Baumeister und eine Universität am Hof.",
          {"building": {"university": 1}, "min_dev": 120}, {"prestige": 20, "mods": {"tech_cost": -0.03}}),
        m("hun_np_bohemia", "Die Krone Böhmens", "Matthias greift nach Mähren und Schlesien.",
          {"owns_any": ["moravia", "silesia", "lusatia"]}, {"mil": 50, "mods": {"combat": 0.02}}, "hun_np_croatia"),
    ],
    "MAM": [
        m("mam_np_hejaz", "Hüter der heiligen Stätten", "Mekka und Medina unter dem Schutz des Sultans.",
          {"owns_any": ["mecca", "medina"]}, {"prestige": 25, "mods": {"income": 0.03}}),
        m("mam_np_red_sea", "Das Rote Meer", "Suakin und Dschidda sichern den Gewürzweg nach Indien.",
          {"owns_any": ["suakin", "asir", "tihama"]}, {"dip": 40, "mods": {"trade": 0.03}}, "mam_np_hejaz"),
        m("mam_np_yemen", "Aden, Tor nach Indien", "Wer Aden hält, nimmt den Portugiesen den Pfeffer weg.",
          {"owns": ["aden"]}, {"gold": 150, "prestige": 15}, "mam_np_red_sea"),
        m("mam_np_nubia", "Die Nubische Grenze", "Assuan und Dongola, Gold und Sklaven? Oder Handel und Frieden mit Alwa?",
          {"owns_any": ["dongola", "alwa"]}, {"mil": 40, "mods": {"manpower": 0.05}}),
        m("mam_np_fortress", "Die Zitadelle von Kairo", "Neue Mauern und Kanonen gegen die Osmanen.",
          {"tech": {"mil": 8}, "regs": 20}, {"mil": 60, "mods": {"combat": 0.03}}),
    ],
    "QAR": [
        m("qar_np_tabriz", "Die Blaue Moschee", "Täbris soll die schönste Stadt zwischen Kaukasus und Golf werden.",
          {"building": {"marketplace": 1}, "min_dev": 120}, {"prestige": 15, "adm": 30}),
        m("qar_np_baghdad", "Herr von Bagdad", "Die alte Kalifenstadt und das Zweistromland gehören den Schwarzen Hammeln.",
          {"owns": ["baghdad", "basra", "mosul"]}, {"mil": 40, "mods": {"tax": 0.03}}),
        m("qar_np_aq", "Die Weißen Hammel", "Uzun Hasan ist der Erzfeind. Diyarbakır muss fallen.",
          {"owns": ["diyarbakir"]}, {"mil": 50, "prestige": 15}),
        m("qar_np_isfahan", "Die Perlen Persiens", "Isfahan und Fars, das Erbe der Timuriden.",
          {"owns": ["isfahan", "fars"]}, {"adm": 50, "mods": {"income": 0.05}}, "qar_np_baghdad"),
        m("qar_np_caspian", "Seide vom Kaspischen Meer", "Gilan und Masandaran liefern die Seide für Täbris.",
          {"owns_any": ["gilan", "mazandaran"]}, {"dip": 40, "mods": {"trade": 0.03}}),
        m("qar_np_georgia", "Die Pässe des Kaukasus", "Georgien und Schirwan zahlen Tribut oder fallen.",
          {"owns_any": ["tbilisi", "shamakhi"]}, {"mil": 40, "prestige": 10}, "qar_np_aq"),
        m("qar_np_gulf", "Der Persische Golf", "Hormus ist der reichste Hafen der Welt.",
          {"owns": ["hormuz"]}, {"gold": 150, "mods": {"trade": 0.05}}, "qar_np_isfahan"),
        m("qar_np_shah", "Schahinschah", "Ein Reich wie das der Sassaniden: ruf dich zum Schah von Persien aus.",
          {"min_dev": 350}, {"prestige": 30, "mods": {"manpower": 0.05}}, "qar_np_gulf"),
    ],
    "ETH": [
        m("eth_np_zara", "Die Reformen Zara Yaqobs", "Kirche und Krone, ein Gesetz für das ganze Hochland.",
          {"tech": {"adm": 3}}, {"adm": 40, "prestige": 10}),
        m("eth_np_adal", "Der Krieg gegen Adal", "Harar und Zeila bedrohen das Reich, solange sie frei sind.",
          {"owns_any": ["harar", "zeila"]}, {"mil": 50, "prestige": 15}),
        m("eth_np_sea", "Ein Hafen am Roten Meer", "Massawa und Zeila öffnen das Hochland zur Welt.",
          {"owns_any": ["medri_bahri", "zeila", "danakil"], "building": {"harbor": 1}}, {"dip": 50, "mods": {"trade": 0.05}}),
        m("eth_np_nubia", "Die Brüder in Nubien", "Alwa und Dongola, die letzten Christen am Nil.",
          {"owns_any": ["alwa", "sennar", "dongola"]}, {"prestige": 15, "mods": {"manpower": 0.05}}),
        m("eth_np_allies", "Briefe nach Lissabon", "Ein christlicher König jenseits des Meeres könnte helfen.",
          {"allies": 1, "year_min": 1490}, {"dip": 50, "prestige": 10}, "eth_np_sea"),
        m("eth_np_gondar", "Die Burgen von Gondar", "Eine feste Hauptstadt mit Palästen statt wandernder Zelte.",
          {"monuments_min": 1, "min_dev": 100}, {"prestige": 25, "mods": {"income": 0.05}}, "eth_np_zara"),
        m("eth_np_yemen", "Das Erbe von Aksum", "Einst herrschten die Könige von Aksum auch jenseits des Meeres.",
          {"owns_any": ["sanaa", "aden", "tihama"]}, {"mil": 50, "mods": {"trade": 0.03}}, "eth_np_sea"),
        m("eth_np_somali", "Die Häfen der Somali", "Berbera und das Ogaden, die Küste des Weihrauchs.",
          {"owns": ["berbera", "ogaden"]}, {"gold": 120, "prestige": 10}, "eth_np_adal"),
    ],
}


def ev(eid, tag, title, text, trigger, options):
    return {"id": eid, "tag": tag, "title": title, "text": text, "trigger": trigger, "options": options}


def opt(text, effects, ai=None):
    o = {"text": text, "effects": effects}
    if ai is not None:
        o["ai"] = ai
    return o


EVENTS = [
    # Portugal
    ev("np_por_slave_question", "POR", "Menschen von der Küste Guineas",
       "Kapitäne bringen gefangene Afrikaner nach Lagos und bieten sie auf dem Markt an. Der Hof ist gespalten.",
       {"year_min": 1444, "year_max": 1480},
       [opt("Den Handel erlauben, die Krone kassiert mit.", {"gold": 120, "prestige": -15}),
        opt("Verbieten: wir handeln mit Gold und Pfeffer, nicht mit Menschen.", {"prestige": 15, "dip": 30}, 70),
        opt("Freie Siedler statt Gefangener für die Inseln anwerben.", {"gold": -40, "mods": {"production": 0.02}})]),
    ev("np_por_tordesillas", "POR", "Eine Linie durch den Ozean",
       "Kastilien schlägt vor, die neu entdeckte Welt mit einer Linie von Pol zu Pol zu teilen.",
       {"year_min": 1490, "year_max": 1520, "alive": "SPA"},
       [opt("Unterschreiben: Frieden mit Kastilien.", {"relations": {"SPA": 40}, "dip": 30}, 60),
        opt("Die Linie weiter nach Westen schieben.", {"relations": {"SPA": -20}, "prestige": 10}),
        opt("Kein Papier teilt das Meer.", {"mil": 40, "relations": {"SPA": -40}})]),
    ev("np_por_lisbon_quake", "POR", "Gewürze in Lissabon",
       "Die Lagerhäuser am Tejo quellen über von Pfeffer. Die Preise in Antwerpen fallen.",
       {"year_min": 1500, "year_max": 1580, "ships_min": 10},
       [opt("Mehr Schiffe nach Indien.", {"gold": -60, "mods": {"trade": 0.03}}, 60),
        opt("Den Überschuss verkaufen.", {"gold": 150}),
        opt("Die Faktorei in Antwerpen ausbauen.", {"dip": 40, "relations": {"BUR": 20}})]),
    ev("np_por_sebastian", "POR", "Der König will nach Afrika",
       "Der junge König träumt von einem Kreuzzug gegen Marokko. Die Räte warnen.",
       {"year_min": 1560, "year_max": 1600, "alive": "MOR"},
       [opt("Ins Feld!", {"war": "MOR", "mil": 40}),
        opt("Lieber die Festungen verstärken.", {"mil": 30, "gold": -40}, 70),
        opt("Einen Vertrag mit dem Sultan schließen.", {"relations": {"MOR": 40}, "dip": 20})]),
    # Venice
    ev("np_ven_galley_slaves", "VEN", "Ruderer für die Galeeren",
       "Die Flotte braucht Tausende Ruderer. Der Rat streitet: Sträflinge, gekaufte Gefangene oder bezahlte Freiwillige?",
       {"year_min": 1450, "year_max": 1600},
       [opt("Gefangene vom Sklavenmarkt kaufen.", {"gold": 60, "prestige": -10, "mods": {"naval": 0.03}}),
        opt("Freiwillige anständig bezahlen.", {"gold": -60, "prestige": 10, "mods": {"naval": 0.03}}, 70),
        opt("Sträflinge an die Ruder.", {"mods": {"naval": 0.02}, "dip": -10})]),
    ev("np_ven_carnival", "VEN", "Karneval in Venedig",
       "Masken, Feste und Fremde aus aller Welt. Der Rat fragt, ob das Fest größer werden soll.",
       {"year_min": 1470, "at_peace": True},
       [opt("Ein Fest für ganz Europa.", {"gold": -50, "prestige": 20}, 60),
        opt("Steuern auf die Feiernden.", {"gold": 80}),
        opt("Lieber in die Flotte investieren.", {"mil": 30})]),
    ev("np_ven_cambrai", "VEN", "Die Liga gegen Venedig",
       "Der Papst, Frankreich und der Kaiser haben sich gegen die Republik verbündet.",
       {"year_min": 1505, "year_max": 1515, "min_dev": 120},
       [opt("Kämpfen, um jede Stadt.", {"mil": 40, "regs": 4}, 60),
        opt("Die Liga mit Gold spalten.", {"gold": -120, "dip": 50}),
        opt("Terraferma aufgeben, das Meer behalten.", {"prestige": -15, "mods": {"naval": 0.03}})]),
    # Hungary
    ev("np_hun_corvinus", "HUN", "Ein König aus dem Volk",
       "Der Adel wählt den jungen Matthias Corvinus zum König. Er will eine starke Krone.",
       {"year_min": 1455, "year_max": 1470},
       [opt("Eine Sondersteuer für die Schwarze Armee.", {"gold": -60, "mods": {"combat": 0.03}}, 60),
        opt("Den Adel schonen.", {"prestige": 10, "dip": 30}),
        opt("Gelehrte nach Buda holen.", {"adm": 50})]),
    ev("np_hun_dozsa", "HUN", "Der Bauernkreuzzug",
       "Bauern, die zum Kreuzzug gerufen wurden, wenden ihre Waffen gegen die Grundherren.",
       {"year_min": 1500, "year_max": 1530},
       [opt("Hart durchgreifen und die Leibeigenschaft verschärfen.", {"mil": 30, "mods": {"tax": 0.03, "manpower": -0.05}}),
        opt("Die Forderungen der Bauern teilweise erfüllen.", {"prestige": 10, "mods": {"manpower": 0.05}, "gold": -40}, 70),
        opt("Den Kreuzzug abblasen.", {"prestige": -10})]),
    ev("np_hun_border", "HUN", "Die Grenzfestungen",
       "Die Burgen an der Save verfallen. Die Osmanen warten nur darauf.",
       {"year_min": 1444, "alive": "TUR"},
       [opt("Ausbauen, koste es, was es wolle.", {"gold": -80, "mil": 40}, 60),
        opt("Die Grenzer selbst bezahlen lassen.", {"mods": {"manpower": 0.03}, "prestige": -5}),
        opt("Gesandte nach Konstantinopel.", {"relations": {"TUR": 30}, "dip": 20})]),
    # Mamluks
    ev("np_mam_spice_tax", "MAM", "Der Sultan und der Pfeffer",
       "Der Sultan könnte den Gewürzhandel zum Staatsmonopol machen. Die Karimi-Kaufleute wären ruiniert.",
       {"year_min": 1444, "year_max": 1500},
       [opt("Monopol! Die Gewinne gehören dem Sultan.", {"gold": 150, "mods": {"trade": -0.03}}),
        opt("Die Kaufleute frei handeln lassen.", {"mods": {"trade": 0.05}}, 70),
        opt("Eine maßvolle Abgabe.", {"gold": 60, "dip": 20})]),
    ev("np_mam_slave_soldiers", "MAM", "Neue Mamluken",
       "Das Heer kauft seine Krieger seit Jahrhunderten als Knaben vom Schwarzen Meer. Die Preise steigen.",
       {"year_min": 1450, "year_max": 1600},
       [opt("Weiter kaufen, die alte Ordnung hält.", {"gold": -80, "regs": 4, "prestige": -5}),
        opt("Freie Ägypter und Beduinen anwerben.", {"mods": {"manpower": 0.08}, "prestige": 5}, 70),
        opt("Feuerwaffen statt Reiter.", {"mil": 50, "mods": {"combat": 0.02}})]),
    ev("np_mam_plague", "MAM", "Die Pest in Kairo",
       "Wieder wütet die Seuche in den Gassen der Stadt.",
       {"year_min": 1460, "year_max": 1520},
       [opt("Die Stadt abriegeln.", {"gold": -40, "manpower": -2}, 60),
        opt("Gebete und Almosen.", {"prestige": 10, "gold": -60}),
        opt("Nichts tun.", {"manpower": -6, "prestige": -5})]),
    ev("np_mam_portuguese", "MAM", "Fremde Schiffe im Indischen Ozean",
       "Portugiesen haben das Kap umrundet und greifen die Pilgerschiffe an.",
       {"year_min": 1500, "year_max": 1530, "alive": "POR"},
       [opt("Eine Flotte im Roten Meer bauen.", {"gold": -100, "ships": 4, "relations": {"POR": -40}}, 60),
        opt("Mit Venedig gemeinsame Sache machen.", {"relations": {"VEN": 40}, "dip": 30}),
        opt("Mit den Portugiesen verhandeln.", {"relations": {"POR": 30}, "prestige": -10})]),
    # Qara Qoyunlu
    ev("np_qar_jahan", "QAR", "Jahan Shah, Schah der Welt",
       "Der Herrscher der Schwarzen Hammel ist Dichter und Eroberer zugleich.",
       {"year_min": 1444, "year_max": 1467},
       [opt("Nach Osten, gegen die Timuriden!", {"mil": 40, "claim": ["isfahan", "fars"]}, 60),
        opt("Gedichte und Moscheen.", {"prestige": 15, "adm": 30}),
        opt("Die Stämme belohnen.", {"gold": -50, "mods": {"manpower": 0.05}})]),
    ev("np_qar_safavid", "QAR", "Der Orden von Ardabil",
       "Scheich Junayd predigt einen neuen Glauben. Die Turkmenen der Berge hören ihm zu.",
       {"year_min": 1447, "year_max": 1500, "alive": "SAF"},
       [opt("Den Scheich vertreiben.", {"war": "SAF", "mil": 30}),
        opt("Den Orden mit Land und Ehren einbinden.", {"relations": {"SAF": 50}, "prestige": -5}, 70),
        opt("Abwarten.", {"dip": 20})]),
    ev("np_qar_succession", "QAR", "Streit unter den Söhnen",
       "Die Söhne des Schahs streiten schon jetzt um das Erbe.",
       {"year_min": 1455, "year_max": 1520},
       [opt("Das Reich teilen.", {"prestige": -15, "dip": 40}),
        opt("Einen Erben bestimmen, die anderen verbannen.", {"mil": 30, "mods": {"combat": 0.02}}, 60),
        opt("Die Stammesältesten entscheiden lassen.", {"prestige": 5, "adm": 30})]),
    ev("np_qar_tabriz_bazaar", "QAR", "Der Basar von Täbris",
       "Kaufleute aus Venedig, Indien und China treffen sich in Täbris.",
       {"year_min": 1444, "at_peace": True},
       [opt("Zölle senken.", {"mods": {"trade": 0.04}}, 60),
        opt("Zölle erhöhen.", {"gold": 100}),
        opt("Eine neue Karawanserei bauen.", {"gold": -50, "dev_capital": 1})]),
    ev("np_qar_slave_raids", "QAR", "Beute aus dem Kaukasus",
       "Die Emire wollen in Georgien Menschen rauben und auf den Märkten verkaufen.",
       {"year_min": 1444, "year_max": 1600, "alive": "GEO"},
       [opt("Plündern lassen.", {"gold": 100, "relations": {"GEO": -50}, "prestige": -10}),
        opt("Verbieten und Tribut verlangen.", {"gold": 40, "relations": {"GEO": 10}}, 70),
        opt("Handel mit Georgien statt Raub.", {"relations": {"GEO": 40}, "mods": {"trade": 0.02}})]),
    # Ethiopia
    ev("np_eth_zara_yaqob", "ETH", "Der strenge Kaiser",
       "Zara Yaqob verlangt, dass jeder Christ das Kreuz auf der Stirn trägt. Die Mönche murren.",
       {"year_min": 1444, "year_max": 1470},
       [opt("Die Kirche einen, mit Härte.", {"adm": 40, "prestige": 10, "mods": {"unrest": 0.25}}),
        opt("Die Klöster ihren Weg gehen lassen.", {"dip": 30, "mods": {"unrest": -0.25}}, 70),
        opt("Ein Konzil einberufen.", {"prestige": 15, "gold": -40})]),
    ev("np_eth_florence", "ETH", "Mönche in Florenz",
       "Äthiopische Mönche aus Jerusalem sind beim Konzil in Italien gewesen und berichten von Europa.",
       {"year_min": 1444, "year_max": 1480},
       [opt("Gesandte nach Rom und Lissabon.", {"dip": 40, "prestige": 10}, 60),
        opt("Europa ist weit.", {"adm": 30}),
        opt("Handwerker aus Europa holen.", {"gold": -50, "mods": {"production": 0.03}})]),
    ev("np_eth_slave_trade", "ETH", "Gefangene aus dem Süden",
       "Nach den Feldzügen bieten Händler aus Adal an, Gefangene über das Meer zu verkaufen.",
       {"year_min": 1450, "year_max": 1640},
       [opt("Verkaufen.", {"gold": 100, "prestige": -15}),
        opt("Die Gefangenen ansiedeln und taufen.", {"prestige": 10, "mods": {"manpower": 0.03}}, 70),
        opt("Frei lassen gegen Tribut der Stämme.", {"gold": 30, "dip": 30})]),
    ev("np_eth_gran", "ETH", "Der Linkshänder",
       "Ahmad ibn Ibrahim, genannt Gran, sammelt in Adal ein Heer mit osmanischen Musketen.",
       {"year_min": 1525, "year_max": 1545, "alive": "ADA"},
       [opt("Die Pässe befestigen.", {"gold": -80, "mil": 40}, 60),
        opt("Hilfe aus Portugal erbitten.", {"relations": {"POR": 50}, "dip": 20}),
        opt("Angreifen, bevor er bereit ist.", {"war": "ADA", "regs": 4})]),
    ev("np_eth_coffee", "ETH", "Die Bohnen aus Kaffa",
       "Hirten im Süden kauen rote Beeren, die wach halten. Händler aus dem Jemen zahlen gut dafür.",
       {"year_min": 1450},
       [opt("Den Handel fördern.", {"mods": {"trade": 0.04}}, 60),
        opt("Auf die Ausfuhr Zoll erheben.", {"gold": 80}),
        opt("Die Mönche verbieten es als heidnisch.", {"prestige": 5, "adm": 20})]),
    ev("np_eth_succession", "ETH", "Der Berg der Prinzen",
       "Alle männlichen Verwandten des Kaisers leben auf dem Amba Geshen, damit sie keinen Aufstand anzetteln.",
       {"year_min": 1444},
       [opt("Die alte Sitte bewahren.", {"mods": {"unrest": -0.25}}, 60),
        opt("Einen Prinzen als Statthalter einsetzen.", {"adm": 40, "mods": {"unrest": 0.25}}),
        opt("Die Prinzen erziehen lassen.", {"prestige": 10, "dip": 20})]),
]


def main():
    # nations: playable flag (one line per nation, keep the layout)
    path = os.path.join(ROOT, "data/nations.json")
    lines = open(path, encoding="utf-8").read().split("\n")
    for i, l in enumerate(lines):
        mt = re.match(r'  "([A-Z]{3})": ', l)
        if mt and mt.group(1) in PLAYABLE and '"playable": true' not in l:
            lines[i] = l.replace('"emoji": ', '"playable": true, "emoji": ', 1) if '"emoji": ' in l else l
            assert '"playable": true' in lines[i], mt.group(1)
    out = "\n".join(lines)
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)
    # missions: national block before rivalry/era missions
    path = os.path.join(ROOT, "data/missions.json")
    data = json.load(open(path, encoding="utf-8"))
    for tag in PLAYABLE:
        old = [x for x in data.get(tag, []) if "_np_" not in x["id"]]
        keep = [x for x in old if "_riv_" not in x["id"]]
        riv = [x for x in old if "_riv_" in x["id"]]
        data[tag] = keep + MISSIONS[tag] + riv
    ids = [x["id"] for v in data.values() for x in v]
    assert len(ids) == len(set(ids))
    out = "{\n" + ",\n".join('  "%s": [\n' % tag + ",\n".join(render_mission(x) for x in ms) + "\n  ]" for tag, ms in data.items()) + "\n}\n"
    json.loads(out)
    open(path, "w", encoding="utf-8").write(out)
    replace_block("np_", EVENTS)
    print("playable", PLAYABLE, "missions", {t: len(data[t]) for t in PLAYABLE}, "events", len(EVENTS))


if __name__ == "__main__":
    main()
