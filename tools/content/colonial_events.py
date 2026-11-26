"""Historical first colonies (2026-11-17, Linus: "alle colonial nations bekommen durch ein Event eine historical
colonial province, auch Entdeckung der Region durch Event").

Events "col_*": each colonial nation gets one founding event in its historical window. Option 1 founds the
colony ("colony_grant": the first still-free province of the list becomes a settled, cored province of the
realm, and the seas around it are discovered); option 2 only discovers the coast ("discover") for a cheaper
price; option 3 declines. The trigger "colony_free" keeps the event away when every listed province is
already taken (or not on the map yet: keys of regions another thread is adding, e.g. "pernambuco", are
simply skipped until they exist).

Run: python3 tools/content/colonial_events.py
"""
import events_io


def col(eid, tag, title, text, years, keys, found, discover, decline, extra_trigger=None, ai=(70, 20, 10)):
    tr = {"year_min": years[0], "year_max": years[1], "coastal": True, "colony_free": keys}
    tr.update(extra_trigger or {})
    return {"id": "col_" + eid, "tag": tag, "title": title, "text": text, "image": "exploration", "trigger": tr,
            "options": [
                {"text": found[0], "effects": dict({"colony_grant": keys}, **found[1]), "ai": ai[0]},
                {"text": discover[0], "effects": dict({"discover": keys}, **discover[1]), "ai": ai[1]},
                {"text": decline[0], "effects": decline[1], "ai": ai[2]}]}


EVENTS = [
    col("spa_hispaniola", "SPA", "Land im Westen!",
        "Der Genuese ist zurück. Statt Indien hat er Inseln gefunden, mit Gold an den Flüssen und Menschen, die "
        "ihn für einen Gott halten. Auf Hispaniola stehen schon die ersten Hütten von La Isabela.",
        (1490, 1515), ["quisqueya", "ayiti", "boriken", "havana", "oriente"],
        ("Eine Stadt gründen: Santo Domingo.", {"gold": -60, "prestige": 10}),
        ("Nur Karten zeichnen und Gold suchen lassen.", {"gold": 40, "dip": 30}),
        ("Die Inseln sind nicht Indien. Die Mauren gehen vor.", {"mil": 50, "adm": 30})),
    col("por_mina", "POR", "São Jorge da Mina",
        "An der Goldküste tauschen die Akan Gold gegen Tuch und Messing. Ein Kapitän schlägt vor, dort eine "
        "steinerne Festung zu bauen, damit kein Kastilier den Handel stört.",
        (1470, 1500), ["gold_coast", "akan", "ivory_coast", "allada"],
        ("Die Festung bauen.", {"gold": -50, "mods": {"trade": 0.01}}),
        ("Nur einen Handelsposten am Strand.", {"gold": 50, "dip": 20}),
        ("Weiter nach Süden, das Kap ist wichtiger.", {"dip": 50, "prestige": 5})),
    col("por_brazil", "POR", "Terra de Vera Cruz",
        "Cabrals Flotte nach Indien ist zu weit nach Westen abgetrieben und hat eine Küste voller Rotholz "
        "gefunden. Nach dem Vertrag von Tordesillas gehört sie Portugal.",
        (1499, 1540), ["pernambuco", "bahia"],
        ("Kapitanate an Adlige vergeben.", {"gold": -40, "estate": {"adel": 4}, "prestige": 5}),
        ("Nur Rotholz schlagen lassen.", {"gold": 70, "dip": 15}),
        ("Indien zuerst.", {"dip": 40, "mods": {"trade": 0.01}})),
    col("spa_plata", "SPA", "Der Silberfluss",
        "Am Río de la Plata gründet Pedro de Mendoza eine Stadt. Die Siedler hoffen auf den Weg zu den "
        "Silberbergen im Westen.",
        (1530, 1590), ["rio_plata"],
        ("Buenos Aires gründen.", {"gold": -50, "prestige": 10}),
        ("Nur die Mündung erkunden.", {"dip": 40, "gold": 20}),
        ("Peru ist reicher.", {"gold": 80})),
    col("eng_virginia", "ENG", "Jamestown",
        "Die Virginia Company hat drei Schiffe ausgerüstet. Hundert Siedler wollen an einem Fluss im Land der "
        "Powhatan eine Festung bauen.",
        (1585, 1625), ["powhatan", "secotan", "susquehannock", "lenape"],
        ("Den Freibrief der Krone geben.", {"gold": -40, "prestige": 10}),
        ("Nur die Küste vermessen lassen.", {"dip": 40, "gold": 20}),
        ("Lieber Spaniens Silberflotten kapern.", {"gold": 90, "relations": {"SPA": -30}})),
    col("fra_quebec", "FRA", "Québec",
        "Samuel de Champlain will am Sankt-Lorenz-Strom eine Stadt gründen, wo der Fluss schmal wird. Die "
        "Huronen bieten Biberpelze und ein Bündnis.",
        (1600, 1640), ["stadacona", "hochelaga", "gaspe", "wendake"],
        ("Neufrankreich gründen.", {"gold": -50, "prestige": 10}),
        ("Nur Pelzhändler schicken.", {"gold": 60, "dip": 15}),
        ("Frankreich braucht seine Söhne zu Hause.", {"mil": 50, "adm": 20})),
    col("ned_amsterdam", "NED", "Nieuw Amsterdam",
        "Kaufleute aus Holland haben den Lenape eine Insel an einer großen Flussmündung abgekauft. Ein Fort und "
        "eine Windmühle stehen schon.",
        (1605, 1644), ["munsee", "lenape", "mahican"],
        ("Die Westindische Kompanie gründen.", {"gold": -40, "mods": {"trade": 0.01}}),
        ("Nur Pelzhandel am Fluss.", {"gold": 60, "dip": 15}),
        ("Die Ostindienfahrt ist lohnender.", {"gold": 30, "dip": 40})),
    col("ned_guiana", "NED", "Die Wilde Küste",
        "Zeeländer Kaufleute haben an der Küste von Guayana Handelsposten zwischen den Flüssen angelegt. Sie "
        "wollen Zuckermühlen bauen.",
        (1590, 1644), ["suriname", "guayana"],
        ("Eine Kolonie mit freien Siedlern.", {"gold": -50, "prestige": 5}),
        ("Nur Handelsposten.", {"gold": 60, "dip": 15}),
        ("Zu viel Fieber, zu wenig Gewinn.", {"adm": 40, "gold": 20})),
    col("dan_westindies", "DAN", "Sankt Thomas",
        "Ein Kapitän aus Kopenhagen meldet eine Insel in der Karibik, die weder Spanier noch Engländer "
        "beanspruchen. Ein guter Hafen für Kaufleute aller Länder.",
        (1600, 1644), ["antilles", "boriken", "lucayas"],
        ("Eine Handelsstation gründen.", {"gold": -40, "mods": {"trade": 0.01}}),
        ("Die Route für die Flotte kartieren.", {"dip": 40, "gold": 15}),
        ("Der Sundzoll ist sicherer.", {"gold": 70})),
    col("sco_novascotia", "SCO", "Nova Scotia",
        "König Jakob vergibt Baronien in Neu-Schottland an jeden, der Siedler über das Meer bringt.",
        (1615, 1644), ["mikmaq", "abenaki", "wolastoqiyik"],
        ("Die Baronien verkaufen und Siedler schicken.", {"gold": 30, "estate": {"adel": 4}, "prestige": 5}),
        ("Nur Fischer und Pelzhändler.", {"gold": 50, "dip": 15}),
        ("Schotten bleiben in Schottland.", {"mil": 40, "adm": 20})),
    col("eng_plymouth", "ENG", "Die Pilgerväter",
        "Religiöse Abweichler wollen auf der Mayflower über das Meer, um in Frieden ihren Glauben zu leben. Sie "
        "bitten um ein Patent.",
        (1610, 1644), ["wampanoag", "massachusett", "pequot"],
        ("Ein Patent für Neuengland.", {"gold": -20, "estate": {"klerus": -3}, "prestige": 5}),
        ("Ziehen lassen, ohne Patent.", {"dip": 30, "estate": {"klerus": 3}}),
        ("Sie sollen sich der Kirche fügen.", {"estate": {"klerus": 6}, "adm": 30}),
        ai=(50, 30, 20)),
]


def main():
    data = events_io.replace_block("col_", EVENTS)
    print("events.json: %d events (%d col_)" % (len(data), len(EVENTS)))


if __name__ == "__main__":
    main()
