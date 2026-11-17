extends SceneTree
## Loads user://save.json (or --new TAG --seed N) in the real main scene, plays at speed 1 and reports
## every frame over 150 ms (UI + simulation; crash/freeze hunt). Under xvfb with opengl3 for real rendering.
##   godot --headless --path . -s res://tools/load_probe.gd -- --months 24 [--new SPA --seed 43106]
func _init() -> void:
	_run()

func _run() -> void:
	var months := 24
	var new_tag := ""
	var seed_v := 7
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size() - 1):
		if args[i] == "--months": months = int(args[i+1])
		if args[i] == "--new": new_tag = args[i+1]
		if args[i] == "--seed": seed_v = int(args[i+1])
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.2).timeout
	m.settings.tips = false
	var t0 := Time.get_ticks_msec()
	if new_tag != "":
		m.game = load("res://scripts/core/game.gd").new()
		m.game.setup(m.data, seed_v, new_tag)
		m.game.set_difficulty("easy")
		m._after_game_loaded()
		m._close_modal()
	else:
		m._load_game("auto")
	print("load ms=", Time.get_ticks_msec() - t0, " month=", m.game.month)
	var g = m.game
	g.prof = {}
	var start: int = g.month
	m._set_speed(1)
	var frames := 0
	var last := Time.get_ticks_usec()
	var worst := 0
	while g.month < start + months and not g.game_over:
		await process_frame
		frames += 1
		var now := Time.get_ticks_usec()
		var dt := now - last
		last = now
		worst = maxi(worst, dt)
		if dt > 150000:
			print("SLOW frame %d month=%d dt=%d ms modal=%s panel=%s" % [frames, g.month, dt / 1000, m.modal.visible, m.panel_mode])
		if m.modal.visible:
			while not g.pending_events.is_empty():
				g.choose_event_option(g.player, g.pending_events[0], 0)
			while not g.pending_peace.is_empty():
				g.answer_player_peace(g.pending_peace[0], true)
			m._close_modal()
		if m.speed == 0:
			m._set_speed(1)
	print("done months=%d frames=%d worst=%d ms" % [g.month - start, frames, worst / 1000])
	var keys: Array = g.prof.keys()
	keys.sort_custom(func(a, b): return g.prof[a] > g.prof[b])
	for k in keys.slice(0, 12):
		print("  ", k, " ", g.prof[k])
	quit()
