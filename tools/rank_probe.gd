extends SceneTree
## Realm size, treasury and power over an AI game, for sizing rank costs and stability (Progression, Stability).
## godot --headless -s res://tools/rank_probe.gd -- --years 100 --seed 1000

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")


func _init() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			args[a[i].substr(2)] = a[i + 1]
	var years := int(args.get("years", "100"))
	var g = Game.new()
	g.setup(Data.load_all(), int(args.get("seed", "1000")), "")
	for m in years * 12 + 1:
		if m % 300 == 0:
			_report(g)
		g.tick()
	quit()


func _report(g) -> void:
	var tags: Array = g.order.filter(func(t): return g.nations[t].alive and t != "NAT")
	tags.sort_custom(func(x, y): return g.nations[x].dev_total > g.nations[y].dev_total)
	var line := "Y%d" % g.year()
	var ranks := {}
	for t in tags:
		var n = g.nations[t]
		var r: int = n.get("rank") if "rank" in n else 0
		ranks[r] = ranks.get(r, 0) + 1
	line += " ranks=%s" % str(ranks)
	print(line)
	for t in tags.slice(0, 8):
		var n = g.nations[t]
		var stab: float = n.get("stability") if "stability" in n else 0.0
		print("  %s prov=%d dev=%d gold=%d inc=%.1f adm=%d prest=%d stab=%d rank=%s" % [t, g.provinces_of(t).size(), n.dev_total, n.gold, n.income, n.adm, n.prestige, stab, str(n.get("rank") if "rank" in n else "-")])
