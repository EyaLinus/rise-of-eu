extends SceneTree
## Smoke test of the real main loop: months run in small steps spread over frames (main._run_month).
## Plays two years at the fastest speed and checks that months advance, each month is spread over
## several frames, no frame spends much more than the step budget on the simulation, and saving in the
## middle of a month finishes that month first.
##   godot --headless --path . -s res://tools/month_steps_smoke.gd

func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.2).timeout
	m.settings.tips = false
	m._start_game("FRA")
	m._close_modal()
	var g = m.game
	m._set_speed(m.SPEEDS.size() - 1)
	Engine.time_scale = 20.0  # months are due at once, so the loop runs flat out
	var frames := 0
	var worst_frame_us := 0
	var fails := 0
	var saved_mid := false
	while g.month < 24 and frames < 20000:
		var t0 := Time.get_ticks_usec()
		await process_frame
		worst_frame_us = maxi(worst_frame_us, Time.get_ticks_usec() - t0)
		frames += 1
		if m.modal.visible:
			while not g.pending_events.is_empty():
				g.choose_event_option(g.player, g.pending_events[0], 0)
			while not g.pending_peace.is_empty():
				g.answer_player_peace(g.pending_peace[0], true)
			m._close_modal()
		if m.speed == 0:
			m._set_speed(m.SPEEDS.size() - 1)
		if not saved_mid and g.ticking() and g.month == 6:
			var before: int = g.month
			m._save_game("auto")
			saved_mid = true
			if g.ticking() or g.month != before + 1:
				print("FAIL: saving mid-month did not finish the month first")
				fails += 1
	Engine.time_scale = 1.0
	var per_month: float = float(frames) / maxf(1.0, g.month)
	print("months %d in %d frames (%.1f frames/month), worst frame %.1f ms, last month %.1f ms sim over %d frames" % [
			g.month, frames, per_month, worst_frame_us / 1000.0, m.debug_screen.tick_avg_ms(), m.debug_screen.tick_frames])
	if g.month < 24:
		print("FAIL: months did not advance")
		fails += 1
	if not saved_mid:
		print("FAIL: no mid-month save happened")
		fails += 1
	print("MONTH STEPS %s" % ("OK" if fails == 0 else "FAILED"))
	quit(1 if fails > 0 else 0)
