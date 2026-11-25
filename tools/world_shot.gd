extends SceneTree
## Screenshots of any map spots, for reviewing new regions and map art (needs a display, e.g. xvfb-run):
## godot --path . -s res://tools/world_shot.gd -- --out /tmp/shots --at moscow:0.6,yakutsk:0.4 [--mode 0] [--reveal]
## Each spot is a province key (or x;y in map pixels) and a zoom. The game starts as France, runs 2 months.

var out := "user://world_shots"
var spots := []
var mode := 0
var reveal := false
var size := Vector2i(1600, 900)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--out":
				out = args[i + 1]
				i += 1
			"--at":
				spots = args[i + 1].split(",")
				i += 1
			"--mode":
				mode = int(args[i + 1])
				i += 1
			"--reveal":
				reveal = true
			"--size":
				var p: PackedStringArray = args[i + 1].split("x")
				size = Vector2i(int(p[0]), int(p[1]))
				i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)
	root.size = size
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	_run(m)


func _run(m) -> void:
	await create_timer(0.5).timeout
	m._start_game("FRA")
	m.settings.tips = false
	m._close_modal()
	var g = m.game
	for i in 2:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	m._after_tick()
	m._close_modal()
	m._close_panel()
	if reveal:
		load("res://scripts/core/debug_tools.gd").reveal_world(g, "FRA")
	m.map.map_mode = mode
	for s in spots:
		var parts: PackedStringArray = str(s).split(":")
		var at := Vector2.ZERO
		if parts[0].contains(";"):
			var xy: PackedStringArray = parts[0].split(";")
			at = Vector2(float(xy[0]), float(xy[1]))
		elif g.key_to_pid.has(parts[0]):
			at = g.provinces[g.key_to_pid[parts[0]]].center
		else:
			push_error("unknown spot " + parts[0])
			continue
		m.map.focus(at, float(parts[1]) if parts.size() > 1 else 1.0)
		m.map.refresh()
		await process_frame
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png(out + "/" + parts[0].replace(";", "_") + "_" + (parts[1] if parts.size() > 1 else "1") + ".png")
	quit()
