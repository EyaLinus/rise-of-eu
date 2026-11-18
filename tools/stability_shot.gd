extends SceneTree
## Screenshots of the stability plaque (four levels) and the realm rank ladder in the nation panel.
## xvfb-run godot --path . -s res://tools/stability_shot.gd -- --out DIR [--scale 1.4] [--width 1560]

var out := "user://shots"
var scale := 1.0
var width := 1280


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--out":
				out = args[i + 1]
			"--scale":
				scale = float(args[i + 1])
			"--width":
				width = int(args[i + 1])
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(out + "/" + name + ".png")


func _run() -> void:
	var path := "user://settings.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"tips": false, "ui_scale": scale, "sound": false, "music": 0.0}))
	f.close()
	DisplayServer.window_set_size(Vector2i(int(width * scale), int(720 * scale)))
	root.size = Vector2i(int(width * scale), int(720 * scale))
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.3).timeout
	m._start_game("POR")
	m.settings.tips = false
	m._close_modal()
	var g = m.game
	for i in 24:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	var n = g.nations.POR
	n.gold = 600.0
	n.adm = 300.0
	n.prestige = 120.0
	m._after_tick()
	m._close_modal()
	for v in [-80.0, -20.0, 20.0, 75.0]:
		n.stability = v
		g.Stability.refresh_bonus(g, n)
		m._update_top()
		m._open_panel("nation")
		await _shot("stab_%d" % int(v))
	m.section_open["nat_rank"] = true
	m._open_panel("nation")
	await _shot("rank_panel")
	quit()
