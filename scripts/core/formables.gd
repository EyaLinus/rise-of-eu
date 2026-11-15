extends RefCounted
## Formable realms (data/formables.json): a nation from the `from` list that holds `need` of the listed
## provinces may proclaim the new realm. It keeps its tag (wars, saves and flags stay valid) but takes the
## new name and map colour, gains prestige, claims on the missing provinces and a lasting bonus in
## n.bonus["formed"]. One formation per nation. Static helpers on the game `g` (g.formable_defs).


static func setup(g, data: Dictionary) -> void:
	g.formable_defs = data.get("formables", {})


## Formables this nation could ever proclaim (shown in the UI), in data order.
static func options(g, tag: String) -> Array:
	var r := []
	if g.nations[tag].formed != "":
		return r
	for id in g.formable_defs:
		if tag in g.formable_defs[id].from and not _taken(g, id):
			r.append(id)
	return r


## True when another nation already proclaimed this realm.
static func _taken(g, id: String) -> bool:
	for t in g.order:
		if g.nations[t].alive and g.nations[t].formed == id:
			return true
	return false


## [held, need] of the core provinces (held = owned and controlled).
static func progress(g, tag: String, id: String) -> Array:
	var f: Dictionary = g.formable_defs[id]
	var held := 0
	for key in f.provinces:
		var pid: int = g.key_to_pid.get(key, -1)
		if pid >= 0 and g.provinces[pid].owner == tag and g.provinces[pid].controller == tag:
			held += 1
	return [held, int(f.need)]


static func missing(g, tag: String, id: String) -> Array:
	var r := []
	for key in g.formable_defs[id].provinces:
		var pid: int = g.key_to_pid.get(key, -1)
		if pid >= 0 and g.provinces[pid].owner != tag:
			r.append(pid)
	return r


static func cost(g) -> float:
	return float(g.bal.form_cost_adm)


static func block_reason(g, tag: String, id: String) -> String:
	if not g.formable_defs.has(id):
		return "Unbekanntes Reich."
	var n = g.nations[tag]
	if n.formed != "":
		return "Du hast schon ein Reich gegründet."
	if not tag in g.formable_defs[id].from:
		return "Nur für: %s." % ", ".join(g.formable_defs[id].from.map(func(t): return g.nations[t].name if g.nations.has(t) else t))
	if _taken(g, id):
		return "Dieses Reich gibt es schon."
	if n.overlord != "":
		return "Ein Vasall kann kein Reich ausrufen."
	if g.is_at_war(tag):
		return "Nicht im Krieg."
	var pr := progress(g, tag, id)
	if pr[0] < pr[1]:
		return "Du hältst erst %d von %d Kernprovinzen." % [pr[0], pr[1]]
	if n.adm < cost(g):
		return "Zu wenig 📜 Verwaltung (%d)." % int(cost(g))
	return ""


static func form(g, tag: String, id: String) -> String:
	var r := block_reason(g, tag, id)
	if r != "":
		return r
	var n = g.nations[tag]
	var f: Dictionary = g.formable_defs[id]
	var old: String = n.name
	n.adm -= cost(g)
	n.formed = id
	apply_identity(g, n)
	n.prestige += float(g.bal.form_prestige)
	for pid in missing(g, tag, id):
		n.claims[pid] = true
	g.stats["formed"] = g.stats.get("formed", 0) + 1
	g.world_event("👑 Neues Reich ausgerufen: %s (bisher %s)!" % [f.name, old])
	g.fire_event(tag, "form_" + id.to_lower())
	return ""


## Name, colour and bonus of a formed realm (also after loading a save).
static func apply_identity(g, n) -> void:
	if n.formed == "" or not g.formable_defs.has(n.formed):
		n.bonus.erase("formed")
		return
	var f: Dictionary = g.formable_defs[n.formed]
	n.name = f.name
	n.color = Color(f.color)
	var b := {}
	for k in f.get("bonus", {}):
		b[k] = float(f.bonus[k])
	n.bonus["formed"] = b


## Yearly: the AI proclaims a realm as soon as it can (the player decides in the realm panel).
static func ai_yearly(g) -> void:
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or tag == g.player or n.formed != "":
			continue
		for id in options(g, tag):
			if block_reason(g, tag, id) == "":
				form(g, tag, id)
				break
