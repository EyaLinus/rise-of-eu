#!/usr/bin/env python3
"""Generates data/council.json: the council of state (9 seats, names per government family, passive effects
per level, automations) and the government-type mechanics (elections, factions, republican tradition).
Run: python3 tools/content/council.py   (never hand-edit data/council.json)."""
import json, os

FAMILIES = ["monarchie", "republik", "kirche", "stamm"]

COUNCIL_NAME = {"monarchie": "Kronrat", "republik": "Signoria", "kirche": "Kapitel", "stamm": "Ältestenrat"}

# id, icon, power used for promotions, per-level passive effects, names per family, short text,
# automation: [title, text]
SEATS = [
    ("war", "⚔️", "mil", {"combat": 0.01, "army_power": 0.02},
     ["Marschall", "Kriegskommissar", "Ordensmarschall", "Kriegsherr"],
     "Führt den Krieg im Großen: stellt Generäle und lässt erschöpfte Heere drillen.",
     ["Generäle und Drill", "Gibt jeder Armee ab 4 Regimentern einen General und drillt Heere unter 60 % Moral auf eigenem Boden, solange Militärpunkte über der Reserve bleiben."]),
    ("diplo", "🕊️", "dip", {"ae_decay": 0.05},
     ["Kanzler", "Gesandter der Republik", "Kardinalstaatssekretär", "Sprecher der Sippen"],
     "Pflegt den Ruf des Reiches und die Freundschaften mit Verbündeten.",
     ["Ruf und Freundschaften", "Stellt den Ruf wieder her, sobald die Aggressive Expansion über der Grenze liegt, und verbessert Beziehungen zu Verbündeten unter 100, solange Diplomatiepunkte über der Reserve bleiben."]),
    ("trade", "🤝", "dip", {"trade": 0.02},
     ["Handelsmeister", "Konsul der Kaufleute", "Prokurator der Güter", "Karawanenführer"],
     "Lenkt Händler und Handelsschiffe dorthin, wo Gewinn wartet.",
     ["Händler und Fernhandel", "Schickt Händler selbst in die besten Märkte und kauft Fernhandelsschiffe bis zur Obergrenze, solange Gold über der Reserve bleibt."]),
    ("construction", "🏗️", "adm", {"build_cost": -0.03},
     ["Hofbaumeister", "Stadtbaumeister", "Dombaumeister", "Lagermeister"],
     "Plant Bauten im ganzen Land und drückt die Preise der Handwerker.",
     ["Autobau", "Baut selbst das lohnendste Gebäude, solange Gold über der Reserve bleibt. Je Stufe ab 2 ein Bauprojekt mehr pro Monat."]),
    ("coin", "💰", "adm", {"tax": 0.02},
     ["Schatzmeister", "Kämmerer der Republik", "Camerlengo", "Hüter des Tributs"],
     "Hütet die Schatzkammer, tilgt Schulden und verhindert den Bankrott.",
     ["Schulden und Notkredit", "Zahlt Kredite zurück, sobald danach noch die Reserve in der Kasse liegt, und nimmt einen Notkredit, bevor die Kasse ins Minus rutscht."]),
    ("navy", "⚓", "mil", {"ship_cost": -0.04, "naval": 0.02},
     ["Großadmiral", "Flottenkapitän", "Ordensadmiral", "Bootsherr"],
     "Baut und unterhält die Flotte.",
     ["Flottenbau", "Baut jeden Monat Schiffe, bis der gewählte Anteil des Flottenlimits erreicht ist, solange Gold über der Reserve bleibt."]),
    ("army", "🛡️", "mil", {"recruit_cost": -0.04, "manpower": 0.02},
     ["Konnetabel", "Hauptmann der Miliz", "Komtur", "Anführer der Reiter"],
     "Hebt Truppen aus und hält das Heer auf Sollstärke.",
     ["Rekrutierung", "Hebt jeden Monat Regimenter in der Hauptstadt aus, bis der gewählte Anteil des Truppenlimits steht (je Stufe 1 Regiment pro Monat), solange Gold über der Reserve bleibt."]),
    ("development", "🏘️", "adm", {"develop_cost": -0.03},
     ["Landvogt", "Prokurator der Länder", "Landpfleger", "Hüter der Weiden"],
     "Entscheidet, wo überschüssige Verwaltungs-, Diplomatie- und Militärpunkte das Land entwickeln.",
     ["Entwicklung", "Entwickelt eine Provinz nach deiner Wahl (Hauptstadt, niedrigste, höchste oder günstigste Entwicklung), sobald eine Punkteart die gewählte Schwelle erreicht."]),
    ("education", "🎓", "adm", {"tech_cost": -0.01},
     ["Prinzenerzieher", "Rektor der Akademie", "Magister der Domschule", "Erzähler der Ahnen"],
     "Bildet den Nachfolger aus und bringt dem Volk Lesen und Rechnen bei.",
     ["Erziehung", "Unterrichtet den Erben oder Nachfolger einmal im Jahr in der gewählten Fähigkeit, sobald die Punkte die gewählte Schwelle erreichen."]),
]

# Automation options: key -> [label, [values], default index, value format]
OPTIONS = {
    "war": {"reserve": ["Militär-Reserve", [0, 50, 100, 200, 400], 2, "pts"]},
    "diplo": {"ae": ["AE-Grenze", [0, 5, 10, 20, 40], 2, "num"], "reserve": ["Diplomatie-Reserve", [0, 50, 100, 200, 400], 2, "pts"]},
    "trade": {"ships": ["Fernhandelsschiffe kaufen", [0, 1], 1, "bool"], "reserve": ["Gold-Reserve", [0, 50, 100, 250, 500, 1000], 2, "gold"]},
    "construction": {"reserve": ["Gold-Reserve", [0, 50, 100, 250, 500, 1000], 2, "gold"]},
    "coin": {"repay": ["Kredite tilgen", [0, 1], 1, "bool"], "emergency": ["Notkredit", [0, 1], 1, "bool"], "reserve": ["Gold-Reserve", [0, 50, 100, 250, 500, 1000], 2, "gold"]},
    "navy": {"target": ["Ziel (Flottenlimit)", [25, 50, 75, 100], 1, "pct"], "reserve": ["Gold-Reserve", [0, 50, 100, 250, 500, 1000], 2, "gold"]},
    "army": {"target": ["Ziel (Truppenlimit)", [25, 50, 75, 90, 100], 2, "pct"], "reserve": ["Gold-Reserve", [0, 50, 100, 250, 500, 1000], 2, "gold"], "war_only": ["Nur im Krieg", [0, 1], 0, "bool"]},
    "development": {"mode": ["Ziel", ["capital", "lowest", "highest", "cheapest", "off"], 3, "mode"], "at": ["Schwelle", [100, 75, 50, 25], 0, "pct_cap"]},
    "education": {"focus": ["Fach", ["weakest", "adm", "dip", "mil"], 0, "focus"], "at": ["Schwelle", [100, 75, 50, 25], 2, "pct_cap"]},
}

MODE_LABELS = {"capital": "Hauptstadt", "lowest": "niedrigste Entwicklung", "highest": "höchste Entwicklung",
               "cheapest": "günstigste", "off": "aus (Punkte verfallen)",
               "weakest": "schwächste Fähigkeit", "adm": "Verwaltung", "dip": "Diplomatie", "mil": "Militär"}

# Factions that put up candidates in elections, per family: id, name, agenda effects (for the elected ruler's term)
FACTIONS = {
    "republik": [
        ("kaufleute", "Kaufleute", {"trade": 0.10, "merchants": 1}, "Handel zuerst: neue Kontore, sichere Seewege."),
        ("zuenfte", "Zünfte", {"production": 0.08, "build_cost": -0.05}, "Werkstätten, Stadtmauern und gute Arbeit."),
        ("popolo", "Popolo", {"unrest": -1.0, "manpower": 0.10}, "Brot, Milizen und Mitsprache für die kleinen Leute."),
    ],
    "kirche": [
        ("kurie", "Kurie", {"prestige": 0.5, "conversion": 0.25}, "Die Rechte der Kirche mehren, den Glauben verbreiten."),
        ("reformer", "Reformer", {"tech_cost": -0.05, "unrest": -0.5}, "Gelehrte Prälaten, Schulen und Ordnung in den Klöstern."),
        ("ritter", "Ritterbrüder", {"combat": 0.05, "manpower": 0.10}, "Das Schwert für den Glauben."),
    ],
    "monarchie": [
        ("magnaten", "Magnaten", {"manpower": 0.10, "estate_adel": 10}, "Ein König, der die Freiheiten des Adels achtet."),
        ("staedte", "Städte", {"tax": 0.08, "estate_buerger": 10}, "Ein König für Handel, Märkte und Stadtrechte."),
        ("bischoefe", "Bischöfe", {"prestige": 0.5, "estate_klerus": 10}, "Ein frommer König, gesalbt und gesegnet."),
    ],
    "stamm": [
        ("krieger", "Krieger", {"combat": 0.05, "army_power": 0.05}, "Beute und Ruhm für alle Reiter."),
        ("haendler", "Händler", {"trade": 0.10, "tax": 0.05}, "Sichere Karawanenwege und volle Märkte."),
        ("aelteste", "Älteste", {"unrest": -1.0, "develop_cost": -0.05}, "Weiden, Brunnen und alte Bräuche."),
    ],
}

ELECTION_TITLE = {"republik": "Wahl in der Republik", "kirche": "Das Kapitel wählt", "monarchie": "Königswahl",
                  "stamm": "Der Ältestenrat tritt zusammen"}
ELECTION_TEXT = {
    "republik": "Die Amtszeit ist um. Die Parteien der Stadt stellen ihre Kandidaten auf. Wer gewinnt, regiert die nächsten Jahre nach seinem Programm.",
    "kirche": "Der Stuhl ist verwaist. Die Brüder des Kapitels versammeln sich, um einen Nachfolger aus ihrer Mitte zu wählen.",
    "monarchie": "Der Thron ist frei. Die Großen des Reiches treten zur Wahl zusammen, und jede Partei hat ihren Bewerber.",
    "stamm": "Der Anführer ist tot. Die Ältesten der Sippen beraten, wer nun die Stämme führen soll.",
}

cfg = {
    "_doc": "Generated by tools/content/council.py. Council of state + government-type mechanics (scripts/core/council.gd, regime.gd).",
    "council_name": COUNCIL_NAME,
    "seats": [{"id": s[0], "icon": s[1], "power": s[2], "per_level": s[3],
               "names": dict(zip(FAMILIES, s[4])), "text": s[5], "auto": {"title": s[6][0], "text": s[6][1]},
               "options": {k: {"label": v[0], "values": v[1], "default": v[2], "fmt": v[3]} for k, v in OPTIONS[s[0]].items()}}
              for s in SEATS],
    "mode_labels": MODE_LABELS,
    "max_skill": 5,
    "hire_gold": 40,          # gold per skill level to hire
    "salary": 0.15,           # gold per month per skill level
    "promote_power": 40,      # power per current level to promote
    "experience_years": 6,    # years of service at one level before a free level-up
    "pool_size": 3,
    "pool_months": 12,        # candidates are replaced after this many months
    "family_cost": {"monarchie": 1.0, "republik": 0.8, "kirche": 0.9, "stamm": 0.75},
    "ai_seats_per_100_dev": 1.0,
    "ai_min_gold": 200,
    "general_min_regs": 4,
    "drill_below": 0.6,
    # government-type mechanics
    "republic_term": 4,
    "republic_max_terms": 3,  # incumbent may run again while below this many terms
    "tradition_start": 50,
    "tradition_year": 2,
    "tradition_reelect": -15,
    "tradition_effects": {"tax": 0.05, "unrest": -1.0, "prestige": 0.5},  # at 100; mirrored at 0
    "elective_families": ["republik", "kirche", "stamm"],
    "elective_forms": ["Wahlmonarchie"],
    "factions": {fam: [{"id": f[0], "name": f[1], "agenda": f[2], "text": f[3]} for f in lst] for fam, lst in FACTIONS.items()},
    "election_title": ELECTION_TITLE,
    "election_text": ELECTION_TEXT,
}

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "council.json")
with open(out, "w", encoding="utf-8") as f:
    json.dump(cfg, f, ensure_ascii=False, indent=1)
    f.write("\n")
print("wrote", os.path.normpath(out))
