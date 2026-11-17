extends SceneTree
## Screenshots of the rich tooltips (tooltips.gd): top bar tip, locked tip with a nested term, a province chip.
## xvfb-run godot --path . --resolution 1560x720 -s res://tools/tip_shot.gd -- --out /tmp/tips --scale 1.4
## Restores user://settings.json afterwards.

var out := "user://tip_shots"
var scale := 1.0
var _settings_backup := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i] == "--out":
			out = args[i + 1]
		elif args[i] == "--scale":
			scale = float(args[i + 1])
	DirAccess.make_dir_recursive_absolute(out)
	if FileAccess.file_exists("user://settings.json"):
		_settings_backup = FileAccess.get_file_as_string("user://settings.json")
	var m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	_run(m)


func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	root.get_texture().get_image().save_png(out + "/" + name + ".png")


func _run(m) -> void:
	await create_timer(0.3).timeout
	m.settings.ui_scale = scale
	m._apply_settings()
	m._start_game("POR")
	m.settings.tips = false
	m._close_modal()
	for i in 3:
		m.game.tick()
	m.game.pending_events.clear()
	m.game.pending_peace.clear()
	m.game.nations.POR.tech.dip = 12
	m._after_tick()
	await process_frame
	m._touch_input = true  # no mouse in the container: touch tips stay open until closed
	var slot: Control = m.top_slots.gold
	m.tips.show_for(slot, slot.get_global_rect().get_center())
	await _shot("a_gold_tip")
	m.tips._show_term(0, "tax")
	await _shot("b_locked_nested")
	m.tips.close_all()
	var lis: int = m.game.key_to_pid.get("lisboa", m.game.nations.POR.capital)
	m.prov_tab = "info"
	m._on_province_tapped(lis)
	await process_frame
	var chip: Control = null
	for c in m.side_box.find_children("*", "PanelContainer", true, false):
		if c.tooltip_text.begins_with("Stadt") or c.tooltip_text.begins_with("Land"):
			chip = c
	if chip != null:
		m.tips.show_for(chip, chip.get_global_rect().get_center())
		await _shot("c_chip_tip")
	m.tips.close_all()
	m.tips.show_for(m.top_slots.settlers, m.top_slots.settlers.get_global_rect().get_center())
	await _shot("d_settlers")
	m.tips.close_all()
	m._close_panel()
	m._on_province_context(lis, m.map.to_screen(m.game.provinces[lis].center))
	await _shot("e_quick_own")
	var sev: int = m.game.key_to_pid.get("sevilla", 0)
	m._on_province_context(sev, m.map.to_screen(m.game.provinces[sev].center))
	await _shot("f_quick_foreign")
	m.quick.close()
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f != null and _settings_backup != "":
		f.store_string(_settings_backup)
	quit()
