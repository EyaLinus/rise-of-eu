extends SceneTree
## Map/UI cost probe: draw calls, primitives and CPU time per frame at several zoom levels, the cost
## of a full map refresh, of the per-tick map update and of rebuilding each side panel.
## Needs a real renderer (llvmpipe under xvfb is fine for counts, NOT for GPU timings):
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 -s res://tools/render_perf.gd -- [--years 30]
## Local tool, not part of CI.

func _init() -> void:
	_run()


func _frame_stats(n: int) -> Dictionary:
	var dc := 0.0
	var prim := 0.0
	var obj := 0.0
	var cpu := 0.0
	for i in n:
		var t0 := Time.get_ticks_usec()
		await process_frame
		cpu += Time.get_ticks_usec() - t0
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		obj += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	return {"draw_calls": dc / n, "primitives": prim / n, "objects": obj / n, "frame_ms": cpu / 1000.0 / n}


func _run() -> void:
	var years := 30
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size() - 1):
		if args[i] == "--years":
			years = int(args[i + 1])
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.3).timeout
	m.settings.tips = false
	m._start_game("FRA")
	m._close_modal()
	var g = m.game
	var map = m.map
	print("viewport %s, nodes %d, map layers %d" % [root.get_visible_rect().size, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), map._layers.size()])
	# play some years headless-fast so the map has wars, roads, cities
	for i in years * 12:
		g.tick()
		while not g.pending_events.is_empty():
			g.choose_event_option(g.player, g.pending_events[0], 0)
		while not g.pending_peace.is_empty():
			g.answer_player_peace(g.pending_peace[0], true)
	var t0 := Time.get_ticks_usec()
	map.refresh()
	await process_frame
	print("full map.refresh() + first frame: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	for z in [0.25, 0.5, 0.8, 1.5, 3.0]:
		map.zoom = z
		map._clamp()
		map.refresh()
		await process_frame
		var s: Dictionary = await _frame_stats(30)
		print("zoom %.2f: %4.0f draw calls, %6.0f primitives, %4.0f objects, %.1f ms/frame (CPU+llvmpipe)" % [z, s.draw_calls, s.primitives, s.objects, s.frame_ms])
	map.zoom = 0.8
	map._clamp()
	map.refresh()
	# per-tick UI cost: tick + _after_tick (map pieces, top bar, panel)
	m._open_panel("nation")
	var tick_us := 0
	var after_us := 0
	var redraws := 0
	for i in 24:
		var a := Time.get_ticks_usec()
		g.tick()
		var b := Time.get_ticks_usec()
		m._after_tick()
		await process_frame
		var c := Time.get_ticks_usec()
		tick_us += b - a
		after_us += c - b
		redraws += map.world_redraws
		while not g.pending_events.is_empty():
			g.choose_event_option(g.player, g.pending_events[0], 0)
		while not g.pending_peace.is_empty():
			g.answer_player_peace(g.pending_peace[0], true)
		m._close_modal()
	# pieces of _after_tick
	var parts := {"update_top": 0, "map.check_dev": 0, "map.refresh_after_tick": 0, "panel._refresh": 0, "frame": 0}
	for i in 12:
		g.tick()
		var a := Time.get_ticks_usec()
		m._update_top()
		var b := Time.get_ticks_usec()
		map.check_dev_changes()
		var c := Time.get_ticks_usec()
		map.refresh_after_tick()
		var d := Time.get_ticks_usec()
		m._refresh()
		var e := Time.get_ticks_usec()
		await process_frame
		var f := Time.get_ticks_usec()
		parts.update_top += b - a
		parts["map.check_dev"] += c - b
		parts["map.refresh_after_tick"] += d - c
		parts["panel._refresh"] += e - d
		parts.frame += f - e
		while not g.pending_events.is_empty():
			g.choose_event_option(g.player, g.pending_events[0], 0)
		while not g.pending_peace.is_empty():
			g.answer_player_peace(g.pending_peace[0], true)
	for k in parts:
		print("  %-24s %.1f ms" % [k, parts[k] / 12000.0])
	print("per month: tick %.1f ms, after_tick+frame %.1f ms, world pieces redrawn %.1f" % [tick_us / 24000.0, after_us / 24000.0, redraws / 24.0])
	for mode in ["nation", "economy", "diplomacy", "wars", "navy", "missions", "ranking", "tech", "gov"]:
		var a := Time.get_ticks_usec()
		m._open_panel(mode)
		await process_frame
		print("panel %-10s %.1f ms (open + frame), nodes %d" % [mode, (Time.get_ticks_usec() - a) / 1000.0, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	print("memory static %.1f MB, video %.1f MB, texture %.1f MB" % [OS.get_static_memory_usage() / 1048576.0,
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])
	quit()
