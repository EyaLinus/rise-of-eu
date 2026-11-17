# Performance-Plan: ganze Weltkarte flüssig auf Android und PC

Stand 2026-11-17, Code-Stand `main` f1491bc (v1.0.0 + Afrika). Alle Zahlen sind auf **einem Kern
eines Cloud-Xeon @ 2.1 GHz** gemessen (Referenz-CPU = 1,0×). Wie schnell das auf Linus' Handy und PC ist,
ist **nicht gemessen** (siehe „Offene Fragen“).

## 0. Entscheidungen (Linus, 2026-11-17) und Stand

- **Zielgröße: ~1000 Provinzen.**
- **Geschwindigkeit:** Stufe 1 (1,2 s je Monat) muss flüssig laufen, Stufe 2 (0,6 s) ist Bonus,
  **Stufen 3–5 werden entfernt.** Damit ist das Budget nicht „möglichst viele Monate pro Sekunde“,
  sondern: **ein Monat muss in 600 ms fertig sein (Stufe 2) und darf nie einen Frame einfrieren.**
  Bei 1000 Provinzen und einem Handy, das 3× langsamer ist als die Referenz-CPU, heißt das:
  Ø-Tick auf der Referenz-CPU ≤ ~150 ms (Stufe 2) bzw. ≤ ~300 ms (Stufe 1), **und** die Simulation
  muss aus dem Hauptthread raus. Folge: **Phase 2 (Thread) vor Phase 4 (KI)**.
- Gerätewerte vom Handy/PC folgen später.

**Phase 1 erledigt** (gleicher PR): Modifikator-Cache je Nation (`Nation.modv`, `set_bonus`/`clear_bonus`),
Vasallen-/Embargo-Index (`Nation.links_ver`), Marine nur bei Bedarf, Event-Index je Tag mit Jahresgrenzen.
Ergebnis 40 Jahre Seed 7: **93,7 → 65,8 ms/Tick (−30 %)**, schlimmster Tick 322 → 273 ms.
Spielverlauf **bitgenau identisch** zu `main` (`tools/state_hash.gd`, 40 Jahre, Seeds 7 und 11).
Die Jahres-Staffelung (Option C, Teil 2) ändert den Spielverlauf und wandert deshalb nach Phase 4,
mit Balance-Läufen; mit dem Thread aus Phase 2 ist der Jahres-Spike ohnehin unsichtbar.

**Phase 2a erledigt** (gleicher PR), **ohne Thread**: Statt die Simulation in einen Hintergrund-Thread zu
legen (Race Conditions mit jeder UI-Leseoperation, Web-Export bräuchte SharedArrayBuffer), wird ein Monat
in **Schritte** zerlegt (`Game.tick_begin()` / `tick_step()`: ein Schritt je Reich bzw. je Weltsystem,
Jahresarbeit ebenso). `main.gd` rechnet je Frame ~5 ms (10 ms, wenn der nächste Monat schon fällig ist)
und reicht den fertigen Monat dann an die UI. `tick()` läuft dieselben Schritte am Stück, deshalb bleibt der
Spielverlauf bitgenau gleich. Speichern beendet einen angefangenen Monat erst (`finish_tick()`).
Längster Einzelschritt heute 14–19 ms (Armeen, KI eines großen Reichs im Krieg) statt 220–370 ms für
einen ganzen Monat. Geschwindigkeitsstufen 3–5 entfernt. Neuer CI-Check `tools/month_steps_smoke.gd`.
Rest-Ruckler: `_after_tick` (Panel-Neuaufbau ~30–40 ms) → Phase 2b.

**Phase 3a erledigt** (Texturen, Option H ohne Kacheln): Terrain-Texturen VRAM-komprimiert (S3TC auf PC,
ETC2 auf Android) mit Mipmaps: Texturspeicher **95 → 31 MB**, Videospeicher 108 → 44 MB. Optisch im
Screenshot-Vergleich kein sichtbarer Unterschied. APK wächst um ~8 MB (komprimierte Texturen sind größer als
das verlustfreie Format auf der Platte, dafür viel kleiner im Grafikspeicher).

Werkzeuge (alle neu bzw. überarbeitet in diesem PR):

| Werkzeug | Was es misst |
|---|---|
| `tools/perf.gd -- --years 60 --every 20` | echte `Game.tick()` mit eingebautem Profiler (`g.prof`), Zeit je Phase, schlimmster Tick, Speicher, Savegröße, Save/Load-Zeit, optional `--json` |
| `tools/render_perf.gd` (xvfb + opengl3) | Draw Calls / Primitive je Zoomstufe, Kosten von `map.refresh()`, Kosten pro Monat im UI (`_after_tick` aufgeteilt), Kosten je Panel, Textur-/Videospeicher |
| `Game._pmark(key)` | Profiler-Marke im Kern; ohne `g.prof` ein No-op (Kosten < 0,1 %) |
| `tools/state_hash.gd -- --years 40 [--seed N] [--dump f.json]` | Hash des kompletten Spielstands je Jahr: reine Performance-Änderungen müssen **identische** Hashes wie `main` liefern |

---

## 1. Baseline (gemessen)

### 1.1 Simulation (474 Provinzen, 98 Nationen, Seed 7, Spieler FRA, 100 Jahre)

| Zeitraum | ms/Tick | schlimmster Tick | lebende Reiche | Armeen |
|---|---|---|---|---|
| 1444–1469 | 90 | 360 | 93 | 98 |
| 1469–1494 | 100 | 376 | 85 | 108 |
| 1494–1519 | 91 | 302 | 76 | 104 |
| 1519–1544 | 91 | 328 | 70 | 116 |

Aufteilung (1444–1469, Anteil am Tick):

| Phase | ms/Tick | % | Bemerkung |
|---|---|---|---|
| Wirtschaft je Nation (`_economy`) | 22,1 | 24 | kein einzelner Hotspot, ~12 Teile je 1–4 ms |
| Ereignisse (jährlich, auf Monat umgerechnet) | 13,0 | 14 | 668 Events × 98 Nationen `check_conditions` in **einem** Monat → Jahres-Spike |
| KI Gold (`_spend_gold`) | 10,3 | 11 | |
| KI Macht (`_spend_power`) | 7,5 | 8 | |
| Marine (`Naval.monthly`, 2× `refresh`) | 6,0 | 7 | Kriege × Meere × Provinzen |
| Armeen (`_armies_tick`) | 5,9 | 7 | |
| KI Diplomatie | 5,8 | 6 | |
| Märkte | 5,1 | 6 | |
| KI Regierung | 4,0 | 4 | |
| KI Armeeführung | 3,8 | 4 | BFS je Armee, wächst mit Kriegen auf 7 ms |
| Rest (Stände, Jahres-Systeme, Kolonien, Handel …) | ~7 | 8 | |

Feinere Messung in `_economy` (30 Jahre): Macht/Diplo-Überlast 3,6 ms, Rivalen 3,3 ms (darin
`embargoed_by` = Schleife über alle Nationen **je Nation**), Provinzschleife 3,3 ms, Cache-Update 2,4 ms,
Handelseinkommen 2,4 ms, Unterhalt 2,0 ms, Ausgaben 1,8 ms, Unruhe 1,4 ms.

Mikro-Messungen: `Game.mod(n, key)` wird **~4 000×/Monat** aufgerufen, 2,6 µs je Aufruf (10 Bonusquellen
durchlaufen) ≈ 10 ms/Tick ≈ 11 %. `check_conditions` ~2 150×/Monat im Schnitt (im Jahresmonat ~26 000×).
`float(bal.x)` kostet 0,14 µs – einzeln billig, in Summe spürbar.

**Wichtigste Erkenntnis:** Die Kosten sind *breit verteilt*. Es gibt keinen einzelnen Hotspot, den man
fixt und alles ist gut. Es gibt aber drei strukturelle Muster, die mit der Weltgröße schlechter als
linear wachsen:

1. **O(Nationen²)**: `vassals_of`, `embargoed_by`, `armies_of`, `wars_of`, `control_armies` laufen jeweils über
   *alle* Nationen/Armeen/Kriege und werden *je Nation* aufgerufen.
2. **O(Nationen × Inhalt)**: Ereignisse und Missionen prüfen jedes Jahr alles für jeden. Jeder neue
   Content-Batch macht das teurer.
3. **Alles im selben Monat**: das Jahr endet für alle Nationen gleichzeitig → Tick mit 300–380 ms.

### 1.2 Skalierung (gleiche Messung, drei Code-Stände, 40 Jahre)

| Stand | Provinzen | Nationen | ms/Tick |
|---|---|---|---|
| vor Nahost (#150) | 355 | 78 | 66,7 |
| vor Afrika (#158) | 402 | 87 | 83,4 |
| heute | 474 | 98 | 93,7 |

Log-Log-Steigung ≈ **1,2** bezogen auf Provinzen (≈ 1,5 bezogen auf Nationen). Achtung: zwischen den
Ständen kam auch anderer Content dazu (Events, Güter, Nationen), die Steigung enthält also
„Wachstum durch Content“ mit. Das ist für die Prognose eigentlich richtig so, denn Content kommt weiter dazu.

### 1.3 UI und Rendering (1280×720, llvmpipe-Softwarerenderer)

| Messung | Wert |
|---|---|
| Draw Calls je Frame, Zoom 0,25 / 0,5 | ~440 / ~420 |
| Draw Calls je Frame, Zoom 0,8 / 1,5 / 3,0 | ~1 150 / ~1 110 / ~1 090 |
| Primitive je Frame | 20 000 – 27 000 |
| `map.refresh()` komplett (Kartenmodus-Wechsel) | 160–220 ms |
| pro Monat: `_update_top` / `check_dev` / `refresh_after_tick` | 2,5 / 0,3 / 3,0 ms |
| pro Monat: Panel `_refresh` + Layout im nächsten Frame | 12 + ~25 ms |
| Panel öffnen (Neuaufbau aller Controls) | 45–95 ms |
| Texturspeicher | **95 MB** (Terrain unkomprimiert, `compress/mode=0`, keine Mipmaps) |
| Statischer Speicher (Kern + UI) | 67–83 MB |

Frame-Zeiten aus llvmpipe sind **keine** GPU-Zeiten. Verlässlich sind Draw Calls, Primitive und die
CPU-Teile (`refresh`, Panels).

### 1.4 Spielstand

0,4–0,6 MB JSON (0,1 MB gezippt). `JSON.stringify` 40 ms, Laden (`from_dict`) 60–70 ms, beides auf dem
Hauptthread.

### 1.5 Was das für das Spielgefühl heißt

Die Simulation läuft **im Hauptthread**. `main.gd` begrenzt zwar die Anzahl Ticks pro Frame, aber ein
einzelner Tick von 90 ms (Jahresende 350 ms) friert den Frame trotzdem ein. Dazu kommen 40 ms UI pro Monat.
Auf der Referenz-CPU sind damit **~7 Monate/s** das Maximum, mit Ruckler bei jedem Monat und einem
deutlichen Hänger jedes Jahr. Auf einem Mittelklasse-Handy schätze ich 2–3× langsamer
(**ungemessen**).

---

## 2. Prognose ganze Welt

Kartenmaßstab heute: 48 px je Breitengrad. Ganze Welt (180° W bis 180° O, 72° N bis 56° S):
**~11 100 × 6 150 px** (heute 4 089 × 4 776, davon viel Leerfläche).

Provinzen bei ähnlicher Dichte wie Nahost/Afrika (Europa bleibt dichter): Indien 60–80, China 80–110,
Südostasien + Indonesien 50–70, Japan/Korea 15–25, Zentralasien + Sibirien + Russland Ost 60–90,
Iran Ost/Afghanistan 15–25, Südamerika 50–80, Ozeanien 10–20 → **+350 bis +500 Provinzen, gesamt
~850–1 000** und **~180–230 Nationen**. Unsicherheit: hängt komplett davon ab, wie dicht wir Asien machen
wollen (EU5 selbst hat dort sehr viele Provinzen).

| | heute | ganze Welt (Schätzung, ohne Optimierung) |
|---|---|---|
| Ø ms/Tick (Ref-CPU) | 90–100 | **210–260** (Steigung 1,2) |
| Jahres-Tick | 300–380 ms | **800–1 000 ms** |
| Max. Monate/s (Ref-CPU, Sim allein) | ~10 | ~4 |
| Mittelklasse-Handy (Faktor 2–3, geschätzt) | ~3–5 Monate/s | **~1,5–2 Monate/s**, Jahres-Hänger 2–3 s |
| Terrain-Textur unkomprimiert | 81 MB | **~270 MB** (passt nicht in 4096er-Limit, nicht in Mobil-VRAM) |
| Draw Calls Übersicht | ~450–1 150 | **2 000–2 500** |
| Spielstand | 0,5 MB | ~1,2–1,5 MB, Stringify ~100 ms |

Dazu kommen geplante Systeme und mehr Kartengrafik. Fazit: **Ohne Umbau ist die ganze Welt auf Android
nicht spielbar**, auf PC zäh. Mit den Maßnahmen unten halte ich es für erreichbar, allerdings nicht mit
einem einzigen Trick.

---

## 3. Optionen (bewertet)

| Option | Gewinn (geschätzt) | Aufwand | Risiko | Empfehlung |
|---|---|---|---|---|
| **A. Indizes statt Vollscans** (`vassals_of`, `embargoed_by`, Armeen je Besitzer, Kriege je Nation, Nachbarn) | 8–15 % jetzt, viel mehr bei 200 Nationen (entfernt O(N²)) | klein | klein (reine Caches, Tests decken ab) | **Phase 1** |
| **B. `mod()`-Cache je Nation** (invalidiert über `set_bonus`) | ~8–10 % | klein | mittel (vergessene Invalidierung = falsche Werte) → Test vergleicht Cache gegen Neuberechnung | **Phase 1** |
| **C. Ereignisse indizieren + Jahresarbeit über 12 Monate verteilen** | Jahres-Spike −80 %, Ø −10 % | klein | klein-mittel (RNG-Reihenfolge ändert sich, Balance prüfen) | **Phase 1** |
| **D. Marine nur bei Bedarf** (`refresh` 1× statt 2×, nur Meere mit Flotten im Krieg) | ~4–5 % | klein | klein | **Phase 1** |
| **E. Simulation in Hintergrund-Thread** (Tick auf `WorkerThreadPool`, UI liest nur zwischen Ticks, Spielerbefehle werden gepuffert) | Frames werden **unabhängig** von der Tick-Dauer → keine Ruckler mehr, auch bei 250 ms-Ticks | mittel | mittel (Race Conditions, wenn UI während des Ticks liest; braucht klares Lese-Gate) | **Phase 2** – größter Gewinn fürs Spielgefühl |
| **F. Autosave im Thread** (`to_dict` im Hauptthread 5 ms, `stringify` + Schreiben im Thread) | Hänger −40–100 ms | klein | klein | Phase 2 |
| **G. Karten-Renderer mit Provinz-ID-Textur + Farbpaletten-Shader** (Füllung, Grenzen, Kartenmodi in 1–2 Draw Calls; Picking über ID-Textur) | Draw Calls ~1 000 → ~50–150, unabhängig von Provinzzahl; Kartenmodus-Wechsel 200 ms → < 5 ms | mittel-groß | mittel (Pipeline, Shader auf GLES3 testen, Optik muss gleich gut bleiben) | **Phase 3** |
| **H. Gekachelte, VRAM-komprimierte Terrain-Textur** (2048er-Kacheln, ETC2/ASTC auf Android, S3TC/BPTC auf PC, Mipmaps, Kacheln nur im Bild) | Texturspeicher 95 MB → ~25 MB heute, Welt ~40–60 MB | mittel | klein-mittel | **Phase 3** (Pflicht für die Welt) |
| **I. KI-LOD / Staffelung** (kleine oder weit entfernte Reiche denken alle 2–3 Monate, Armee-BFS mit Reichweitenlimit und geteilten Distanzfeldern) | KI −30–50 % | mittel | **Balance** (KI wird träger) → 2 Seeds × 16 Läufe vor/nach | Phase 4 |
| **J. Typisierung der Hot Paths** (`g: Game`, `n: Nation`, `p: Province` statt untypisiert; `bal`-Werte als typisierte Felder) | 10–25 % auf betroffene Schleifen (Godot 4 nutzt typisierte Opcodes) | mittel (viel Fläche, mechanisch) | klein | Phase 4/5, schrittweise |
| **K. Datenorientierte Arrays** (Provinzfelder als `PackedInt32Array`/`PackedFloat32Array`, Nationen per Index statt String-Tag) | 1,5–3× in Provinzschleifen | groß (berührt fast alles + Spielstand) | hoch | Phase 5 – nur wenn nach 1–4 das Budget nicht reicht |
| **L. GDExtension (C++) für Kernels** (BFS/Pfade, Märkte, Bedingungsprüfung) | 10–50× für diese Kernels | groß (Build für Android arm64, Windows, Linux-CI, Web/WASM) | hoch (Build-Pipeline, Debugbarkeit) | **jetzt nicht**; erst wenn K nicht reicht |
| **M. C#** | – | – | Android-Export mit .NET in 4.3 experimentell, Web gar nicht | **nein** |
| **N. Paralleles Rechnen im Tick** (reine Lese-Phasen wie Event-Bedingungen, Marktsummen auf mehrere Kerne) | Phase-abhängig 2–3× | mittel | mittel (GDScript-Threads + geteilte Dictionaries) | später, nach E |
| **O. Godot-Upgrade 4.3 → 4.4/4.5** | unklar, ich habe keine verlässlichen Zahlen für GDScript-Speedups | mittel (Export, Android) | mittel | einmal messen (perf.gd auf beiden), nicht blind |
| **P. Panels inkrementell aktualisieren** statt neu bauen | 12–35 ms/Monat weniger, Panel-Öffnen schneller | mittel | klein | Phase 4 |

---

## 4. Roadmap

Schätzungen für den Aufwand gelten für mich (autonome Threads) inklusive Tests und Balance-Läufen.
Gewinne sind **Schätzungen ±50 %**; jede Phase misst vorher/nachher mit `tools/perf.gd`.

| Phase | Inhalt | Aufwand | Ziel |
|---|---|---|---|
| **0** (dieser PR) | Profiler-Marken im Kern, `perf.gd` neu, `render_perf.gd`, dieses Dokument | erledigt | Baseline |
| **1 Quick Wins** ✓ | A, B, C (Index), D | erledigt | −30 %, bitgenau gleich |
| **2a Gestufter Monat** ✓ | E (als Zeitscheiben statt Thread), Stufen 3–5 entfernen | erledigt | Frame-Zeit unabhängig vom Tick |
| **2b UI pro Monat** | P (Panels nur ändern statt neu bauen), F (Autosave) | ~1 Tag | kein Ruckler beim Monatswechsel |
| **3 Welt-Karte** | G, H (+ Projektion neu, die heutige „Atlantik-Verschiebung“ passt nicht zur ganzen Welt) | 2–4 Tage | Rendering skaliert nicht mehr mit Provinzzahl, Textur passt aufs Handy |
| **4 KI & UI** | I, J (Hot Paths), P | 2–3 Tage | Ø Tick nochmal −25–35 %, UI pro Monat < 10 ms |
| **5 nur falls nötig** | K, dann evtl. L | 3–6 Tage | wenn Welt-Budget nach Phase 4 nicht erreicht |

Erwartung nach Phase 1–4 für die ganze Welt (Ref-CPU): **~90–130 ms/Tick** statt 210–260. Das reicht mit
Phase 2 (Thread) für flüssige Frames und ~8–10 Monate/s am PC; auf einem Mittelklasse-Handy für
~3–5 Monate/s. Ob das „flüssig genug“ ist, entscheidet sich am echten Gerät. Wenn nicht, ist Phase 5 der
nächste Hebel.

Reihenfolge-Begründung: Phase 1 ist billig und macht jede spätere Messung sauberer. Phase 2 bringt den
größten spürbaren Effekt, bevor die Welt wächst. Phase 3 ist **Voraussetzung** für neue Regionen jenseits
von ~4 096 px Breite und sollte vor der nächsten großen Kartenerweiterung kommen.

---

## 5. Performance-Budget

Ziel-Plattformen: PC (60 fps) und Mittelklasse-Android (30 fps stabil, 60 wo möglich).
Budget auf der Referenz-CPU, **bei ganzer Welt**, nach Phase 1–4:

### 5.1 Simulation (Ø ms je Monat, Ref-CPU)

| Bereich | Budget | heute (474 Prov.) |
|---|---|---|
| Wirtschaft + Märkte + Handel | 25 | 28 |
| KI (alle Teile) | 35 | 32 |
| Militär (Armeen, Kriege, Belagerungen, Marine) | 15 | 12 |
| Jahres-Systeme (Events, Missionen, Regierung …) – gestaffelt | 8 | 16 |
| Kolonien, Religion, Stände, Sonstiges | 7 | 4 |
| **Reserve für neue Systeme** | **20** | – |
| **Summe** | **110** | 92 |
| schlimmster Tick | ≤ 2 × Ø | ~4 × Ø |

Regeln für **jedes neue Feature**:
- Messen mit `tools/perf.gd -- --years 40` vor/nach. Ein neues System darf **≤ 2 ms Ø pro Tick**
  kosten (≈ 2 %), sonst braucht es Staffelung (nicht jeder Monat, nicht jede Nation) oder eine
  Begründung im PR.
- Keine Schleife über alle Nationen/Armeen/Provinzen **innerhalb** einer Schleife über alle Nationen
  (O(N²)). Stattdessen Index pflegen oder einmal pro Tick vorberechnen.
- Jährliche Arbeit nicht im selben Monat für alle Nationen.
- Neue Event-/Missionsbedingungen: billig zuerst prüfen (Jahr, Tag, Flags), teure Bedingungen
  (Provinzschleifen) zuletzt.
- Neue Profiler-Marke `g._pmark("…")` für jedes System mit eigener Schleife.

### 5.2 Rendering & UI

| Messgröße | Budget (ganze Welt) | heute |
|---|---|---|
| Draw Calls je Frame (jeder Zoom) | ≤ 400 | 420–1 150 |
| Texturspeicher gesamt | ≤ 128 MB (Android) | 95 MB |
| UI-Arbeit pro Monat (Top-Bar, Karte, Panel) | ≤ 8 ms | ~40 ms |
| Kartenmodus-Wechsel | ≤ 30 ms | 160–220 ms |
| Panel öffnen | ≤ 40 ms | 45–95 ms |
| neue Kartengrafik (Sprites, Glyphen, Effekte) | ≤ 50 Draw Calls zusätzlich, LOD ab Zoom < 0,7 aus | – |

### 5.3 Speicher & Spielstand

| | Budget | heute |
|---|---|---|
| Statischer Speicher | ≤ 200 MB | 67–83 MB |
| Spielstand | ≤ 2 MB, Speichern ohne Hänger > 30 ms im Hauptthread | 0,5 MB, 45 ms |

---

## 6. Abstürze (Nebenbefund, Hypothese)

Frühere Threads haben Speicher-/Node-Lecks ausgeschlossen. Neu aufgefallen: die Terrain-Texturen liegen
**unkomprimiert** und ohne Mipmaps im VRAM (95 MB, mit Afrika gewachsen). Auf Handys mit wenig
Grafikspeicher kann das zu Treiber-Abstürzen führen. Das ist eine **Hypothese, nicht belegt**. Phase 3 (H)
würde sie nebenbei beseitigen. Ein Absturzlog vom Gerät (Debug-Panel) bleibt die beste Quelle.

---

## 7. Offene Fragen / Unsicherheiten

1. **Echte Geräte-Zahlen fehlen.** Das Debug-Panel (F12 bzw. Menü) zeigt die Tick-Dauer. Eine Zahl vom
   Handy und vom PC (z. B. „Tick Ø xx ms nach 20 Jahren“) ersetzt meine Faktor-2–3-Schätzung.
2. **Wie dicht soll Asien werden?** 850 oder 1 400 Provinzen ist ein Unterschied von Faktor ~1,7 in der
   Prognose.
3. **Welche Maximalgeschwindigkeit ist Pflicht?** Heute verspricht Stufe 5 25 Monate/s, das schafft
   schon die jetzige Karte nicht. Realistisch für die ganze Welt: PC ~8–10, Handy ~3–5 Monate/s.
4. Balance-Effekte von Phase 1 (geänderte RNG-Reihenfolge) und Phase 4 (KI-LOD) werden mit
   `balance_loop` (2 Seeds) geprüft, nicht im CI (CI bleibt kurz).
