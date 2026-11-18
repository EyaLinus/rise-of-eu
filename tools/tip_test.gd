extends SceneTree
## Rich tooltip behaviour with a simulated mouse (headless, a few seconds; in CI):
## hover opens after the delay, the tip locks, a locked tip survives the move into it, nested term tips,
## moving away closes everything, touch long press opens a locked tip. Exits 1 on a failure.

var fails := 0
var m


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	var backup := FileAccess.get_file_as_string("user://settings.json") if FileAccess.file_exists("user://settings.json") else ""
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	await create_timer(0.2).timeout
	m._start_game("FRA")
	m.settings.tips = false
	m.settings.tip_delay = 1
	m._close_modal()
	await process_frame
	m._update_top()
	await process_frame
	root.notification(Node.NOTIFICATION_WM_MOUSE_ENTER)
	root.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)  # headless: no window events, the GUI ignores the mouse until then
	var slot: Control = m.top_slots.gold
	var at: Vector2 = slot.get_global_rect().get_center()
	await _move(at)
	await create_timer(0.1).timeout
	check(not m.tips.is_open(), "no tip before the delay")
	await create_timer(0.4).timeout
	check(m.tips.is_open() and m.tips.tips[0].src == slot, "tip opens after hovering the gold slot")
	# the icon counts too (whole slot is the hover area)
	var icon: Control = slot.find_children("*", "TextureRect", true, false)[0]
	await _move(icon.get_global_rect().get_center())
	await process_frame
	check(m.tips.is_open() and m.tips.tips[0].src == slot, "icon of the slot keeps the tip")
	await create_timer(1.0).timeout
	check(m.tips.tips[0].locked, "tip locks after staying on the control")
	var tip_rect: Rect2 = m.tips.tips[0].panel.get_global_rect()
	await _move(tip_rect.get_center())
	await create_timer(0.5).timeout
	check(m.tips.is_open(), "locked tip stays while the mouse is in it")
	# nested term tip
	m.tips._on_meta_hover(m.tips.tips[0], "kw:tax")
	await process_frame
	check(m.tips.tips.size() == 2 and m.tips.tips[1].key == "tax", "hovering a term opens its explanation")
	check(m.tips.tips[1].locked, "nested tip is locked (its own terms can be hovered)")
	m.tips._on_meta_hover(m.tips.tips[1], "kw:gold")
	await process_frame
	check(m.tips.tips.size() == 3 and m.tips.tips[2].key == "gold", "a term inside a nested tip opens a third tip")
	m.tips._on_meta_hover(m.tips.tips[2], "kw:market")
	await process_frame
	m.tips._on_meta_hover(m.tips.tips[3], "kw:trade")
	await process_frame
	check(m.tips.tips.size() >= 5, "nesting has no depth limit (%d open)" % m.tips.tips.size())
	check(not m.tips.tips[1].rtl.text.contains("kw:tax"), "a term does not link to itself")
	await _move(Vector2(m.size.x / 2, m.size.y - 200))
	await create_timer(0.6).timeout
	check(not m.tips.is_open(), "moving away closes all tips")
	# settings: the lock delay and the show delay are sliders (ms)
	m.settings.tip_lock_ms = 200.0
	m.settings.tip_show_ms = 50.0
	check(absf(m.tips.lock_s() - 0.2) < 0.001 and absf(m.tips.delay() - 0.05) < 0.001, "tooltip delays come from the ms settings")
	await _move(at)
	await create_timer(0.6).timeout
	check(m.tips.is_open() and m.tips.tips[0].locked, "tip locks after the shortened lock delay")
	await _move(Vector2(m.size.x / 2, m.size.y - 200))
	await create_timer(0.6).timeout
	m.settings.erase("tip_lock_ms")
	m.settings.erase("tip_show_ms")
	# a quick pass over a control does not lock
	await _move(at)
	await create_timer(0.5).timeout
	await _move(Vector2(m.size.x / 2, m.size.y - 200))
	await create_timer(0.1).timeout
	check(not m.tips.is_open(), "unlocked tip closes at once when leaving")
	# click on a term opens its panel
	await _move(at)
	await create_timer(1.6).timeout
	m.tips._on_meta_click(m.tips.tips[0], "kw:tax")
	await process_frame
	check(m.panel_mode == "economy" and not m.tips.is_open(), "clicking a term opens its screen")
	m._close_panel()
	# formatter: short lines, tables, terms
	var bb: String = m.tips.format("Stadt: +20 % Steuern, +25 % Handelsmacht, ein Bauplatz mehr, aber 30 % weniger Mannschaften und +0.5 Unruhe.")
	check(bb.count("\n") >= 4 and bb.contains("kw:unrest"), "modifier lists become one line each, terms are links")
	check(m.tips.format("A\nB\tC").contains("[table=2]"), "TAB rows become a table")
	check(m.tips.format("Militärtechnik").find("kw:") < 0, "no term inside a longer word")
	# quick actions (right click / long press on a province)
	var g = m.game
	var paris: int = g.key_to_pid["paris"]
	m._on_province_context(paris, Vector2(400, 300))
	check(m.quick.visible and m.quick.box.get_child_count() >= 5, "right click on an own province opens the quick menu")
	var labels := []
	for e in m.quick.entries(paris):
		labels.append(e[0])
	check(labels.any(func(t): return t.contains("Entwickeln")) and labels.any(func(t): return t.contains("Regiment")), "own province: develop and recruit are one click away")
	check(labels.any(func(t): return t.contains("Notre-Dame") and t.contains("2→3")), "own province: the next landmark level is in the quick menu")
	g.nations.FRA.gold = 5000.0
	var before: int = g.provinces[paris].constructing.size()
	m.quick.entries(paris)[0][1].call()
	check(not g.provinces[paris].constructing.is_empty() or before > 0, "first quick entry starts the best building")
	var london: int = g.key_to_pid["london"]
	var fl := []
	for e in m.quick.entries(london):
		fl.append(e[0])
	check(fl.any(func(t): return t.contains("Krieg")) and fl.any(func(t): return t.contains("Diplomatie")), "foreign province: war and diplomacy in the quick menu")
	m.quick.close()
	m.selected_army = -1
	# touch: long press opens a locked tip
	m._touch_input = true
	m._press_pos = at
	m._press_time = Time.get_ticks_msec() / 1000.0 - 1.0
	m._dragging = false
	m._suppress_click = false
	m._press_range = null
	m._check_long_press()
	check(m.tips.is_open() and m.tips.tips[0].locked, "touch long press opens a locked tip")
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f != null and backup != "":
		f.store_string(backup)
	print("TIP TEST %s (%d failed)" % ["OK" if fails == 0 else "FAILED", fails])
	quit(1 if fails > 0 else 0)


## Headless Godot tracks no hovered control: tell the tooltip loop what lies under the "mouse".
func _move(p: Vector2) -> void:
	m.tips.fake_mouse = p
	m.tips.fake_hover = null
	for i in range(m.tips.tips.size() - 1, -1, -1):
		if m.tips.tips[i].panel.get_global_rect().has_point(p):
			m.tips.fake_hover = m.tips.tips[i].rtl
			break
	if m.tips.fake_hover == null:
		var c: Control = m._tooltip_at(m.hud, p)
		m.tips.fake_hover = c
	await process_frame
	await process_frame
