extends RefCounted
## Native realms (Inca, Aztecs, Mali ...) cannot send settlers like the Old World does. Instead they bring
## the free tribes next door into their realm: diplomacy power (more for bigger, stronger tribes) and some
## gold turn a neighbouring province of uncolonized native land (owner NAT) into an uncored province.
## The AI does it only for the playable native realms, at peace and up to a size cap (balance ai_tribe_max_provinces), so the Inca can grow into an Andean empire without
## every small tribe in the Americas swallowing the land the colonizers need.

const NATIVE := "NAT"


static func is_native_realm(g, tag: String) -> bool:
	return tag != NATIVE and g.nation_data_native.has(tag)


static func dip_cost(g, pid: int) -> float:
	var p = g.provinces[pid]
	return float(g.bal.tribe_dip_base) + float(g.bal.tribe_dip_per_dev) * float(p.dev) + float(g.bal.tribe_dip_per_native) * p.natives


static func gold_cost(g, pid: int) -> float:
	return float(g.bal.tribe_gold_per_dev) * float(g.provinces[pid].dev)


static func borders(g, tag: String, pid: int) -> bool:
	for a in g.provinces[pid].adj:
		if g.provinces[a].owner == tag:
			return true
	return false


static func block_reason(g, tag: String, pid: int) -> String:
	if not is_native_realm(g, tag):
		return "Nur Reiche der Ureinwohner gliedern Stämme ein (andere gründen Kolonien)."
	var p = g.provinces[pid]
	if p.owner != NATIVE:
		return "Dieses Land gehört schon einem Reich."
	if p.colonist != "":
		return "Hier siedeln schon Fremde (%s)." % g.nations[p.colonist].name
	if not borders(g, tag, pid):
		return "Nur Stämme an unserer Grenze."
	var n = g.nations[tag]
	if n.dip < dip_cost(g, pid):
		return "Zu wenig Diplomatie (%d)." % int(ceil(dip_cost(g, pid)))
	if n.gold < gold_cost(g, pid):
		return "Zu wenig Gold (%d)." % int(ceil(gold_cost(g, pid)))
	return ""


## Integrates the tribe: "" on success, else the reason.
static func integrate(g, tag: String, pid: int) -> String:
	var why := block_reason(g, tag, pid)
	if why != "":
		return why
	var n = g.nations[tag]
	var p = g.provinces[pid]
	n.dip -= dip_cost(g, pid)
	n.gold -= gold_cost(g, pid)
	p.owner = tag
	p.controller = tag
	p.prev_owner = ""
	p.core_months = 0
	p.natives = 0.0
	g.owned[NATIVE].erase(pid)
	g.owned[tag].append(pid)
	g.Economy.refresh_local(g, p)
	g.stats.tribes = int(g.stats.get("tribes", 0)) + 1
	g.log_msg("🪶 %s: Die Stämme von %s schließen sich dem Reich an." % [n.name, p.name], [tag])
	return ""


## Yearly: AI playable native realms take in one bordering tribe when they can spare the power.
static func ai_yearly(g) -> void:
	if not g.owned.has(NATIVE) or g.owned[NATIVE].is_empty():
		return
	for tag in g.nation_data_native:
		if tag == g.player or not g.nations.has(tag):
			continue
		var n = g.nations[tag]
		if not n.alive or not n.playable or n.overlord != "" or g.provinces_of(tag).size() >= int(g.bal.ai_tribe_max_provinces):
			continue
		if g.is_at_war(tag) or g.rng.randf() > float(g.bal.ai_tribe_chance):
			continue
		var best := -1
		var best_cost := INF
		for pid in g.provinces_of(tag):
			for a in g.provinces[pid].adj:
				var q = g.provinces[a]
				if q.owner == NATIVE and q.colonist == "":
					var c := dip_cost(g, a)
					if c < best_cost:
						best = a
						best_cost = c
		if best >= 0 and n.dip >= best_cost + float(g.bal.ai_tribe_reserve):
			integrate(g, tag, best)
