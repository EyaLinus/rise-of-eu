"""Age decisions ("Weichen des Zeitalters"): writes data/ages.json and the "age_" block of data/events.json.

Every age asks three questions, one every 12-20 years. A question is a manual event "age_q_<id>" fired by
Ages.yearly (scripts/core/ages.gd); its options carry the effect {"age_pick": [question, option]}. The chosen
option gives its modifiers for the rest of the game (n.bonus["ages"]), can be deepened twice for power
("up" is added per extra level) and some options get a "synergy" bonus when an earlier option was chosen.

Design rules:
- The harsh historical choices (slave trade, forced labour, expulsion, witch trials, serfdom) pay at once
  ("once" gold) and have the highest raw yield, but cost unrest, prestige or research for good and draw bad
  follow-up events. The humane alternatives start lower, deepen better, have synergies and good follow-ups:
  over 50+ years they are worth at least as much. Two follow-ups let a realm leave a harsh path later.
- Follow-up events use the condition age_pick; pure flavour ("age_fun_") is player-only so it cannot dilute
  the AI's event pool (lesson from the court batch).
- No emoji in the texts (data files need a pixel glyph for each).

Run: python3 tools/content/age_decisions.py (idempotent, see events_io.py).
"""
import json
import os

import events_io
from ctx_events import ev

OUT = os.path.join(events_io.ROOT, "data/ages.json")

AGES = [
    {"id": "renaissance", "name": "Renaissance", "from": 1444, "motto": "Alte Gewissheiten wanken: Bücher, Söldner und Bankiers verändern die Höfe."},
    {"id": "entdeckungen", "name": "Entdeckungen", "from": 1500, "motto": "Die Welt wird größer. Wer hinausfährt, entscheidet auch, wie er dort herrscht."},
    {"id": "reformation", "name": "Reformation", "from": 1550, "motto": "Glaube spaltet Länder und Familien. Angst und Wissen wachsen nebeneinander."},
    {"id": "absolutismus", "name": "Absolutismus", "from": 1600, "motto": "Der Staat wird zur Maschine. Wer bezahlt sie, und wer hat darin noch eine Stimme?"},
]


def opt(id, name, text, effects, up, power, ai=33, tone="", once=None, synergy=None):
    o = {"id": id, "name": name, "text": text, "tone": tone, "effects": effects, "up": up, "power": power, "ai": ai}
    if once:
        o["once"] = once
    if synergy:
        o["synergy"] = {"with": synergy[0], "effects": synergy[1]}
    return o


def q(id, age, year, title, text, image, options):
    return {"id": id, "age": age, "year": year, "title": title, "text": text, "image": image, "options": options}


QUESTIONS = [
    # ------------------------------------------------------------ Renaissance
    q("buchdruck", "renaissance", 1452, "Die schwarze Kunst",
      "In Mainz druckt ein Goldschmied Bücher mit beweglichen Lettern. Bald kann jeder Krämer lesen, was früher nur Mönche abschrieben: Bibeln, Kalender, Schmähschriften. Wie hält es dein Reich mit den Pressen?", "printing",
      [opt("druck_frei", "Freie Pressen", "Wer drucken will, soll drucken. Wissen verbreitet sich, Gerüchte auch.",
           {"tech_cost": -0.06, "unrest": 0.25}, {"tech_cost": -0.03}, "adm"),
       opt("druck_zensur", "Zensur mit dem Segen der Kirche", "Jedes Blatt braucht ein Siegel. Ruhe im Land, Staub in den Köpfen.",
           {"unrest": -0.75, "estate_klerus": 5, "prestige": 0.5, "tech_cost": 0.02}, {"unrest": -0.5}, "adm"),
       opt("druck_hof", "Königliche Hofdruckerei", "Die Krone druckt selbst: Gesetze, Ruhmesblätter und teure Privilegien.",
           {"prestige": 0.5, "income": 0.03}, {"income": 0.015, "prestige": 0.25}, "adm")]),
    q("kriegsvolk", "renaissance", 1468, "Wer führt das Schwert?",
      "Das Lehnsaufgebot kommt spät, kämpft sechs Wochen und geht zur Ernte heim. Die Hauptleute verlangen eine Entscheidung, wie das Reich künftig Krieg führt.", "camp",
      [opt("condottieri", "Söldnerführer unter Vertrag", "Erfahrene Kriegsunternehmer. Sie siegen, solange die Kasse stimmt.",
           {"combat": 0.06, "maintenance": 0.05}, {"combat": 0.025}, "mil"),
       opt("miliz", "Bürgermiliz", "Jede Stadt stellt Schützen und Spieße. Wer sein Haus verteidigt, läuft nicht davon.",
           {"manpower": 0.12, "estate_buerger": 5}, {"manpower": 0.07}, "mil"),
       opt("ordonnanz", "Stehende Kompanien", "Besoldete Truppen, das ganze Jahr unter Waffen und nur der Krone verpflichtet.",
           {"force_limit": 2, "army_power": 0.05, "maintenance": 0.03}, {"force_limit": 1}, "mil")]),
    q("vertriebene", "renaissance", 1492, "Die Vertriebenen",
      "Aus Spanien werden Juden und Mauren vertrieben. Zehntausende suchen ein neues Land: Ärzte, Drucker, Seidenweber, Geldwechsler, Familien mit dem, was sie tragen können. Schiffe liegen vor deinen Häfen, und auch im eigenen Reich fordern Eiferer, mit den Andersgläubigen ebenso zu verfahren.", "city",
      [opt("aufnahme", "Zuflucht gewähren", "Die Tore öffnen und Schutzbriefe ausstellen. Der Klerus murrt, die Werkstätten füllen sich.",
           {"trade": 0.06, "production": 0.04, "estate_klerus": -5}, {"trade": 0.03, "tech_cost": -0.01}, "dip", ai=34, tone="human",
           once={"prestige": 5}),
       opt("schutzgeld", "Dulden gegen Schutzgeld", "Wer bleiben will, zahlt dafür. Weder Zuflucht noch Vertreibung, aber verlässliche Einnahmen.",
           {"tax": 0.06, "unrest": 0.25}, {"tax": 0.03}, "adm", ai=33),
       opt("vertreibung", "Vertreiben und enteignen", "Ein Glaube, ein Reich. Die Krone zieht Häuser und Schuldscheine ein, die Werkbänke bleiben leer.",
           {"estate_klerus": 10, "religious_unrest": -0.3, "conversion": 0.2, "unrest": -0.25, "production": -0.03, "trade": -0.02}, {"conversion": 0.1}, "adm", ai=33,
           tone="hart", once={"gold": 250})]),
    # ------------------------------------------------------------ Entdeckungen
    q("seefahrt", "entdeckungen", 1502, "Der Blick über das Meer",
      "Kapitäne kehren mit Pfeffer, Karten und haarsträubenden Geschichten zurück. Der Rat streitet, was das Meer für dein Reich sein soll: Schule, Jagdrevier oder Marktplatz.", "exploration",
      [opt("seeschule", "Schule der Steuerleute", "Karten, Sterne und Kompass als Lehrfach. Wer rechnen kann, kommt auch wieder heim.",
           {"naval": 0.15, "tech_cost": -0.03}, {"naval": 0.05, "tech_cost": -0.01}, "dip"),
       opt("kaperbriefe", "Kaperbriefe", "Seeräuber mit Urkunde. Ein Zehntel der Beute für die Krone, der Ärger für die Nachbarn.",
           {"naval": 0.05, "income": 0.04, "ae_gen": 0.05}, {"income": 0.02}, "mil"),
       opt("kontore", "Handelskontore", "Faktoreien in fremden Häfen, mit eigenen Waagen, Richtern und Lagerhäusern.",
           {"merchants": 1, "trade": 0.03}, {"trade": 0.02}, "dip")]),
    q("menschenhandel", "entdeckungen", 1518, "Der Handel mit Menschen",
      "Die Pflanzer in Übersee verlangen Arbeitskräfte, und Kapitäne bieten an, sie zu liefern: Menschen, an Afrikas Küsten gekauft oder geraubt, in Ketten über das Meer verschifft. Die Gewinne wären enorm. Ein Mönch aus den Kolonien steht ebenfalls vor dem Rat und beschreibt, was er auf den Schiffen gesehen hat. Dies ist eine der Entscheidungen, an denen man dein Reich messen wird.", "naval",
      [opt("sklavenhandel", "Am Sklavenhandel verdienen", "Lizenzen für die Menschenhändler. Schnelles Gold, erkauft mit Elend, Aufständen und Schande.",
           {"trade": 0.12, "production": 0.06, "unrest": 0.5, "prestige": -0.5}, {"trade": 0.04, "unrest": 0.25}, "dip", ai=34,
           tone="hart", once={"gold": 150}, synergy=("kaperbriefe", {"income": 0.02})),
       opt("freie_arbeit", "Freie Siedler und Lohnarbeit", "Land und Lohn für jeden, der hinausfährt. Es wächst langsamer, aber es gehört Menschen, die bleiben wollen.",
           {"production": 0.05, "manpower": 0.05, "unrest": -0.25}, {"production": 0.03, "tax": 0.02}, "adm", ai=33, tone="human",
           synergy=("aufnahme", {"production": 0.03})),
       opt("afrika_handel", "Verträge mit Afrikas Reichen", "Gesandte nach Benin, Kongo und Mali: Gold, Pfeffer und Elfenbein gegen Tuch und Eisen, unter Gleichen.",
           {"trade": 0.07, "dip": 0.25, "prestige": 0.5}, {"trade": 0.04, "prestige": 0.25}, "dip", ai=33, tone="human",
           synergy=("kontore", {"trade": 0.04}))]),
    q("unterworfene", "entdeckungen", 1536, "Die Unterworfenen",
      "Eroberte Dörfer, fremde Sprachen, Silberadern im Berg. Die Statthalter wollen die Unterworfenen den Siedlern als Arbeiter zuteilen. Juristen und Ordensleute widersprechen: Auch Besiegte seien Untertanen mit Rechten. Wie regiert dein Reich Land, das es mit dem Schwert genommen hat?", "mine",
      [opt("zwangsarbeit", "Zwangsarbeit in Minen und Feldern", "Die Besiegten schuften für die Sieger. Die Erträge steigen, die Dörfer leeren sich.",
           {"tax": 0.10, "production": 0.06, "unrest": 0.5, "manpower": -0.05}, {"tax": 0.03, "unrest": 0.25}, "adm", ai=34,
           tone="hart", once={"gold": 100}),
       opt("schutzgesetze", "Schutzgesetze", "Verbot der Versklavung, königliche Richter, feste Abgaben. Die Siedler toben, das Land wird ruhig.",
           {"unrest": -0.5, "coring": -0.15, "prestige": 0.5}, {"coring": -0.05, "tax": 0.03}, "adm", ai=33, tone="human"),
       opt("selbstverwaltung", "Bündnis und Selbstverwaltung", "Die alten Fürsten bleiben im Amt und stellen Truppen. Nachbarn sehen: Diesem Reich kann man sich fügen.",
           {"manpower": 0.10, "ae_gen": -0.08, "religious_unrest": -0.2}, {"manpower": 0.05, "ae_decay": 0.05}, "dip", ai=33, tone="human")]),
    # ------------------------------------------------------------ Reformation
    q("glaubensfrage", "reformation", 1555, "Wessen Land, dessen Glaube?",
      "In jeder Stadt predigen zwei Kanzeln gegeneinander. Nachbarn zeigen Nachbarn an, Zünfte spalten sich nach Bekenntnis. Die Krone muss sagen, wie viel Glauben sie ihren Untertanen vorschreibt.", "reformation",
      [opt("glaubensgerichte", "Glaubensgerichte", "Ein Bekenntnis, durchgesetzt mit Verhör und Scheiterhaufen. Die Gelehrten gehen als Erste.",
           {"conversion": 0.5, "estate_klerus": 10, "unrest": -0.5, "tax": 0.03, "tech_cost": 0.03}, {"conversion": 0.25, "unrest": -0.25}, "adm", ai=34, tone="hart"),
       opt("duldung", "Edikt der Duldung", "Jeder bete, wie er will, solange er Steuern zahlt. Die Bischöfe grollen, die Kaufleute atmen auf.",
           {"religious_unrest": -0.5, "trade": 0.05, "production": 0.02, "estate_klerus": -5}, {"religious_unrest": -0.15, "production": 0.02}, "dip", ai=33,
           tone="human", synergy=("aufnahme", {"trade": 0.03})),
       opt("staatskirche", "Kirche unter der Krone", "Der Herrscher ernennt die Bischöfe und verwaltet das Kirchengut.",
           {"tax": 0.05, "adm": 0.5, "estate_klerus": -10}, {"tax": 0.02}, "adm", ai=33)]),
    q("hexenwahn", "reformation", 1572, "Der Hexenhammer",
      "Missernten, kalte Sommer, totes Vieh: Irgendwer muss schuld sein. In den Dörfern brennen die ersten Scheiterhaufen, Richter verlangen Vollmachten für Folter und Sondergerichte. Ein junger Jurist am Hof wagt zu sagen, unter der Folter gestehe jeder alles.", "inquisition",
      [opt("hexenprozesse", "Die Prozesse zulassen", "Das Volk bekommt seine Schuldigen, die Richter deren Besitz. Niemand ist mehr sicher.",
           {"unrest": -1.0, "estate_klerus": 5, "tech_cost": 0.03}, {"unrest": -0.25}, "adm", ai=34, tone="hart",
           once={"gold": 60}),
       opt("folterverbot", "Folter und Hexenprozesse verbieten", "Kein Geständnis unter Zwang, keine Anklage ohne Beweis. Die Eiferer schäumen, die Universitäten horchen auf.",
           {"tech_cost": -0.04, "prestige": 0.5, "estate_klerus": -5}, {"tech_cost": -0.02, "prestige": 0.25}, "adm", ai=33, tone="human",
           synergy=("druck_frei", {"tech_cost": -0.02})),
       opt("hofgericht", "Jede Anklage vor das Hofgericht", "Die Dorfrichter verlieren die Blutgerichtsbarkeit. Langsame Akten retten Leben.",
           {"unrest": -0.5, "estate_buerger": 5, "adm": 0.25}, {"unrest": -0.25}, "adm", ai=33, tone="human")]),
    q("wissenschaft", "reformation", 1588, "Die neue Wissenschaft",
      "Fernrohre, Brennöfen, Zahlenkolonnen: Gelehrte, Scharlatane und Ordensleute bewerben sich um die Gunst und das Geld des Hofes. Alle versprechen die Zukunft.", "alchemy",
      [opt("sternwarte", "Sternwarte und Akademie", "Messen statt glauben. Der Hof bezahlt Instrumente und stellt keine Fragen zum Weltbild.",
           {"tech_cost": -0.06, "prestige": 0.25}, {"tech_cost": -0.025}, "adm", synergy=("seeschule", {"naval": 0.05})),
       opt("goldmacher", "Goldmacher am Hof", "Ein Labor im Keller des Schlosses. Vielleicht finden sie Gold. Wahrscheinlich etwas anderes.",
           {"income": 0.02, "prestige": 0.5}, {"income": 0.02}, "adm"),
       opt("ordensschulen", "Schulen der Orden", "Kollegien in jeder Bischofsstadt: Latein, Rhetorik, Gehorsam, und sehr gute Mathematik.",
           {"conversion": 0.2, "adm": 0.5, "estate_klerus": 5}, {"conversion": 0.1, "tech_cost": -0.02}, "adm")]),
    # ------------------------------------------------------------ Absolutismus
    q("staende", "absolutismus", 1604, "Krone oder Stände?",
      "Der Landtag verweigert neue Steuern, solange er nicht mitregiert. Die Minister raten, ihn nie wieder einzuberufen. Die Kasse ist in beiden Fällen leer.", "diet",
      [opt("alleinherrschaft", "Der Herrscher ist der Staat", "Regieren per Erlass, mit Intendanten statt Ständen. Schnell, einsam und teuer bewacht.",
           {"adm": 0.5, "tax": 0.05, "estate_adel": -10, "unrest": 0.25}, {"tax": 0.03}, "adm"),
       opt("mitsprache", "Mit den Ständen regieren", "Steuern nur mit Zustimmung, dafür werden sie auch gezahlt. Langsamer, aber niemand greift zur Mistgabel.",
           {"unrest": -0.5, "estate_buerger": 10, "estate_adel": 5, "tax": 0.03}, {"unrest": -0.2, "income": 0.01}, "adm", tone="human"),
       opt("aemterkauf", "Käufliche Ämter", "Jedes Amt hat seinen Preis, jeder Bau seinen Aufschlag. Die Kasse klingelt sofort.",
           {"income": 0.05, "build_cost": 0.05}, {"income": 0.02}, "adm", once={"gold": 100})]),
    q("bauern", "absolutismus", 1618, "Die Bauern und die Scholle",
      "Das Korn ist teuer, die Güter suchen Arbeiter. Die Grundherren verlangen, den Bauern das Wegziehen zu verbieten und die Frondienste zu verdoppeln. Andere Räte halten dagegen: Freie Bauern zahlen mehr Steuern und stellen bessere Soldaten.", "harvest",
      [opt("leibeigenschaft", "Die Bauern an die Scholle binden", "Fron an sechs Tagen der Woche. Die Scheunen der Herren füllen sich, die Dörfer schweigen.",
           {"production": 0.10, "tax": 0.03, "estate_adel": 10, "unrest": 0.5, "manpower": -0.05}, {"production": 0.03, "unrest": 0.25}, "adm", ai=34, tone="hart",
           once={"gold": 80}),
       opt("bauernbefreiung", "Die Bauern freigeben", "Eigener Hof, eigene Ernte, freier Abzug. Der Adel tobt, die Rekrutenlisten wachsen.",
           {"manpower": 0.10, "tax": 0.03, "estate_adel": -10, "unrest": -0.25}, {"manpower": 0.05, "production": 0.02}, "adm", ai=33, tone="human",
           synergy=("freie_arbeit", {"production": 0.03})),
       opt("erbpacht", "Erbpacht und feste Abgaben", "Der Hof bleibt in der Familie, die Abgabe steht im Buch. Wer mehr erntet, behält mehr.",
           {"tax": 0.05, "develop_cost": -0.05}, {"develop_cost": -0.03, "tax": 0.01}, "adm", ai=33, tone="human")]),
    q("kriegskasse", "absolutismus", 1630, "Der Krieg ernährt den Krieg",
      "Heere von nie gesehener Größe ziehen durch Europa, und kein Schatzamt kann sie bezahlen. Ein Kriegsunternehmer bietet an, deine Armee aus dem Land zu ernähren, durch das sie marschiert. Der Kämmerer schlägt stattdessen Anleihen vor, der Generalquartiermeister Magazine und pünktlichen Sold.", "siege",
      [opt("kontributionen", "Kontributionen eintreiben", "Jede besetzte Stadt zahlt oder brennt. Billig für die Krone, unvergessen bei allen anderen.",
           {"maintenance": -0.15, "ae_gen": 0.10, "unrest": 0.25}, {"maintenance": -0.04}, "mil", ai=34, tone="hart",
           synergy=("condottieri", {"combat": 0.03})),
       opt("staatsbank", "Staatsbank und Anleihen", "Der Krieg auf Kredit, getilgt von den Enkeln. Die Bankiers bauen gleich mit.",
           {"income": 0.04, "build_cost": -0.05}, {"income": 0.02}, "adm", ai=33, synergy=("druck_hof", {"income": 0.02})),
       opt("magazine", "Magazine und geregelter Sold", "Brot aus dem Depot statt aus dem Bauernhaus. Soldaten, die satt sind, plündern nicht und halten stand.",
           {"army_power": 0.08, "army_power_regen": 0.10, "unrest": -0.25, "maintenance": 0.03}, {"army_power": 0.03}, "mil", ai=33, tone="human",
           synergy=("ordonnanz", {"combat": 0.03}))]),
]


def pick(o):
    return {"age_pick": o}


def follow(id, option, year, title, text, image, options, extra=None, once=True):
    trig = {"age_pick": option, "year_min": year}
    trig.update(extra or {})
    return ev("age_" + id, title, text, image, trig, options, once=once)


FOLLOW = [
    # --- printing
    follow("flugschriften", "druck_frei", 1470, "Flugschriften",
           "Ein Drucker verkauft auf dem Markt ein Blatt, das deinen Schatzmeister als Dieb zeichnet. Leider stimmen die Zahlen.", "printing",
           [("Den Schatzmeister prüfen lassen.", {"adm": 25, "prestige": -1}),
            ("Selbst antworten, gedruckt und doppelt so witzig.", {"dip": 20, "prestige": 1}),
            ("Die Auflage aufkaufen.", {"gold": -20, "prestige": 1}, 8)]),
    follow("verbotene_buecher", "druck_zensur", 1470, "Die Kiste aus Basel",
           "Zöllner finden in einem Fass Heringe dreihundert verbotene Bücher. Der Zensor will sie verbrennen, dein Leibarzt hätte gern eines davon.", "printing",
           [("Verbrennen, wie das Gesetz es will.", {"estate": {"klerus": 5}, "prestige": 1}),
            ("In der Hofbibliothek wegschließen.", {"adm": 20}),
            ("Dem Leibarzt eines zustecken.", {"adm": 30, "estate": {"klerus": -4}})]),
    # --- refugees
    follow("neue_werkstaetten", "aufnahme", 1500, "Seide, Brillen, Seekarten",
           "Die Flüchtlinge von einst haben Werkstätten gegründet. In der Hauptstadt entsteht ein ganzes Viertel aus Webstühlen, Linsenschleifern und Kartenzeichnern.", "market",
           [("Ein Marktprivileg für das neue Viertel.", {"dev_capital": 1, "estate": {"buerger": 4}}),
            ("Ihre Gelehrten an den Hof holen.", {"adm": 30, "dip": 20}),
            ("Ihre Handelsfreunde in der Fremde nutzen.", {"gold": 60, "prestige": 2})]),
    follow("hetzprediger", "aufnahme", 1505, "Der Hetzprediger",
           "Ein Wanderprediger zieht durch die Vorstädte und gibt den Aufgenommenen die Schuld an Teuerung und Seuchen. Vor ihrem Viertel sammelt sich eine Menge.", "revolt",
           [("Die Stadtwache vor das Viertel stellen.", {"mil": -10, "prestige": 2}),
            ("Den Prediger des Landes verweisen.", {"estate": {"klerus": -4}, "adm": 10}),
            ("Den Schutzbrief öffentlich erneuern.", {"dip": 15, "estate": {"buerger": 3}})]),
    follow("leere_gassen", "vertreibung", 1500, "Leere Gassen",
           "Die Seidenweberei steht still, der einzige Arzt der Hafenstadt ist fort, und die Schuldscheine, die die Krone eingezogen hat, will niemand einlösen. Die Zünfte fragen, wer nun die Steuern zahlen soll.", "town_fire",
           [("Fremde Handwerker anwerben.", {"gold": -40, "dev_random": 1}, 8),
            ("Es aussitzen.", {"dev_random": -1, "estate": {"buerger": -4}}),
            ("Den Vertriebenen die Rückkehr anbieten.", {"age_pick": ["vertriebene", "schutzgeld"], "prestige": -3, "estate": {"klerus": -5}}, 30)]),
    follow("schutzgeld_streit", "schutzgeld", 1500, "Der Preis des Bleibens",
           "Der Schatzmeister will das Schutzgeld verdoppeln. Die Gemeinden antworten höflich, dass Antwerpen und Saloniki nichts verlangen.", "bank",
           [("Beim alten Satz bleiben.", {"dip": 15, "estate": {"buerger": 3}}),
            ("Verdoppeln.", {"gold": 70, "dev_random": -1}),
            ("Das Schutzgeld abschaffen, Zuflucht ohne Preis.", {"age_pick": ["vertriebene", "aufnahme"]}, 20)]),
    # --- slave trade and its alternatives
    follow("schiffsaufstand", "sklavenhandel", 1525, "Aufstand an Bord",
           "Auf einem Schiff deiner Lizenznehmer haben die Gefangenen die Ketten gesprengt und die Mannschaft überwältigt. Sie segeln zurück nach Afrika. Die Reeder verlangen Kriegsschiffe und Entschädigung.", "naval",
           [("Sie ziehen lassen.", {"prestige": 1, "estate": {"buerger": -3}}),
            ("Die Reeder entschädigen.", {"gold": -50}, 8),
            ("Kriegsschiffe hinterherschicken.", {"mil": -20, "prestige": -2, "estate": {"buerger": 3}})]),
    follow("moench_klagt_an", "sklavenhandel", 1540, "Die Predigt",
           "Am Adventssonntag steigt ein Dominikaner auf die Kanzel der Hofkirche und fragt die versammelten Herren: Mit welchem Recht haltet ihr diese Menschen in so grausamer Knechtschaft? Sind sie keine Menschen? Die Reeder verlassen die Kirche, der Hof wartet auf dein Wort.", "church",
           [("Den Mönch reden lassen, mehr nicht.", {"prestige": -1, "estate": {"klerus": -3}}),
            ("Ihn in ein fernes Kloster versetzen.", {"prestige": -3, "estate": {"buerger": 3}}),
            ("Er hat recht: die Lizenzen widerrufen, freie Arbeit einführen.", {"age_pick": ["menschenhandel", "freie_arbeit"], "prestige": 6, "gold": -60, "estate": {"klerus": 5}}, 10)]),
    follow("entlaufene", "sklavenhandel", 1560, "Die Freien in den Bergen",
           "Entflohene haben in den Bergen eigene Dörfer gegründet, mit Palisaden, Feldern und einem gewählten König. Jede Strafexpedition kehrt kleiner zurück.", "revolt",
           [("Einen Vertrag schließen: ihre Freiheit gegen Frieden.", {"dip": -15, "prestige": 2}),
            ("Die nächste Expedition ausrüsten.", {"manpower": -400, "mil": -15}),
            ("Wegsehen.", {"prestige": -2, "estate": {"adel": -3}})]),
    follow("abschaffung", "sklavenhandel", 1600, "Die Bittschrift",
           "Zehntausend Unterschriften, gesammelt von Handwerkern, Pfarrern und ehemaligen Seeleuten: Der Menschenhandel soll enden. Die Pflanzer drohen mit dem Ruin, die Hafenstädte mit Aufruhr, und in den Kolonien wächst die Angst vor dem nächsten Aufstand.", "diet",
           [("Die Bittschrift zu den Akten legen.", {"prestige": -3, "we": 1}),
            ("Den Handel verbieten, die Pflanzer entschädigen.", {"age_pick": ["menschenhandel", "freie_arbeit"], "gold": -120, "prestige": 8}, 10),
            ("Den Handel verbieten, ohne einen Heller.", {"age_pick": ["menschenhandel", "freie_arbeit"], "prestige": 8, "estate": {"buerger": -8, "adel": -5}}, 35)]),
    follow("siedlerstrom", "freie_arbeit", 1535, "Land für jeden",
           "Die Kunde geht durch die Dörfer: Drüben bekommt jeder, der arbeitet, eigenen Boden. Zweite Söhne, Tagelöhner und entlassene Soldaten drängen auf die Schiffe.", "exploration",
           [("Die Überfahrt bezuschussen.", {"gold": -30, "dev_random": 2}, 8),
            ("Handwerker bevorzugen.", {"dev_random": 1, "adm": 15}),
            ("Die Besten für die Garnisonen werben.", {"manpower": 600})]),
    follow("lohnstreit", "freie_arbeit", 1555, "Der Lohn der Freien",
           "Die Pflanzer klagen: Freie Arbeiter verlangen das Doppelte und gehen, wenn es ihnen nicht passt. Die Nachbarreiche verkaufen ihren Zucker billiger.", "market",
           [("Standhaft bleiben, der Ruf ist mehr wert.", {"prestige": 3, "estate": {"buerger": -3}}),
            ("Mühlen und Pressen fördern statt Hände.", {"adm": -20, "mods": {"production": 0.02}}),
            ("Schutzzölle gegen Zucker aus Sklavenarbeit.", {"dip": -15, "gold": 50})]),
    follow("gesandte_afrika", "afrika_handel", 1530, "Gesandte aus dem Süden",
           "Eine Gesandtschaft aus dem Königreich Kongo zieht in die Hauptstadt ein: Adlige in Samt und Leopardenfell, ein Prinz, der fließend Latein spricht, Geschenke aus Elfenbein und Raffiabast. Der Hof staunt.", "procession",
           [("Sie mit allen Ehren empfangen.", {"prestige": 4, "dip": 20}),
            ("Den Prinzen an der Universität studieren lassen.", {"adm": 25, "prestige": 2}),
            ("Einen festen Handelsvertrag aushandeln.", {"gold": 70})]),
    follow("goldkueste", "afrika_handel", 1550, "Gold statt Ketten",
           "Deine Faktoren melden: Weil dein Reich keine Menschen kauft, öffnen die Könige der Küste ihm Märkte, die den Sklavenhändlern verschlossen bleiben. Die Konkurrenz streut Gerüchte an den Börsen.", "bank",
           [("Den Vorsprung ausbauen.", {"mods": {"trade": 0.02}}),
            ("Den Gewinn in die Flotte stecken.", {"ships": 3}),
            ("Die Gerüchte mit Zahlen widerlegen.", {"dip": 20, "prestige": 2})]),
    # --- conquered lands
    follow("silberberg", "zwangsarbeit", 1545, "Der Berg, der Menschen frisst",
           "Aus den Silberminen kommt ein Bericht, den der Statthalter zurückhalten wollte: Von zehn Zwangsarbeitern, die in den Berg gehen, kommen sieben nicht zurück. Ganze Täler sind entvölkert. Das Silber fließt weiter.", "mine",
           [("Die Schichten verkürzen.", {"gold": -40, "prestige": 2}, 8),
            ("Nichts ändern.", {"gold": 60, "prestige": -3, "dev_random": -1}),
            ("Die Zwangsarbeit beenden, Schutzgesetze erlassen.", {"age_pick": ["unterworfene", "schutzgesetze"], "prestige": 6, "estate": {"adel": -6}}, 25)]),
    follow("grosser_aufstand", "zwangsarbeit", 1570, "Der große Aufstand",
           "Ein Nachfahre der alten Könige hat die Dörfer hinter sich gebracht. Statthalter fliehen, Minen stehen still, und seine Boten fordern nur eines: das Ende der Fron.", "revolt",
           [("Verhandeln und die Fron mildern.", {"dip": -20, "prestige": 1}),
            ("Den Aufstand niederschlagen.", {"manpower": -800, "we": 2, "prestige": -2}),
            ("Nachgeben: Selbstverwaltung unter den alten Fürsten.", {"age_pick": ["unterworfene", "selbstverwaltung"], "prestige": 3}, 25)]),
    follow("siedler_murren", "schutzgesetze", 1545, "Die Siedler murren",
           "Eine Abordnung der Siedler steht vor dem Thron: Ohne Zwangsarbeiter könnten sie ihre Güter nicht halten. Einige drohen offen, sich einen anderen König zu suchen.", "diet",
           [("Fest bleiben. Das Gesetz gilt für alle.", {"prestige": 3, "estate": {"adel": -4}}),
            ("Ihnen Steuern erlassen.", {"gold": -40, "estate": {"adel": 3}}, 8),
            ("Die Wortführer nach Hause schicken, in Ketten.", {"adm": 15, "estate": {"adel": -6}})]),
    follow("treue_untertanen", "schutzgesetze", 1565, "Die Klage vor dem König",
           "Ein Dorf am anderen Ende der Welt hat seinen Statthalter verklagt und vor deinem Gericht gewonnen. Die Nachricht verbreitet sich schneller als jedes Heer: Bei diesem König bekommt man Recht.", "treaty",
           [("Das Urteil überall verlesen lassen.", {"prestige": 4, "dip": 15}),
            ("Freiwillige aus den Provinzen annehmen.", {"manpower": 700}),
            ("Die dankbaren Dörfer zahlen pünktlich.", {"gold": 60})]),
    follow("fuerstenrat", "selbstverwaltung", 1555, "Der Rat der alten Fürsten",
           "Die verbündeten Fürsten der eroberten Länder kommen zum ersten Mal gemeinsam an deinen Hof. Sie bringen Krieger, Geschenke und eine lange Liste von Wünschen.", "coronation",
           [("Ihre Krieger in das Heer aufnehmen.", {"manpower": 800, "mil": 15}),
            ("Ihre Söhne am Hof erziehen.", {"dip": 25, "prestige": 2}),
            ("Die Wünsche prüfen. Gründlich. Jahrelang.", {"adm": 20})]),
    # --- faith, witches, science
    follow("gelehrte_fliehen", "glaubensgerichte", 1565, "Die leeren Lehrstühle",
           "Drei Professoren sind über Nacht geflohen, einer mit der halben Sternwarte im Gepäck. An der Universität lehrt nun der Neffe des Großinquisitors Mathematik.", "inquisition",
           [("So sei es.", {"adm": -15, "estate": {"klerus": 3}}),
            ("Den Gerichten die Universitäten entziehen.", {"adm": 20, "estate": {"klerus": -5}}),
            ("Die Gerichte auflösen, ein Edikt der Duldung erlassen.", {"age_pick": ["glaubensfrage", "duldung"], "prestige": 3, "estate": {"klerus": -8}}, 15)]),
    follow("zwei_kirchen", "duldung", 1565, "Zwei Türme, ein Markt",
           "In der Hauptstadt teilen sich zwei Bekenntnisse eine Kirche: die einen um acht, die anderen um zehn. Der Küster hat doppelte Arbeit, der Markt doppelt so viele Kunden.", "church",
           [("Ein Zeichen für das ganze Reich.", {"prestige": 3, "estate": {"buerger": 4}}),
            ("Zugezogene Kaufleute begrüßen.", {"gold": 50, "dev_capital": 1}),
            ("Die Prediger zum Streitgespräch laden, ohne Messer.", {"dip": 20, "adm": 10})]),
    follow("denunziation", "hexenprozesse", 1580, "Die Liste",
           "Unter der Folter hat eine Angeklagte vierzig Namen genannt. Darunter: die Frau des Bürgermeisters, zwei Domherren und die Amme deines Erben. Der Richter bittet um Anweisung.", "inquisition",
           [("Die Liste verbrennen und den Richter entlassen.", {"prestige": 1, "estate": {"klerus": -4}}),
            ("Das Gesetz nimmt seinen Lauf.", {"dev_random": -1, "prestige": -3, "estate": {"buerger": -5}}),
            ("Genug. Folter und Hexenprozesse werden verboten.", {"age_pick": ["hexenwahn", "folterverbot"], "prestige": 4}, 30)]),
    follow("streitschrift", "folterverbot", 1585, "Die Streitschrift",
           "Ein Beichtvater, der zweihundert Verurteilte zum Scheiterhaufen begleitet hat, schreibt anonym ein Buch: Keine einzige sei schuldig gewesen. Es wird in deinem Reich gedruckt, weil es nirgends sonst gedruckt werden darf.", "printing",
           [("Den Druck beschützen.", {"prestige": 4, "adm": 15}),
            ("Den Verfasser an die Universität berufen.", {"adm": 30}),
            ("Das Buch an alle Nachbarhöfe schicken.", {"dip": 25, "prestige": 2})]),
    follow("phosphor", "goldmacher", 1595, "Das kalte Feuer",
           "Dein Goldmacher hat sechzig Eimer Harn eingekocht, um Gold zu gewinnen. Herausgekommen ist ein weißes Wachs, das im Dunkeln leuchtet und von selbst zu brennen beginnt. Gold ist es nicht. Der Hof ist trotzdem begeistert.", "alchemy",
           [("Bei jedem Fest vorführen.", {"prestige": 4}),
            ("Das Rezept teuer an andere Höfe verkaufen.", {"gold": 80}),
            ("Den Mann weiterforschen lassen, mit besserer Lüftung.", {"adm": 30})]),
    follow("porzellan", "goldmacher", 1610, "Weißes Gold",
           "Um dem Galgen zu entgehen, hat dein eingesperrter Goldmacher etwas anderes erfunden: hartes, weißes, durchscheinendes Porzellan, wie es sonst nur aus China kommt. Er fragt höflich, ob das auch zählt.", "alchemy",
           [("Es zählt. Eine Manufaktur gründen.", {"mods": {"production": 0.03}, "prestige": 3}),
            ("Das Geheimnis streng bewachen und teuer verkaufen.", {"gold": 150}),
            ("Ihn freilassen und adeln.", {"prestige": 4, "adm": 20})]),
    follow("explosion", "goldmacher", 1600, "Der Knall im Schlosskeller",
           "Kurz nach Mitternacht fliegt das Labor in die Luft. Der Goldmacher sitzt rußgeschwärzt, aber glücklich im Hof und spricht von einem Durchbruch. Der Westflügel hat kein Dach mehr.", "town_fire",
           [("Das Labor vor die Stadtmauer verlegen.", {"gold": -30, "adm": 15}, 8),
            ("Die Mischung den Kanonieren zeigen.", {"mil": 35}),
            ("Der Westflügel war ohnehin hässlich.", {"prestige": 1})]),
    follow("neuer_stern", "sternwarte", 1604, "Der neue Stern",
           "Am Abendhimmel steht ein Stern, der gestern nicht da war. Deine Astronomen messen Nacht für Nacht und stellen fest: Er steht weit hinter dem Mond, dort, wo sich nach der Lehre der Alten nie etwas ändern darf.", "comet",
           [("Die Messungen drucken lassen.", {"adm": 30, "prestige": 3}),
            ("Erst die Theologen fragen.", {"estate": {"klerus": 4}, "adm": 10}),
            ("Den Stern nach deinem Haus benennen.", {"prestige": 5})]),
    # --- estates, peasants, war chest
    follow("fronde", "alleinherrschaft", 1620, "Barrikaden",
           "Die Richter des obersten Gerichts weigern sich, deine Erlasse einzutragen. Am Morgen stehen Ketten über den Straßen der Hauptstadt und der Adel reitet auf seine Güter.", "revolt",
           [("Nachts die Rädelsführer verhaften.", {"estate": {"adel": -6}, "adm": 20}),
            ("Zum Schein nachgeben und abwarten.", {"prestige": -2, "estate": {"adel": 5}}),
            ("Die Stände doch wieder einberufen.", {"age_pick": ["staende", "mitsprache"], "prestige": -2}, 15)]),
    follow("budget_debatte", "mitsprache", 1620, "Die längste Sitzung",
           "Seit elf Tagen streitet der Landtag über die Biersteuer. Ein Abgeordneter redet seit sechs Stunden, zwei sind eingeschlafen, einer ist ein Hund. Am Ende steht ein Haushalt, den tatsächlich alle bezahlen wollen.", "diet",
           [("Unterschreiben.", {"gold": 80, "estate": {"buerger": 3}}),
            ("Unterschreiben und den Hund ehrenhalber adeln.", {"prestige": 3, "gold": 40}),
            ("Die Geschäftsordnung straffen.", {"adm": 30})]),
    follow("bauernflucht", "leibeigenschaft", 1630, "Die Dörfer leeren sich",
           "Nachts ziehen ganze Familien über die Grenze, zu den Kosaken, in die Städte, in die Sümpfe. Die Gutsherren verlangen Reiter, um die eigenen Bauern zu jagen.", "famine",
           [("Die Fron auf drei Tage begrenzen.", {"prestige": 1, "estate": {"adel": -5}}),
            ("Reiter schicken.", {"mil": -15, "dev_random": -1, "estate": {"adel": 4}}),
            ("Es hat keinen Sinn: die Bauern freigeben.", {"age_pick": ["bauern", "bauernbefreiung"], "prestige": 4}, 20)]),
    follow("freie_hoefe", "bauernbefreiung", 1630, "Der dritte Acker",
           "Bauern, denen die Ernte gehört, probieren Dinge aus: Klee auf der Brache, Rüben fürs Vieh, eine seltsame Knolle aus Übersee. Die Zehntscheunen sind zu klein geworden.", "harvest",
           [("Die neuen Methoden überall bekannt machen.", {"dev_random": 2}),
            ("Den Überschuss besteuern, maßvoll.", {"gold": 80}),
            ("Die Söhne der Freibauern als Unteroffiziere werben.", {"manpower": 700, "mil": 15})]),
    follow("verbrannte_stadt", "kontributionen", 1635, "Die Stadt, die nicht zahlen konnte",
           "Eine belagerte Stadt konnte die geforderte Summe nicht aufbringen. Deine Söldner haben sie drei Tage lang geplündert und angezündet. Flugblätter mit dem Bild der brennenden Türme gehen durch ganz Europa.", "town_fire",
           [("Die Obristen vor ein Kriegsgericht stellen.", {"prestige": 2, "mil": -20}),
            ("Schweigen.", {"prestige": -4, "ae": 5}),
            ("Schluss damit: Magazine und Sold statt Plünderung.", {"age_pick": ["kriegskasse", "magazine"], "prestige": 3, "gold": -60}, 10)]),
    follow("volle_magazine", "magazine", 1635, "Brot auf dem Marsch",
           "Zum ersten Mal marschiert ein Heer durch die eigenen Dörfer, ohne dass die Bauern das Vieh in den Wald treiben. Die Soldaten zahlen sogar für die Hühner. Meistens.", "camp",
           [("Die Ordnung zum Vorbild erklären.", {"prestige": 3, "army_power": 0.1}),
            ("Die dankbaren Dörfer stellen Rekruten.", {"manpower": 600}),
            ("Den Quartiermeister befördern.", {"mil": 30})]),
]


def fun(id, year, title, text, image, options, extra=None):
    trig = {"year_min": year, "is_player": True}
    trig.update(extra or {})
    return ev("age_fun_" + id, title, text, image, trig, options)


FUN = [
    fun("tanzwut", 1518, "Die Tanzwut",
        "In einer deiner Städte beginnt eine Frau auf der Gasse zu tanzen und hört nicht mehr auf. Nach einer Woche tanzen vierhundert, manche bis zum Umfallen. Die Ärzte empfehlen: mehr Tanz. Der Rat hat bereits Musikanten bestellt.", "plague",
        [("Musikanten und eine Bühne, die Ärzte werden es wissen.", {"prestige": -1, "adm": 10}),
         ("Die Tänzer zu einer Wallfahrt führen.", {"estate": {"klerus": 4}}),
         ("Die Musikanten nach Hause schicken und abwarten.", {"adm": 20})], {"year_max": 1560}),
    fun("elefant", 1505, "Ein Elefant bei Hofe",
        "Ein fremder König schickt dir zum Geschenk einen weißen Elefanten. Er kann sich verbeugen, mit dem Rüssel Wasser spritzen und frisst am Tag so viel wie eine Kompanie Landsknechte.", "procession",
        [("Er zieht bei jedem Fest voran.", {"prestige": 4, "gold": -20}, 8),
         ("Dem Papst weiterschenken.", {"dip": 25, "prestige": 1}),
         ("Einen Maler rufen, bevor er alles auffrisst.", {"prestige": 2, "adm": 10})]),
    fun("einhorn", 1480, "Das Horn des Einhorns",
        "Ein Händler aus dem Norden bietet ein gedrehtes Horn an, zwei Klafter lang, garantiert vom Einhorn, wirksam gegen jedes Gift. Dein Leibarzt meint, es rieche nach Fisch.", "market",
        [("Kaufen. Ein Herrscher braucht ein Einhorn.", {"gold": -60, "prestige": 5}, 8),
         ("Den Leibarzt das Horn prüfen lassen.", {"adm": 20}),
         ("Den Händler fragen, wo diese Einhörner schwimmen.", {"dip": 15, "prestige": 1})]),
    fun("schwein", 1460, "Das Schwein vor Gericht",
        "Ein Schwein hat im Dorf ein Kind umgerannt. Der Dorfrichter hat ihm den Prozess gemacht, mit Verteidiger und Zeugen. Der Verteidiger hat Berufung eingelegt, sie liegt nun auf deinem Tisch.", "diet",
        [("Das Urteil bestätigen, Ordnung muss sein.", {"adm": 10, "prestige": -1}),
         ("Freispruch wegen Unzurechnungsfähigkeit.", {"prestige": 1, "estate": {"buerger": 2}}),
         ("Den Verteidiger einstellen. Der Mann ist gut.", {"adm": 25})]),
    fun("reinheitsgebot", 1516, "Der Bierstreit",
        "Brauer strecken das Bier mit Ochsengalle, Ruß und Stechapfel. Nach einem besonders bunten Markttag verlangt die Stadt ein Gesetz: nur Gerste, Hopfen und Wasser.", "tavern",
        [("Das Gebot erlassen.", {"estate": {"buerger": 5}, "prestige": 1}),
         ("Eine Biersteuer gleich dazu.", {"gold": 50, "estate": {"buerger": -2}}),
         ("Erst gründlich selbst verkosten.", {"prestige": 1, "adm": -5})], {"year_max": 1580}),
    fun("flugmaschine", 1490, "Der Mann, der fliegen will",
        "Ein Maler und Ingenieur zeigt dir Zeichnungen: ein Wagen mit Kanonen ringsum, ein Boot unter Wasser, Flügel für Menschen. Er bittet um Geld, einen Turm und einen Freiwilligen.", "artist",
        [("Geld und Turm. Den Freiwilligen sucht er selbst.", {"gold": -40, "adm": 30, "prestige": 2}, 8),
         ("Er soll lieber Festungen zeichnen.", {"mil": 30}),
         ("Er soll lieber mein Porträt malen.", {"prestige": 4})], {"year_max": 1530}),
    fun("falscher_prinz", 1470, "Der falsche Prinz",
        "In einer Hafenstadt behauptet ein junger Mann, der totgeglaubte Erbe eines Nachbarthrons zu sein. Er hat die Nase der Familie, tadellose Manieren und Schulden bei jedem Wirt.", "conspiracy",
        [("Mit Ehren empfangen. Man weiß ja nie.", {"dip": 20, "prestige": -1}),
         ("Dem Nachbarn ausliefern.", {"dip": 10, "gold": 40}),
         ("Als Tanzlehrer anstellen.", {"prestige": 2})]),
    fun("komet", 1531, "Der Schweifstern",
        "Ein Komet steht am Himmel, so hell, dass er Schatten wirft. Die Prediger verkünden das Ende, die Wirte verkaufen Kometenwein, dein Astrologe bittet um eine Gehaltserhöhung.", "comet",
        [("Bußprozessionen anordnen.", {"estate": {"klerus": 4}}),
         ("Den Astrologen eine Vorhersage wagen lassen. Schriftlich.", {"adm": 15, "prestige": 1}),
         ("Kometenwein für den Hof.", {"prestige": 2, "gold": -10}, 8)]),
    fun("kartoffel", 1590, "Die Teufelsknolle",
        "Aus Übersee kommt eine Knolle, die auf schlechtem Boden wächst und satt macht. Die Bauern rühren sie nicht an: Sie steht nicht in der Bibel. Ein Rat schlägt vor, das Feld von Soldaten bewachen zu lassen, damit die Leute sie für wertvoll halten und nachts stehlen.", "harvest",
        [("Bewachen lassen, aber nachts schlecht.", {"dev_random": 2, "prestige": 1}),
         ("Per Erlass anordnen.", {"dev_random": 1, "estate": {"adel": -2}}),
         ("Sie zuerst an der Hoftafel servieren.", {"prestige": 3})]),
    fun("kaffeehaus", 1610, "Der Türkentrank",
        "Ein Armenier eröffnet in der Hauptstadt ein Haus, in dem ein bitteres schwarzes Getränk ausgeschenkt wird. Die Gäste schlafen nicht mehr, lesen Zeitung und reden über Politik. Die Brauer verlangen ein Verbot, der Klerus auch.", "tavern",
        [("Erlauben. Wache Untertanen rechnen besser.", {"adm": 25, "estate": {"buerger": 4}}),
         ("Erlauben und besteuern.", {"gold": 60}),
         ("Selbst probieren, dann entscheiden. Um drei Uhr nachts.", {"prestige": 2, "dip": 15})]),
    fun("tulpen", 1634, "Das Tulpenfieber",
        "Für eine einzige Blumenzwiebel wird in den Städten der Preis eines Stadthauses gezahlt. Dein Kämmerer hat heimlich drei gekauft. Dein Koch hat eine davon für eine Zwiebel gehalten.", "bank",
        [("Den Handel mit Zwiebeln auf Zeit verbieten.", {"adm": 15, "estate": {"buerger": -3}}),
         ("Mitspielen und rechtzeitig verkaufen.", {"gold": 120, "prestige": -1}),
         ("Den Koch befördern. Er hat als Einziger den wahren Wert erkannt.", {"prestige": 3})]),
    fun("wunderkammer", 1560, "Die Wunderkammer",
        "Dein Hofmeister schlägt eine Sammlung vor, wie sie jeder Fürst von Rang besitzt: ein ausgestopftes Krokodil, ein Kirschkern mit hundert geschnitzten Gesichtern, eine Uhr, die Enten nachahmt, und ein Stück vom Turm zu Babel (mit Echtheitsbrief).", "scholar",
        [("Einrichten und Gästen vorführen.", {"gold": -50, "prestige": 5}, 8),
         ("Nur das Nützliche: Instrumente und Karten.", {"adm": 25}),
         ("Den Echtheitsbrief prüfen lassen.", {"dip": 15, "prestige": 1})]),
    fun("riesenkanone", 1465, "Die größte Kanone der Welt",
        "Ein Gießer bietet an, ein Geschütz zu bauen, dessen Kugel ein Mann nicht umfassen kann. Sechzig Ochsen ziehen es, es schießt siebenmal am Tag, und beim Probeschuss sei bisher fast niemand gestorben.", "artillery",
        [("Gießen lassen. Allein der Anblick bricht Mauern.", {"gold": -60, "mil": 40, "prestige": 2}, 8),
         ("Lieber zwanzig kleine.", {"mil": 30}),
         ("Den Gießer höflich an den Rivalen empfehlen.", {"dip": 20})], {"year_max": 1520}),
    fun("astrologe", 1500, "Die Prophezeiung",
        "Dein Hofastrologe sagt für den kommenden Februar eine Sintflut voraus. In der Stadt werden Boote auf Dächer gebaut, ein Graf hat eine Arche für seine Familie und zwei Musikanten bestellt.", "scholar",
        [("Die Leute beruhigen.", {"adm": 15}),
         ("Vorsichtshalber Korn einlagern.", {"gold": -20, "prestige": 2}, 8),
         ("Dem Astrologen sagen: Im März sprechen wir über sein Gehalt.", {"prestige": 2, "dip": 10})], {"year_max": 1560}),
    fun("kalte_sommer", 1601, "Das Jahr ohne Sommer",
        "Im Juni fällt Schnee, die Sonne steht rot und matt am Himmel, der Wein erfriert am Stock. Seeleute erzählen, am anderen Ende der Welt sei ein Berg explodiert. Niemand glaubt ihnen.", "volcano",
        [("Die Kornspeicher öffnen.", {"gold": -40, "prestige": 3}, 8),
         ("Die Ausfuhr von Getreide verbieten.", {"adm": -15, "estate": {"buerger": -3}}),
         ("Die Seeleute befragen und alles aufschreiben lassen.", {"adm": 20})], {"year_max": 1640}),
    fun("hofnarr", 1450, "Die Wahrheit des Narren",
        "Bei Tisch fragt dein Narr laut, warum der Kanzler jedes Jahr ein neues Schloss baut, während die Krone Schulden macht. Der Kanzler lacht als Einziger nicht.", "court",
        [("Lachen und es dabei belassen.", {"prestige": 1}),
         ("Die Bücher des Kanzlers prüfen lassen.", {"gold": 70, "estate": {"adel": -4}}),
         ("Den Narren zum Rechnungsprüfer ernennen.", {"adm": 30, "prestige": -1})]),
    fun("uhr", 1475, "Die Uhr, die alles weiß",
        "Ein Uhrmacher hat für den Rathausturm ein Werk gebaut, das Stunden, Mondphasen, Sternzeichen und Feiertage zeigt, dazu zwölf Apostel, die zu jeder vollen Stunde vorbeiziehen. Die Stadträte fürchten, er könne eine noch schönere für die Nachbarstadt bauen.", "city",
        [("Ihn fürstlich bezahlen und im Land halten.", {"gold": -30, "prestige": 4}, 8),
         ("Ihn zum Lehrmeister einer Zunft machen.", {"dev_capital": 1}),
         ("Die Stadträte daran erinnern, dass Blenden verboten ist.", {"adm": 15, "prestige": 1})]),
    fun("tabak", 1575, "Rauch aus dem Mund",
        "Ein Seemann wird auf dem Markt mit Wasser übergossen: Aus seinem Mund quoll Rauch, man hielt ihn für besessen. Er erklärt, das sei ein Kraut aus der Neuen Welt und sehr gesund.", "tavern",
        [("Das Kraut besteuern, bevor es jemand verbietet.", {"gold": 60}),
         ("Die Ärzte ein Gutachten schreiben lassen.", {"adm": 20}),
         ("Dem Mann ein trockenes Hemd geben.", {"prestige": 1, "estate": {"buerger": 2}})]),
]


def question_event(qd):
    opts = [("%s. %s" % (o["name"], o["text"]), pick([qd["id"], o["id"]]), o["ai"]) for o in qd["options"]]
    return ev("age_q_" + qd["id"], qd["title"], qd["text"], qd["image"], {}, opts, manual=True)


def main():
    ids = set()
    for qd in QUESTIONS:
        assert len(qd["options"]) == 3, qd["id"]
        for o in qd["options"]:
            assert o["id"] not in ids, o["id"]
            ids.add(o["id"])
    for qd in QUESTIONS:
        for o in qd["options"]:
            assert "synergy" not in o or o["synergy"]["with"] in ids, o["id"]
    events = [question_event(qd) for qd in QUESTIONS] + FOLLOW + FUN
    for e in events:
        trig = e["trigger"]
        assert "age_pick" not in trig or trig["age_pick"] in ids, e["id"]
        for o in e["options"]:
            p = o["effects"].get("age_pick")
            assert p is None or (p[1] in ids and any(qd["id"] == p[0] for qd in QUESTIONS)), e["id"]
    doc = {"_doc": "Generated by tools/content/age_decisions.py, edit there.", "max_level": 3, "up_cost": [100, 160],
           "ai_up_chance": 0.2, "ages": AGES, "questions": QUESTIONS}
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("{\n")
        for k in ("_doc", "max_level", "up_cost", "ai_up_chance", "ages"):
            f.write(' "%s": %s,\n' % (k, json.dumps(doc[k], ensure_ascii=False)))
        f.write(' "questions": [\n')
        f.write(",\n".join("  " + json.dumps(qd, ensure_ascii=False) for qd in QUESTIONS))
        f.write("\n ]\n}\n")
    data = events_io.replace_block("age_", events)
    print("ages.json: %d questions, %d options; events.json: %d events (%d age_)" % (
        len(QUESTIONS), len(ids), len(data), len(events)))


if __name__ == "__main__":
    main()
