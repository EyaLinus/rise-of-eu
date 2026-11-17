extends SceneTree
## Goods price check: godot --headless -s res://tools/price_probe.gd -- --years 200 --seed 1
## Prints every 20 years the mean price multiplier (price / base price), how many goods sit on the
## floor or ceiling, world supply against the start, and the average income of the living majors.

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")


func _init() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	for i in range(0, a.size() - 1, 2):
		args[a[i].trim_prefix("--")] = a[i + 1]
	var data := Data.load_all()
	var g = Game.new()
	g.setup(data, int(args.get("seed", "1")), "")
	var s0 := 0.0
	for k in g.base_supply:
		s0 += float(g.base_supply[k])
	for y in int(args.get("years", "200")):
		for m in 12:
			g.tick()
		if (y + 1) % 20 == 0:
			var sum := 0.0
			var lo := 0
			var hi := 0
			for k in g.goods_def:
				var r: float = float(g.prices[k]) / float(g.goods_def[k].price)
				sum += r
				lo += 1 if r <= float(g.bal.price_min) + 0.001 else 0
				hi += 1 if r >= float(g.bal.price_max) - 0.001 else 0
			var s := 0.0
			var sup: Dictionary = g.Economy.supply(g)
			for k in sup:
				s += float(sup[k])
			var inc := 0.0
			var nm := 0
			for t in g.order:
				if g.nations[t].alive and g.nations[t].major:
					inc += g.nations[t].income
					nm += 1
			print("Y%d mean %.2f floor %d ceil %d of %d  supply x%.2f  major income %.1f" % [g.year(), sum / g.goods_def.size(), lo, hi, g.goods_def.size(), s / s0, inc / maxi(1, nm)])
	quit()
