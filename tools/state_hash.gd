extends SceneTree
## Determinism check for refactors: plays an all-AI game and prints a hash of the full save state.
## Same seed + same rules must give the same hash before and after a pure performance change.
##   godot --headless --path . -s res://tools/state_hash.gd -- --years 20 [--seed 7] [--player FRA]

const Data = preload("res://scripts/core/data.gd")
const Game = preload("res://scripts/core/game.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var years := 20
	var seed_v := 7
	var player := "FRA"
	var dump := ""  # write the final state as JSON to this path (diff two runs to find what differs)
	for i in range(0, args.size() - 1):
		match args[i]:
			"--years": years = int(args[i + 1])
			"--seed": seed_v = int(args[i + 1])
			"--player": player = args[i + 1]
			"--dump": dump = args[i + 1]
	var g = Game.new()
	g.setup(Data.load_all(), seed_v, player)
	for y in years:
		for m in 12:
			g.tick()
			while not g.pending_events.is_empty():
				g.choose_event_option(g.player, g.pending_events[0], 0)
		print("year %d  state %s" % [g.year(), str(JSON.stringify(g.to_dict()).hash())])
	if dump != "":
		var f := FileAccess.open(dump, FileAccess.WRITE)
		f.store_string(JSON.stringify(g.to_dict(), " ", true))
	quit()
