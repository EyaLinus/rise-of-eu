extends SceneTree
## Far trade + diplomacy probe: Cape route, Indiamen, factories, dominance, diplomatic capacity.
## godot --headless --path . -s res://tools/trade_probe.gd -- [seed] [years]

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_value := int(args[0]) if args.size() > 0 else 1
	var years := int(args[1]) if args.size() > 1 else 120
	var g := Game.new()
	g.setup(Data.load_all(), seed_value, "")
	var T = g.Trade
	for y in years:
		for m in 12:
			if g.game_over:
				break
			g.tick()
		if y % 20 == 19 or (y > 30 and y < 60 and y % 5 == 4):
			_report(g, T)
	quit()


func _report(g, T) -> void:
	var tops := []
	for tag in g.order:
		var n = g.nations[tag]
		if n.alive:
			tops.append([n.income, tag])
	tops.sort_custom(func(a, b): return a[0] > b[0])
	var s := "== %d cape=%s route=%.1f known=%s factories=%s dom=%d" % [g.year(), g.east.cape, T.route_value(g), g.east.known.keys(), g.east.factories, g.east.dom.size()]
	print(s)
	for i in mini(8, tops.size()):
		var tag: String = tops[i][1]
		var n = g.nations[tag]
		print("  %s dev %d inc %.1f trade %.1f east %.1f ships %d dipt %d diplo %d/%d allies %d vassals %d gold %.0f dip %.0f" % [tag, n.dev_total, n.income,
				n.trade_income, T.east_income(g, tag), T.ships(g, tag), n.tech.dip, g.diplo_used(tag), g.diplo_cap(tag), n.allies.size(), g.vassals_of(tag).size(), n.gold, n.dip])
	var over := []
	for tag in g.order:
		if g.nations[tag].alive and g.diplo_over(tag) > 0:
			over.append("%s+%d" % [tag, g.diplo_over(tag)])
	print("  over cap: ", over)
	for tag in ["POR", "SPA", "ENG", "FRA", "NED", "CAS"]:
		if g.nations.has(tag) and g.nations[tag].alive:
			var n = g.nations[tag]
			print("  %s inc %.1f trade %.1f east %.1f ships %d fac %s dipt %d" % [tag, n.income, n.trade_income, T.east_income(g, tag), T.ships(g, tag), T.factories_of(g, tag), n.tech.dip])
	var line := "  markets:"
	for m in g.markets:
		var e: Dictionary = g.market_cache[m]
		var best := ""
		var bs := 0.0
		for t in e.power:
			if e.power[t] > bs:
				bs = e.power[t]
				best = t
		line += " %s=%.0f(%s %d%%)" % [g.provinces[m].name.left(6), e.value, best, int(100 * bs / maxf(1.0, e.total))]
	print(line)
