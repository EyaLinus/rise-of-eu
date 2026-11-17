extends SceneTree
## Map-only screenshots for before/after art reviews (needs a display, e.g. xvfb-run):
## godot --path . -s res://tools/map_shot.gd -- --out /tmp/map_shots

var out := "user://map_shots"


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
	for i in 30:
		g.tick()
	# a war so armies move and sieges show
	g.nations.FRA.truces.erase("BRI")
	g.nations.BRI.truces.erase("FRA")
	g.declare_war("FRA", "BRI")
	for i in 8:
		g.tick()
	g.pending_events.clear()
	g.pending_peace.clear()
	m._after_tick()
	m._close_modal()
	m._close_panel()
	var paris: Vector2 = g.provinces[g.key_to_pid["paris"]].center
	m.map.focus(paris, 1.6)
	await _shot("map_default")
	m.map.focus(paris, 3.0)
	await _shot("map_zoomed_in")
	m.map.focus(Vector2(3000, 750), 0.45)
	await _shot("map_europe")
	m.map.focus(Vector2(3100, 1000), 1.2)
	await _shot("map_mediterranean")
	m.map.focus(g.provinces[g.key_to_pid["baghdad"]].center, 0.9)
	await _shot("map_middle_east")
	m.map.focus(g.provinces[g.key_to_pid["amhara"]].center, 1.2)
	await _shot("map_horn")
	# Africa south of the Sahara: fogged for France, then revealed (two terrain textures meet at the
	# Gulf of Guinea; zoomed out the half-size texture covers everything)
	var kongo: Vector2 = g.provinces[g.key_to_pid["kongo"]].center if g.key_to_pid.has("kongo") else paris
	m.map.focus(kongo + Vector2(400, 0), 0.4)
	m.map.refresh()
	await _shot("map_africa_fog")
	load("res://scripts/core/debug_tools.gd").reveal_world(g, "FRA")
	m.map.refresh()
	await _shot("map_africa")
	m.map.focus(kongo + Vector2(0, -250), 1.0)
	await _shot("map_congo_seam")
	if g.key_to_pid.has("kilwa"):
		m.map.focus(g.provinces[g.key_to_pid["kilwa"]].center, 1.2)
		await _shot("map_swahili")
		m.map.focus(g.provinces[g.key_to_pid["highveld"]].center, 1.0)
		await _shot("map_south_africa")
	# selection, hover tooltip, war map mode
	m.map.focus(paris, 1.4)
	m.map.selected_pid = g.key_to_pid["paris"]
	m.map.hover_pid = g.key_to_pid["rennes"] if g.key_to_pid.has("rennes") else -1
	m.map._hover_pos = m.map.to_screen(g.provinces[max(m.map.hover_pid, 0)].center)
	m.map.refresh()
	await _shot("map_selected_hover")
	m.map.hover_pid = -1
	m.map.selected_pid = -1
	m.map.map_mode = m.map.MODE_WAR
	m.map.refresh()
	await _shot("map_war")
	m.map.focus(Vector2(3000, 750), 0.45)
	await _shot("map_war_europe")
	# development map mode: cities in brick tones, countryside green-gold
	m.map.map_mode = 2
	m.map.focus(paris, 1.0)
	m.map.refresh()
	await _shot("map_development")
	quit()
