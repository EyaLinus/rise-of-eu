"""Three more special national events for every playable nation except Hungary (which has tools/content/hungary.py)
(2026-11-17, Linus: "mehr besondere Nation-Events für alle playable nations").

Events "nx_*", tag-specific, placed before the gov_ block. Topics avoid the ones the older batches already cover.
Rules: every option is a real trade-off (checked with tools/event_value.py), permanent mods 0.02-0.04, war
options keep a low AI weight, cruelty always has a humane alternative.

Run: python3 tools/content/nation_events_v2.py
"""
import events_io


def ev(eid, tag, title, text, image, trigger, options):
    return {"id": "nx_" + eid, "tag": tag, "title": title, "text": text, "image": image, "trigger": trigger,
            "options": [dict(text=o[0], effects=o[1], **({"ai": o[2]} if len(o) > 2 else {})) for o in options]}


EVENTS = [
    # --- England
    ev("eng_wool_staple", "ENG", "Der Wollstapel von Calais",
       "Alle englische Wolle für den Kontinent muss über den Stapel in Calais. Die Tuchmacher in Suffolk wollen "
       "lieber selbst weben und Tuch statt Wolle verkaufen.",
       "market", {"year_min": 1444, "year_max": 1520},
       [("Den Stapel behalten: Zölle für die Krone.", {"gold": 90, "estate": {"buerger": -4}}, 50),
        ("Die Tuchmacher fördern.", {"mods": {"production": 0.03}, "gold": -40}),
        ("Flämische Weber ins Land holen.", {"dev_random": 1, "relations": {"BUR": 20}, "estate": {"buerger": -2}})]),
    ev("eng_dissolution", "ENG", "Die Auflösung der Klöster",
       "Die Klöster besitzen ein Viertel des Landes. Thomas Cromwell legt eine Liste vor: Sie alle könnten der "
       "Krone gehören.",
       "church", {"year_min": 1530, "year_max": 1560, "flag": "ev_eng_reformation"},
       [("Alles einziehen und an den Adel verkaufen.", {"gold": 150, "estate": {"klerus": -12, "adel": 5}}, 50),
        ("Nur die kleinen Klöster.", {"gold": 100, "estate": {"klerus": -4}}),
        ("Die Klöster als Schulen behalten.", {"adm": 60, "mods": {"tech_cost": -0.02}, "gold": -40})]),
    ev("eng_shakespeare", "ENG", "Ein Theater am Südufer",
       "Ein Schauspieler aus Stratford schreibt Stücke über die Könige Englands. Die Puritaner wollen die Theater "
       "schließen, die Königin lacht über seine Komödien.",
       "tavern", {"year_min": 1585, "year_max": 1625},
       [("Die Truppe unter königlichen Schutz stellen.", {"prestige": 15, "estate": {"klerus": -3}}, 50),
        ("Die Stücke sollen die Tudors loben.", {"adm": 30, "dip": 20}),
        ("Die Theater schließen.", {"estate": {"klerus": 6}, "gold": 30})]),
    # --- France
    ev("fra_jeanne_trial", "FRA", "Die Rehabilitierung der Jungfrau",
       "Zwanzig Jahre nach Rouen verlangt die Mutter Jeannes d'Arc einen neuen Prozess. Der König zögert: Er "
       "verdankt ihr die Krone, aber nicht gern.",
       "inquisition", {"year_max": 1460},
       [("Ein neuer Prozess, ein gerechtes Urteil.", {"prestige": 20, "relations": {"PAP": 20}, "gold": -30}, 60),
        ("Die Sache ruhen lassen.", {"adm": 40}),
        ("Die Engländer öffentlich anklagen.", {"mil": 30, "relations": {"ENG": -30}, "prestige": 5})]),
    ev("fra_loire", "FRA", "Schlösser an der Loire",
       "Der König hat Italien gesehen und will es zu Hause. Leonardo da Vinci soll in Amboise wohnen, Chambord "
       "soll das schönste Schloss der Welt werden.",
       "artist", {"year_min": 1495, "year_max": 1560},
       [("Chambord bauen lassen.", {"gold": -100, "prestige": 25, "dev_capital": 1}, 40),
        ("Den Meister holen, nicht das Schloss.", {"gold": -30, "mods": {"tech_cost": -0.02}}),
        ("Lieber Festungen an der Grenze.", {"mil": 50, "manpower": 1})]),
    ev("fra_nantes", "FRA", "Das Edikt von Nantes",
       "Nach dreißig Jahren Bürgerkrieg bietet der König den Hugenotten Sicherheitsplätze und Gewissensfreiheit "
       "an. Paris murrt, die Hugenotten trauen dem Frieden nicht.",
       "treaty", {"year_min": 1585, "year_max": 1630},
       [("Das Edikt verkünden.", {"mods": {"religious_unrest": -0.3}, "estate": {"klerus": -6}, "dip": 20}, 60),
        ("Nur Duldung, keine Festungen.", {"adm": 30, "estate": {"klerus": -2}, "prestige": 5}),
        ("Paris ist eine Messe wert: ein katholisches Reich.", {"estate": {"klerus": 8}, "relations": {"PAP": 30}, "convert_random": 1})]),
    # --- Spain
    ev("spa_salamanca", "SPA", "Die Schule von Salamanca",
       "Theologen in Salamanca fragen, ob die Völker der Neuen Welt Rechte haben und ob Preise gerecht sein müssen. "
       "Der Hof ist sich nicht sicher, ob er die Antwort hören will.",
       "scholar", {"year_min": 1520, "year_max": 1600},
       [("Ihre Gesetze für die Indios annehmen.", {"prestige": 15, "estate": {"klerus": 4, "adel": -4}}, 60),
        ("Nur die Wirtschaftslehre nutzen.", {"adm": 40, "mods": {"income": 0.02}, "gold": -40}),
        ("Die Gelehrten zum Schweigen bringen.", {"estate": {"adel": 5}, "gold": 40, "prestige": -10})]),
    ev("spa_mesta", "SPA", "Die Mesta",
       "Die Schafzüchtergilde treibt Millionen Merinoschafe quer durch Kastilien. Die Bauern klagen über zertrampelte "
       "Felder, die Mesta zahlt der Krone viel Geld.",
       "harvest", {"year_min": 1450, "year_max": 1600},
       [("Die Privilegien der Mesta bestätigen.", {"gold": 100, "dev_random": -1}, 50),
        ("Den Bauern Zäune erlauben.", {"dev_random": 1, "estate": {"adel": -4}, "gold": -20}),
        ("Wolle exportieren, aber besteuern.", {"mods": {"trade": 0.02}, "estate": {"adel": -2}})]),
    ev("spa_teresa", "SPA", "Teresa von Ávila",
       "Eine Nonne aus Ávila gründet arme, strenge Klöster und schreibt über ihre Visionen. Die Inquisition liest "
       "mit, das Volk verehrt sie schon jetzt als Heilige.",
       "church", {"year_min": 1555, "year_max": 1600},
       [("Ihre Reform unterstützen.", {"prestige": 10, "estate": {"klerus": 6}, "gold": -30}, 60),
        ("Der Inquisition die Bücher überlassen.", {"adm": 30, "estate": {"klerus": 3}}),
        ("Die reichen Klöster lieber besteuern.", {"gold": 80, "estate": {"klerus": -5}})]),
    # --- Bohemia
    ev("boh_kutna_hora", "BOH", "Der Prager Groschen",
       "Die Silberminen von Kuttenberg sind tiefer als je zuvor, und das Wasser steigt. Die Münzmeister wollen "
       "den Groschen strecken.",
       "mine", {"year_min": 1450, "year_max": 1600},
       [("Neue Pumpen und tiefere Stollen.", {"gold": -60, "mods": {"income": 0.03}}, 50),
        ("Den Groschen verdünnen.", {"gold": 120, "prestige": -10}),
        ("Die Bergleute selbst verwalten lassen.", {"estate": {"buerger": 6}, "adm": 30})]),
    ev("boh_tycho", "BOH", "Der Astronom mit der Silbernase",
       "Tycho Brahe sucht einen neuen Herrn. Er bringt Instrumente, einen Elch und einen jungen Gehilfen namens "
       "Kepler mit.",
       "scholar", {"year_min": 1595, "year_max": 1610},
       [("Beide an den Hof holen.", {"gold": -50, "mods": {"tech_cost": -0.03}}, 50),
        ("Nur die Horoskope für den Kaiser.", {"prestige": 10, "dip": 20}),
        ("Der Hof hat schon genug Sonderlinge.", {"gold": 30, "adm": 30})]),
    ev("boh_hussite_hymns", "BOH", "Die Gesangbücher der Utraquisten",
       "In den Dörfern singen sie die Messe auf Tschechisch und reichen den Kelch an alle. Rom verlangt das Ende "
       "der Kompaktaten.",
       "printing", {"year_min": 1460, "year_max": 1580},
       [("Die Kompaktaten verteidigen.", {"prestige": 10, "estate": {"buerger": 5}, "relations": {"PAP": -30}}, 50),
        ("Nachgeben, aber langsam.", {"relations": {"PAP": 30}, "dip": 30, "estate": {"buerger": -3}}),
        ("Die Bücher drucken und verkaufen.", {"gold": 60, "mods": {"production": 0.01}})]),
    # --- Habsburg
    ev("hab_tirol_mines", "HAB", "Das Bergwerk am Inn",
       "Die Fugger bieten an, die Tiroler Silberbergwerke für zehn Jahre zu pachten. Das Geld wäre sofort da.",
       "bank", {"year_min": 1480, "year_max": 1560},
       [("Verpachten.", {"gold": 120, "mods": {"income": -0.02}}, 40),
        ("Selbst betreiben.", {"gold": -20, "mods": {"production": 0.04}}),
        ("Gegen einen Kredit für den Krieg tauschen.", {"regs": 5, "estate": {"buerger": -3}})]),
    ev("hab_spanish_riding", "HAB", "Pferde aus Spanien",
       "Aus Spanien kommen Lipizzaner nach Wien. Der Hof will eine Reitschule bauen, die Generäle wollen "
       "Kürassiere.",
       "court", {"year_min": 1560, "year_max": 1644},
       [("Eine Hofreitschule bauen.", {"gold": -20, "prestige": 20}, 50),
        ("Kürassiere ausrüsten.", {"mods": {"combat": 0.03}, "gold": -30}),
        ("Die Zucht verkaufen.", {"gold": 50})]),
    ev("hab_military_border", "HAB", "Die Militärgrenze",
       "Kroaten, Serben und Walachen siedeln an der Grenze zum Sultan. Sie bekommen Land, wenn sie jederzeit "
       "zur Waffe greifen.",
       "border", {"year_min": 1522, "year_max": 1644, "alive": "TUR"},
       [("Die Militärgrenze einrichten.", {"mods": {"manpower": 0.04}, "estate": {"adel": -4}}, 60),
        ("Die Grenzer besteuern.", {"gold": 80, "manpower": -1}),
        ("Burgen statt Bauern.", {"gold": -50, "mil": 50})]),
    # --- Russia
    ev("rus_pskov", "RUS", "Die Glocke von Pskow",
       "Pskow ist die letzte freie Stadtrepublik der Rus. Ihre Wetsche-Glocke ruft das Volk zur Versammlung. Der "
       "Großfürst will sie nach Moskau bringen lassen.",
       "city", {"year_min": 1470, "year_max": 1530},
       [("Die Glocke abnehmen.", {"adm": 40, "prestige": 5, "estate": {"buerger": -5}}, 60),
        ("Pskow seine Rechte lassen, gegen Tribut.", {"gold": 70, "dip": 20}),
        ("Die Kaufleute nach Moskau umsiedeln.", {"dev_capital": 1, "estate": {"buerger": -3}, "prestige": -5})]),
    ev("rus_stroganov", "RUS", "Die Stroganows",
       "Eine Kaufmannsfamilie bietet an, den Ural auf eigene Kosten zu besiedeln: Salzsiedereien, Festungen, "
       "Kosaken. Sie wollen dafür Steuerfreiheit für zwanzig Jahre.",
       "steppe", {"year_min": 1550, "year_max": 1620},
       [("Den Freibrief ausstellen.", {"mods": {"production": 0.03}, "estate": {"buerger": 5}}, 60),
        ("Nur gegen Abgaben.", {"gold": 80, "estate": {"buerger": -3}}),
        ("Die Krone besiedelt selbst.", {"gold": -50, "adm": 40, "dev_random": 1})]),
    ev("rus_printing", "RUS", "Der erste Drucker Moskaus",
       "Iwan Fjodorow hat den ersten Apostel in Moskau gedruckt. Die Schreiber fürchten um ihr Brot und brennen "
       "nachts seine Werkstatt nieder.",
       "printing", {"year_min": 1550, "year_max": 1600},
       [("Eine neue Druckerei unter Schutz des Zaren.", {"gold": -40, "mods": {"tech_cost": -0.02}}, 50),
        ("Er soll nach Litauen gehen.", {"relations": {"LIT": 20}, "estate": {"klerus": 5}}),
        ("Die Schreiber bekommen Recht.", {"estate": {"klerus": 6}, "adm": 20})]),
    # --- Naples
    ev("nap_castel_nuovo", "NAP", "Der Triumphbogen",
       "Alfonso will den Eingang des Castel Nuovo mit einem marmornen Triumphbogen schmücken, wie die Kaiser "
       "in Rom.",
       "artist", {"year_max": 1470},
       [("Den Bogen bauen.", {"gold": -60, "prestige": 20}, 50),
        ("Die Mauern verstärken statt schmücken.", {"mil": 40, "gold": -10}),
        ("Die Künstler nach Mailand verkaufen.", {"gold": 50, "relations": {"MLO": 20}})]),
    ev("nap_silk", "NAP", "Seide aus Kalabrien",
       "In Kalabrien wachsen Maulbeerbäume an jedem Hang. Kaufleute aus Florenz wollen die Rohseide billig "
       "kaufen, die Zünfte wollen sie in Neapel weben.",
       "market", {"year_min": 1450, "year_max": 1620},
       [("Die Seidenweberei in Neapel fördern.", {"mods": {"production": 0.03}, "gold": -40}, 50),
        ("An Florenz verkaufen.", {"gold": 90, "relations": {"TUS": 20}}),
        ("Ein Monopol der Krone.", {"gold": 50, "estate": {"buerger": -5}, "adm": 20})]),
    ev("nap_giordano", "NAP", "Ein Mönch aus Nola",
       "Giordano Bruno lehrt, das Universum sei unendlich und voller Welten. Die Inquisition in Rom fordert seine "
       "Auslieferung.",
       "inquisition", {"year_min": 1570, "year_max": 1610},
       [("Ausliefern.", {"relations": {"PAP": 40}, "estate": {"klerus": 5}, "prestige": -5}, 50),
        ("Ihn fliehen lassen.", {"dip": 30, "estate": {"klerus": -3}}),
        ("Ihn heimlich an der Universität lehren lassen.", {"mods": {"tech_cost": -0.02}, "relations": {"PAP": -30}})]),
    # --- Burgundy
    ev("bur_tapestries", "BUR", "Die Teppiche von Arras",
       "Die Weber von Arras und Tournai bekommen Aufträge aus ganz Europa. Ein einziger Wandteppich kostet so viel "
       "wie ein Regiment.",
       "market", {"year_min": 1444, "year_max": 1550},
       [("Als Geschenke an fremde Höfe.", {"dip": 40, "relations": {"FRA": 15, "ENG": 15}, "gold": -20}, 50),
        ("Exportzölle erheben.", {"gold": 80, "estate": {"buerger": -3}}),
        ("Den Zünften Privilegien geben.", {"mods": {"production": 0.02}, "estate": {"buerger": 4}})]),
    ev("bur_banquet", "BUR", "Das Fasanenfest",
       "In Lille schwören die Ritter des Hofes auf einen lebenden Fasan, gegen die Türken zu ziehen. Das Fest "
       "kostet mehr als ein Feldzug.",
       "court", {"year_max": 1470},
       [("Das Gelübde halten und Truppen schicken.", {"prestige": 15, "mil": -30, "relations": {"PAP": 30}}, 40),
        ("Ein schönes Fest war es trotzdem.", {"prestige": 10, "gold": -40, "estate": {"adel": 4}}),
        ("Das Geld lieber sparen.", {"gold": 60, "estate": {"adel": -3}})]),
    ev("bur_dikes", "BUR", "Die Polder",
       "Holländische Deichbauer wollen mit Windmühlen ganze Seen trockenlegen. Neues Land, aber nur, wenn die "
       "Deiche halten.",
       "harvest", {"year_min": 1500, "year_max": 1644, "owns": ["holland"]},
       [("Die Seen trockenlegen.", {"gold": -80, "dev_random": 2}, 50),
        ("Nur die Deiche verstärken.", {"gold": -30, "adm": 40}),
        ("Die Deichgrafen sollen es selbst bezahlen.", {"estate": {"buerger": -4}, "dev_random": 1})]),
    # --- Portugal
    ev("por_lisbon_quake", "POR", "Die Casa da Índia",
       "Alle Waren aus Indien müssen über das Haus Indiens in Lissabon. Die Händler aus Antwerpen bieten an, den "
       "ganzen Pfeffer auf einmal zu kaufen.",
       "bank", {"year_min": 1500, "year_max": 1600},
       [("Alles an Antwerpen verkaufen.", {"gold": 130, "mods": {"trade": -0.01}}, 50),
        ("Lissabon soll der Markt sein.", {"mods": {"trade": 0.03}, "gold": -30}),
        ("Die Krone handelt selbst, mit eigenen Agenten.", {"adm": 30, "dip": 30})]),
    ev("por_camoes", "POR", "Die Lusiaden",
       "Ein einäugiger Soldat ist aus Indien zurückgekehrt. Er hat ein Epos über Vasco da Gama geschrieben und "
       "es schwimmend aus einem Schiffbruch gerettet.",
       "printing", {"year_min": 1560, "year_max": 1600},
       [("Ihm eine Pension geben.", {"prestige": 15, "gold": -20}, 50),
        ("Das Werk drucken lassen.", {"dip": 30, "prestige": 5}),
        ("Die Zensur soll es erst prüfen.", {"estate": {"klerus": 5}, "adm": 20})]),
    ev("por_restoration", "POR", "Die Restauração",
       "Vierzig Adlige stürmen in Lissabon den Palast der Statthalterin. Sie rufen den Herzog von Braganza zum "
       "König aus, gegen Madrid.",
       "revolt", {"year_min": 1620, "year_max": 1644},
       [("Den Herzog krönen.", {"prestige": 20, "relations": {"SPA": -40}, "estate": {"adel": 5}}, 50),
        ("Bündnis mit England und Frankreich suchen.", {"dip": 50, "relations": {"ENG": 30, "FRA": 30}}),
        ("Die Grenze zu Spanien befestigen.", {"gold": -40, "mil": 40, "manpower": 1})]),
    # --- Venice
    ev("ven_murano", "VEN", "Die Glasbläser von Murano",
       "Ein Glasbläser hat ein Glas erfunden, klar wie Bergkristall. Fremde Fürsten bieten ihm ein Vermögen, "
       "wenn er die Lagune verlässt.",
       "market", {"year_min": 1450, "year_max": 1600},
       [("Ihn adeln und halten.", {"mods": {"production": 0.02}, "prestige": 5, "gold": -30}, 50),
        ("Das Geheimnis an Frankreich verkaufen.", {"gold": 90, "relations": {"FRA": 20}}),
        ("Die Zunft bewacht ihn.", {"estate": {"buerger": 5}, "adm": 20})]),
    ev("ven_ghetto", "VEN", "Das Ghetto",
       "Der Senat streitet: Die jüdischen Kaufleute sollen auf einer Insel bei der Gießerei wohnen, hinter "
       "Toren, die nachts verschlossen werden. Die Händler am Rialto brauchen ihren Kredit.",
       "city", {"year_min": 1500, "year_max": 1560},
       [("Gleiche Rechte für alle Kaufleute.", {"mods": {"trade": 0.02}, "estate": {"klerus": -5}}, 60),
        ("Das Ghetto einrichten.", {"estate": {"klerus": 5}, "gold": 40, "prestige": -5}),
        ("Eine Abgabe für den Schutz verlangen.", {"gold": 70, "dip": -10})]),
    ev("ven_palladio", "VEN", "Villen auf der Terraferma",
       "Ein Baumeister namens Palladio baut Landhäuser wie antike Tempel. Die Patrizier wollen ihr Geld vom "
       "Seehandel aufs Land bringen.",
       "artist", {"year_min": 1540, "year_max": 1600},
       [("Das Land kultivieren.", {"dev_random": 1, "mods": {"trade": -0.01}, "prestige": 5}, 50),
        ("Kirchen in Venedig statt Villen.", {"prestige": 15, "gold": -20, "estate": {"klerus": 4}}),
        ("Das Geld gehört aufs Meer.", {"ships": 3, "mil": 15})]),
    # --- Poland
    ev("pol_copernicus", "POL", "De revolutionibus",
       "Ein Domherr aus Frauenburg behauptet, die Erde drehe sich um die Sonne. Er zögert, das Buch zu "
       "veröffentlichen.",
       "scholar", {"year_min": 1510, "year_max": 1550},
       [("Den Druck bezahlen.", {"gold": -30, "mods": {"tech_cost": -0.02}}, 50),
        ("Er soll erst die Münzreform ausarbeiten.", {"adm": 40}),
        ("Lieber nicht, Rom liest mit.", {"relations": {"PAP": 30}, "estate": {"klerus": 4}})]),
    ev("pol_hussaria", "POL", "Die geflügelten Husaren",
       "Die Reiter tragen Flügel aus Adlerfedern am Rücken. Wenn sie angreifen, rauscht es wie ein Sturm. "
       "Jede Fahne kostet ein Vermögen.",
       "camp", {"year_min": 1500, "year_max": 1644},
       [("Mehr Fahnen aufstellen.", {"gold": -40, "mods": {"combat": 0.03}}, 50),
        ("Der Adel soll sie selbst bezahlen.", {"estate": {"adel": -5}, "regs": 3}),
        ("Billigere Kosaken anwerben.", {"manpower": 1, "mil": 20})]),
    ev("pol_jews_council", "POL", "Der Rat der Vier Länder",
       "Die jüdischen Gemeinden wollen ihre Steuern selbst verteilen und ihre Streitigkeiten selbst richten. Sie "
       "bieten dafür eine feste Summe.",
       "diet", {"year_min": 1540, "year_max": 1640},
       [("Den Rat anerkennen.", {"mods": {"income": 0.02}, "estate": {"buerger": 3}}, 60),
        ("Mehr Geld verlangen.", {"gold": 90, "estate": {"buerger": -3}}),
        ("Die Szlachta soll das regeln.", {"estate": {"adel": 5}, "adm": 20})]),
    # --- Ottomans
    ev("tur_topkapi", "TUR", "Der Neue Palast",
       "Der Sultan baut auf der Spitze der Halbinsel einen Palast mit drei Höfen. Wer in den dritten Hof darf, "
       "regiert das Reich.",
       "court", {"year_min": 1460, "year_max": 1490, "owns": ["constantinople"]},
       [("Eine Palastschule für Pagen gründen.", {"adm": 40, "mods": {"tech_cost": -0.02}, "gold": -60}, 50),
        ("Prunk für die Gesandten.", {"prestige": 15, "dip": 20, "gold": -30}),
        ("Die Janitscharen kasernieren.", {"mil": 50, "manpower": 1})]),
    ev("tur_piri_reis", "TUR", "Die Karte des Piri Reis",
       "Ein Kapitän hat aus zwanzig Karten, darunter eine des Kolumbus, eine Weltkarte gezeichnet. Er will ein "
       "Buch über alle Küsten des Mittelmeers schreiben.",
       "exploration", {"year_min": 1510, "year_max": 1560},
       [("Das Kitab-ı Bahriye fördern.", {"mods": {"naval": 0.03}, "gold": -40}, 50),
        ("Die Karte dem Sultan schenken.", {"prestige": 10, "dip": 20}),
        ("Lieber Galeeren als Karten.", {"ships": 2, "mil": 10})]),
    ev("tur_coffeehouse", "TUR", "Die Kaffeehäuser",
       "In Istanbul öffnen Kaffeehäuser. Dichter, Schachspieler und Klatschmäuler sitzen dort bis in die Nacht. "
       "Die Gelehrten nennen den Kaffee eine Sünde.",
       "tavern", {"year_min": 1550, "year_max": 1644},
       [("Besteuern statt verbieten.", {"gold": 70, "estate": {"klerus": -3}}, 50),
        ("Verbieten.", {"estate": {"klerus": 6}, "prestige": -5}),
        ("Spitzel in die Kaffeehäuser schicken.", {"adm": 40, "estate": {"buerger": -2}})]),
    # --- Qara Qoyunlu
    ev("qar_blue_mosque", "QAR", "Die Blaue Moschee",
       "In Täbris wird eine Moschee gebaut, deren Kacheln blauer sind als der Himmel. Die Tochter des Schahs "
       "führt die Aufsicht.",
       "artist", {"year_min": 1460, "year_max": 1500},
       [("Die Moschee vollenden.", {"gold": -60, "prestige": 20}, 50),
        ("Kacheln aus Täbris verkaufen.", {"gold": 60, "mods": {"production": 0.01}}),
        ("Eine Medrese daneben.", {"adm": 40, "estate": {"klerus": 3}})]),
    ev("qar_nomads", "QAR", "Sommerweiden",
       "Die Stämme wollen im Sommer mit ihren Herden in die Berge ziehen, quer durch bebaute Felder. Die Bauern "
       "in Aserbaidschan klagen beim Schah.",
       "steppe", {"year_min": 1444, "year_max": 1600},
       [("Die alten Wege der Stämme schützen.", {"mods": {"manpower": 0.03}, "dev_random": -1}, 50),
        ("Die Felder schützen.", {"dev_random": 1, "estate": {"adel": -5}}),
        ("Weidegeld verlangen.", {"gold": 60, "estate": {"adel": -2}})]),
    ev("qar_silk_road", "QAR", "Karawanen nach Bursa",
       "Persische Seide geht über Täbris nach Bursa, wo die Osmanen sie verzollen. Venezianische Gesandte bieten "
       "einen anderen Weg an.",
       "market", {"year_min": 1450, "year_max": 1600},
       [("Mit Venedig gegen die Osmanen.", {"relations": {"VEN": 40, "TUR": -30}, "mods": {"trade": 0.02}}, 50),
        ("Mit dem Sultan verhandeln.", {"relations": {"TUR": 30}, "gold": 50}),
        ("Eigene Webereien in Täbris.", {"gold": -40, "mods": {"production": 0.02}})]),
    # --- Mamluks
    ev("mam_cairo_hospital", "MAM", "Das Hospital des Qalawun",
       "Das große Krankenhaus in Kairo nimmt jeden auf, ob reich oder arm, und spielt den Kranken Musik vor. "
       "Die Stiftung reicht nicht mehr.",
       "plague", {"year_min": 1444, "year_max": 1600},
       [("Die Stiftung erneuern.", {"gold": -50, "prestige": 10, "manpower": 1}, 60),
        ("Die Ärzte bezahlen, die Musiker nicht.", {"gold": -20, "adm": 30}),
        ("Die Stiftung für das Heer nutzen.", {"gold": 60, "estate": {"klerus": -5}})]),
    ev("mam_nile_flood", "MAM", "Der Nilmesser",
       "Auf der Insel Roda misst eine Säule das Steigen des Nils. Steigt er zu wenig, hungert Ägypten. Steigt "
       "er zu viel, ertrinken die Dörfer. Dieses Jahr steigt er zu wenig.",
       "famine", {"year_min": 1444},
       [("Getreide aus den Speichern verteilen.", {"gold": -50, "prestige": 10}, 50),
        ("Die Steuern stunden.", {"gold": -20, "estate": {"buerger": 4}, "adm": -10}),
        ("Getreide aus Syrien einführen.", {"gold": -30, "dip": 20, "relations": {"VEN": 10}})]),
    ev("mam_circassians", "MAM", "Junge Mamluken aus dem Kaukasus",
       "Die Sklavenhändler bringen weniger Jungen aus Tscherkessien als früher. Ohne sie gibt es keine neuen "
       "Mamluken. Die Emire schlagen vor, freie Söldner anzuwerben.",
       "camp", {"year_min": 1460, "year_max": 1600},
       [("Freie Söldner und Feuerwaffen.", {"mods": {"combat": 0.02}, "estate": {"adel": -5}}, 60),
        ("Söhne der Mamluken zulassen.", {"manpower": 2, "estate": {"adel": 5}}),
        ("Die Tscherkessen mit Gold locken, als freie Männer.", {"gold": -60, "regs": 3})]),
    # --- Ethiopia
    ev("eth_kebra", "ETH", "Kebra Nagast",
       "Die Mönche lesen aus der Herrlichkeit der Könige: Der Kaiser stammt von Salomo und der Königin von Saba ab. "
       "Ein Gelehrter aus Gondar zweifelt daran.",
       "church", {"year_min": 1444, "year_max": 1600},
       [("Die alte Linie preisen.", {"prestige": 15, "estate": {"klerus": 4}}, 60),
        ("Den Gelehrten anhören.", {"adm": 40, "estate": {"klerus": -3}}),
        ("Abschriften an fremde Höfe senden.", {"dip": 30, "relations": {"POR": 20}})]),
    ev("eth_gondar", "ETH", "Eine Hauptstadt aus Stein",
       "Seit Jahrhunderten zieht der Hof mit seinen Zelten durch das Land. Ein Kaiser will endlich eine feste "
       "Stadt mit Burgen am Tanasee.",
       "city", {"year_min": 1600, "year_max": 1644},
       [("Gondar bauen.", {"gold": -80, "dev_capital": 2}, 50),
        ("Der Hof bleibt im Sattel.", {"mil": 40, "prestige": 5}),
        ("Portugiesische Baumeister holen.", {"gold": -40, "relations": {"POR": 30}, "adm": 30})]),
    ev("eth_jesuits", "ETH", "Die Jesuiten am Hof",
       "Ein spanischer Jesuit predigt am Hof und gewinnt den Kaiser für Rom. Die Mönche und die Bauern rufen zum "
       "Widerstand.",
       "church", {"year_min": 1600, "year_max": 1644},
       [("Den Glauben der Väter behalten.", {"estate": {"klerus": 8}, "relations": {"POR": -20}}, 60),
        ("Rom und Lissabon als Verbündete.", {"relations": {"POR": 40, "PAP": 30}, "estate": {"klerus": -8}, "mods": {"combat": 0.02}}),
        ("Die Jesuiten lehren, aber nicht taufen.", {"adm": 30, "mods": {"tech_cost": -0.02}, "estate": {"klerus": -3}})]),
]

def main():
    data = events_io.replace_block("nx_", EVENTS)
    print("events.json: %d events (%d nx_)" % (len(data), len(EVENTS)))


if __name__ == "__main__":
    main()
