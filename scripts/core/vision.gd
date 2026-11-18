extends RefCounted
## Fog of war (EU-style, kept simple). Static helpers on the game `g`.
##
## A realm sees its own land, the land of its overlord, subjects and allies, every province one of
## these realms occupies or has an army in, and the coasts of the seas where one of their fleets
## sails in strength. Around all of that it sees one province further (scouts, merchants, rumours).
## Everything else lies in the fog: borders and owners stay known (old maps), but foreign armies,
## battles and transports there are hidden.
##
## Only the player's view uses it (map, tooltips, province panel); the AI keeps its full knowledge, as
## in the paradox games. It is derived from the game state, so nothing is saved.

const Naval = preload("res://scripts/core/naval.gd")

const HIDDEN := 0
const EDGE := 1  ## seen from next door: one province beyond our own sight
const SEEN := 2  ## own land, allies, our armies and fleets


## Realms whose sight `tag` shares: itself, its overlord and fellow subjects, its own subjects, its allies.
static func sharers(g, tag: String) -> Array:
	var r := [tag]
	if not g.nations.has(tag):
		return r
	for t in g._subject_bloc(tag):
		if not r.has(t):
			r.append(t)
	for t in g.nations[tag].allies:
		if not r.has(t) and g.nations.has(t) and g.nations[t].alive:
			r.append(t)
	return r


## Sight of `tag` per province id: HIDDEN, EDGE or SEEN. Without a realm (observer) everything is SEEN.
## Cost: one pass over provinces, armies and the sharers' fleets (well under a millisecond).
static func compute(g, tag: String) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(g.provinces.size())
	if tag == "" or not g.nations.has(tag):
		seen.fill(SEEN)
		return seen
	var share := {}
	for t in sharers(g, tag):
		share[t] = true
	var core := []
	for p in g.provinces:
		if share.has(p.owner) or share.has(p.controller):
			core.append(p.id)
	for a in g.armies:
		if share.has(a.owner):
			core.append(a.pid)
			if a.path.size() >= 2 and a.path[0] == a.pid:
				core.append(a.path[1])  # marching: the next province is already in sight
	for v in g.voyages:
		if share.has(v.army.owner):
			core.append(int(v.to))
	var min_ships := float(g.bal.get("fog_fleet_ships", 5))
	for t in share:
		var pres: Dictionary = Naval.presence(g, t)
		for sea in pres:
			if float(pres[sea]) >= min_ships and g.sea_by_id.has(sea):
				core.append_array(g.sea_by_id[sea].provinces)
	for pid in core:
		seen[pid] = SEEN
	var ring := int(g.bal.get("fog_sight", 1))
	var front := core
	for _i in ring:
		var nxt := []
		for pid in front:
			for nb in g.provinces[pid].adj:
				if seen[nb] == HIDDEN:
					seen[nb] = EDGE
					nxt.append(nb)
		front = nxt
	return seen


## The sight the player had last time it was computed this month (cached on the game; nothing saved).
static func player_sight(g) -> PackedByteArray:
	var allies: int = g.nations[g.player].allies.size() if g.nations.has(g.player) else 0
	var key := "%s:%d:%d:%d:%d:%d" % [g.player, g.month, g.armies.size(), g.voyages.size(), allies, _army_hash(g)]
	if g.vision_key != key:
		g.vision_key = key
		g.vision = compute(g, g.player)
	return g.vision


## Changes when one of our armies moved (the player can move them while the game is paused).
static func _army_hash(g) -> int:
	var h := 0
	for a in g.armies:
		if a.owner == g.player:
			h = h * 31 + a.pid + (a.path[1] * 7 if a.path.size() >= 2 else 0)
	return h


## Does the player see this province right now? (Always true without fog or without a player.)
static func sees(g, pid: int) -> bool:
	if g.player == "" or not g.fog_of_war:
		return true
	var s: PackedByteArray = player_sight(g)
	return pid < 0 or pid >= s.size() or s[pid] != HIDDEN


## Is this army visible to the player? Own and allied armies always are, others only outside the fog.
static func sees_army(g, a) -> bool:
	if g.player == "" or not g.fog_of_war or a.owner == g.player:
		return true
	return sees(g, a.pid)
