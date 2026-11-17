extends SceneTree
## Tracks one nation over AI games: when/how it dies, vassal status, size.
## godot --headless -s res://tools/nation_probe.gd -- --tag HUN --runs 8 --years 200 --seed 1000
## Prints PROBE {json} per run and a PROBE_SUMMARY line.

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")


func _init() -> void:
	var args := {}
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			args[a[i].substr(2)] = a[i + 1]
	var tag: String = args.get("tag", "HUN")
	var runs := int(args.get("runs", "4"))
	var years := int(args.get("years", "200"))
	var seed0 := int(args.get("seed", "1000"))
	var data := Data.load_all()
	var dead := 0
	var dev_sum := 0.0
	for i in runs:
		var g = Game.new()
		g.setup(data, seed0 + i, "")
		var r := {"seed": seed0 + i, "died": 0, "by": "", "how": "", "vassal_of": "", "vassal_year": 0}
		var start_dev: float = g.nation_dev(tag)
		var prev := {}
		for m in years * 12:
			var st_inh := int(g.stats.get("died_inherit", 0))
			var st_ann := int(g.stats.get("died_annexed", 0))
			var buda_before: String = g.provinces[g.nations[tag].capital].owner if g.nations[tag].alive else ""
			g.tick()
			var n = g.nations[tag]
			if n.overlord != "" and r.vassal_of == "":
				r.vassal_of = n.overlord
				r.vassal_year = g.year()
			if not n.alive:
				r.died = g.year()
				r.how = "inherit" if int(g.stats.get("died_inherit", 0)) > st_inh else ("annex_vassal" if int(g.stats.get("died_annexed", 0)) > st_ann else "conquest")
				# heir = whoever owns most former provinces
				var cnt := {}
				for pid in prev:
					var o: String = g.provinces[pid].owner
					cnt[o] = cnt.get(o, 0) + 1
				var best := ""
				for o in cnt:
					if best == "" or cnt[o] > cnt[best]:
						best = o
				r.by = best
				break
			prev = {}
			for pid in g.provinces_of(tag):
				prev[pid] = true
		r["start_dev"] = start_dev
		r["end_dev"] = g.nation_dev(tag) if g.nations[tag].alive else 0
		r["provinces"] = g.provinces_of(tag).size() if g.nations[tag].alive else 0
		if r.died > 0:
			dead += 1
		dev_sum += float(r.end_dev)
		print("PROBE " + JSON.stringify(r))
	print("PROBE_SUMMARY " + JSON.stringify({"tag": tag, "runs": runs, "dead": dead, "avg_end_dev": dev_sum / maxi(runs, 1)}))
	quit()
