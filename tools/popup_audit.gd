extends SceneTree
## Opens every event popup once and flags any whose layout does not settle (a Container/RichTextLabel
## resize loop floods Godot's message queue and freezes the game for seconds, v1.0.1 crash at 1452).
##   godot --headless --path . -s res://tools/popup_audit.gd -- [--only age_] [--scale 0.85] [--width 1920] [--height 1080] [--chain] [--fail]
## A popup counts as slow when it needs more than 250 ms for two frames (normal: 10-40 ms).
func _init() -> void:
	_run()

func _run() -> void:
	var only := ""
	var scale := 1.0
	var width := 1920
	var height := 1080
	var fail := false
	var chain := false
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--fail": fail = true
		if args[i] == "--chain": chain = true
		if i + 1 >= args.size(): continue
		if args[i] == "--only": only = args[i+1]
		if args[i] == "--scale": scale = float(args[i+1])
		if args[i] == "--width": width = int(args[i+1])
		if args[i] == "--height": height = int(args[i+1])
	root.size = Vector2i(width, height)
	await process_frame
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.2).timeout
	m.settings.tips = false
	m.settings.ui_scale = scale
	m.get_window().content_scale_factor = scale
	m._start_game("SPA")
	m._close_modal()
	await process_frame
	var bad := 0
	var n := 0
	var ids: Array = m.game.event_by_id.keys()
	ids.sort()
	for id in ids:
		if only != "" and not String(id).begins_with(only):
			continue
		n += 1
		var t0 := Time.get_ticks_msec()
		m._show_event(id)
		await process_frame
		await process_frame
		var dt := Time.get_ticks_msec() - t0
		if dt > 250:
			bad += 1
			print("POPUP_SLOW %s %d ms" % [id, dt])
		if not chain:  # --chain: popups follow each other like an event chain (no close in between)
			m._close_modal()
			await process_frame
	print("popup_audit: %d popups, %d slow (scale %.2f, %dx%d)" % [n, bad, scale, width, height])
	quit(1 if fail and bad > 0 else 0)
