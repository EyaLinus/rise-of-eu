extends SceneTree
## Subject types probe (Subjects): colonial nations, dominions, appanages and their independence over time.
## godot --headless --path . -s res://tools/subject_probe.gd -- [seed] [years] [every]

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := int(args[0]) if args.size() > 0 else 1
	var years := int(args[1]) if args.size() > 1 else 150
	var every := int(args[2]) if args.size() > 2 else 25
	var g := Game.new()
	g.setup(Data.load_all(), seed_value, "")
	var t0 := Time.get_ticks_msec()
	for y in years:
		for m in 12:
			if g.game_over:
				break
			g.tick()
		if y % every == every - 1:
			_report(g)
	print("stats colonial_nations=%d appanages=%d independence=%d colonies=%d  %.1f s" % [int(g.stats.get("colonial_nations", 0)), int(g.stats.get("appanages", 0)),
			int(g.stats.get("independence", 0)), int(g.stats.get("colonies", 0)), (Time.get_ticks_msec() - t0) / 1000.0])
	quit()


func _report(g) -> void:
	var S = g.Subjects
	var lines := []
	var by := {"": 0, "colony": 0, "dominion": 0, "appanage": 0}
	for t in g.order:
		var n = g.nations[t]
		if not n.alive:
			continue
		if n.overlord != "":
			by[n.subject] += 1
			if n.subject != "":
				lines.append("  %s %s %s of %s: %d prov, dev %d, liberty %.2f, since %d" % [S.icon(g, t), t, n.name, n.overlord, g.provinces_of(t).size(), n.dev_total, g.liberty(t),
						g.year() - (g.month - n.vassal_since) / 12])
		elif n.flags.has("former_colony") or n.flags.has("flag_of"):
			lines.append("  🗽 %s %s independent (founded by %s): %d prov, dev %d" % [t, n.name, n.flags.get("flag_of", "?"), g.provinces_of(t).size(), n.dev_total])
	print("== %d vassals %d colonies %d dominions %d appanages %d" % [g.year(), by[""], by.colony, by.dominion, by.appanage])
	for l in lines:
		print(l)
