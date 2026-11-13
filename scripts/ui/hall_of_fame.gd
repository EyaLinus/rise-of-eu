## Hall of fame: the player's finished games (user://hall.json), best score first.
## Pure data helpers so the list can be tested headless; main.gd shows it in the start menu and at game end.
class_name HallOfFame

const PATH := "user://hall.json"
const MAX_ENTRIES := 30


static func load_entries(path: String = PATH) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Array else []


static func save_entries(entries: Array, path: String = PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(entries))


## Adds a finished game and returns its place in the hall (1 = best ever).
static func add(entry: Dictionary, path: String = PATH) -> int:
	var entries := load_entries(path)
	entries.append(entry)
	entries.sort_custom(func(a, b): return float(a.score) > float(b.score))
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	save_entries(entries, path)
	for i in entries.size():
		if is_same(entries[i], entry):
			return i + 1
	return entries.size()  # dropped off the end: worse than every kept game


## The entry for a finished (or lost) game.
static func entry_for(g) -> Dictionary:
	var n = g.nations[g.player]
	var dt := Time.get_datetime_dict_from_system()
	return {"tag": g.player, "difficulty": g.difficulty, "score": int(g.score(g.player)), "rank": g.rank_of(g.player) if n.alive else 0,
			"year": g.year(), "dev": n.dev_total, "provinces": g.provinces_of(g.player).size(), "alive": n.alive,
			"date": "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]}
