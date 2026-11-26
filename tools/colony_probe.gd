extends SceneTree
## Colonization by region over time: godot --headless -s res://tools/colony_probe.gd -- --years 150 --seed 1
## Prints every 10 years: owned colonies per region and colonizer, running colonies, known Oceania seas.

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")
const Col = preload("res://scripts/core/colonial.gd")


func _init() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	for i in range(0, a.size() - 1, 2):
		args[a[i].trim_prefix("--")] = a[i + 1]
	var years := int(args.get("years", "150"))
	var g = Game.new()
	g.setup(Data.load_all(), int(args.get("seed", "1")), "")
	for m in years * 12:
		g.tick()
		if m % 120 == 119:
			var by := {}
			var running := 0
			for pid in g.overseas:
				var p = g.provinces[pid]
				if p.colonist != "":
					running += 1
				if p.owner != Col.NATIVE and not Col.is_native_realm(g, p.owner):
					var r := Col.region(g, pid)
					by[r] = by.get(r, {})
					by[r][p.owner] = int(by[r].get(p.owner, 0)) + 1
			var ex := []
			for tag in g.atlantic_tags:
				if g.nations[tag].col_exhaust >= 1.0:
					ex.append("%s:%d" % [tag, int(g.nations[tag].col_exhaust)])
			print("Y%d running=%d %s" % [1444 + (m + 1) / 12, running, JSON.stringify(by)])
			print("   exhaustion " + " ".join(ex))
	quit()
