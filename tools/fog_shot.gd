extends SceneTree
## Fog of war screenshots (needs a display, e.g. xvfb-run):
## godot --path . -s res://tools/fog_shot.gd -- --out /tmp/fog_shots

var out := "user://fog_shots"


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
	root.get_texture().get_image().save_png(out + "/" + name + ".png")


func _run(m) -> void:
	await create_timer(0.5).timeout
	m._start_game("FRA")
	m.settings.tips = false
	m._close_modal()
	var g = m.game
	for i in 24:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	m._after_tick()
	m._close_modal()
	m._close_panel()
	var paris: Vector2 = g.provinces[g.key_to_pid["paris"]].center
	g.fog_of_war = true
	m.map.focus(paris + Vector2(250, 0), 0.6)
	m.map.refresh()
	await _shot("fog_on")
	g.fog_of_war = false
	m.map.refresh()
	await _shot("fog_off")
	g.fog_of_war = true
	m.map.focus(paris, 1.4)
	m.map.refresh()
	await _shot("fog_on_close")
	quit()
