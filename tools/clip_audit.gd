extends SceneTree
## Finds cut-off UI text: opens every panel and screen and lists each Label / Button whose text is trimmed
## (clip_text / ellipsis) or that sits outside its clipping parent (top bar strip).
## xvfb-run godot --path . -s res://tools/clip_audit.gd -- [--scale 1.4] [--width 1560] [--big] [--shots DIR] [--fail]
## Restores user://settings.json afterwards.

var scale := 1.0
var width := 1280
var big := false
var shots := ""
var found := {}  # "panel|text" -> detail


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--scale":
				scale = float(args[i + 1])
			"--width":
				width = int(args[i + 1])
			"--big":
				big = true
			"--shots":
				shots = args[i + 1]
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
	_run("--fail" in args)


func _run(fail: bool) -> void:
	var path := "user://settings.json"
	var old := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"big_ui": big, "tips": false, "ui_scale": scale, "sound": false}))
	f.close()
	DisplayServer.window_set_size(Vector2i(int(width * scale), int(720 * scale)))
	root.size = Vector2i(int(width * scale), int(720 * scale))
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.3).timeout
	m._start_game("FRA")
	m.settings.tips = false
	m._close_modal()
	var g = m.game
	for i in 24:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	# a rich late-game state: big numbers must still fit
	var n = g.nations.FRA
	n.gold = 123456.0
	n.adm = 999.0
	n.dip = 999.0
	n.mil = 999.0
	n.manpower = 123456.0
	n.ae = 87.0
	m._after_tick()
	m._close_modal()

	await _check(m, "topbar")
	for p in ["nation", "diplomacy", "wars", "navy", "missions", "log", "mapmodes", "advice", "modifiers", "ranking", "hre"]:
		m._open_panel(p)
		await _check(m, p)
	for t in ["overview", "trade", "goods"]:
		m.econ_tab = t
		m._open_panel("economy")
		await _check(m, "economy/" + t)
	for t in ["haushalt", "hof", "recht", "staende"]:
		m.gov_screen.tab = t
		m._open_panel("government")
		await _check(m, "government/" + t)
	for b in ["adm", "dip", "mil"]:
		m._open_panel("tech")
		m.tech_screen._select(b)
		await _check(m, "tech/" + b)
	var own: Array = g.provinces_of("FRA") if g.has_method("provinces_of") else []
	if not own.is_empty():
		m._open_panel("province", own[0])
		await _check(m, "province")
	m._open_panel("other", "ENG")
	await _check(m, "other")
	m._close_panel()
	var gv = g.govt
	m._open_panel("government")
	gv_pick(m, gv)
	await _check(m, "law_picker")
	m._close_modal()
	m.gov_screen._pick_reform(gv.reforms[0].id)
	await _check(m, "reform_picker")
	m._close_modal()
	m.gov_screen._pick_advisor()
	await _check(m, "advisor_picker")
	m._close_modal()
	# an event option that angers an estate (shows "→ X")
	for id in g.event_by_id:
		var hit := false
		for o in g.event_by_id[id].get("options", []):
			for k in o.get("effects", {}).get("estate", {}):
				if float(o.effects.estate[k]) < 0.0:
					hit = true
		if hit:
			m._show_event(id)
			await _check(m, "event_estate")
			m._close_modal()
			break
	var ev: Array = g.event_by_id.keys()
	for i in mini(ev.size(), 6):
		m._show_event(ev[i * 7 % ev.size()])
		await _check(m, "event")
		m._close_modal()
	var keys := found.keys()
	keys.sort()
	for k in keys:
		print("CLIP ", k, "  ", found[k])
	print("CLIP_TOTAL %d (scale %.2f width %d big %s)" % [keys.size(), scale, width, big])
	if old != "":
		var w := FileAccess.open(path, FileAccess.WRITE)
		w.store_string(old)
		w.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(1 if fail and not keys.is_empty() else 0)


func _check(m, where: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	if shots != "":
		root.get_texture().get_image().save_png("%s/%s_%s.png" % [shots, where.replace("/", "_"), int(scale * 100)])
	_walk(m, where)
	# the side panel must stay on screen and keep its width (content wider than it pushes it over the map)
	var sp: Control = m.side_panel
	if sp.visible:
		var vw: float = m.get_viewport().get_visible_rect().size.x
		if sp.get_global_rect().end.x > vw + 1.0:
			found["%s|side panel" % where] = "off screen to the right (%.0f > %.0f)" % [sp.get_global_rect().end.x, vw]
		elif sp.size.x > -sp.offset_left + 1.0:  # allowed (it grows toward the map), just worth knowing
			print("WIDE %s side panel %.0f instead of %.0f" % [where, sp.size.x, -sp.offset_left])


func _walk(node: Node, where: String) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if (node is Label or node is Button) and (where == "topbar" or not _in_topbar(node)):
		_test(node, where)
	for c in node.get_children():
		_walk(c, where)


func _text_w(c: Control, text: String) -> float:
	var font: Font = c.get_theme_font("font")
	var fs: int = c.get_theme_font_size("font_size")
	var w := 0.0
	for line in text.split("\n"):
		w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	return w


func _test(c: Control, where: String) -> void:
	var text: String = c.text
	if text.strip_edges() == "":
		return
	var avail := c.size.x
	var sb: StyleBox = c.get_theme_stylebox("normal")
	if sb != null:
		avail -= sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
	if c is Button and c.icon != null and not c.expand_icon:
		avail -= c.icon.get_width() + c.get_theme_constant("h_separation")
	var clipping: bool = c.clip_text or c.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
	if (c is Label or c is Button) and c.autowrap_mode != TextServer.AUTOWRAP_OFF:
		clipping = false  # wraps instead (unless a single word is too long, ignored)
	var need := _text_w(c, text)
	if clipping and need > avail + 1.0:
		found["%s|%s" % [where, text.replace("\n", " / ").left(60)]] = "need %d px, have %d" % [need, avail]
		return
	# outside the visible rect of a clipping ancestor (e.g. the top bar resource strip)
	var p := c.get_parent()
	while p != null and p is Control:
		if p.clip_contents:
			var pr: Rect2 = p.get_global_rect()
			var r := c.get_global_rect()
			if r.end.x > pr.end.x + 1.0 or r.position.x < pr.position.x - 1.0:
				if r.position.x < pr.end.x and r.end.x > pr.position.x or r.position.x >= pr.end.x:
					found["%s|%s" % [where, text.replace("\n", " / ").left(60)]] = "outside clip parent %s" % p.get_class()
			break
		p = p.get_parent()


func _in_topbar(c: Node) -> bool:
	return c is Control and c.get_global_rect().position.y < 60.0 and c.get_global_rect().position.x < root.size.x * 0.6


func gv_pick(m, gv) -> void:
	for l in gv.laws:
		for o in l.options:
			if float(o.get("effects", {}).get("estate_adel", 0.0)) < 0.0 or float(o.get("effects", {}).get("estate_klerus", 0.0)) < 0.0:
				m.gov_screen._pick_law(l.id)
				return
	m.gov_screen._pick_law(gv.laws[0].id)
