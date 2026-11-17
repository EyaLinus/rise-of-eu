"""Writes data/units.json: unit types, era mixes and nation unique units (scripts/core/units.gd).

Edit here and rerun `python3 tools/content/units.py`; never hand-edit the JSON.
Unique bonuses are relative to the replaced type's stat (+0.2 = +20 %).
"""
import json
import os

TYPES = {
    "inf": {"name": "Infanterie", "emoji": "🛡️", "fire": 1.0, "shock": 1.0, "pursuit": 0.5, "cost": 1.0,
            "text": "Rückgrat jeder Armee: solide in Feuergefecht und Nahkampf, günstig."},
    "cav": {"name": "Kavallerie", "emoji": "🐎", "fire": 0.4, "shock": 1.7, "pursuit": 2.0, "cost": 1.5, "rough": 0.6,
            "text": "Stark im Nahkampf und bei der Verfolgung, schwach im Feuergefecht. In Wald, Hügeln, Gebirge und Sumpf nur %d %% Wucht."},
    "art": {"name": "Artillerie", "emoji": "💣", "fire": 2.4, "shock": 0.35, "pursuit": 0.0, "cost": 2.0, "siege": 1.5,
            "text": "Gewaltig im Feuergefecht (erste zwei Runden), schwach im Nahkampf, beschleunigt Belagerungen. Teuer, braucht Militärtechnik %d."},
}

# default mix per military tech level: AI armies and the "Standard" template follow it
ERA_MIX = [
    [0, {"inf": 0.75, "cav": 0.25, "art": 0.0}],
    [3, {"inf": 0.7, "cav": 0.22, "art": 0.08}],
    [6, {"inf": 0.65, "cav": 0.2, "art": 0.15}],
    [10, {"inf": 0.6, "cav": 0.18, "art": 0.22}],
]

UNIQUE = {
    "TUR": ["Janitscharen", "inf", {"fire": 0.15, "shock": 0.2}, "Die Elite-Infanterie des Sultans."],
    "POL": ["Flügelhusaren", "cav", {"shock": 0.3, "pursuit": 0.2}, "Gepanzerte Lanzenreiter mit Federflügeln."],
    "SPA": ["Tercios", "inf", {"fire": 0.15, "shock": 0.15}, "Pikeniere und Arkebusiere in festen Gevierthaufen."],
    "FRA": ["Gendarmes", "cav", {"shock": 0.25}, "Schwere Ordonnanzreiterei des Königs."],
    "ENG": ["Langbogenschützen", "inf", {"fire": 0.35}, "Ihre Pfeilhagel entscheiden das Feuergefecht."],
    "HAB": ["Landsknechte", "inf", {"shock": 0.2, "fire": 0.05}, "Söldner mit Langspieß und Zweihänder."],
    "BOH": ["Wagenburg", "inf", {"fire": 0.25}, "Hussitische Kriegswagen mit Handbüchsen."],
    "RUS": ["Strelitzen", "inf", {"fire": 0.25}, "Musketiere des Zaren."],
    "NAP": ["Condottieri", "inf", {"shock": 0.15, "pursuit": 0.2}, "Erfahrene Söldnerhauptleute Italiens."],
    "BUR": ["Ordonnanzartillerie", "art", {"fire": 0.2}, "Die beste Artillerie ihrer Zeit."],
    "SWI": ["Reisläufer", "inf", {"shock": 0.3}, "Gefürchtete Schweizer Gewalthaufen."],
    "SCO": ["Highlander", "inf", {"shock": 0.25}, "Der Sturmangriff der Clans."],
    "VEN": ["Stradioti", "cav", {"fire": 0.3, "pursuit": 0.3}, "Leichte Reiter vom Balkan."],
    "HUN": ["Schwarze Armee", "inf", {"fire": 0.15, "shock": 0.15}, "Das stehende Heer des Königs."],
    "MAM": ["Mamluken", "cav", {"shock": 0.3, "fire": 0.2}, "Sklavenkrieger, von Kindheit an im Sattel."],
    "CRI": ["Tatarenreiter", "cav", {"fire": 0.4, "pursuit": 0.4}, "Blitzschnelle Steppenreiter."],
    "KAZ": ["Steppenbogenschützen", "cav", {"fire": 0.5}, "Berittene Bogenschützen der Horde."],
    "QAR": ["Turkmenische Reiter", "cav", {"fire": 0.35, "pursuit": 0.2}, "Reiter der Schwarzen Hammel."],
    "AKK": ["Turkmenische Reiter", "cav", {"fire": 0.35, "pursuit": 0.2}, "Reiter der Weißen Hammel."],
    "TEU": ["Ordensritter", "cav", {"shock": 0.25}, "Die Ritter des Deutschen Ordens."],
    "LIT": ["Litauische Reiterei", "cav", {"fire": 0.2, "pursuit": 0.25}, "Leichte Reiter der Wälder und Sümpfe."],
    "BYZ": ["Warägergarde", "inf", {"shock": 0.25}, "Die letzte Leibwache des Kaisers."],
    "KNI": ["Johanniter", "inf", {"shock": 0.2, "fire": 0.1}, "Die Ritter von Rhodos."],
    "GEN": ["Genueser Armbrustschützen", "inf", {"fire": 0.35}, "Gesuchte Schützen auf allen Schlachtfeldern."],
    "ARA": ["Almogàvares", "inf", {"shock": 0.2, "pursuit": 0.2}, "Leichtes Fußvolk der Grenzkriege."],
    "GEO": ["Aznauri", "cav", {"shock": 0.2}, "Der Kriegeradel Georgiens."],
    "MOR": ["Berberreiter", "cav", {"fire": 0.2, "pursuit": 0.3}, "Wendige Reiter des Maghreb."],
    "TLE": ["Berberreiter", "cav", {"fire": 0.2, "pursuit": 0.3}, "Wendige Reiter des Maghreb."],
    "TUN": ["Berberreiter", "cav", {"fire": 0.2, "pursuit": 0.3}, "Wendige Reiter des Maghreb."],
    "SON": ["Tuareg-Kamelreiter", "cav", {"fire": 0.2, "pursuit": 0.3}, "Herren der Sahara."],
    "AZT": ["Jaguarkrieger", "inf", {"shock": 0.3}, "Die Elitekrieger Tenochtitlans."],
    "SER": ["Panzerreiter", "cav", {"shock": 0.2}, "Der serbische Adel zu Pferd."],
    "DAN": ["Kalmarer Landwehr", "inf", {"fire": 0.1, "shock": 0.1}, "Bauernaufgebot aus drei Kronen."],
    "SAV": ["Savoyer Pikeniere", "inf", {"shock": 0.15}, "Alpenfußvolk."],
    "POR": ["Arkebusiere", "inf", {"fire": 0.2}, "Frühe Feuerwaffen von der Küste."],
    "BRA": ["Märkische Reiter", "cav", {"shock": 0.15, "pursuit": 0.15}, "Reiter der Mark."],
}

if __name__ == "__main__":
    out = {
        "types": TYPES,
        "era_mix": ERA_MIX,
        "max_share": {"cav": 0.6, "art": 0.5},
        "art_tech": 3,
        "unique": {t: {"name": u[0], "type": u[1], "bonus": u[2], "text": u[3]} for t, u in UNIQUE.items()},
    }
    p = os.path.join(os.path.dirname(__file__), "..", "..", "data", "units.json")
    json.dump(out, open(p, "w"), ensure_ascii=False, indent=1)
    print("units.json:", len(UNIQUE), "unique units")
