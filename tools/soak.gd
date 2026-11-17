extends SceneTree
## Soak test for crash and leak hunts: the real main loop plays a nation by itself (events and peace
## offers answered, panels cycled, map zoomed) and prints memory, object and node counts every 5 years.
## Local tool, not part of CI. With a real renderer (finds what headless cannot):
##   xvfb-run -a godot --path . --rendering-driver opengl3 -s res://tools/soak.gd -- --years 100 --speed 3
## Watch the process size from outside as well (ps -o rss -C godot): it includes driver memory.
func _init() -> void:
	_run()

func _run() -> void:
	var years := 100
	var tag := "FRA"
	var spd := -1  # game speed step, -1 = fastest
	var scale := 1.0
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size() - 1):
		if args[i] == "--years": years = int(args[i+1])
		if args[i] == "--tag": tag = args[i+1]
		if args[i] == "--speed": spd = int(args[i+1])
		if args[i] == "--timescale": scale = float(args[i+1])
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.2).timeout
	m.settings.tips = false
	m._start_game(tag)
	m._close_modal()
	var g = m.game
	m._open_panel("nation")
	if spd < 0:
		spd = m.SPEEDS.size() - 1
	m._set_speed(spd)
	Engine.time_scale = scale
	var next := 60
	var frames := 0
	var modes := ["nation", "economy", "diplomacy", "wars", "navy", "missions", "log", "ranking"]
	while g.month < years * 12 and not g.game_over:
		await process_frame
		frames += 1
		if m.modal.visible:
			while not g.pending_events.is_empty():
				g.choose_event_option(tag, g.pending_events[0], 0)
			while not g.pending_peace.is_empty():
				g.answer_player_peace(g.pending_peace[0], true)
			m._close_modal()
		if frames % 400 == 0:
			m._open_panel(modes[(frames / 400) % modes.size()])
			m.map.zoom_by(1.07 if (frames / 400) % 2 == 0 else 0.93)
			m.map.pan_by(Vector2(30, 10))
		if m.speed == 0:
			m._set_speed(spd)
		if g.month >= next:
			next += 60
			print("Y%d frames=%d mem=%.1fMB objs=%d nodes=%d orphans=%d res=%d vid=%.1fMB armies=%d" % [g.month / 12, frames, OS.get_static_memory_usage() / 1048576.0, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0, g.armies.size()])
	print("done month=", g.month, " game_over=", g.game_over)
	quit()
