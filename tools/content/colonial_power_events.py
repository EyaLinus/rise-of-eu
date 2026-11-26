"""Colonial superpowers and Oceania (2026-11-26, Linus: "In Ozeanien auch Colonys möglich machen (historisch)",
"Colonie events für colonial superpowers", "Colonial exhaust").

Events "colp_*":
- generic events for realms with many colonies (trigger "colonies_min"): viceroys, creoles, silver fleets,
  pirates, missions, smuggling, emigration, chartered companies. Several of them move the colonial exhaustion
  (effect "col_exhaust", condition "col_exhaust_min") that every finished colony builds up (colonial.gd).
- exhaustion events (trigger "col_exhaust_min"): the motherland is tired of sending settlers.
- historical Oceania voyages in their real windows: Mendaña (Solomons 1568), Quirós (Vanuatu 1606), the
  Duyfken (Cape York 1606), Dirk Hartog (West Australia 1616), Tasman (Tasmania/New Zealand 1642), and for
  endless play Cook (1770) and Botany Bay (1788). They discover the coasts ("discover") or found the
  historical settlement ("colony_grant"); "colony_free" keeps them away once the land is taken.

"knows_sea" lists only seas that start unknown (colonial.NEW_SEAS): the Old World seas of Asia are known to
every realm from the start.

Run: python3 tools/content/colonial_power_events.py
"""
import events_io


def ev(eid, title, text, trigger, options, tag=None, image="exploration"):
    e = {"id": "colp_" + eid, "title": title, "text": text, "image": image, "trigger": trigger,
         "options": [{"text": t, "effects": eff, "ai": ai} for t, eff, ai in options]}
    if tag:
        e["tag"] = tag
    return e


def oc(eid, tag, title, text, years, keys, found, discover, decline, ai=(50, 35, 15), extra=None):
    """Historical voyage to Oceania: found / only chart / decline (like colonial_events.col)."""
    tr = {"year_min": years[0], "year_max": years[1], "coastal": True, "colony_free": keys}
    tr.update(extra or {})
    opts = []
    opts.append((found[0], dict({"colony_grant": keys}, **found[1]), ai[0]))
    opts.append((discover[0], dict({"discover": keys}, **discover[1]), ai[1]))
    opts.append((decline[0], decline[1], ai[2]))
    return ev(eid, title, text, tr, opts, tag=tag)


GENERIC = [
    ev("viceroy", "Ein Vizekönig für Übersee",
       "Briefe aus den Kolonien brauchen Monate bis in die Hauptstadt, und jede Antwort kommt zu spät. Der Rat "
       "schlägt vor, einen Vizekönig mit eigenem Hof und eigenen Richtern über das Meer zu schicken.",
       {"colonies_min": 10},
       [("Ein Vizekönigreich einrichten.", {"adm": -60, "col_exhaust": -20, "mods": {"col_exhaust_decay": 0.25}, "prestige": 5}, 60),
        ("Die Krone entscheidet selbst, auch wenn es dauert.", {"gold": 40, "col_exhaust": 10, "estate": {"adel": 3}}, 25),
        ("Die Kaufleute sollen die Kolonien verwalten.", {"mods": {"trade": 0.01}, "estate": {"buerger": 4}, "col_exhaust": -5}, 15)],
       image="court"),
    ev("creoles", "Die Kreolen fordern Mitsprache",
       "In den Kolonien geborene Familien sind reich geworden. Sie wollen eigene Räte, eigene Ämter und nicht "
       "länger von Beamten regiert werden, die nur ein paar Jahre bleiben.",
       {"colonies_min": 12, "year_min": 1520},
       [("Koloniale Räte zulassen.", {"col_exhaust": -15, "mods": {"income": 0.02}, "prestige": -5}, 50),
        ("Alle Ämter bleiben in der Hand des Mutterlands.", {"col_exhaust": 10, "estate": {"adel": 4}, "stability": -3}, 30),
        ("Ämter verkaufen, an wen auch immer.", {"gold": 80, "col_exhaust": 5}, 20)],
       image="diet"),
    ev("silver_fleet", "Die Silberflotte",
       "Im Hafen liegen zwanzig Schiffe voller Silber, Zucker und Farbholz. Die Überfahrt ist lang, und "
       "Freibeuter warten vor den Inseln.",
       {"colonies_min": 8, "year_min": 1510, "region_colonies": {"america": 5}},
       [("Kriegsschiffe als Geleit mitschicken.", {"gold": 120, "mil": -30, "prestige": 5}, 55),
        ("Allein segeln lassen, das spart Kosten.", {"gold": 180, "col_exhaust": 5}, 25),
        ("Bei den Bankiers versichern.", {"gold": 90, "estate": {"buerger": 3}}, 20)],
       image="naval"),
    ev("pirates", "Freibeuter vor unseren Kolonien",
       "Kaperfahrer fremder Kronen und Seeräuber ohne Herrn plündern unsere Küstenorte und kapern die "
       "Versorgungsschiffe. Die Siedler fühlen sich verlassen.",
       {"colonies_min": 6, "year_min": 1540, "coastal": True},
       [("Eine Küstenwache aufstellen.", {"gold": -80, "ships": 2, "col_exhaust": -5}, 50),
        ("Selbst Kaperbriefe ausstellen.", {"gold": 60, "ae": 5, "prestige": -5}, 30),
        ("Die Kolonien müssen sich selbst schützen.", {"col_exhaust": 10, "mil": 20}, 20)],
       image="naval"),
    ev("missions", "Missionare für die Kolonien",
       "Mönche und Prediger bitten um Schiffe und Geld, um in den neuen Ländern Kirchen und Schulen zu bauen. "
       "Andere warnen: Zwang macht die Ureinwohner zu Feinden.",
       {"colonies_min": 5},
       [("Missionen mit Schulen und Spitälern stiften.", {"gold": -50, "estate": {"klerus": 4}, "prestige": 5}, 45),
        ("Die Ureinwohner nach ihrem Glauben leben lassen.", {"dip": 40, "estate": {"klerus": -4}, "col_exhaust": -5}, 35),
        ("Kein Geld dafür.", {"gold": 30, "estate": {"klerus": -2}}, 20)],
       image="church"),
    ev("smuggling", "Schmuggel blüht",
       "Die Kolonien dürfen nur mit dem Mutterland handeln. Trotzdem landen fremde Schiffe in versteckten Buchten, "
       "und die Zöllner sehen weg.",
       {"colonies_min": 8, "year_min": 1530},
       [("Den Handel öffnen und Zoll nehmen.", {"mods": {"trade": 0.02}, "estate": {"buerger": 3}, "col_exhaust": -5}, 45),
        ("Hart durchgreifen.", {"gold": 40, "mil": -20, "col_exhaust": 5}, 35),
        ("Die Zöllner besser bezahlen.", {"gold": -40, "adm": 20}, 20)],
       image="market"),
    ev("emigrants", "Eine Auswanderungswelle",
       "Missernten, hohe Pacht und Glaubensstreit treiben Tausende in die Häfen. Sie wollen über das Meer, "
       "wenn man sie lässt.",
       {"colonies_min": 4, "year_min": 1560},
       [("Freie Überfahrt und Land für jeden.", {"gold": -60, "mods": {"colonists": 1}, "col_exhaust": -10}, 55),
        ("Nur ausgewählte Handwerker ziehen lassen.", {"dip": 30, "col_exhaust": -5}, 30),
        ("Die Bauern werden zu Hause gebraucht.", {"manpower": 2, "estate": {"adel": 3}}, 15)],
       image="harvest"),
    ev("company", "Eine Kompanie für Übersee",
       "Kaufleute wollen eine Aktiengesellschaft gründen, die Schiffe, Forts und Siedler selbst bezahlt. Sie "
       "verlangen dafür ein Monopol und das Recht, Krieg zu führen.",
       {"colonies_min": 6, "year_min": 1590},
       [("Den Freibrief ausstellen.", {"mods": {"trade": 0.02, "col_exhaust_gain": -0.2}, "estate": {"buerger": 5}, "prestige": 5}, 60),
        ("Nur ein Monopol, kein Heer.", {"gold": 50, "mods": {"trade": 0.01}}, 25),
        ("Die Krone braucht keine Kaufleute.", {"adm": 30, "estate": {"buerger": -4}}, 15)],
       image="bank"),
    ev("frontier", "Siedler drängen ins Landesinnere",
       "Die Küsten sind vergeben. Junge Familien ziehen über Flüsse und Berge, oft gegen den Willen der Behörden "
       "und ohne Vertrag mit den Völkern dort.",
       {"colonies_min": 15, "year_min": 1600},
       [("Grenzen mit den Ureinwohnern vertraglich festlegen.", {"dip": -40, "col_exhaust": -10, "prestige": 5}, 45),
        ("Sie gewähren lassen.", {"col_exhaust": 10, "gold": 40}, 35),
        ("Forts entlang der Grenze bauen.", {"gold": -70, "mil": -20, "col_exhaust": -5}, 20)],
       image="border"),
]

EXHAUSTION = [
    ev("tired", "Leere Häfen",
       "Zu viele Schiffe sind über das Meer gefahren, zu wenige kommen zurück. Die Werften klagen, und in den "
       "Dörfern heißt es, die Kolonien fressen ihre Söhne.",
       {"col_exhaust_min": 45},
       [("Ein paar Jahre keine neuen Kolonien.", {"col_exhaust": -20, "prestige": -5}, 50),
        ("Prämien für Seeleute und Siedler.", {"gold": -90, "col_exhaust": -12}, 30),
        ("Weiter, das Meer gehört uns.", {"prestige": 5, "stability": -4}, 20)],
       image="tavern"),
    ev("fever", "Fieber in den Kolonien",
       "Schiffe bringen Kranke zurück, Siedler sterben am Fieber, und neue Siedler wollen nicht mehr fahren. Die "
       "Ärzte raten zu Quarantäne und besseren Vorräten.",
       {"col_exhaust_min": 30, "colonies_min": 5},
       [("Quarantänehäfen und Spitäler bauen.", {"gold": -60, "col_exhaust": -10}, 50),
        ("Die Schiffe besser verproviantieren.", {"gold": -30, "adm": -20, "col_exhaust": -8}, 30),
        ("Es sterben eben Menschen.", {"col_exhaust": 8, "estate": {"klerus": -3}}, 20)],
       image="plague"),
]

OCEANIA = [
    oc("solomons", "SPA", "Die Inseln Salomos",
       "Álvaro de Mendaña ist von Peru aus nach Westen gesegelt und hat Inseln gefunden. Seine Männer glauben, "
       "dort liege das Goldland König Salomos.",
       (1565, 1600), ["solomons", "new_britain"],
       ("Eine Siedlung auf den Inseln gründen.", {"gold": -60, "prestige": 10}),
       ("Nur die Inseln kartieren lassen.", {"dip": 30, "prestige": 5}),
       ("Kein Gold, keine Gewürze. Peru genügt.", {"gold": 50}),
       extra={"knows_sea": ["humboldt", "melanesia", "south_pacific", "east_indian"]}),
    oc("espiritu", "SPA", "Australia del Espíritu Santo",
       "Pedro Fernandes de Quirós hält eine große Insel im Südmeer für den gesuchten Südkontinent. Er will eine "
       "Stadt gründen: Nueva Jerusalén.",
       (1600, 1625), ["vanuatu", "new_caledonia"],
       ("Nueva Jerusalén gründen.", {"gold": -50, "estate": {"klerus": 3}, "prestige": 10}),
       ("Nur die Küste vermessen.", {"dip": 30}),
       ("Der Südkontinent ist ein Traum.", {"adm": 30, "gold": 20}),
       extra={"knows_sea": ["humboldt", "melanesia", "south_pacific", "east_indian"]}),
    oc("duyfken", "NED", "Die Fahrt der Duyfken",
       "Willem Janszoon ist von Bantam aus nach Osten gesegelt und an einer flachen Küste gelandet, die er für "
       "einen Teil Neuguineas hält. Gold hat er nicht gefunden.",
       (1600, 1640), ["cape_york", "trans_fly", "arnhem"],
       ("Einen Handelsposten an der Küste lassen.", {"gold": -40, "mods": {"trade": 0.01}}),
       ("Die Küste in die Karten eintragen.", {"dip": 30, "prestige": 5}),
       ("Die Gewürzinseln sind wichtiger.", {"gold": 60}),
       extra={"knows_sea": ["east_indian", "indian"]}),
    oc("hartog", "NED", "Eendrachtsland",
       "Auf dem Weg nach Batavia ist Dirk Hartog zu weit nach Osten gesegelt und an eine unbekannte, trockene "
       "Küste gestoßen. Er hat einen Zinnteller an einen Pfahl genagelt.",
       (1610, 1650), ["gascoyne", "swan", "pilbara"],
       ("Eine Versorgungsstation für die Indienfahrer bauen.", {"gold": -50, "prestige": 5}),
       ("Die Brouwer-Route kartieren.", {"dip": 30, "mods": {"trade": 0.01}}),
       ("Nur Sand und Fliegen.", {"gold": 40}),
       extra={"knows_sea": ["east_indian", "indian", "south_aus"]}),
    oc("tasman", "NED", "Abel Tasmans Fahrt",
       "Die Kompanie in Batavia schickt Abel Tasman nach Süden, um den Südkontinent zu suchen. Er findet ein "
       "Land mit hohen Wäldern und weiter östlich Inseln mit kriegerischen Bewohnern.",
       (1635, 1670), ["palawa", "northland", "waitaha", "fiji"],
       ("Ein Fort in Van-Diemens-Land bauen.", {"gold": -70, "prestige": 5}),
       ("Die Entdeckungen kartieren.", {"dip": 40, "prestige": 10}),
       ("Kein Handel, keine Gewinne.", {"gold": 50}),
       ai=(10, 70, 20), extra={"knows_sea": ["east_indian", "south_aus", "arafura"]}),
    oc("cook", "ENG", "Captain Cook im Südmeer",
       "Ein Kapitän der Flotte kehrt von einer langen Fahrt zurück: er hat die Ostküste eines großen Kontinents "
       "vermessen und Aotearoa umsegelt. Die Botaniker sind begeistert.",
       (1700, 1800), ["eora", "turrbal", "northland", "waikato", "hawaii"],
       ("Gleich Siedler hinterherschicken.", {"gold": -80, "prestige": 5}),
       ("Die Karten veröffentlichen.", {"dip": 40, "prestige": 10}),
       ("Die Karten geheim halten.", {"adm": 30}),
       ai=(15, 60, 25)),
    oc("botany", "ENG", "Die Erste Flotte",
       "Die Gefängnisse sind voll, und Amerika nimmt keine Sträflinge mehr. Ein Plan schlägt vor, sie an eine "
       "Bucht im fernen Süden zu bringen, wo der Kapitän einst Pflanzen gesammelt hat.",
       (1720, 1830), ["eora", "kamilaroi", "turrbal"],
       ("Die Flotte nach Botany Bay schicken.", {"gold": -60, "prestige": 5}),
       ("Nur einen Hafen für Walfänger.", {"dip": 30, "mods": {"trade": 0.01}}),
       ("Sträflinge bleiben in den Gefängnissen.", {"adm": 30, "stability": -2}),
       extra={"knows_sea": ["coral", "tasman", "south_aus"]}),
    oc("southland", None, "Terra Australis",
       "Seeleute erzählen von einem großen Südland jenseits der Gewürzinseln. Kartenmacher zeichnen es seit "
       "Jahrhunderten ein, doch niemand hat es betreten.",
       (1580, 1900), ["arnhem", "kimberley", "cape_york", "sepik"],
       ("Eine Expedition mit Siedlern ausrüsten.", {"gold": -80, "prestige": 5}),
       ("Kartografen mitschicken.", {"dip": -20, "prestige": 5}),
       ("Seemannsgarn.", {"gold": 20}),
       ai=(30, 50, 20), extra={"knows_sea": ["east_indian", "arafura"], "colonies_min": 3}),
]


def main():
    events = GENERIC + EXHAUSTION + OCEANIA
    data = events_io.replace_block("colp_", events)
    print("events.json: %d events (%d colp_)" % (len(data), len(events)))


if __name__ == "__main__":
    main()
