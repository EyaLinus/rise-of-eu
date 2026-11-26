#!/usr/bin/env python3
"""Hard choices and disasters (Linus 2026-11-26: more negative "pick your poison" and disaster-prevention events).

Two blocks in data/events.json:
- "pp_" (kind "poison"): every answer costs something, in a different currency (gold, power, estates,
  development, timed penalties). The player picks the lesser evil.
- "dz_" (kinds "warning" / "disaster"): a warning (dz_<x>_warn) fires when a realm is in a matching crisis
  (low stability, unrest, loans, war exhaustion, angry nobles, mixed faith, colonial exhaustion, ...).
  Two answers prevent the disaster in different ways, the third saves resources now and sets the flag
  dz_<x>. The disaster dz_<x> can only fire while that flag is set (yearly draw, so usually within a few
  years); every answer clears the flag again ("clear_flag").
Timed penalties use the effect "tmods" {"name", "months", "mods"} (Game.add_tmods, bonus source "tmods").

Rules: first option gold-free (AI default), gold-costing options AI weight <= 10, repeatable warnings are
gated by crisis conditions (never always-eligible for all AI realms), permanent "mods" are not used here.
Run: python3 tools/content/hardship_events.py (idempotent, see events_io.py).
"""
import events_io


def tm(name, months, **mods):
    return {"tmods": {"name": name, "months": months, "mods": mods}}


def fx(*parts, **kw):
    e = {}
    for p in parts:
        e.update(p)
    e.update(kw)
    return e


def opt(text, effects, ai=None):
    o = {"text": text, "effects": effects}
    if effects.get("gold", 0) < 0:
        o["ai"] = min(ai if ai is not None else 10, 10)
    elif ai is not None:
        o["ai"] = ai
    return o


def ev(id, kind, title, text, image, trigger, options, once=True):
    e = {"id": id}
    if not once:
        e["once"] = False
    e.update({"tag": "*", "kind": kind, "title": title, "text": text, "image": image, "trigger": trigger, "options": options})
    return e


# ---------------------------------------------------------------- pick your poison

PP = [
    ev("pp_plague_city", "poison", "Fieber in der Hauptstadt",
       "In den Gassen am Hafen sterben die ersten Familien. Die Ärzte streiten, die Händler packen schon. Jede Entscheidung kostet jetzt etwas.", "plague",
       {"year_min": 1446},
       [opt("Die Stadt abriegeln. Kein Wagen hinein, keiner hinaus.", fx(tm("pp_quarantine", 36, trade=-0.12), estate={"buerger": -5}), 40),
        opt("Die Ärzte gewähren lassen und beten.", {"dev_capital": -1, "manpower": -2}, 30),
        opt("Der Hof flieht aufs Land.", {"prestige": -6, "stability": -8}, 20)]),
    ev("pp_bad_harvest", "poison", "Missernte",
       "Regen im Frühjahr, Hagel im Sommer. Die Scheunen bleiben halb leer, und der Winter kommt bestimmt.", "famine",
       {"year_min": 1445, "stability_max": 50},
       [opt("Die Bauern müssen es durchstehen.", fx(tm("pp_hunger", 36, unrest=1.0), manpower=-2), 40),
        opt("Getreide aus dem Ausland kaufen.", {"gold": -50}),
        opt("Der Adel muss seine Speicher öffnen.", {"estate": {"adel": -8}, "stability": -3}, 30)]),
    ev("pp_debasement", "poison", "Leere Münzen",
       "Der Münzmeister zeigt dir die Bücher: Silber fehlt an allen Ecken. Er hat drei Vorschläge, und keiner gefällt ihm selbst.", "bank",
       {"gold_max": 60, "year_min": 1450},
       [opt("Die Münze strecken. Mehr Kupfer, weniger Silber.", fx(tm("pp_debased", 60, trade=-0.10, production=-0.04), gold=40), 40),
        opt("Den Hofstaat zusammenstreichen.", {"prestige": -6, "estate": {"adel": -5}}, 30),
        opt("Einen neuen Kredit aufnehmen.", {"loan": 1}, 20)]),
    ev("pp_border_raids", "poison", "Plünderer an der Grenze",
       "Reiterbanden brennen Grenzdörfer nieder und verschwinden über die Grenze, bevor die Truppen kommen.", "border",
       {"year_min": 1446, "at_peace": True},
       [opt("Die Grenzdörfer aufgeben.", {"dev_random": -1}, 30),
        opt("Eine Strafexpedition ausschicken.", {"mil": -40, "manpower": -1}, 40),
        opt("Den Anführern Tribut zahlen.", {"gold": -35, "prestige": -3})]),
    ev("pp_preacher", "poison", "Ein Wanderprediger",
       "Ein Prediger zieht durchs Land und wettert gegen Bischöfe und Steuern. Tausende folgen ihm, und die Kirche verlangt seinen Kopf.", "procession",
       {"year_min": 1450},
       [opt("Ihn predigen lassen.", fx(tm("pp_preacher", 48, religious_unrest=0.25), estate={"klerus": -6}), 35),
        opt("Ihn der Kirche ausliefern.", fx(tm("pp_martyr", 36, unrest=0.5), prestige=-2), 35),
        opt("Ihn mit Gold zum Schweigen bringen.", {"gold": -30, "dip": -10})]),
    ev("pp_mutiny", "poison", "Murren im Lager",
       "Der Sold ist drei Monate im Rückstand. Die Hauptleute melden offene Meuterei in zwei Regimentern.", "camp",
       {"regs": 8, "year_min": 1446},
       [opt("Die Rädelsführer hängen.", {"army_power": -0.3, "estate": {"adel": -3}}, 40),
        opt("Den Sold sofort nachzahlen.", {"gold": -45}),
        opt("Die Unzufriedenen nach Hause schicken.", {"manpower": -3, "mil": -15}, 30)]),
    ev("pp_noble_feud", "poison", "Fehde der Barone",
       "Zwei große Familien führen Krieg gegeneinander, mitten im Reich. Beide verlangen, dass die Krone Partei ergreift.", "knights",
       {"year_min": 1446},
       [opt("Für die eine Seite entscheiden.", {"estate": {"adel": -8}, "stability": -2}, 35),
        opt("Beide in die Schranken weisen.", {"stability": -6, "mil": -20}, 35),
        opt("Wegsehen, bis sie müde sind.", tm("pp_feud", 60, tax=-0.08, unrest=0.5), 30)]),
    ev("pp_city_fire", "poison", "Großbrand",
       "Ein Funke in einer Bäckerei, ein trockener Sommer, und ein ganzes Viertel der Hauptstadt liegt in Asche.", "town_fire",
       {"year_min": 1446},
       [opt("Die Bürger sollen selbst wieder aufbauen.", {"dev_capital": -1, "estate": {"buerger": -3}}, 40),
        opt("Die Krone bezahlt den Wiederaufbau.", {"gold": -45}),
        opt("Der Stadt die Steuern erlassen.", fx(tm("pp_fire", 48, tax=-0.10), estate={"buerger": 3}), 30)]),
    ev("pp_storm_flood", "poison", "Sturmflut",
       "Das Meer bricht durch die Deiche. Felder versalzen, Dörfer stehen bis zu den Dächern im Wasser.", "naval",
       {"coastal": True, "year_min": 1446},
       [opt("Das überflutete Land aufgeben.", {"dev_random": -1}, 35),
        opt("Neue Deiche bauen lassen.", {"adm": -40}, 35),
        opt("Die Bauern zur Fronarbeit zwingen.", fx(tm("pp_dikes", 24, unrest=1.0), manpower=-1), 30)]),
    ev("pp_insulted_envoy", "poison", "Der beleidigte Gesandte",
       "Bei einem Bankett hat dein Bruder einen fremden Gesandten öffentlich verspottet. Halb Europa lacht, die andere Hälfte ist empört.", "court",
       {"year_min": 1446},
       [opt("Sich öffentlich entschuldigen.", {"prestige": -5}, 40),
        opt("Teure Geschenke an alle Höfe.", {"dip": -35}, 40),
        opt("Den Bruder verteidigen.", tm("pp_insult", 60, ae_gen=0.10), 20)]),
    ev("pp_bank_crash", "poison", "Ein Bankhaus wankt",
       "Das größte Bankhaus des Landes kann nicht mehr zahlen. Kaufleute stürmen die Kontore, Gläubiger stehen vor deinem Palast.", "bank",
       {"year_min": 1470},
       [opt("Die Bank fallen lassen.", fx(tm("pp_crash", 60, trade=-0.10), estate={"buerger": -5}), 40),
        opt("Die Bank mit Kronsilber retten.", {"gold": -60}),
        opt("Ihre Schulden übernehmen.", {"loan": 1, "estate": {"buerger": 3}}, 30)]),
    ev("pp_camp_fever", "poison", "Lagerfieber",
       "Ruhr und Fleckfieber gehen im Heerlager um. Jeden Morgen tragen sie Dutzende hinaus.", "camp",
       {"at_war": True},
       [opt("Weitermarschieren. Der Krieg wartet nicht.", {"manpower": -3, "army_power": -0.15}, 40),
        opt("Die Lager auflösen und die Truppen verteilen.", {"we": 2}, 30),
        opt("Ärzte aus der Hauptstadt holen.", {"gold": -30, "mil": -15})]),
    ev("pp_false_prince", "poison", "Ein falscher Prinz",
       "Ein junger Mann behauptet, der totgeglaubte Sohn des alten Königs zu sein. Er hat Anhänger, Briefe und ein Muttermal.", "conspiracy",
       {"year_min": 1450},
       [opt("Ihn ignorieren.", {"stability": -8}, 35),
        opt("Ein öffentlicher Prozess.", {"adm": -30, "prestige": -2}, 40),
        opt("Ein Kopfgeld aussetzen.", {"gold": -35, "prestige": -2})]),
    ev("pp_guild_strike", "poison", "Die Zünfte streiken",
       "Weber, Gerber und Schmiede legen die Arbeit nieder. Sie verlangen alte Rechte zurück und drohen mit dem Auszug aus der Stadt.", "city",
       {"year_min": 1460, "cities_min": 1},
       [opt("Den Zünften nachgeben.", tm("pp_guilds", 48, production=-0.08), 40),
        opt("Die Stadtwache schicken.", fx(tm("pp_strike", 24, unrest=0.5), estate={"buerger": -8}), 30),
        opt("Die Löhne aus der Kasse aufbessern.", {"gold": -40})]),
    ev("pp_tithe", "poison", "Streit um den Zehnten",
       "Die Bischöfe verlangen den vollen Zehnten, die Bauern können nicht mehr zahlen, und die Kasse der Krone braucht ihren Teil.", "church",
       {"year_min": 1450},
       [opt("Die Kirche soll verzichten.", {"estate": {"klerus": -8}}, 35),
        opt("Die Krone verzichtet auf ihren Anteil.", tm("pp_tithe_crown", 60, tax=-0.06), 35),
        opt("Die Bauern müssen zahlen.", tm("pp_tithe_farmers", 48, unrest=0.75), 30)]),
    ev("pp_drought", "poison", "Dürre",
       "Seit Monaten kein Regen. Die Brunnen versiegen, das Vieh steht mit hängenden Köpfen auf verbrannten Weiden.", "harvest",
       {"year_min": 1446},
       [opt("Das Vieh schlachten.", fx(tm("pp_drought", 36, production=-0.05), manpower=-2), 40),
        opt("Neue Brunnen graben lassen.", {"adm": -35}, 35),
        opt("Wasser und Brot rationieren.", {"stability": -6}, 25)]),
    ev("pp_pirates", "poison", "Piraten vor der Küste",
       "Freibeuter kapern Handelsschiffe in Sichtweite der Häfen. Die Reeder verlangen Schutz, sofort.", "naval",
       {"coastal": True, "year_min": 1450},
       [opt("Die Häfen eine Weile schließen.", tm("pp_pirates", 36, trade=-0.12), 40),
        opt("Die Kriegsflotte ausschicken.", {"mil": -30, "army_power": -0.1}, 35),
        opt("Schutzgeld an die Piraten zahlen.", {"gold": -35, "prestige": -2})]),
    ev("pp_tax_strike", "poison", "Steuerverweigerer",
       "Ganze Landstriche zahlen nicht mehr. Die Steuereintreiber kehren mit leeren Taschen zurück, manche gar nicht.", "revolt",
       {"stability_max": 10, "year_min": 1446},
       [opt("Die Steuern senken.", tm("pp_tax_cut", 60, tax=-0.10), 40),
        opt("Ein Exempel statuieren.", {"stability": -5, "estate": {"buerger": -6}}, 30),
        opt("Die Steuern an Pächter verkaufen.", fx(tm("pp_tax_farm", 48, unrest=1.0), gold=25, estate={"buerger": -4}), 30)]),
    ev("pp_comet", "poison", "Ein Komet am Himmel",
       "Ein Schweifstern steht seit Wochen über dem Land. Prediger verkünden das Ende der Welt, die Leute verlassen ihre Felder.", "comet",
       {"year_min": 1450},
       [opt("Bußprozessionen anordnen.", fx(tm("pp_comet", 24, production=-0.05), estate={"klerus": 3}), 40),
        opt("Gelehrte erklären lassen, was ein Komet ist.", {"adm": -25, "estate": {"klerus": -4}}, 35),
        opt("Nichts tun. Er wird schon weiterziehen.", {"stability": -5}, 25)]),
    ev("pp_deserters", "poison", "Deserteure im Land",
       "Entlaufene Soldaten ziehen in Banden durch die Dörfer und plündern, was sie finden.", "revolt",
       {"we_min": 5},
       [opt("Sie jagen lassen.", {"mil": -30, "manpower": -1}, 40),
        opt("Eine Amnestie verkünden.", fx(tm("pp_amnesty", 36, unrest=0.5), prestige=-3), 35),
        opt("Sie als Söldner anwerben.", {"gold": -30, "regs": 1})]),
]


# ---------------------------------------------------------------- disasters: warning -> (prevented | flag) -> disaster

def chain(x, warn_title, warn_text, warn_img, trigger, prevent_a, prevent_b, ignore, dis_title, dis_text, dis_img, dis_opts):
    w = ev("dz_%s_warn" % x, "warning", warn_title, warn_text, warn_img, dict(trigger, not_flag="dz_" + x),
           [opt(prevent_a[0], prevent_a[1], 45), opt(prevent_b[0], prevent_b[1], prevent_b[2] if len(prevent_b) > 2 else 30),
            opt(ignore[0], fx(ignore[1], flag="dz_" + x), 25)], once=False)
    d = ev("dz_" + x, "disaster", dis_title, dis_text, dis_img, {"flag": "dz_" + x},
           [opt(o[0], fx(o[1], clear_flag="dz_" + x), o[2] if len(o) > 2 else None) for o in dis_opts], once=False)
    return [w, d]


DZ = sum([
    chain("famine", "Leere Speicher",
          "Die Vorratskammern sind halb leer, die Preise steigen jede Woche. Wenn auch nur eine Ernte ausfällt, droht eine Hungersnot.", "famine",
          {"stability_max": 0, "year_min": 1446},
          ("Vorräte anlegen lassen.", {"adm": -45}),
          ("Korn im Ausland kaufen.", {"gold": -50}),
          ("Die Speicher verkaufen. Es wird schon gut gehen.", {"gold": 20}),
          "Hungersnot",
          "Die Ernte ist verdorben, die Speicher sind leer. Menschen essen Baumrinde, Kinder sterben am Straßenrand, ganze Dörfer ziehen bettelnd in die Städte.", "famine",
          [("Die Not ertragen.", fx(tm("dz_famine", 60, unrest=1.5), manpower=-3), 40),
           ("Teures Getreide um jeden Preis.", {"gold": -80, "stability": -5}),
           ("Die Städte versorgen, das Land opfern.", {"dev_random": -2, "stability": -5, "estate": {"buerger": 3}}, 35)]),
    chain("peasants", "Unruhe in den Dörfern",
          "In den Wirtshäusern wird von alten Rechten gesprochen, von Sensen und Dreschflegeln. Die Vögte melden Versammlungen bei Nacht.", "tavern",
          {"unrest_min": 3, "year_min": 1446},
          ("Die Beschwerden der Bauern anhören.", {"adm": -40, "estate": {"adel": -3}}),
          ("Truppen in die Dörfer legen.", {"mil": -40}, 35),
          ("Bauern murren immer.", {}),
          "Der Bauernkrieg",
          "Die Bauern haben sich erhoben. Klöster brennen, Burgen werden gestürmt, ein Heer aus Tausenden zieht mit Fahnen und Sensen durch das Land.", "revolt",
          [("Der Adel schlägt den Aufstand nieder.", {"estate": {"adel": 5}, "dev_random": -2, "stability": -8}, 40),
           ("Die Forderungen erfüllen.", fx(tm("dz_peasants", 96, tax=-0.12), stability=2), 35),
           ("Söldner anwerben und Ordnung schaffen.", {"gold": -100, "we": 3})]),
    chain("bankrupt", "Die Gläubiger werden ungeduldig",
          "Die Bankiers verlangen ihre Zinsen, neue Kredite gibt es nur noch zu Wucherzinsen. Der Schatzmeister spricht offen vom Staatsbankrott.", "bank",
          {"loans_min": 2},
          ("Den Hofstaat verkleinern.", {"prestige": -5, "adm": -20}),
          ("Eine Sondersteuer erheben.", fx(tm("dz_bankrupt_tax", 36, unrest=0.5), gold=40), 35),
          ("Weiter auf Pump leben.", {}),
          "Staatsbankrott",
          "Die Krone kann ihre Schulden nicht mehr bedienen. Die Bankhäuser schließen ihre Kontore, Söldner verlangen ihren Sold, und kein Kaufmann gibt mehr Kredit.", "bank",
          [("Die Schulden für nichtig erklären.", fx(tm("dz_bankrupt", 60, trade=-0.15), loan_forgiven=2, prestige=-15, estate={"buerger": -10}), 40),
           ("Krongüter verpfänden.", {"dev_random": -3, "gold": 50}, 30),
           ("Die Münze verschlechtern.", tm("dz_debased", 60, production=-0.10, unrest=1.0), 30)]),
    chain("plague", "Fieber in den Häfen",
          "Aus fernen Häfen kommen Schiffe mit kranken Matrosen. Die Ärzte erkennen die Beulen und werden bleich.", "plague",
          {"coastal": True, "year_min": 1450, "stability_max": 30},
          ("Strenge Quarantäne für alle Schiffe.", tm("dz_quarantine", 24, trade=-0.05)),
          ("Ärzte und Pestspitäler bezahlen.", {"gold": -40}),
          ("Den Handel nicht behindern.", {"gold": 15}),
          "Der schwarze Tod",
          "Die Pest ist zurück. Karren voller Toter rollen durch die Straßen, die Glocken läuten nicht mehr, weil die Glöckner gestorben sind.", "plague",
          [("Das Land leidet und überlebt.", {"dev_random": -2, "manpower": -3}, 40),
           ("Städte abriegeln, Märkte schließen.", tm("dz_plague", 60, production=-0.10, tax=-0.10), 35),
           ("Die Schuld bei Fremden suchen.", {"stability": -10, "prestige": -5}, 25)]),
    chain("mutiny", "Erschöpfte Regimenter",
          "Die Truppen sind kriegsmüde. Offiziere schreiben von Männern, die nicht mehr marschieren wollen, und von Hauptleuten, die mit dem Feind verhandeln.", "camp",
          {"we_min": 8},
          ("Drill und harte Disziplin.", {"mil": -50}),
          ("Sold und Wein für alle.", {"gold": -50}),
          ("Sie werden schon durchhalten.", {}),
          "Meuternde Regimenter",
          "Ganze Regimenter haben ihre Offiziere verjagt und ziehen plündernd durchs eigene Land. Sie verlangen Sold, Frieden und Straffreiheit.", "revolt",
          [("Mit Gewalt zur Ordnung rufen.", {"manpower": -3, "stability": -5, "army_power": -0.4}, 40),
           ("Zahlen und begnadigen.", {"gold": -80, "mil": -30}),
           ("Die Meuterer entlassen.", fx(tm("dz_mutiny", 48, combat=-0.10), manpower=-2), 35)]),
    chain("nobles", "Verschwörung des Adels",
          "Die großen Familien treffen sich ohne dich. Man spricht von alten Freiheiten, von einem besseren König und von Waffen in den Burgen.", "conspiracy",
          {"estate_max": {"adel": 30}},
          ("Ihre Privilegien bestätigen.", fx(tm("dz_privileges", 60, tax=-0.05), estate={"adel": 8})),
          ("Die Rädelsführer verhaften.", {"adm": -40, "estate": {"adel": -3}}, 35),
          ("Laut bellen, nicht beißen.", {}),
          "Adelsaufstand",
          "Die Barone haben sich erhoben. Sie besetzen Burgen und Städte und rufen einen Gegenkönig aus.", "knights",
          [("Gnade und neue Privilegien.", {"estate": {"adel": 10}, "stability": -10, "prestige": -5}, 35),
           ("Krieg gegen die eigenen Vasallen.", {"manpower": -3, "we": 3, "dev_random": -1, "estate": {"adel": -5}}, 35),
           ("Ihnen Land und Ämter überlassen.", {"dev_random": -2, "estate": {"adel": 15}}, 30)]),
    chain("heresy", "Ketzer im Land",
          "In den Grenzprovinzen predigen Andersgläubige offen auf den Marktplätzen. Die Bischöfe fürchten um das Seelenheil des Reiches und um ihre Kirchen.", "church",
          {"faith_share_max": 0.75, "year_min": 1450},
          ("Missionare und Schulen schicken.", {"dip": -40}),
          ("Die Inquisition einsetzen.", fx(tm("dz_inquisition", 36, unrest=0.5), estate={"klerus": 5}), 35),
          ("Gott wird es richten.", {}),
          "Glaubenskrieg im Land",
          "Bilderstürmer verwüsten Kirchen, Prediger rufen zum heiligen Krieg, Nachbarn erschlagen Nachbarn. Das Reich zerfällt in Glaubensparteien.", "inquisition",
          [("Die Ordnung mit Gewalt wiederherstellen.", fx(tm("dz_heresy", 96, religious_unrest=0.5), stability=-6), 35),
           ("Ein Toleranzedikt erlassen.", {"estate": {"klerus": -12}, "prestige": -4}, 35),
           ("Zwangsbekehrungen.", fx(tm("dz_conversion", 48, unrest=1.0), dev_random=-2), 30)]),
    chain("colonies", "Murren in den Kolonien",
          "Siedler klagen über Steuern, Statthalter über fehlende Soldaten. In den Hafenkneipen jenseits des Meeres spricht man vom eigenen Weg.", "exploration",
          {"col_exhaust_min": 60},
          ("Neue Siedlungen eine Weile aussetzen.", tm("dz_col_pause", 36, colony_cost=0.25)),
          ("Gouverneure und Garnisonen bezahlen.", {"gold": -50}),
          ("Die Kolonien brauchen die Krone mehr als umgekehrt.", {}),
          "Aufstand in den Kolonien",
          "Die Siedler haben den Statthalter vertrieben. Sie zahlen keine Abgaben mehr und handeln mit wem sie wollen.", "revolt",
          [("Den Handel umleiten und abwarten.", fx(tm("dz_colonies", 60, trade=-0.10), prestige=-5), 40),
           ("Truppen über das Meer schicken.", {"gold": -60, "mil": -30}),
           ("Ihnen Selbstverwaltung gewähren.", fx(tm("dz_col_autonomy", 60, income=-0.05), col_exhaust=-20, estate={"buerger": -5}), 30)]),
], [])


def check(e):
    assert len(e["options"]) == 3, e["id"]
    assert e["options"][0]["effects"].get("gold", 0) >= 0, e["id"]
    for o in e["options"]:
        eff = o["effects"]
        assert "mods" not in eff, e["id"]
        if eff.get("gold", 0) < 0:
            assert o.get("ai", 25) <= 10, e["id"]
        assert eff.get("manpower", 0) > -100, e["id"]  # regiments, not men
        t = eff.get("tmods")
        if t:
            assert 12 <= t["months"] <= 120 and t["name"], e["id"]
            for v in t["mods"].values():
                assert abs(v) <= 1.5, e["id"]
    if e["kind"] == "poison":  # every answer costs something
        for o in e["options"]:
            eff = o["effects"]
            bad = any(eff.get(k, 0) < 0 for k in ("gold", "adm", "dip", "mil", "prestige", "stability", "manpower", "dev_random", "dev_capital", "army_power")) \
                or any(v < 0 for v in eff.get("estate", {}).values()) or "tmods" in eff or "loan" in eff or eff.get("we", 0) > 0
            assert bad, (e["id"], o["text"])


def main():
    for e in PP + list(DZ):
        check(e)
    events_io.replace_block("pp_", PP)
    data = events_io.replace_block("dz_", list(DZ))
    print("events %d (pp %d, dz %d)" % (len(data), len(PP), len(DZ)))


if __name__ == "__main__":
    main()
