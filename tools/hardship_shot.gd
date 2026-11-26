extends SceneTree
## Screenshots of the new event kinds and council traits (thread "Add council bonuses and new event types"):
## xvfb-run -a godot --path . -s res://tools/hardship_shot.gd -- --out /tmp/shots

var out := "user://shots"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--out":
		out = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	_run(m)


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(out + "/" + name + ".png")


func _run(m) -> void:
	await create_timer(0.5).timeout
	m._start_game("HUN")
	m.settings.tips = false
	m._close_modal()
	m._show_event("start_alliance")
	await _shot("01_start_alliance")
	m._close_modal()
	m._show_event("age_q_buchdruck")
	await _shot("02_historical_decision")
	m._close_modal()
	m._show_event("pp_bank_crash")
	await _shot("03_poison")
	m._close_modal()
	m._show_event("dz_famine_warn")
	await _shot("04_warning")
	m._close_modal()
	m._show_event("dz_famine")
	await _shot("05_disaster")
	m._close_modal()
	m.game.pending_events.clear()
	m.game.nations.HUN.gold = 3000.0
	m.gov_screen.tab = "rat"
	m._open_panel("government")
	await _shot("06_council")
	m.gov_screen.council._pick("coin")
	await _shot("07_council_pick")
	m._close_modal()
	m.game.Council.hire(m.game, "HUN", "coin", 2)
	m.game.Council.hire(m.game, "HUN", "war", 1)
	m._refresh()
	await _shot("08_council_hired")
	quit()
