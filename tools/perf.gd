extends SceneTree
## Per-phase timing of the real monthly tick (Game.tick with the built-in profiler), plus memory,
## save size and save/load time. Prints one block per interval because the cost grows over the game.
##   godot --headless --path . -s res://tools/perf.gd -- --years 60 [--every 20] [--seed 7] [--player FRA] [--json out.json]
## Keep runs short in CI (rule: no 200-year sims there); 40-60 years is enough for a comparison.

const Data = preload("res://scripts/core/data.gd")
const Game = preload("res://scripts/core/game.gd")


func _arg(args: PackedStringArray, key: String, def: String) -> String:
	var i := args.find(key)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else def


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var years := int(_arg(args, "--years", "60"))
	var every := int(_arg(args, "--every", "20"))
	var seed_v := int(_arg(args, "--seed", "7"))
	var player := _arg(args, "--player", "FRA")
	var out := _arg(args, "--json", "")
	var t0 := Time.get_ticks_usec()
	var data: Dictionary = Data.load_all()
	var t1 := Time.get_ticks_usec()
	var g = Game.new()
	g.setup(data, seed_v, player)
	var t2 := Time.get_ticks_usec()
	print("provinces %d  nations %d  load_data %.0f ms  setup %.0f ms" % [g.provinces.size(), g.nations.size(),
			(t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	var report := {"provinces": g.provinces.size(), "nations": g.nations.size(), "intervals": []}
	var total := {}
	var months := 0
	for block in range(0, years, every):
		if "prof" in g:
			g.prof = {}
		var n := 0
		var w0 := Time.get_ticks_usec()
		var worst := 0
		var worst_step := 0
		var worst_step_name := ""
		var step_max := {}  # step method -> [max usec, steps over 16 ms]
		for m in mini(every, years - block) * 12:
			var a := Time.get_ticks_usec()
			if "_steps" in g:
				# the stepped month of the UI: also find the longest single step (one frame's worth at most)
				if g.tick_begin():
					while true:
						var nxt: Callable = g._steps[g._step_i]
						var sa := Time.get_ticks_usec()
						var more: bool = g.tick_step()
						var sd := Time.get_ticks_usec() - sa
						var sk: String = nxt.get_method()
						var sm: Array = step_max.get(sk, [0, 0])
						step_max[sk] = [maxi(sm[0], sd), sm[1] + (1 if sd > 16000 else 0)]
						if sd > worst_step:
							worst_step = sd
							worst_step_name = nxt.get_method()
						if not more:
							break
			else:
				g.tick()
			worst = maxi(worst, Time.get_ticks_usec() - a)
			n += 1
		var wall := Time.get_ticks_usec() - w0
		months += n
		var alive := 0
		for tag in g.order:
			if g.nations[tag].alive:
				alive += 1
		print("\n== %d-%d  (%d alive, %d armies, %d wars)  %.2f ms/tick  worst tick %.1f ms" % [
				g.year() - mini(every, years - block), g.year(), alive, g.armies.size(), g.wars.size(),
				wall / 1000.0 / n, worst / 1000.0])
		if worst_step > 0:
			print("  longest single step: %s %.1f ms" % [worst_step_name, worst_step / 1000.0])
			var sks: Array = step_max.keys()
			sks.sort_custom(func(x, y): return step_max[x][0] > step_max[y][0])
			var parts := []
			for sk in sks.slice(0, 8):
				parts.append("%s %.1f (%d>16ms)" % [sk, step_max[sk][0] / 1000.0, step_max[sk][1]])
			print("  steps by max ms: " + ", ".join(parts))
		var pr: Dictionary = g.prof if "prof" in g else {}
		var keys: Array = pr.keys()
		keys.sort_custom(func(x, y): return pr[x] > pr[y])
		var iv := {"year": g.year(), "ms_tick": wall / 1000.0 / n, "worst_ms": worst / 1000.0, "alive": alive,
				"armies": g.armies.size(), "phases": {}}
		for k in keys:
			var ms: float = pr[k] / 1000.0 / n
			total[k] = total.get(k, 0) + pr[k]
			iv.phases[k] = ms
			if ms >= 0.05:
				print("  %-12s %7.2f ms/tick  %4.1f %%" % [k, ms, 100.0 * pr[k] / wall])
		report.intervals.append(iv)
		if g.game_over:
			break
	if "prof" in g:
		g.prof = null
	# save / load
	var s0 := Time.get_ticks_usec()
	var d: Dictionary = g.to_dict()
	var s1 := Time.get_ticks_usec()
	var txt := JSON.stringify(d)
	var s2 := Time.get_ticks_usec()
	var parsed = JSON.parse_string(txt)
	var g2 = Game.new()
	g2.setup(Data.load_all(), seed_v, player)
	var s3 := Time.get_ticks_usec()
	g2.from_dict(parsed)
	var s4 := Time.get_ticks_usec()
	print("\nsave: to_dict %.0f ms, stringify %.0f ms, size %.2f MB (%.2f MB gzip)  load: from_dict %.0f ms" % [
			(s1 - s0) / 1000.0, (s2 - s1) / 1000.0, txt.length() / 1048576.0,
			txt.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP).size() / 1048576.0, (s4 - s3) / 1000.0])
	print("memory: static %.1f MB (peak %.1f MB), objects %d" % [OS.get_static_memory_usage() / 1048576.0,
			OS.get_static_memory_peak_usage() / 1048576.0, Performance.get_monitor(Performance.OBJECT_COUNT)])
	report["save_mb"] = txt.length() / 1048576.0
	report["mem_mb"] = OS.get_static_memory_usage() / 1048576.0
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "\t"))
	quit()
