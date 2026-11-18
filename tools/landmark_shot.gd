extends SceneTree
## Screenshots of the historical landmarks (scripts/core/landmarks.gd): map sprites around Iberia and
## France, an own province with landmarks, a foreign one and the nation overview.
## xvfb-run godot --path . -s res://tools/landmark_shot.gd -- --out DIR [--scale 1.4]

var out := "user://lm_shots"
var scale := 1.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--out":
				out = args[i + 1]
			"--scale":
				scale = float(args[i + 1])
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("shot ", name)


func _run() -> void:
	var path := "user://settings.json"
	var old := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"tips": false, "ui_scale": scale, "sound": false, "music": 0.0}))
	f.close()
	DisplayServer.window_set_size(Vector2i(int(1280 * scale), int(720 * scale)))
	root.size = Vector2i(int(1280 * scale), int(720 * scale))
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.3).timeout
	m._start_game("SPA")
	m.settings.tips = false
	m._close_modal()
	var g = m.game
	var L = g.Landmarks
	var n = g.nations.SPA
	n.gold = 5000.0
	for k in ["adm", "dip", "mil"]:
		n.tech[k] = 12
	L.invest(g, "SPA", "sevilla_port")
	for i in 3:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	g.landmarks["santiago"].lvl = 3
	g.landmarks["escorial"].lvl = 1
	L.refresh_bonus(g)
	m._after_tick()
	m._close_modal()
	m.map.focus(g.provinces[g.key_to_pid["toledo"]].center, 1.6)
	m.map.refresh()
	await _shot("lm_map_iberia")
	m.map.focus(g.provinces[g.key_to_pid["paris"]].center, 2.4)
	m.map.refresh()
	await _shot("lm_map_paris")
	m.prov_tab = "info"
	m._open_panel("province", g.key_to_pid["sevilla"])
	await _shot("lm_province_own")
	m.prov_tab = "build"
	m._open_panel("province", g.key_to_pid["toledo"])
	await _shot("lm_province_build")
	m._open_panel("province", g.key_to_pid["paris"])
	await _shot("lm_province_foreign")
	m.section_open["nat_monuments"] = true
	m._open_panel("nation")
	var sc = m.side_box.get_parent()
	await process_frame
	if sc is ScrollContainer:
		sc.scroll_vertical = 100000
	await _shot("lm_nation")
	if old != "":
		var w := FileAccess.open(path, FileAccess.WRITE)
		w.store_string(old)
		w.close()
	quit(0)
