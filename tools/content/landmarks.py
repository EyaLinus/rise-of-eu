"""Historical landmarks (data/landmarks.json): medium prestige buildings on single provinces.

Unlike the great works (data/monuments.json, one per realm in the capital) a landmark belongs to its
province: whoever owns the province owns the landmark. Many already stand in 1444 (start level 1-3),
others can only be founded later (tech requirement). Owners raise them to level 3 with gold.
Landmarks with a "nation" are bound to that realm: only it may build and raise them, and a foreign
owner gets just half of the realm-wide bonus (the local effects stay in full).

Effects are per level: KINDS gives every landmark of a kind its base effects, "extra" adds
landmark-specific ones. Run: python3 tools/content/landmarks.py
"""
import json, os

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "landmarks.json")

# per level: local = province effects (Economy.refresh_local keys), nation = realm modifiers (Game.mod keys)
KINDS = {
    "church":   {"emoji": "⛪", "local": {"unrest": -0.4}, "nation": {"prestige": 0.15, "estate_klerus": 1.0}},
    "mosque":   {"emoji": "🕌", "local": {"unrest": -0.4}, "nation": {"prestige": 0.15, "estate_klerus": 1.0}},
    "palace":   {"emoji": "🏰", "local": {"tax": 0.1}, "nation": {"prestige": 0.3, "dip": 0.1}},
    "fortress": {"emoji": "🛡️", "local": {"manpower": 0.15, "unrest": -0.3}, "nation": {"force_limit": 0.5, "prestige": 0.1}},
    "port":     {"emoji": "⚓", "local": {"trade_power": 0.25, "trade_flat": 1.0}, "nation": {"trade": 0.01, "naval": 0.02, "prestige": 0.1}},
    "school":   {"emoji": "🎓", "local": {"unrest": -0.2}, "nation": {"tech_cost": -0.01, "adm": 0.05, "prestige": 0.1}},
    "market":   {"emoji": "🏦", "local": {"trade_power": 0.3, "tax": 0.1}, "nation": {"income": 0.01, "prestige": 0.1}},
    "temple":   {"emoji": "🗿", "local": {"unrest": -0.3, "tax": 0.05}, "nation": {"prestige": 0.25}},
}

# (id, province key, name, kind, start level, bound nation, tech [cat, lvl] for level 1, cost factor, extra nation fx, text)
L = [
    # England
    ("westminster", "london", "Westminster Abbey", "church", 2, "", None, 1.0, {}, "Krönungskirche der englischen Könige."),
    ("tower_london", "london", "Tower of London", "fortress", 1, "ENG", None, 1.0, {"force_limit": 0.5}, "Burg, Kerker und Schatzkammer der Krone."),
    ("portsmouth", "wessex", "Königliche Werft Portsmouth", "port", 0, "ENG", ["dip", 5], 1.2, {"naval": 0.03}, "Trockendock und Werft der königlichen Flotte."),
    ("oxford", "midlands", "Universität Oxford", "school", 1, "", None, 1.0, {}, "Älteste Universität der englischsprachigen Welt."),
    ("york_minster", "york", "York Minster", "church", 1, "", None, 1.0, {}, "Gotische Kathedrale des Nordens."),
    ("edinburgh", "lothian", "Edinburgh Castle", "fortress", 1, "", None, 1.0, {}, "Die Burg auf dem Vulkanfelsen über Edinburgh."),
    ("trinity_dublin", "pale", "Trinity College", "school", 0, "", ["adm", 7], 1.0, {}, "Kolleg in Dublin, gegründet 1592."),
    # France
    ("notre_dame", "paris", "Notre-Dame de Paris", "church", 2, "", None, 1.0, {}, "Die Kathedrale auf der Île de la Cité."),
    ("louvre", "paris", "Louvre", "palace", 1, "FRA", None, 1.0, {}, "Festung, dann Residenz der französischen Könige."),
    ("versailles", "paris", "Schloss Versailles", "palace", 0, "FRA", ["adm", 13], 1.6, {"prestige": 0.3, "estate_adel": 1.0}, "Der Hof des Sonnenkönigs, Vorbild für ganz Europa."),
    ("chartres", "orleans", "Kathedrale von Chartres", "church", 1, "", None, 1.0, {}, "Glasfenster, die ganz Europa bewundert."),
    ("mont_st_michel", "normandy", "Mont-Saint-Michel", "church", 1, "", None, 1.0, {"force_limit": 0.25}, "Kloster und Festung im Wattenmeer."),
    ("avignon", "provence", "Papstpalast Avignon", "palace", 1, "", None, 1.0, {"estate_klerus": 1.0}, "Sitz der Päpste im 14. Jahrhundert."),
    ("carcassonne", "languedoc", "Carcassonne", "fortress", 1, "", None, 1.0, {}, "Doppelter Mauerring über der Aude."),
    ("bordeaux_port", "bordeaux", "Hafen von Bordeaux", "port", 1, "", None, 1.0, {}, "Weinhandel mit ganz Nordeuropa."),
    ("lyon_fairs", "lyon", "Messen von Lyon", "market", 1, "", None, 1.0, {}, "Seide, Bücher und Wechselbriefe."),
    # Spain, Aragon, Granada
    ("sevilla_port", "sevilla", "Hafen von Sevilla", "port", 0, "SPA", ["dip", 6], 1.3, {"colony_cost": -0.05, "trade": 0.01}, "Casa de Contratación: alle Schiffe aus der Neuen Welt laufen hier ein."),
    ("giralda", "sevilla", "Kathedrale von Sevilla", "church", 1, "", None, 1.0, {}, "Größte gotische Kirche der Welt mit der Giralda."),
    ("escorial", "toledo", "El Escorial", "palace", 0, "SPA", ["adm", 10], 1.5, {"prestige": 0.2, "estate_klerus": 1.0}, "Kloster, Palast und Grablege Philipps II."),
    ("toledo_cathedral", "toledo", "Kathedrale von Toledo", "church", 1, "", None, 1.0, {}, "Sitz des Primas von Spanien."),
    ("santiago", "galicia", "Santiago de Compostela", "church", 2, "", None, 1.0, {}, "Ziel des Jakobswegs."),
    ("burgos_cathedral", "burgos", "Kathedrale von Burgos", "church", 1, "", None, 1.0, {}, "Gotik aus Kastiliens Wollhandel."),
    ("salamanca", "leon", "Universität Salamanca", "school", 1, "", None, 1.0, {}, "Hier wird über das Völkerrecht der Neuen Welt gestritten."),
    ("alhambra", "granada", "Alhambra", "palace", 2, "", None, 1.0, {}, "Palaststadt der Nasriden."),
    ("llotja", "barcelona", "Llotja de Mar", "market", 1, "", None, 1.0, {"naval": 0.02}, "Seehandelsbörse und Konsulat des Meeres."),
    ("lonja_seda", "valencia", "Seidenbörse Valencia", "market", 0, "", ["dip", 3], 1.0, {}, "Prunkvolle Börse der Seidenhändler (1482)."),
    ("aljaferia", "zaragoza", "Aljafería", "palace", 1, "", None, 1.0, {}, "Maurischer Palast der Könige von Aragón."),
    # Portugal
    ("casa_india", "lisbon", "Casa da Índia & Torre de Belém", "port", 0, "POR", ["dip", 4], 1.3, {"trade": 0.015, "colony_cost": -0.05}, "Gewürzhandel und Krone kontrollieren jede Fahrt nach Indien."),
    ("jeronimos", "lisbon", "Hieronymitenkloster", "church", 0, "POR", ["adm", 6], 1.2, {"prestige": 0.1}, "Manuelinische Pracht aus dem Pfefferhandel."),
    ("sagres", "algarve", "Seefahrerschule Sagres", "school", 0, "POR", ["dip", 3], 1.0, {"naval": 0.03}, "Kartographen und Kapitäne Heinrichs des Seefahrers."),
    ("coimbra", "porto", "Universität Coimbra", "school", 1, "", None, 1.0, {}, "Gelehrte für Krone und Kirche."),
    # Bohemia
    ("prague_castle", "prague", "Prager Burg", "palace", 2, "BOH", None, 1.0, {}, "Größte Burganlage Europas über der Moldau."),
    ("charles_bridge", "prague", "Karlsbrücke", "market", 1, "", None, 1.0, {}, "Steinbrücke mit Handel und Zoll."),
    ("carolinum", "prague", "Karlsuniversität", "school", 1, "", None, 1.0, {}, "Älteste Universität Mitteleuropas."),
    ("karlstein", "pilsen", "Burg Karlštejn", "fortress", 1, "BOH", None, 1.0, {"prestige": 0.1}, "Hier liegen die Reichskleinodien."),
    ("kutna_hora", "moravia", "Silberstadt Kuttenberg", "market", 1, "", None, 1.0, {}, "Silberbergbau und Münzstätte."),
    # Austria
    ("stephansdom", "wien", "Stephansdom", "church", 1, "", None, 1.0, {}, "Das Wahrzeichen Wiens."),
    ("hofburg", "wien", "Hofburg", "palace", 1, "HAB", None, 1.0, {"dip": 0.05}, "Residenz der Habsburger."),
    ("schoenbrunn", "wien", "Schloss Schönbrunn", "palace", 0, "HAB", ["adm", 12], 1.5, {"prestige": 0.25}, "Das habsburgische Versailles."),
    ("goldenes_dachl", "tirol", "Goldenes Dachl", "palace", 1, "", None, 0.8, {}, "Prunkerker Maximilians in Innsbruck."),
    ("graz_arsenal", "steiermark", "Landeszeughaus Graz", "fortress", 0, "HAB", ["mil", 6], 1.0, {"force_limit": 0.5}, "Waffen für die Abwehr der Osmanen."),
    # Russia
    ("kremlin", "moscow", "Moskauer Kreml", "fortress", 2, "RUS", None, 1.0, {"prestige": 0.15}, "Burg, Kirchen und Paläste der Zaren."),
    ("st_basil", "moscow", "Basilius-Kathedrale", "church", 0, "RUS", ["adm", 7], 1.3, {"prestige": 0.1}, "Gebaut zum Sieg über Kasan (1561)."),
    ("trinity_lavra", "vladimir", "Dreifaltigkeitskloster", "church", 1, "", None, 1.0, {}, "Geistiges Herz der russischen Kirche."),
    ("sophia_novgorod", "novgorod", "Sophienkathedrale Nowgorod", "church", 1, "", None, 1.0, {}, "Kirche der freien Handelsrepublik."),
    ("peterhof_hansa", "novgorod", "Peterhof (Hansekontor)", "market", 1, "", None, 1.0, {}, "Pelze und Wachs gegen Tuch und Salz."),
    ("kiev_lavra", "kiev", "Kiewer Höhlenkloster", "church", 2, "", None, 1.0, {}, "Mutterkloster der Rus."),
    ("smolensk", "smolensk", "Festung Smolensk", "fortress", 0, "", ["mil", 5], 1.0, {}, "Der Schlüssel zwischen Moskau und Litauen."),
    # Naples, Sicily, Papacy, Italy
    ("castel_nuovo", "napoli", "Castel Nuovo", "fortress", 1, "NAP", None, 1.0, {}, "Triumphbogen Alfons' von Aragón."),
    ("caserta", "napoli", "Königspalast Caserta", "palace", 0, "NAP", ["adm", 14], 1.5, {"prestige": 0.2}, "Größter Palast des Barock."),
    ("monte_cassino", "abruzzo", "Montecassino", "church", 1, "", None, 1.0, {}, "Mutterkloster der Benediktiner."),
    ("san_nicola", "apulia", "Basilika San Nicola", "church", 1, "", None, 1.0, {}, "Pilgerziel in Bari."),
    ("palermo_palace", "sicily", "Normannenpalast Palermo", "palace", 1, "", None, 1.0, {}, "Mosaiken aus Byzanz, Arabien und dem Norden."),
    ("st_peter", "rome", "Petersdom", "church", 1, "", ["adm", 6], 1.6, {"prestige": 0.2}, "Neubau ab 1506: die größte Kirche der Christenheit."),
    ("colosseum", "rome", "Kolosseum", "temple", 2, "", None, 1.0, {}, "Ruine des alten Rom, Ziel aller Reisenden."),
    ("florence_duomo", "florence", "Dom von Florenz", "church", 2, "", None, 1.0, {}, "Brunelleschis Kuppel."),
    ("medici_bank", "florence", "Bank der Medici", "market", 1, "", None, 1.0, {"income": 0.01}, "Wechsel und Kredite für Päpste und Könige."),
    ("siena_duomo", "siena", "Dom von Siena", "church", 1, "", None, 1.0, {}, "Gestreifter Marmor über der Stadt."),
    ("bologna_univ", "bologna", "Universität Bologna", "school", 2, "", None, 1.0, {}, "Älteste Universität Europas."),
    ("milan_duomo", "milan", "Mailänder Dom", "church", 1, "", None, 1.0, {}, "Seit 1386 im Bau."),
    ("san_giorgio", "genoa", "Banco di San Giorgio", "market", 2, "", None, 1.0, {"income": 0.01}, "Die Bank, die Genua regiert."),
    # Venice
    ("doge_palace", "venice", "Dogenpalast", "palace", 2, "VEN", None, 1.0, {}, "Regierungssitz der Serenissima."),
    ("arsenale", "venice", "Arsenal von Venedig", "port", 2, "VEN", None, 1.0, {"naval": 0.04}, "Eine Galeere am Tag."),
    ("san_marco", "venice", "Markusdom", "church", 1, "", None, 1.0, {}, "Goldene Mosaiken und Beute aus Byzanz."),
    ("padua_univ", "verona", "Universität Padua", "school", 1, "", None, 1.0, {}, "Anatomie und Astronomie."),
    ("candia", "crete", "Festung Candia", "fortress", 1, "", None, 1.0, {}, "Venedigs Bollwerk im Ägäischen Meer."),
    # Poland-Lithuania, Prussia
    ("wawel", "krakow", "Wawel", "palace", 2, "POL", None, 1.0, {}, "Burg und Krönungskathedrale der polnischen Könige."),
    ("jagiellonian", "krakow", "Jagiellonen-Universität", "school", 1, "", None, 1.0, {}, "Hier studiert Kopernikus."),
    ("wieliczka", "krakow", "Salzbergwerk Wieliczka", "market", 1, "", None, 1.0, {}, "Das weiße Gold der Krone."),
    ("warsaw_castle", "warsaw", "Königsschloss Warschau", "palace", 0, "POL", ["adm", 6], 1.2, {"dip": 0.05}, "Neue Hauptstadt der Republik beider Nationen."),
    ("lwow_cathedral", "lwow", "Kathedrale von Lemberg", "church", 1, "", None, 1.0, {}, "Drei Konfessionen in einer Stadt."),
    ("marienburg", "marienburg", "Marienburg", "fortress", 2, "", None, 1.0, {}, "Größte Backsteinburg der Welt."),
    ("vilnius_castle", "vilnius", "Burg Vilnius", "fortress", 1, "", None, 1.0, {}, "Sitz der Großfürsten von Litauen."),
    # Hungary
    ("buda_castle", "buda", "Burg Buda", "palace", 2, "HUN", None, 1.0, {}, "Renaissancehof von Matthias Corvinus."),
    ("corviniana", "buda", "Bibliotheca Corviniana", "school", 0, "HUN", ["adm", 4], 1.0, {"tech_cost": -0.01}, "Eine der größten Bibliotheken Europas."),
    ("pressburg_dom", "pressburg", "Martinsdom Pressburg", "church", 1, "", None, 1.0, {}, "Krönungskirche der ungarischen Könige."),
    ("temesvar", "temes", "Festung Temeswar", "fortress", 1, "HUN", None, 1.0, {}, "Grenzfestung gegen die Osmanen."),
    ("kassa_dom", "kassa", "Elisabethdom Kaschau", "church", 1, "", None, 1.0, {}, "Gotik am Handelsweg nach Polen."),
    ("fortified_churches", "transylvania", "Kirchenburgen Siebenbürgens", "fortress", 1, "", None, 0.8, {}, "Die Dörfer verteidigen sich selbst."),
    # Holy Roman Empire, North
    ("cologne_dom", "cologne", "Kölner Dom", "church", 1, "", None, 1.0, {}, "Unvollendet, aber schon riesig."),
    ("kaiserburg", "nuremberg", "Kaiserburg Nürnberg", "fortress", 1, "", None, 1.0, {}, "Hier halten die Kaiser Hof."),
    ("frauenkirche", "munich", "Frauenkirche München", "church", 0, "", ["adm", 3], 0.8, {}, "Zwei Türme mit welschen Hauben (1488)."),
    ("heidelberg", "palatinate", "Universität Heidelberg", "school", 1, "", None, 1.0, {}, "Älteste Universität im Reich."),
    ("leipzig_univ", "leipzig", "Universität Leipzig", "school", 1, "", None, 1.0, {}, "Gelehrte und Buchdrucker."),
    ("zwinger", "dresden", "Zwinger", "palace", 0, "", ["adm", 12], 1.3, {}, "Barocke Festkulisse der Kurfürsten."),
    ("berlin_palace", "berlin", "Berliner Schloss", "palace", 0, "", ["adm", 8], 1.2, {}, "Residenz der Hohenzollern."),
    ("hamburg_port", "hamburg", "Hamburger Hafen", "port", 1, "", None, 1.0, {}, "Tor der Hanse zur Nordsee."),
    ("kronborg", "copenhagen", "Schloss Kronborg", "fortress", 0, "", ["mil", 5], 1.2, {"trade": 0.02}, "Hier zahlt jedes Schiff den Sundzoll."),
    ("tre_kronor", "stockholm", "Schloss Tre Kronor", "palace", 1, "", None, 1.0, {}, "Burg der schwedischen Könige."),
    ("bryggen", "bergen", "Bryggen", "market", 1, "", None, 1.0, {}, "Deutsche Brücke, Stockfisch für Europa."),
    ("riga_hansa", "riga", "Hansestadt Riga", "market", 1, "", None, 1.0, {}, "Getreide und Holz aus dem Osten."),
    ("bruges", "flanders", "Börse von Brügge", "market", 2, "", None, 1.0, {}, "Die erste Börse der Welt."),
    # Burgundy
    ("dijon_palace", "dijon", "Herzogspalast Dijon", "palace", 1, "BUR", None, 1.0, {}, "Prunkvollster Hof des Abendlandes."),
    ("beaune", "dijon", "Hospiz von Beaune", "church", 1, "", None, 0.8, {}, "Hôtel-Dieu mit buntem Ziegeldach (1443)."),
    ("antwerp_bourse", "brabant", "Börse Antwerpen", "market", 0, "BUR", ["dip", 6], 1.3, {"income": 0.01}, "Handelsplatz der ganzen Welt (1531)."),
    ("leuven", "brabant", "Universität Löwen", "school", 1, "", None, 1.0, {}, "Humanisten wie Erasmus."),
    ("amsterdam_port", "holland", "Hafen von Amsterdam", "port", 0, "", ["dip", 5], 1.2, {}, "Ostindienfahrer und Getreidespeicher."),
    # Ottomans, Byzantium, Balkans
    ("hagia_sophia", "constantinople", "Hagia Sophia", "church", 2, "", None, 1.0, {"prestige": 0.15}, "Tausend Jahre die größte Kirche der Welt."),
    ("topkapi", "constantinople", "Topkapı-Palast", "palace", 0, "TUR", ["adm", 3], 1.3, {"prestige": 0.2}, "Sitz des Sultans am Bosporus (1459)."),
    ("suleymaniye", "constantinople", "Süleymaniye-Moschee", "mosque", 0, "TUR", ["adm", 9], 1.4, {"prestige": 0.15}, "Sinans Meisterwerk für Süleyman."),
    ("selimiye", "edirne", "Selimiye-Moschee", "mosque", 0, "TUR", ["adm", 11], 1.3, {"prestige": 0.1}, "Sinans größte Kuppel."),
    ("bursa_mosque", "bursa", "Große Moschee Bursa", "mosque", 2, "", None, 1.0, {}, "Zwanzig Kuppeln der ersten Hauptstadt."),
    ("mevlana", "konya", "Mevlana-Kloster", "mosque", 1, "", None, 1.0, {}, "Grab Rumis, Ziel der tanzenden Derwische."),
    ("mystras", "morea", "Mystras", "palace", 1, "", None, 1.0, {}, "Letzte Blüte von Byzanz."),
    ("rhodes", "rhodes", "Großmeisterpalast Rhodos", "fortress", 2, "", None, 1.0, {}, "Bollwerk der Johanniter."),
    # Persia, Mesopotamia
    ("blue_mosque_tabriz", "tabriz", "Blaue Moschee Täbris", "mosque", 0, "QAR", ["adm", 3], 1.0, {"prestige": 0.1}, "Gestiftet von Dschahan Schah (1465)."),
    ("tabriz_bazaar", "tabriz", "Basar von Täbris", "market", 2, "", None, 1.0, {}, "Größter überdachter Basar der Welt."),
    ("van_fortress", "van", "Festung Van", "fortress", 1, "", None, 1.0, {}, "Uralte Felsenburg am See."),
    ("baghdad_bazaar", "baghdad", "Basare von Bagdad", "market", 1, "", None, 1.0, {}, "Handel zwischen Indien und dem Mittelmeer."),
    ("naqsh_jahan", "isfahan", "Platz Naqsch-e Dschahan", "palace", 0, "", ["adm", 12], 1.5, {}, "„Abbild der Welt“ der Safawiden."),
    ("hormuz_port", "hormuz", "Hafen von Hormus", "port", 2, "", None, 1.0, {}, "Perlen, Pferde und Gewürze."),
    # Mamluks, Levant, Arabia
    ("al_azhar", "cairo", "Al-Azhar", "school", 2, "", None, 1.0, {"estate_klerus": 1.0}, "Älteste Hochschule der islamischen Welt."),
    ("cairo_citadel", "cairo", "Zitadelle von Kairo", "fortress", 1, "MAM", None, 1.0, {}, "Sitz der Mamlukensultane."),
    ("pyramids", "cairo", "Pyramiden von Gizeh", "temple", 3, "", None, 1.0, {}, "Das letzte erhaltene Weltwunder der Antike."),
    ("alexandria_port", "alexandria", "Hafen von Alexandria", "port", 1, "", None, 1.0, {}, "Pfeffer für Venedig und Genua."),
    ("dome_rock", "jerusalem", "Felsendom", "mosque", 2, "", None, 1.0, {}, "Goldene Kuppel über Jerusalem."),
    ("holy_sepulchre", "jerusalem", "Grabeskirche", "church", 2, "", None, 1.0, {}, "Ziel der christlichen Pilger."),
    ("umayyad", "damascus", "Umayyaden-Moschee", "mosque", 2, "", None, 1.0, {}, "Eine der ältesten Großmoscheen."),
    ("aleppo_citadel", "aleppo", "Zitadelle von Aleppo", "fortress", 1, "", None, 1.0, {}, "Auf dem Burgberg mitten in der Stadt."),
    ("masjid_haram", "mecca", "Heilige Moschee", "mosque", 3, "", None, 1.0, {"prestige": 0.1}, "Die Kaaba, Ziel der Hadsch."),
    ("prophet_mosque", "medina", "Prophetenmoschee", "mosque", 2, "", None, 1.0, {}, "Grab des Propheten."),
    ("aden_port", "aden", "Hafen von Aden", "port", 1, "", None, 1.0, {}, "Zwischen Indien und dem Roten Meer."),
    # Ethiopia, Horn
    ("lalibela", "amhara", "Felsenkirchen von Lalibela", "church", 2, "ETH", None, 1.0, {"prestige": 0.1}, "Ein neues Jerusalem aus dem Fels."),
    ("aksum", "tigray", "Maria-Zion-Kathedrale Aksum", "church", 1, "", None, 1.0, {}, "Hier ruht die Bundeslade, sagt man."),
    ("gondar", "begemder", "Fasil Ghebbi", "palace", 0, "ETH", ["adm", 8], 1.2, {"prestige": 0.15}, "Burgstadt der Kaiser in Gondar."),
    ("harar_jugol", "harar", "Mauern von Harar", "fortress", 1, "", None, 1.0, {}, "Stadt der Heiligen und des Kaffees."),
    # Maghreb, West Africa
    ("zitouna", "tunis", "Zitouna-Moschee", "mosque", 2, "", None, 1.0, {}, "Gelehrsamkeit in Tunis."),
    ("kairouan_mosque", "kairouan", "Große Moschee Kairouan", "mosque", 2, "", None, 1.0, {}, "Vierte heilige Stadt des Islam."),
    ("qarawiyyin", "fez", "Al-Qarawiyyin", "school", 2, "", None, 1.0, {}, "Seit 859 eine Hochschule."),
    ("koutoubia", "marrakesh", "Koutoubia-Moschee", "mosque", 1, "", None, 1.0, {}, "Ihr Minarett grüßt die Karawanen."),
    ("tlemcen_mosque", "tlemcen", "Große Moschee Tlemcen", "mosque", 1, "", None, 1.0, {}, "Perle des Maghreb."),
    ("sankore", "timbuktu", "Sankore-Universität", "school", 2, "", None, 1.0, {}, "Handschriften aus ganz Afrika."),
    ("djenne", "djenne", "Große Moschee Djenné", "mosque", 1, "", None, 1.0, {}, "Größter Lehmbau der Welt."),
    ("askia_tomb", "gao", "Grab der Askia", "temple", 0, "", ["adm", 4], 1.0, {}, "Lehmpyramide des Songhai-Herrschers (1495)."),
    ("benin_walls", "benin", "Mauern von Benin", "fortress", 1, "", None, 1.0, {}, "Erdwälle länger als die Chinesische Mauer."),
    ("mbanza_kongo", "kongo", "Mbanza Kongo", "palace", 1, "", None, 1.0, {}, "Königsstadt am Kongo."),
    # East and South Africa
    ("great_zimbabwe", "zimbabwe", "Great Zimbabwe", "temple", 2, "", None, 1.0, {}, "Steinerne Stadt der Goldhändler."),
    ("kilwa_port", "kilwa", "Hafen von Kilwa", "port", 1, "", None, 1.0, {}, "Gold aus Sofala für die Swahiliküste."),
    ("fort_jesus", "mombasa", "Fort Jesus", "fortress", 0, "", ["mil", 7], 1.0, {}, "Portugiesische Festung (1593)."),
    # Americas
    ("templo_mayor", "tenochtitlan", "Templo Mayor", "temple", 2, "", None, 1.0, {}, "Doppelpyramide im Herzen Tenochtitlans."),
    ("chichen_itza", "yucatan", "Chichén Itzá", "temple", 1, "", None, 1.0, {}, "Die Pyramide des Kukulcán."),
    ("cahokia", "cahokia", "Monks Mound", "temple", 1, "", None, 1.0, {}, "Der größte Erdhügel Nordamerikas."),
    ("el_morro", "havana", "Castillo del Morro", "fortress", 0, "", ["mil", 6], 1.0, {"naval": 0.02}, "Schützt die Silberflotte in Havanna."),
    ("coricancha", "cusco", "Coricancha", "temple", 2, "INC", None, 1.0, {"prestige": 0.1}, "Der Sonnentempel von Cusco, die Wände mit Gold verkleidet."),
    ("sacsayhuaman", "cusco", "Sacsayhuamán", "fortress", 0, "INC", ["mil", 2], 1.2, {}, "Mauern aus tonnenschweren Steinen über der Hauptstadt."),
    ("machu_picchu", "antisuyu", "Machu Picchu", "palace", 0, "INC", ["adm", 2], 1.0, {}, "Das Landgut Pachacútecs hoch über dem Urubamba."),
    ("chan_chan", "chan_chan", "Chan Chan", "palace", 1, "", None, 1.0, {}, "Die größte Lehmziegelstadt Amerikas."),
    # East Asia, Steppe, Malacca (playable since v1.1.2)
    ("forbidden_city", "beijing", "Verbotene Stadt", "palace", 2, "MNG", None, 1.2, {"prestige": 0.1}, "Der Kaiserpalast mit 980 Gebäuden."),
    ("great_wall_badaling", "xuanfu", "Große Mauer bei Badaling", "fortress", 1, "MNG", None, 1.2, {"force_limit": 0.5}, "Die Steinmauer vor den Pässen nördlich Pekings."),
    ("porcelain_tower", "nanjing", "Porzellanpagode von Nanjing", "temple", 1, "", None, 1.0, {}, "Neun Stockwerke aus glasierten Ziegeln."),
    ("hanlin", "beijing", "Hanlin-Akademie", "school", 1, "", None, 1.0, {}, "Die Gelehrten des Kaisers schreiben Geschichte und prüfen Beamte."),
    ("kinkakuji", "kyoto", "Goldener Pavillon", "temple", 2, "ASH", None, 1.0, {"prestige": 0.1}, "Der Pavillon Ashikaga Yoshimitsus am Spiegelteich."),
    ("ginkakuji", "kyoto", "Silberner Pavillon", "temple", 0, "ASH", ["adm", 3], 1.0, {}, "Teehaus und Sandgarten am Fuß der Ostberge."),
    ("himeji", "harima", "Burg Himeji", "fortress", 0, "", ["mil", 7], 1.0, {}, "Die Burg des Weißen Reihers."),
    ("erdene_zuu", "karakorum", "Kloster Erdene Zuu", "temple", 0, "MGL", ["adm", 5], 1.0, {}, "Das erste buddhistische Kloster der Mongolei, aus den Steinen Karakorums."),
    ("karakorum_ruins", "karakorum", "Ruinen von Karakorum", "palace", 1, "MGL", None, 1.0, {"prestige": 0.1}, "Hier stand der Palast der Großkhane."),
    ("potala", "lhasa", "Potala", "palace", 1, "", None, 1.0, {}, "Burg und Palast über Lhasa."),
    ("malacca_port", "malacca", "Hafen von Malakka", "port", 2, "MLC", None, 1.0, {"trade": 0.02}, "Hundert Sprachen am Kai der Meerenge."),
    ("malacca_palace", "malacca", "Istana des Sultans", "palace", 0, "MLC", ["adm", 2], 1.0, {}, "Ein Holzpalast mit siebenstufigem Dach."),
    ("niani_palace", "niani", "Hof des Mansa", "palace", 1, "MAL", None, 1.0, {"prestige": 0.1}, "Thronsaal mit Kuppel, gebaut von einem Baumeister aus Andalusien."),
]


def main():
    out = {}
    for (lid, prov, name, kind, start, nation, tech, cost, extra, text) in L:
        assert lid not in out, lid
        assert kind in KINDS, kind
        nat = dict(KINDS[kind]["nation"])
        for k, v in extra.items():
            nat[k] = round(nat.get(k, 0.0) + v, 4)
        d = {"name": name, "prov": prov, "kind": kind, "emoji": KINDS[kind]["emoji"], "start": start,
             "local": KINDS[kind]["local"], "nation": nat, "text": text}
        if nation:
            d["bound"] = nation
        if tech:
            d["tech"] = tech
        if cost != 1.0:
            d["cost"] = cost
        out[lid] = d
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("%d landmarks -> %s" % (len(out), OUT))


if __name__ == "__main__":
    main()
