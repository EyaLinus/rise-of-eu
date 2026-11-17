extends SceneTree
## Alert bar check: starts a game with many alerts at once (debt, revolt, idle power, free advisor, ...),
## then checks that the bar under the top bar overlaps neither the top bar, the tab column nor the side panel,
## with the panel closed and open. Prints ALERT_OK / ALERT_BAD lines; --fail exits 1 on overlap.
## xvfb-run godot --path . -s res://tools/alert_shot.gd -- [--scale 1.4] [--width 1560] [--big] [--shots DIR] [--fail]

var scale := 1.0
var width := 1280
var big := false
var shots := ""
var bad := 0


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
	_run("--fail" in args)


func _run(fail: bool) -> void:
	var path := "user://settings.json"
	var old := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"big_ui": big, "tips": false, "ui_scale": scale, "sound": false, "music": 0.0}))
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
	for i in 30:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	var n = g.nations.FRA
	n.gold = -5.0
	n.adm = 990.0
	n.dip = 990.0
	n.mil = 990.0
	n.gov.advisors.clear()
	m._after_tick()
	m._close_modal()
	m._update_top()
	await _check(m, "closed")
	m._open_panel("nation")
	await _check(m, "panel")
	m._open_panel("advice")
	await _check(m, "advice")
	# first icon opens its place
	var first: Button = m.alert_bar.bar.get_child(0)
	first.pressed.emit()
	await process_frame
	print("ALERT_CLICK %s -> panel %s" % [first.name, m.panel_mode])
	if m.panel_mode == "" :
		bad += 1
	print("ALERT_TOTAL bad %d (scale %.2f width %d big %s)" % [bad, scale, width, big])
	if old != "":
		var w := FileAccess.open(path, FileAccess.WRITE)
		w.store_string(old)
		w.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(1 if fail and bad > 0 else 0)


func _check(m, where: String) -> void:
	for i in 4:
		await process_frame
	if shots != "":
		root.get_texture().get_image().save_png("%s/alerts_%s_%d_%d%s.png" % [shots, where, int(scale * 100), width, "_big" if big else ""])
	var bar: HBoxContainer = m.alert_bar.bar
	var r: Rect2 = bar.get_global_rect()
	var top: Control = m.top_labels.date.get_parent().get_parent()
	var msgs := []
	if not bar.visible or bar.get_child_count() == 0:
		msgs.append("bar empty")
	if r.position.y < top.get_global_rect().end.y:
		msgs.append("under top bar")
	if r.intersects(m.left_tabs.get_global_rect()):
		msgs.append("over tabs")
	if m.side_panel.visible and r.intersects(m.side_panel.get_global_rect()):
		msgs.append("over side panel")
	if r.end.x > m.get_viewport_rect().size.x:
		msgs.append("off screen")
	var names := []
	for c in bar.get_children():
		names.append(c.text)
	print("%s %s: %d icons [%s] at %s %s" % ["ALERT_BAD" if not msgs.is_empty() else "ALERT_OK", where, bar.get_child_count(), " ".join(names), r, ", ".join(msgs)])
	bad += msgs.size()
	if bar.get_child_count() > 0:
		var b0: Button = bar.get_child(0)
		print("  top bar end %s, icon size %s min %s" % [top.get_global_rect().end, b0.size, b0.get_combined_minimum_size()])
