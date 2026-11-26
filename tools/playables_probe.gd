extends SceneTree
## Tracks several realms in one all-AI game: provinces, dev, vassal status and death per checkpoint.
## godot --headless -s res://tools/playables_probe.gd -- --tags MNG,ASH,INC --years 100 --seed 1000 --every 20
## Prints PP <year> {tag: "prov/dev[v|†]"} per checkpoint and PP_END {json}.

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")


func _init() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			args[a[i].substr(2)] = a[i + 1]
	var tags: Array = String(args.get("tags", "MNG,ASH,INC,LIT,MGL,AZT,MLC,MAL")).split(",")
	var years := int(args.get("years", "100"))
	var every := int(args.get("every", "20"))
	var g = Game.new()
	g.setup(Data.load_all(), int(args.get("seed", "1000")), "")
	var died := {}
	for m in years * 12:
		g.tick()
		for t in tags:
			if not died.has(t) and not g.nations[t].alive:
				died[t] = g.year()
		if (m + 1) % (every * 12) == 0:
			var row := {}
			for t in tags:
				var n = g.nations[t]
				row[t] = "†%d" % died[t] if died.has(t) else "%d/%d%s" % [g.provinces_of(t).size(), g.nation_dev(t), "v" if n.overlord != "" else ""]
			print("PP %d %s" % [g.year(), JSON.stringify(row)])
	print("PP_END " + JSON.stringify({"died": died, "tribes": int(g.stats.get("tribes", 0))}))
	quit()
