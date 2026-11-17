extends RefCounted
## Debug mode helpers (settings "Debug-Modus", panel scripts/ui/debug_screen.gd). UI-free so the
## headless tests cover them. Two kinds:
## - diagnostics: sizes of every growing game list and the biggest army stacks, to spot leaks and
##   visual overload when a long game slows down or crashes;
## - cheats for testing: resources, take a province, reveal the world, white peace, play as another
##   realm, fire an event, jump ahead in time.
## Cheats only change the running game; the save marks it (stats.debug_used) so a hall-of-fame
## entry can tell. Each cheat returns "" or a German error text, like the other game actions.

const Colonial = preload("res://scripts/core/colonial.gd")


## Counts of everything that grows during a game (a leak shows as a number that only rises).
static func snapshot(g) -> Dictionary:
	var alive := 0
	for t in g.order:
		if g.nations[t].alive:
			alive += 1
	var regs := 0.0
	for a in g.armies:
		regs += float(a.regs)
	var s := {
		"year": g.year(),
		"month": g.month,
		"nations_alive": alive,
		"armies": g.armies.size(),
		"regiments": int(round(regs)),
		"battles": g.battles.size(),
		"wars": g.wars.size(),
		"voyages": g.voyages.size(),
		"log_lines": g.log_lines.size(),
		"chronicle": g.chronicle.size(),
		"pending_events": g.pending_events.size(),
		"pending_peace": g.pending_peace.size(),
		"history": g.history.size(),
		"score_history": g.score_history.size(),
		"peace_memo": g.peace_offer_memo.size(),
		"found": g.found.size(),
	}
	var stacks := stack_counts(g)
	var worst := 0
	for pid in stacks:
		worst = maxi(worst, int(stacks[pid]))
	s["max_stacks_in_province"] = worst
	return s


## pid -> number of separate armies standing there (several 1-regiment stacks = map clutter).
static func stack_counts(g) -> Dictionary:
	var c := {}
	for a in g.armies:
		c[a.pid] = int(c.get(a.pid, 0)) + 1
	return c


## The `limit` provinces with the most army stacks: [[pid, stacks, regiments], ...], most first.
static func crowded_provinces(g, limit: int = 5) -> Array:
	var regs := {}
	for a in g.armies:
		regs[a.pid] = float(regs.get(a.pid, 0.0)) + float(a.regs)
	var rows := []
	var stacks := stack_counts(g)
	for pid in stacks:
		rows.append([pid, int(stacks[pid]), int(round(float(regs[pid])))])
	rows.sort_custom(func(x, y): return x[1] > y[1] or (x[1] == y[1] and x[2] > y[2]))
	return rows.slice(0, limit)


static func _mark(g) -> void:
	g.stats["debug_used"] = int(g.stats.get("debug_used", 0)) + 1


static func add_resources(g, tag: String, gold: float, mana: float, manpower: float = 0.0) -> String:
	if not g.nations.has(tag):
		return "Unbekannte Nation"
	var n = g.nations[tag]
	n.gold += gold
	n.adm += mana
	n.dip += mana
	n.mil += mana
	n.manpower += manpower
	_mark(g)
	return ""


## Gives a province to `tag` at once (no war, no AE). Its old owner may be wiped out by it.
static func take_province(g, tag: String, pid: int) -> String:
	if pid < 0 or pid >= g.provinces.size():
		return "Keine Provinz"
	var p = g.provinces[pid]
	var old: String = p.owner
	if old == tag:
		return "Gehört schon %s" % g.nations[tag].name
	if old == "":
		return "Niemandsland"
	p.owner = tag
	p.controller = tag
	p.prev_owner = old
	p.core_months = 0
	p.siege = 0.0
	p.colonist = ""
	p.colony_months = 0
	g._rebuild_owned()
	for a in g.armies:
		if a.owner == old and a.pid == pid and g.nations[old].capital != pid:
			a.pid = g.nations[old].capital
	g._check_alive(old)
	_mark(g)
	return ""


## Every sea and overseas province becomes known to `tag` (Colonial terra incognita).
static func reveal_world(g, tag: String) -> int:
	var c := 0
	for s in g.seas:
		c += Colonial.reveal_sea(g, tag, s.id)
	for pid in g.overseas:
		if Colonial.reveal(g, tag, pid):
			c += 1
	_mark(g)
	return c


## White peace in every war `tag` takes part in. Returns how many wars ended.
static func end_wars(g, tag: String) -> int:
	var c := 0
	for w in g.wars.duplicate():
		if w.attackers.has(tag) or w.defenders.has(tag):
			g.make_peace(w, w.attackers.has(tag), [])
			c += 1
	if c > 0:
		_mark(g)
	return c


## The player takes over another living realm; the old one goes back to the AI.
static func switch_player(g, tag: String) -> String:
	if not g.nations.has(tag) or not g.nations[tag].alive:
		return "Diese Nation gibt es nicht (mehr)"
	if tag == g.player:
		return "Das bist du schon"
	g.player = tag
	g.pending_events.clear()
	g.pending_peace.clear()
	_mark(g)
	return ""


static func fire_event(g, tag: String, event_id: String) -> String:
	if not g.event_by_id.has(event_id):
		return "Kein Ereignis „%s“" % event_id
	g.fire_event(tag, event_id)
	_mark(g)
	return ""


## Event ids that start with `prefix` (for the event field's suggestions), sorted, at most `limit`.
static func event_ids(g, prefix: String, limit: int = 12) -> Array:
	var out := []
	for id in g.event_by_id:
		if prefix == "" or String(id).begins_with(prefix):
			out.append(String(id))
	out.sort()
	return out.slice(0, limit)


## Runs `months` months without the UI, until the end of the game at the latest. Player decisions on
## the way are answered automatically (first event option, peace offers declined), so a long jump does
## not stop at every event. Returns the months actually run.
static func skip_months(g, months: int) -> int:
	var c := 0
	while c < months and not g.game_over:
		g.tick()
		c += 1
		var guard := 0
		while not g.pending_events.is_empty() and guard < 50:
			g.choose_event_option(g.player, g.pending_events[0], 0)
			guard += 1
		for offer in g.pending_peace.duplicate():
			g.answer_player_peace(offer, false)
		g.pending_peace.clear()
	if c > 0:
		_mark(g)
	return c
