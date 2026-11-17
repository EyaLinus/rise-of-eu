extends SceneTree
var out := "/tmp/claude-0/shots"
func _init() -> void:
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
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("FRA", "ENG")
	g.pending_events.clear()
	g.pending_peace.clear()
	var pid: int = g.key_to_pid["calais"]
	for a in g.armies.duplicate():
		if a.owner == "FRA" or a.owner == "ENG":
			g.armies.erase(a)
	var f = g.spawn_army("FRA", pid, 12.0)
	f.mix = {"inf": 0.6, "cav": 0.3, "art": 0.1}
	var e = g.spawn_army("ENG", pid, 10.0)
	g.nations.FRA.ships = 12.0
	g.nations.ENG.ships = 9.0
	g.Naval.refresh(g)
	g.Warfare.gather(g)
	var b = g.Warfare.battle_at(g, pid)
	for i in 3:
		g.Warfare.fight_round(g, b)
	g.sea_fights = [{"sea": g.seas[0].id, "win": "FRA", "lose": "ENG", "lost": 2.4, "won_lost": 0.8, "month": g.month}]
	m.map._check_battle_rounds()
	m.map.focus(g.provinces[pid].center, 1.0)
	m._open_panel("army", f.id)
	m._after_tick()
	m.map.queue_redraw()
	await create_timer(0.3).timeout
	await _shot("10_battle")
	g.Units.add_template(g, "FRA", "Feldheer", {"cav": 0.3, "art": 0.1})
	g.Units.add_template(g, "FRA", "Reiterheer", {"cav": 0.6})
	m._show_templates()
	await _shot("11_templates")
	quit()
