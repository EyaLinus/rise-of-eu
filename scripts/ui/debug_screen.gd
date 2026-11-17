extends RefCounted
## Debug mode (Einstellungen → 🐞 Debug-Modus): a small performance overlay on the map, the debug panel
## in the side panel (F12 or the 🐞 button in the menu) and a session watch that notices crashes.
## `m` is the main UI (scripts/ui/main.gd); it owns the side panel, modal and button helpers.
##
## Session watch (always on, also without debug mode): user://session.json is rewritten every
## BEAT_MS with the game year, memory and the sizes of the growing game lists. A clean quit or an
## app pause marks it closed; if the next start finds it still "running", the last session crashed
## (or was killed) and the panel shows what the game looked like just before, plus the log tail
## (project setting debug/file_logging writes user://logs/godot.log on every platform).

const DebugTools = preload("res://scripts/core/debug_tools.gd")

const SESSION_PATH := "user://session.json"
const BEAT_MS := 10000
const TICK_SAMPLES := 120

var m
var tick_us: Array = []  # duration of the last TICK_SAMPLES game.tick() calls in microseconds
var last_crash := {}  # heartbeat of the previous session if it did not end cleanly
var pid := -1  # province the cheats act on (selected when the panel was opened)
var event_filter := ""
var overlay: Label
var _event_edit: LineEdit
var _last_beat := 0
var _started_ms := 0
var _overlay_ms := 0


func _init(main) -> void:
	m = main


func enabled() -> bool:
	return bool(m.settings.get("debug", false))


# ---------------------------------------------------------------- session watch

func start_session() -> void:
	_started_ms = Time.get_ticks_msec()
	if FileAccess.file_exists(SESSION_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
		if d is Dictionary and bool(d.get("running", false)) and not bool(d.get("paused", false)):
			last_crash = d
	_write({"running": true, "started": Time.get_datetime_string_from_system()})


func beat(force: bool = false) -> void:
	var now := Time.get_ticks_msec()
	if not force and now - _last_beat < BEAT_MS:
		return
	_last_beat = now
	var d := {
		"running": true,
		"time": Time.get_datetime_string_from_system(),
		"minutes": int((now - _started_ms) / 60000),
		"mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"mem_peak_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0, 0.1),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"fps": int(Performance.get_monitor(Performance.TIME_FPS)),
		"tick_ms": snappedf(tick_avg_ms(), 0.1),
	}
	if m.game != null:
		d["player"] = m.game.player
		d["game"] = DebugTools.snapshot(m.game)
	_write(d)


## Clean end (quit) or app in the background (Android may kill it there without it being a crash).
func end_session(paused: bool = false) -> void:
	beat(true)
	var d = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH)) if FileAccess.file_exists(SESSION_PATH) else {}
	if not d is Dictionary:
		d = {}
	if paused:
		d["paused"] = true
	else:
		d["running"] = false
	_write(d)


func resume_session() -> void:
	beat(true)


func _write(d: Dictionary) -> void:
	var f := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))


# ---------------------------------------------------------------- timing + overlay

func note_tick(usec: int) -> void:
	tick_us.append(usec)
	if tick_us.size() > TICK_SAMPLES:
		tick_us.pop_front()


func tick_avg_ms() -> float:
	if tick_us.is_empty():
		return 0.0
	var s := 0
	for u in tick_us:
		s += u
	return s / 1000.0 / tick_us.size()


func tick_max_ms() -> float:
	var mx := 0
	for u in tick_us:
		mx = maxi(mx, u)
	return mx / 1000.0


func build_overlay(hud: Control) -> void:
	overlay = Label.new()
	overlay.set_anchors_preset(Control.PRESET_CENTER_TOP)
	overlay.offset_top = 68
	overlay.offset_left = -260
	overlay.offset_right = 260
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_theme_font_size_override("font_size", 14)
	overlay.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	overlay.add_theme_color_override("font_outline_color", Color.BLACK)
	overlay.add_theme_constant_override("outline_size", 5)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	hud.add_child(overlay)


## Called every frame; refreshes the overlay twice a second and writes the heartbeat.
func process() -> void:
	beat()
	if overlay == null:
		return
	overlay.visible = enabled() and m.game != null
	if not overlay.visible:
		return
	var now := Time.get_ticks_msec()
	if now - _overlay_ms < 500:
		return
	_overlay_ms = now
	overlay.text = "FPS %d · Monat %.1f ms (max %.1f) · RAM %.0f MB · Armeen %d" % [
		int(Performance.get_monitor(Performance.TIME_FPS)), tick_avg_ms(), tick_max_ms(),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, m.game.armies.size()]


# ---------------------------------------------------------------- panel

func open() -> void:
	pid = m.map.selected_pid
	m._open_panel("debug")


func build() -> void:
	var g = m.game
	m.side_title.text = "🐞 Debug"
	var box: VBoxContainer = m.side_box
	if not last_crash.is_empty():
		_crash_section(box)
	if m._section("dbg_perf", "📈 Leistung"):
		var rows := [
			["FPS", "%d" % int(Performance.get_monitor(Performance.TIME_FPS))],
			["Bild", "%.1f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)],
			["Monat Ø/max", "%.1f / %.1f ms" % [tick_avg_ms(), tick_max_ms()]],
			["RAM jetzt/Spitze", "%.0f / %.0f MB" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
				Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0]],
			["Objekte/Nodes", "%d / %d" % [int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]],
			["Verwaiste Nodes", "%d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))],
			["Draw Calls", "%d" % int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))],
		]
		box.add_child(_table(rows))
	if m._section("dbg_state", "🔍 Spielzustand", false, "Größen aller Listen, die im Lauf des Spiels wachsen. Steigt eine Zahl immer weiter, ist das ein Hinweis auf ein Speicherleck."):
		var s: Dictionary = DebugTools.snapshot(g)
		var rows := []
		for k in s:
			rows.append([k, str(s[k])])
		box.add_child(_table(rows))
		box.add_child(m._lbl("Meiste Armeen auf einer Provinz:", 15, Color(0.75, 0.8, 0.9)))
		for r in DebugTools.crowded_provinces(g, 5):
			var p = g.provinces[r[0]]
			box.add_child(m._btn("📍 %s: %d Armeen, %d Regimenter" % [p.name, r[1], r[2]], func():
				m.map.focus(p.center)
				m._open_panel("province", p.id), "Auf der Karte zeigen"))
	box.add_child(m._grid([
		m._btn("📋 Bericht kopieren", _copy_report, "Leistung, Spielzustand und Absturzinfo in die Zwischenablage, zum Einfügen in eine Fehlermeldung."),
		m._btn("📂 Log-Ordner", func(): OS.shell_open(ProjectSettings.globalize_path("user://logs")), "Öffnet den Ordner mit godot.log.", not OS.has_feature("pc")),
	]))
	if m._section("dbg_cheats", "✨ Cheats", true, "Nur zum Testen. Das Spiel merkt sich, dass gecheatet wurde."):
		_cheats(box)


func _cheats(box: VBoxContainer) -> void:
	var g = m.game
	var me: String = g.player
	box.add_child(m._grid([
		m._btn("💰 +1000 Gold", func(): m._act(DebugTools.add_resources(g, me, 1000.0, 0.0), "💰 +1000")),
		m._btn("📜 +200 Punkte", func(): m._act(DebugTools.add_resources(g, me, 0.0, 200.0), "📜🕊⚔ +200"), "Je 200 Verwaltungs-, Diplomatie- und Militärpunkte"),
		m._btn("👥 +20k Mannschaft", func(): m._act(DebugTools.add_resources(g, me, 0.0, 0.0, 20.0), "👥 +20k")),
		m._btn("🗺 Welt aufdecken", func():
			var c: int = DebugTools.reveal_world(g, me)
			m.map.refresh()
			m._act("", "🗺 %d Gebiete aufgedeckt" % c)),
		m._btn("🕊 Alle Kriege beenden", func():
			var c: int = DebugTools.end_wars(g, me)
			m.map.refresh()
			m._act("" if c > 0 else "Du führst keinen Krieg", "🕊 %d Kriege beendet (weißer Frieden)" % c)),
		m._btn("⏩ 1 Jahr vorspulen", _skip.bind(12), "Ereignisse wählen automatisch die erste Option, Friedensangebote werden abgelehnt."),
		m._btn("⏩ 10 Jahre vorspulen", _skip.bind(120), "Ereignisse wählen automatisch die erste Option, Friedensangebote werden abgelehnt. Dauert ein paar Sekunden."),
		m._btn("🏘 +1 Entwicklung", func():
			for p in g.provinces_of(me):
				g.provinces[p].dev += 1
			m.map.refresh()
			DebugTools._mark(g)
			m._act("", "🏘 +1 Entwicklung in jeder Provinz"), "In jeder eigenen Provinz."),
	]))
	if pid >= 0 and pid < g.provinces.size():
		var p = g.provinces[pid]
		box.add_child(m._btn("🏰 %s übernehmen" % p.name, func():
			var err: String = DebugTools.take_province(g, me, pid)
			m.map.refresh()
			m._act(err, "🏰 %s gehört jetzt dir" % p.name), "Ohne Krieg und ohne Aggression. Wähle vorher eine Provinz auf der Karte.", p.owner == me))
		if p.owner != "" and p.owner != me:
			box.add_child(m._btn("👑 Als %s spielen" % g.nations[p.owner].name, func():
				var err: String = DebugTools.switch_player(g, p.owner)
				m.map.refresh()
				m._act(err, "👑 Du spielst jetzt %s" % g.nations[g.player].name)
				m._update_top(), "Übernimmt das Reich, dem die gewählte Provinz gehört. Dein altes Reich spielt die KI."))
	else:
		box.add_child(m._lbl("Tipp: eine Provinz auf der Karte wählen, dann F12 – sie lässt sich übernehmen oder ihr Reich spielen.", 14, Color(0.7, 0.72, 0.78)))
	# fire an event by id
	box.add_child(m._lbl("📯 Ereignis auslösen", 16))
	var le := LineEdit.new()
	_event_edit = le
	le.placeholder_text = "Ereignis-ID (Anfang genügt)"
	le.text = event_filter
	box.add_child(le)
	var res := VBoxContainer.new()
	box.add_child(res)
	le.text_changed.connect(func(t):
		event_filter = t
		_fill_events(res))
	_fill_events(res)


## Matching event ids as buttons; rebuilt per keystroke without rebuilding the panel (keeps the focus).
func _fill_events(res: VBoxContainer) -> void:
	var g = m.game
	for c in res.get_children():
		c.queue_free()
	if event_filter == "":
		return
	var ids: Array = DebugTools.event_ids(g, event_filter, 10)
	if ids.is_empty():
		res.add_child(m._lbl("Kein Ereignis beginnt mit „%s“." % event_filter, 14, Color(0.8, 0.6, 0.6)))
		return
	var btns := []
	for id in ids:
		btns.append(m._btn(id, func():
			var err: String = DebugTools.fire_event(g, g.player, id)
			m._act(err, "")
			if err == "" and not g.pending_events.is_empty():
				m._show_event(g.pending_events[0])))
	if btns.size() % 2 == 1:
		btns.append(Control.new())
	res.add_child(m._grid(btns))


## The event field has the focus: the monthly panel refresh waits, so typing is not interrupted.
func typing() -> bool:
	return m.panel_mode == "debug" and _event_edit != null and is_instance_valid(_event_edit) and _event_edit.has_focus()


func _skip(months: int) -> void:
	var t0 := Time.get_ticks_msec()
	var c: int = DebugTools.skip_months(m.game, months)
	m.map.check_dev_changes()
	m.map.refresh()
	m._act("", "⏩ %d Monate in %.1f s" % [c, (Time.get_ticks_msec() - t0) / 1000.0])
	if m.game.game_over:
		m._show_game_over()


func _crash_section(box: VBoxContainer) -> void:
	var d := last_crash
	var gs: Dictionary = d.get("game", {})
	var txt := "💀 Die letzte Sitzung endete unerwartet"
	if not gs.is_empty():
		txt += " im Jahr %d" % int(gs.get("year", 0))
	txt += " (%s, nach %d Min., RAM %s MB, Spitze %s MB, Armeen %s)." % [d.get("time", "?"), int(d.get("minutes", 0)),
		str(d.get("mem_mb", "?")), str(d.get("mem_peak_mb", "?")), str(gs.get("armies", "?"))]
	var l: Label = m._lbl(txt, 15, Color(1.0, 0.7, 0.6))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	var tail := log_tail(true, 12)
	if tail != "":
		var t: Label = m._lbl(tail, 12, Color(0.75, 0.75, 0.78))
		t.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		box.add_child(t)
	box.add_child(m._btn("✖ Hinweis ausblenden", func():
		last_crash = {}
		m._refresh()))


## Last `lines` lines of the game log; previous=true reads the log of the session before this one.
func log_tail(previous: bool, lines: int) -> String:
	var dir := "user://logs"
	if not DirAccess.dir_exists_absolute(dir):
		return ""
	var path := dir + "/godot.log"
	if previous:
		var files := []
		for f in DirAccess.get_files_at(dir):
			if f.begins_with("godot") and f.ends_with(".log") and f != "godot.log":
				files.append(f)
		if files.is_empty():
			return ""
		files.sort()  # rotated logs carry a timestamp in their name: the last one is the newest
		path = dir + "/" + files[-1]
	if not FileAccess.file_exists(path):
		return ""
	var all := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	return "\n".join(all.slice(maxi(0, all.size() - lines)))


func report() -> String:
	var lines := ["Rise of EU %s · %s · Godot %s" % [ProjectSettings.get_setting("application/config/version", "?"), OS.get_name(), Engine.get_version_info().string],
		"FPS %d, Monat %.1f ms (max %.1f), RAM %.0f MB (Spitze %.0f)" % [int(Performance.get_monitor(Performance.TIME_FPS)), tick_avg_ms(), tick_max_ms(),
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0]]
	if m.game != null:
		lines.append("Spiel: " + JSON.stringify(DebugTools.snapshot(m.game)))
	if not last_crash.is_empty():
		lines.append("Letzte Sitzung abgestürzt: " + JSON.stringify(last_crash))
		lines.append("Log davor:\n" + log_tail(true, 30))
	return "\n".join(lines)


func _copy_report() -> void:
	DisplayServer.clipboard_set(report())
	m._toast("📋 Bericht kopiert")


func _table(rows: Array) -> GridContainer:
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 16)
	for r in rows:
		gr.add_child(m._lbl(str(r[0]), 15, Color(0.72, 0.75, 0.82)))
		gr.add_child(m._lbl(str(r[1]), 15))
	return gr
