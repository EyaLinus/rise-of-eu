extends RefCounted
## Start-of-game alliance choice of the player (data/start_allies.json, tools/content/start_allies.py).
## On a new game the player gets the one-time event "start_alliance": up to max_historical historical partners
## (with the historical reason), the strongest neighbours as ahistorical choices and the option to stay alone.
## The event is dynamic (built from the map at the start, never stored in events.json); after loading a save
## with the event still open it is built again. Effects: {"alliance": tag} (+ relations, diplomacy for big
## ahistorical partners) or the "alone" effects.

const EVENT_ID := "start_alliance"
const NATIVE := "NAT"


static func cfg(g) -> Dictionary:
	return g.start_allies_cfg


static func _ok(g, tag: String, t: String) -> bool:
	if t == tag or t == NATIVE or not g.nations.has(t):
		return false
	var o = g.nations[t]
	var n = g.nations[tag]
	return o.alive and o.overlord == "" and not n.allies.has(t) and not g.at_war(tag, t) \
			and not n.rivals.has(t) and not o.rivals.has(tag) and float(n.relations.get(t, 0.0)) > -50.0


## [{tag, hist: bool, why}] in display order: historical partners first, then neighbours by size.
static func candidates(g, tag: String) -> Array:
	var r := []
	var c := cfg(g)
	if c.is_empty() or not g.nations.has(tag):
		return r
	var taken := {}
	for h in c.get("historical", {}).get(tag, []):
		if r.size() >= int(c.get("max_historical", 2)):
			break
		if _ok(g, tag, str(h.tag)):
			r.append({"tag": str(h.tag), "hist": true, "why": str(h.why)})
			taken[str(h.tag)] = true
	var near: Array = g.neighbors_of(tag)
	for hops in [2, 4]:
		if near.size() >= 3:
			break
		for t in g.nations_in_range(tag, hops):
			if not near.has(t):
				near.append(t)
	near = near.filter(func(t): return not taken.has(t) and _ok(g, tag, t))
	near.sort_custom(func(a, b): return g.nations[a].dev_total > g.nations[b].dev_total)
	for t in near:
		if r.size() >= int(c.get("max_options", 4)):
			break
		r.append({"tag": t, "hist": false, "why": ""})
	return r


static func _strong(g, tag: String, t: String) -> bool:
	return g.nations[t].dev_total > g.nations[tag].dev_total * float(cfg(g).get("strong_ratio", 1.5))


## Effects of allying with candidate `c`.
static func effects(g, tag: String, c: Dictionary) -> Dictionary:
	var e := {"alliance": c.tag}
	if c.hist:
		e["relations"] = {c.tag: int(cfg(g).get("historical_rel", 20))}
	elif _strong(g, tag, c.tag):
		e["dip"] = -int(cfg(g).get("strong_cost_dip", 25))
	return e


static func option_text(g, tag: String, c: Dictionary) -> String:
	var nm: String = g.nations[c.tag].name
	if c.hist:
		return "Bündnis: %s. Historisch: %s." % [nm, c.why]
	if _strong(g, tag, c.tag):
		return "Bündnis: %s. Ahistorisch, der mächtige Nachbar lässt sich nur mit Mühe überzeugen." % nm
	return "Bündnis: %s. Ahistorisch, ein Nachbar." % nm


static func register_event(g, tag: String) -> bool:
	var cs := candidates(g, tag)
	if cs.is_empty():
		return false
	var o := []
	for c in cs:
		o.append({"text": option_text(g, tag, c), "effects": effects(g, tag, c), "ai": 25})
	o.append({"text": "Allein bleiben. Freie Hand ist auch eine Stärke.", "effects": cfg(g).get("alone", {"dip": 40}), "ai": 10})
	g.event_by_id[EVENT_ID] = {"id": EVENT_ID, "kind": "alliance", "manual": true, "tag": "*",
			"title": str(cfg(g).get("title", "Ein Bündnis")), "text": str(cfg(g).get("text", "%s")) % g.nations[tag].name,
			"image": "treaty", "trigger": {}, "options": o}
	return true


## New game: the player's choice is the first event of the game.
static func start(g) -> void:
	if g.player == "" or not g.nations.has(g.player) or cfg(g).is_empty():
		return
	if register_event(g, g.player) and not g.pending_events.has(EVENT_ID):
		g.pending_events.append(EVENT_ID)


## After loading: an unanswered choice needs its event again.
static func after_load(g) -> void:
	if not g.pending_events.has(EVENT_ID):
		return
	if g.player == "" or not g.nations.has(g.player) or not register_event(g, g.player):
		g.pending_events.erase(EVENT_ID)
