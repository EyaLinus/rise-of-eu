extends SceneTree
## Map clarity before/after screenshots (needs a display, e.g. xvfb-run):
## godot --path . -s res://tools/clarity_shot.gd -- --out /tmp/clarity --months 600
## Plays N months first so roads, cities and landmarks have grown like in a late game.

var out := "user://clarity_shots"
var months := 600


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i] == "--out":
			out = args[i + 1]
		elif args[i] == "--months":
			months = int(args[i + 1])
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
	seed(4242)
	m.start_seed = 4242
	m._start_game("FRA")
	m.settings.tips = false
	m._close_modal()
	var g = m.game
	for i in months:
		g.tick()
		g.pending_events.clear()
		g.pending_peace.clear()
	load("res://scripts/core/debug_tools.gd").reveal_world(g, "FRA")
	m._after_tick()
	m._close_modal()
	m._close_panel()
	var paris: Vector2 = g.provinces[g.key_to_pid["paris"]].center
	m.map.refresh()
	m.map.focus(paris + Vector2(150, -50), 0.5)
	await _shot("a_europe_05")
	m.map.focus(paris + Vector2(150, 0), 0.8)
	await _shot("b_france_08")
	m.map.focus(paris + Vector2(100, 0), 1.2)
	await _shot("c_france_12")
	m.map.focus(paris, 1.8)
	await _shot("d_paris_18")
	m.map.focus(paris, 3.0)
	await _shot("e_paris_30")
	if g.key_to_pid.has("stockholm"):
		m.map.focus(g.provinces[g.key_to_pid["stockholm"]].center + Vector2(-200, 50), 0.8)
		await _shot("f_scandinavia_08")
	m.map.focus(paris + Vector2(-150, -150), 1.0)
	await _shot("g_british_10")
	# a dense road network (levels 1-3 mixed) on bendy coasts: style and the "never over water" rule
	for p in g.provinces:
		if p.center.distance_to(paris) < 700.0:
			p.buildings["road"] = 1 + p.id % 3
	m.map.refresh()
	m.map.focus(paris + Vector2(-120, -40), 1.1)
	await _shot("h_roads_11")
	m.map.focus(paris + Vector2(-300, -150), 2.0)
	await _shot("i_roads_coast_20")
	m.map.focus(paris + Vector2(-250, 0), 0.75)
	await _shot("j_roads_075")
	quit()
