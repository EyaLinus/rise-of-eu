extends RefCounted
## Formable realms (data/formables.json): a nation that meets a realm's requirements may proclaim it. It keeps its
## tag (wars, saves and flags stay valid) but takes the new name and map colour, gains prestige, stability, claims on
## the missing provinces, a lasting bonus in n.bonus["formed"] and possibly a higher rank. Static helpers on the game
## `g` (g.formable_defs).
##
## Requirements per realm (all optional except the provinces):
##   from        tags that may proclaim it, ["*"] = any realm
##   provinces + need   simple form: hold `need` of these provinces
##   groups      [{name, provinces, need}]: every group must be met (regions, EU5-style); replaces provinces/need
##   tier        1 = regional realm (one per nation), 2 = great empire (may follow a tier 1 realm)
##   rank_min    minimum realm rank (Progression.RANKS index), rank_to = rank granted on formation
##   year_min    earliest year, capital_in = the capital must be one of these provinces, no_native = not for natives
##   cost_adm / prestige   override the balance defaults
## A realm can be proclaimed once per game; formed realms stack their bonuses (n.flags["formed_hist"]).

const Progression = preload("res://scripts/core/progression.gd")
const Stability = preload("res://scripts/core/stability.gd")
const RENAMED := {"MAG": "MGB"}  # old saves: the Maghreb used the tag of Maguindanao


static func setup(g, data: Dictionary) -> void:
	g.formable_defs = data.get("formables", {})


static func tier(g, id: String) -> int:
	return int(g.formable_defs[id].get("tier", 1)) if g.formable_defs.has(id) else 0


static func _allowed(g, tag: String, id: String) -> bool:
	var fr: Array = g.formable_defs[id].from
	return "*" in fr or tag in fr


## Formables this nation could ever proclaim (shown in the UI), in data order.
static func options(g, tag: String, taken: Dictionary = {}) -> Array:
	var r := []
	var n = g.nations[tag]
	if taken.is_empty():
		taken = taken_ids(g)
	var cur := tier(g, n.formed)
	for id in g.formable_defs:
		if tier(g, id) <= cur or taken.has(id) or not _allowed(g, tag, id):
			continue
		if g.formable_defs[id].get("no_native", false) and g.nation_data_native.has(tag):
			continue
		if "*" in g.formable_defs[id].from and not _within_reach(g, tag, id):
			continue
		r.append(id)
	return r


## Realms open to everyone ("*") only show up for nations that are on their way: capital in place or a third
## of the provinces held. Keeps Europe and the USA out of every small realm's list.
static func _within_reach(g, tag: String, id: String) -> bool:
	var f: Dictionary = g.formable_defs[id]
	var n = g.nations[tag]
	if f.has("capital_in"):
		return n.capital >= 0 and g.provinces[n.capital].key in f.capital_in
	var pr := progress(g, tag, id)
	return pr[0] * 3 >= pr[1]


## Realms that someone (alive) already proclaimed, also earlier steps of a nation's history.
static func taken_ids(g) -> Dictionary:
	var r := {}
	for t in g.order:
		var n = g.nations[t]
		if n.alive and n.formed != "":
			r[n.formed] = t
			for h in n.flags.get("formed_hist", []):
				r[str(h)] = t
	return r


static func _taken(g, id: String) -> bool:
	return taken_ids(g).has(id)


## Province groups of a realm: [{name, provinces, need}].
static func groups(g, id: String) -> Array:
	var f: Dictionary = g.formable_defs[id]
	if f.has("groups"):
		return f.groups
	return [{"name": "Kernprovinzen", "provinces": f.provinces, "need": f.need}]


static func _held(g, tag: String, keys: Array) -> int:
	var held := 0
	for key in keys:
		var pid: int = g.key_to_pid.get(key, -1)
		if pid >= 0 and g.provinces[pid].owner == tag and g.provinces[pid].controller == tag:
			held += 1
	return held


## [held, need] summed over all groups (held counts at most `need` per group, so it reads as overall progress).
static func progress(g, tag: String, id: String) -> Array:
	var held := 0
	var need := 0
	for gr in groups(g, id):
		held += mini(_held(g, tag, gr.provinces), int(gr.need))
		need += int(gr.need)
	return [held, need]


static func all_provinces(g, id: String) -> Array:
	var r := []
	for gr in groups(g, id):
		r.append_array(gr.provinces)
	return r


static func missing(g, tag: String, id: String) -> Array:
	var r := []
	for key in all_provinces(g, id):
		var pid: int = g.key_to_pid.get(key, -1)
		if pid >= 0 and g.provinces[pid].owner != tag:
			r.append(pid)
	return r


static func cost(g, id: String = "") -> float:
	if id != "" and g.formable_defs.has(id) and g.formable_defs[id].has("cost_adm"):
		return float(g.formable_defs[id].cost_adm)
	return float(g.bal.form_cost_adm)


static func prestige_gain(g, id: String) -> float:
	return float(g.formable_defs[id].get("prestige", g.bal.form_prestige))


## Every condition with its state, for the checklist in the realm panel: [[ok, text], ...].
static func requirements(g, tag: String, id: String) -> Array:
	var f: Dictionary = g.formable_defs[id]
	var n = g.nations[tag]
	var r := []
	if f.has("year_min"):
		r.append([g.year() >= int(f.year_min), "ab dem Jahr %d" % int(f.year_min)])
	if f.has("rank_min"):
		r.append([int(n.rank) >= int(f.rank_min), "Rang %s" % Progression.RANKS[int(f.rank_min)].name])
	if f.has("capital_in"):
		var cap_key: String = g.provinces[n.capital].key if n.capital >= 0 else ""
		r.append([cap_key in f.capital_in, "Hauptstadt in %s" % f.get("capital_name", "der Region")])
	for gr in groups(g, id):
		var h := _held(g, tag, gr.provinces)
		r.append([h >= int(gr.need), "%s: %d von %d nötig (%d in der Region)" % [gr.name, h, int(gr.need), gr.provinces.size()]])
	r.append([n.overlord == "", "kein Vasall"])
	r.append([not g.is_at_war(tag), "im Frieden"])
	r.append([n.adm >= cost(g, id), "%d 📜 Verwaltung" % int(cost(g, id))])
	return r


static func block_reason(g, tag: String, id: String) -> String:
	if not g.formable_defs.has(id):
		return "Unbekanntes Reich."
	var n = g.nations[tag]
	var f: Dictionary = g.formable_defs[id]
	if n.formed != "" and tier(g, id) <= tier(g, n.formed):
		return "Du hast schon ein Reich gegründet."
	if not _allowed(g, tag, id):
		return "Nur für: %s." % ", ".join(f.from.map(func(t): return g.nations[t].name if g.nations.has(t) else t))
	if f.get("no_native", false) and g.nation_data_native.has(tag):
		return "Nicht für Stammesreiche."
	if _taken(g, id):
		return "Dieses Reich gibt es schon."
	if n.overlord != "":
		return "Ein Vasall kann kein Reich ausrufen."
	if g.is_at_war(tag):
		return "Nicht im Krieg."
	if f.has("year_min") and g.year() < int(f.year_min):
		return "Erst ab %d." % int(f.year_min)
	if f.has("rank_min") and int(n.rank) < int(f.rank_min):
		return "Erst ab Rang %s." % Progression.RANKS[int(f.rank_min)].name
	if f.has("capital_in") and (n.capital < 0 or not g.provinces[n.capital].key in f.capital_in):
		return "Hauptstadt muss in %s liegen." % f.get("capital_name", "der Region")
	for gr in groups(g, id):
		var h := _held(g, tag, gr.provinces)
		if h < int(gr.need):
			return "%s: %d/%d" % [gr.name, h, int(gr.need)]
	if n.adm < cost(g, id):
		return "Zu wenig 📜 Verwaltung (%d)." % int(cost(g, id))
	return ""


static func form(g, tag: String, id: String) -> String:
	var r := block_reason(g, tag, id)
	if r != "":
		return r
	var n = g.nations[tag]
	var f: Dictionary = g.formable_defs[id]
	var old: String = n.name
	n.adm -= cost(g, id)
	if n.formed != "":
		var hist: Array = n.flags.get("formed_hist", [])
		hist.append(n.formed)
		n.flags["formed_hist"] = hist
	n.formed = id
	apply_identity(g, n)
	n.prestige += prestige_gain(g, id)
	Stability.add(g, tag, float(g.bal.get("form_stability", 0.0)), "Reichsgründung")
	if int(f.get("rank_to", -1)) > int(n.rank):
		n.rank = int(f.rank_to)
		n.set_bonus("rank", Progression.RANKS[n.rank].bonus)
		Progression._set_base(g, n)
	for pid in missing(g, tag, id):
		n.claims[pid] = true
	g.stats["formed"] = g.stats.get("formed", 0) + 1
	g.world_event("👑 Neues Reich ausgerufen: %s (bisher %s)!" % [f.name, old])
	g.fire_event(tag, "form_" + id.to_lower())
	return ""


## Name, colour and bonus of a formed realm (also after loading a save). Bonuses of earlier realms stay.
static func apply_identity(g, n) -> void:
	n.formed = RENAMED.get(n.formed, n.formed)
	if n.formed == "" or not g.formable_defs.has(n.formed):
		n.clear_bonus("formed")
		return
	var f: Dictionary = g.formable_defs[n.formed]
	n.name = f.name
	n.color = Color(f.color)
	var b := {}
	for id in n.flags.get("formed_hist", []) + [n.formed]:
		var fid: String = RENAMED.get(str(id), str(id))
		if not g.formable_defs.has(fid):
			continue
		for k in g.formable_defs[fid].get("bonus", {}):
			b[k] = b.get(k, 0.0) + float(g.formable_defs[fid].bonus[k])
	n.set_bonus("formed", b)


## Yearly: the AI proclaims a realm as soon as it can (the player decides in the realm panel).
static func ai_yearly(g) -> void:
	var taken := taken_ids(g)
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or tag == g.player or n.overlord != "":
			continue
		for id in options(g, tag, taken):
			if block_reason(g, tag, id) == "":
				form(g, tag, id)
				taken[id] = tag
				break
