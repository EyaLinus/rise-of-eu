extends RefCounted
## The New World: exploration and colonization (EU4/EU5-style, kept simple). Static helpers on the game `g`.
##
## The Americas start as terra incognita for the Old World. A realm with an Atlantic coast and enough
## diplomatic technology sends expeditions from a sea it knows to a neighbouring unknown sea; a
## successful voyage reveals that sea and every coast on it. Known native land (owner NATIVE, a nation
## that is never alive) can be settled: a colony costs gold up front and a little every month, grows
## for some years (slower against strong natives, who now and then raid it) and then becomes a normal,
## cored province of the colonizer. Land next to colonies is revealed as settlers push inland, and every
## discovery becomes common knowledge after a few decades. The native realms (Aztecs, Maya, Iroquois ...)
## are ordinary nations that can be conquered once a colony borders them.

const NATIVE := "NAT"  # owner of uncolonized native land
## Seas beyond the Old World: unknown until explored. Old World realms know every other sea (also the
## West African coast down to Sierra Leone, which Portuguese caravels reached by 1444).
const NEW_SEAS := ["guinea", "ocean", "labrador", "st_lawrence", "east_coast", "sargasso", "caribbean", "gulf", "pacific", "hudson", "lakes"]


static func setup(g, data: Dictionary) -> void:
	g.nw_first = g.provinces.size()
	g.wa_first = g.provinces.size()
	g.nw_end = g.provinces.size()
	for i in data.map.provinces.size():
		var pd: Dictionary = data.map.provinces[i]
		if pd.get("nw", false) and g.nw_first == g.provinces.size():
			g.nw_first = i
		if pd.get("wa", false) and g.wa_first == g.provinces.size():
			g.wa_first = i
		if g.nw_first < g.provinces.size() and not pd.get("nw", false) and i > g.nw_first:
			g.nw_end = i  # the Middle East and the Horn ("east") follow the overseas block: Old World again
			break
	g.found = {}
	if g.nations.has(NATIVE):
		var nat = g.nations[NATIVE]
		nat.alive = false
		nat.ships = 0.0
		g.provinces[nat.capital].fort = 0
		for a in g.armies.duplicate():
			if a.owner == NATIVE:
				g.armies.erase(a)
	for p in g.provinces:
		if p.owner == NATIVE:
			p.natives = float(p.dev) * float(g.bal.natives_per_dev) + float(g.rng.randi_range(0, 2))
	for tag in g.order:
		reset_knowledge(g, g.nations[tag])
	g.atlantic_tags = []
	for tag in g.order:
		var n = g.nations[tag]
		if n.alive and not is_native_realm(g, tag) and _old_atlantic_coast(g, tag):
			g.atlantic_tags.append(tag)


## Start knowledge: the Old World knows its own seas and the coasts on them (West Africa down to Sierra
## Leone), the native realms know their own continent and its seas.
static func reset_knowledge(g, n) -> void:
	n.known_seas = {}
	n.known_nw = {}
	n.expedition = {}
	if is_native_realm(g, n.tag):
		var home := region(g, g.nations[n.tag].capital)
		for s in g.seas:
			for pid in s.provinces:
				if region(g, pid) == home:
					n.known_seas[s.id] = true
					break
		for pid in range(g.nw_first, g.nw_end):
			if region(g, pid) == home:
				n.known_nw[pid] = true
		return
	for s in g.seas:
		if not NEW_SEAS.has(s.id):
			n.known_seas[s.id] = true
			for pid in s.provinces:
				if is_new_world(g, pid):
					n.known_nw[pid] = true
	# the Sahel and Mali are known from the gold caravans; the forest belt and the Guinea coast are not
	for pid in range(g.wa_first, g.nw_end):
		if g.provinces[pid].center.y < float(g.bal.wa_known_y):
			n.known_nw[pid] = true
	# caravan routes: the land next to our own (Morocco knows the way to Taghaza)
	for pid in g.provinces_of(n.tag):
		for a in g.provinces[pid].adj:
			if is_new_world(g, a):
				n.known_nw[a] = true


## "old" (Europe, North Africa, the Near East), "america" or "africa" (West Africa).
static func region(g, pid: int) -> String:
	if not is_new_world(g, pid):
		return "old"
	return "africa" if pid >= g.wa_first else "america"


static func is_native_realm(g, tag: String) -> bool:
	return tag == NATIVE or g.nation_data_native.has(tag)


static func is_new_world(g, pid: int) -> bool:
	return pid >= g.nw_first and pid < g.nw_end


static func is_native_land(g, pid: int) -> bool:
	return g.provinces[pid].owner == NATIVE


## The player (or anyone) has seen this province: always true in the Old World.
static func knows(g, tag: String, pid: int) -> bool:
	if not is_new_world(g, pid) or tag == "":
		return true
	return g.nations[tag].known_nw.has(pid)


static func knows_sea(g, tag: String, sea: String) -> bool:
	return g.nations[tag].known_seas.has(sea)


static func _old_atlantic_coast(g, tag: String) -> bool:
	for s in g.seas:
		if s.id in ["atlantic", "channel", "irish", "north"]:
			for pid in s.provinces:
				if g.provinces[pid].owner == tag:
					return true
	return false


## Learn a province (and remember when the world first heard of it).
static func reveal(g, tag: String, pid: int) -> bool:
	var n = g.nations[tag]
	if not is_new_world(g, pid) or n.known_nw.has(pid):
		return false
	n.known_nw[pid] = true
	var k := str(pid)
	if not g.found.has(k):
		g.found[k] = g.month
	return true


static func reveal_sea(g, tag: String, sea: String) -> int:
	var n = g.nations[tag]
	n.known_seas[sea] = true
	var k := "s:" + sea
	if not g.found.has(k):
		g.found[k] = g.month
	var c := 0
	var s: Dictionary = g.sea_by_id.get(sea, {})
	for pid in s.get("provinces", []):
		if reveal(g, tag, pid):
			c += 1
	return c


# ---------------------------------------------------------------- exploration

static func can_explore_tech(g, n) -> bool:
	return int(n.tech.dip) >= int(g.bal.explore_dip_tech)


## Unknown New World seas next to a sea the realm knows (where its next expedition can sail).
static func explore_targets(g, tag: String) -> Array:
	var n = g.nations[tag]
	var r := []
	for s in g.seas:
		if not NEW_SEAS.has(s.id) or n.known_seas.has(s.id):
			continue
		for a in s.get("adj", []):
			if n.known_seas.has(a):
				r.append(s.id)
				break
	return r


static func explore_cost(g, n) -> float:
	return float(g.bal.explore_cost) * (1.0 + 0.25 * _explored_count(n))


static func _explored_count(n) -> int:
	var c := 0
	for s in NEW_SEAS:
		if n.known_seas.has(s):
			c += 1
	return c


static func explore_block_reason(g, tag: String, sea: String) -> String:
	var n = g.nations[tag]
	if is_native_realm(g, tag):
		return "Nur Reiche der Alten Welt schicken Entdecker aus."
	if not g.atlantic_tags.has(tag):
		return "Braucht eine Küste am Atlantik, Ärmelkanal oder an der Nordsee."
	if not can_explore_tech(g, n):
		return "Braucht Diplomatie-Technologie %d." % int(g.bal.explore_dip_tech)
	if not n.expedition.is_empty():
		return "Eine Expedition ist schon unterwegs."
	if n.known_seas.has(sea):
		return "Dieses Meer ist schon bekannt."
	if not explore_targets(g, tag).has(sea):
		return "Zu weit: erst ein Nachbarmeer erkunden."
	if n.gold < explore_cost(g, n):
		return "Zu wenig Gold (%d)." % int(explore_cost(g, n))
	if n.dip < float(g.bal.explore_dip):
		return "Zu wenig Diplomatie (%d)." % int(g.bal.explore_dip)
	return ""


static func explore(g, tag: String, sea: String) -> String:
	var why := explore_block_reason(g, tag, sea)
	if why != "":
		return why
	var n = g.nations[tag]
	n.gold -= explore_cost(g, n)
	n.dip -= float(g.bal.explore_dip)
	n.expedition = {"sea": sea, "months": int(g.bal.explore_months)}
	if tag == g.player:
		g.log_msg("⛵ Eine Expedition sticht in See: Ziel %s." % g.Naval.sea_name(g, sea), [tag])
	return ""


static func _expedition_tick(g, n) -> void:
	n.expedition.months = int(n.expedition.months) - 1
	if int(n.expedition.months) > 0:
		return
	var sea: String = n.expedition.sea
	n.expedition = {}
	var chance: float = float(g.bal.explore_success) + 0.03 * maxf(0.0, n.tech.dip - float(g.bal.explore_dip_tech))
	if g.rng.randf() > chance:
		g.log_msg("💀 Eine Expedition von %s ist auf dem Weg nach %s verschollen." % [n.name, g.Naval.sea_name(g, sea)], [n.tag])
		return
	var first: bool = not g.found.has("s:" + sea)
	var c := reveal_sea(g, n.tag, sea)
	if first:
		n.prestige += float(g.bal.explore_prestige)
		g.stats.discoveries = int(g.stats.get("discoveries", 0)) + 1
		g.log_msg("🧭 %s entdeckt %s und %d neue Küstenländer!" % [n.name, g.Naval.sea_name(g, sea), c])
	elif n.tag == g.player:
		g.log_msg("🧭 Unsere Expedition kartiert %s (%d Küstenländer)." % [g.Naval.sea_name(g, sea), c], [n.tag])


# ---------------------------------------------------------------- colonies

## Settlers: 1, +1 per dip_tech_per_colonist diplomatic techs, +1 per colonies_per_colonist finished
## colonies (at most +2), +1 per recruited settler band (recruit_colonist), plus "colonists" modifiers.
static func colonists(g, n) -> int:
	return 1 + int(n.tech.dip / int(g.bal.dip_tech_per_colonist)) + colony_settlers(g, n) + int(g.mod(n, "colonists"))


static func colony_settlers(g, n) -> int:
	return mini(2, colonies_owned(g, n.tag) / int(g.bal.colonies_per_colonist))


static func recruited(n) -> int:
	return int(n.flags.get("colonists_bought", 0))


static func recruit_cost(g, n) -> float:
	return float(g.bal.recruit_colonist_dip) * (1.0 + recruited(n))


static func recruit_block_reason(g, tag: String) -> String:
	var n = g.nations[tag]
	if is_native_realm(g, tag):
		return "Nur Reiche der Alten Welt gründen Kolonien."
	if not can_explore_tech(g, n):
		return "Braucht Diplomatie-Technologie %d." % int(g.bal.explore_dip_tech)
	if recruited(n) >= int(g.bal.recruit_colonist_max):
		return "Mehr Siedler finden sich nicht (höchstens %d angeworben)." % int(g.bal.recruit_colonist_max)
	if n.dip < recruit_cost(g, n):
		return "Zu wenig Diplomatie (%d)." % int(recruit_cost(g, n))
	return ""


## Spends diplomatic power for one more settler band, for good (stored in n.mods["colonists"]).
static func recruit_colonist(g, tag: String) -> String:
	var why := recruit_block_reason(g, tag)
	if why != "":
		return why
	var n = g.nations[tag]
	n.dip -= recruit_cost(g, n)
	n.flags["colonists_bought"] = recruited(n) + 1
	n.mods["colonists"] = float(n.mods.get("colonists", 0.0)) + 1.0
	if tag == g.player:
		g.log_msg("🏕 Neue Siedler melden sich für die Kolonien: jetzt %d Siedler." % colonists(g, n), [tag])
	return ""


static func running_colonies(g, tag: String) -> Array:
	var r := []
	for pid in range(g.nw_first, g.nw_end):
		if g.provinces[pid].colonist == tag:
			r.append(pid)
	return r


static func colony_cost(g, tag: String, pid: int) -> float:
	var n = g.nations[tag]
	var more: float = 1.0 + float(g.bal.colony_cost_per_colony) * colonies_owned(g, tag)  # far-flung empires cost more
	return round(float(g.bal.colony_cost) * (1.0 + 0.1 * g.provinces[pid].dev) * more * maxf(0.5, 1.0 + g.mod(n, "colony_cost")))


## Months a colony needs; strong natives slow it down.
static func colony_months(g, p) -> int:
	return int(round(float(g.bal.colony_months) * (1.0 + p.natives * float(g.bal.natives_slow))))


## A province the realm can reach with settlers: next to its land, or a known coast on a sea it knows
## (by ship, so the realm needs a coast of its own).
static func reachable(g, tag: String, pid: int) -> bool:
	var p = g.provinces[pid]
	for a in p.adj:
		if g.provinces[a].owner == tag:
			return true
	if not p.coastal or not has_coast(g, tag):
		return false
	for s in g.province_seas.get(pid, []):
		if knows_sea(g, tag, s):
			return true
	return false


static func has_coast(g, tag: String) -> bool:
	for pid in g.provinces_of(tag):
		if g.province_seas.has(pid):
			return true
	return false


static func colony_block_reason(g, tag: String, pid: int) -> String:
	var n = g.nations[tag]
	var p = g.provinces[pid]
	if p.owner != NATIVE:
		return "Dieses Land gehört schon einem Reich."
	if is_native_realm(g, tag):
		return "Nur Reiche der Alten Welt gründen Kolonien."
	if not knows(g, tag, pid):
		return "Unbekanntes Land: erst erkunden."
	if p.colonist != "":
		return "Hier entsteht schon eine Kolonie (%s)." % g.nations[p.colonist].name
	if not can_explore_tech(g, n):
		return "Braucht Diplomatie-Technologie %d." % int(g.bal.explore_dip_tech)
	if not reachable(g, tag, pid):
		return "Nicht erreichbar: braucht eine bekannte Küste oder eigenes Land daneben."
	if running_colonies(g, tag).size() >= colonists(g, n):
		return "Alle Siedler sind beschäftigt (%d)." % colonists(g, n)
	if n.gold < colony_cost(g, tag, pid):
		return "Zu wenig Gold (%d)." % int(colony_cost(g, tag, pid))
	return ""


static func start_colony(g, tag: String, pid: int) -> String:
	var why := colony_block_reason(g, tag, pid)
	if why != "":
		return why
	var n = g.nations[tag]
	var p = g.provinces[pid]
	n.gold -= colony_cost(g, tag, pid)
	p.colonist = tag
	p.colony_months = 0
	for a in p.adj:
		reveal(g, tag, a)
	if tag == g.player:
		g.log_msg("🏕 Siedler gründen eine Kolonie in %s." % p.name, [tag])
	return ""


static func abandon_colony(g, tag: String, pid: int) -> void:
	var p = g.provinces[pid]
	if p.colonist == tag:
		p.colonist = ""
		p.colony_months = 0


## Progress 0..1 of the colony in `pid`.
static func progress(g, pid: int) -> float:
	var p = g.provinces[pid]
	if p.colonist == "":
		return 0.0
	return clampf(float(p.colony_months) / maxf(1.0, float(colony_months(g, p))), 0.0, 1.0)


## Treaty with the natives: halves their strength in a province being settled (diplomacy power).
static func treaty_block_reason(g, tag: String, pid: int) -> String:
	var p = g.provinces[pid]
	if p.colonist != tag:
		return "Nur wo wir siedeln."
	if p.natives < 1.0:
		return "Die Ureinwohner hier sind schon befriedet."
	if g.nations[tag].dip < float(g.bal.treaty_dip):
		return "Zu wenig Diplomatie (%d)." % int(g.bal.treaty_dip)
	return ""


static func native_treaty(g, tag: String, pid: int) -> String:
	var why := treaty_block_reason(g, tag, pid)
	if why != "":
		return why
	var p = g.provinces[pid]
	g.nations[tag].dip -= float(g.bal.treaty_dip)
	var before := colony_months(g, p)
	p.natives = floorf(p.natives * 0.5)
	# keep the share already built: a treaty does not undo progress
	p.colony_months = int(round(float(p.colony_months) * colony_months(g, p) / maxf(1.0, before)))
	if tag == g.player:
		g.log_msg("🪶 Ein Abkommen mit den Ureinwohnern von %s: weniger Überfälle, schnellere Siedlung." % p.name, [tag])
	return ""


static func _colony_tick(g, p) -> void:
	var n = g.nations[p.colonist]
	if not n.alive:
		p.colonist = ""
		return
	n.gold -= float(g.bal.colony_upkeep)
	p.colony_months += 1
	# native raids
	if p.natives > 0.0 and g.rng.randf() < p.natives * float(g.bal.native_raid_chance):
		var young: bool = p.colony_months < int(g.bal.native_raid_months) * 2
		p.colony_months = maxi(0, p.colony_months - int(g.bal.native_raid_months))
		# a young settlement may be wiped out; an established one only loses time
		if young and g.rng.randf() < float(g.bal.native_raid_destroy):
			if n.tag == g.player:
				g.log_msg("🔥 Ureinwohner zerstören unsere Kolonie in %s." % p.name, [n.tag])
			p.colonist = ""
			p.colony_months = 0
			return
		if n.tag == g.player:
			g.log_msg("⚔️ Ureinwohner überfallen unsere Kolonie in %s." % p.name, [n.tag])
	if p.colony_months >= colony_months(g, p):
		_finish(g, p)


static func _finish(g, p) -> void:
	var tag: String = p.colonist
	var n = g.nations[tag]
	p.colonist = ""
	p.colony_months = 0
	p.owner = tag
	p.controller = tag
	p.prev_owner = ""
	p.core_months = 0
	p.dev = maxi(p.dev, int(g.bal.colony_dev))
	p.natives = 0.0
	p.religion = n.religion
	g.owned[NATIVE].erase(p.id)
	g.owned[tag].append(p.id)
	g.Economy.refresh_local(g, p)
	for a in p.adj:
		reveal(g, tag, a)
	g.stats.colonies = int(g.stats.get("colonies", 0)) + 1
	g.log_msg("🏕 %s: Die Kolonie %s ist gewachsen und gehört nun fest zum Reich." % [n.name, p.name], [tag])


static func colonies_owned(g, tag: String) -> int:
	var c := 0
	for pid in g.provinces_of(tag):
		if is_new_world(g, pid):
			c += 1
	return c


# ---------------------------------------------------------------- ticks

static func monthly(g) -> void:
	if g.nw_first >= g.nw_end:
		return
	for pid in range(g.nw_first, g.nw_end):
		var p = g.provinces[pid]
		if p.colonist != "":
			_colony_tick(g, p)
	for tag in g.atlantic_tags:
		var n = g.nations[tag]
		if not n.alive:
			continue
		if not n.expedition.is_empty():
			_expedition_tick(g, n)
		if tag != g.player and (g.month + tag.hash()) % 4 == 0:
			_ai(g, n)


## Yearly: settlers push inland, and old discoveries become common knowledge.
static func yearly(g) -> void:
	if g.nw_first >= g.nw_end:
		return
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or is_native_realm(g, tag):
			continue
		for pid in g.provinces_of(tag):
			if is_new_world(g, pid):
				for a in g.provinces[pid].adj:
					reveal(g, tag, a)
	var spread: int = int(g.bal.map_spread_years) * 12
	var common_seas := []
	var common_pids := []
	for k in g.found:
		if g.month - int(g.found[k]) < spread:
			continue
		if k.begins_with("s:"):
			common_seas.append(k.substr(2))
			common_pids.append_array(g.sea_by_id.get(k.substr(2), {}).get("provinces", []))
		else:
			common_pids.append(int(k))
	if common_seas.is_empty() and common_pids.is_empty():
		return
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or is_native_realm(g, tag):
			continue
		for s in common_seas:
			n.known_seas[s] = true
		for pid in common_pids:
			n.known_nw[pid] = true


# ---------------------------------------------------------------- AI

static func _ai(g, n) -> void:
	if not can_explore_tech(g, n):
		return
	var drive: float = float(g.colonial_drive.get(n.tag, g.bal.ai_colonial_drive))
	if drive <= 0.0 or g.is_at_war(n.tag) and n.gold < 100.0:
		return
	var reserve: float = float(g.bal.ai_colony_reserve) / drive
	if n.expedition.is_empty() and g.rng.randf() < 0.25 * drive:
		var targets := explore_targets(g, n.tag)
		if not targets.is_empty() and n.gold > explore_cost(g, n) + reserve * 0.5:
			explore(g, n.tag, targets[g.rng.randi_range(0, targets.size() - 1)])
	if running_colonies(g, n.tag).size() >= colonists(g, n) and drive >= 1.0 and n.dip > recruit_cost(g, n) + 150.0:
		recruit_colonist(g, n.tag)
	if running_colonies(g, n.tag).size() >= colonists(g, n) or g.rng.randf() > 0.5 * drive:
		for pid in running_colonies(g, n.tag):
			if g.provinces[pid].natives >= 3.0 and n.dip > float(g.bal.treaty_dip) + 60.0:
				native_treaty(g, n.tag, pid)
		return
	var best := -1
	var best_v := -1e9
	for pid in n.known_nw:
		var p = g.provinces[pid]
		if p.owner != NATIVE or p.colonist != "" or not reachable(g, n.tag, pid):
			continue
		var v: float = p.dev * 2.0 - p.natives * 0.6 + float(g.goods_def[p.good].price) * 10.0 + g.rng.randf() * 2.0
		for a in p.adj:
			if g.provinces[a].owner == n.tag:
				v += 3.0
		if v > best_v:
			best_v = v
			best = pid
	# only with a monthly surplus that carries the colony's upkeep (else colonies drive realms into debt)
	if best >= 0 and n.gold > colony_cost(g, n.tag, best) + reserve and n.income - n.expenses > float(g.bal.colony_upkeep) * 2.0:
		start_colony(g, n.tag, best)


# ---------------------------------------------------------------- save

static func province_save(p) -> Array:
	return [p.colonist, p.colony_months, p.natives]


static func province_load(g, p, e: Array) -> void:
	if e.is_empty():
		if p.owner != NATIVE:
			p.natives = 0.0
		return
	p.colonist = str(e[0])
	p.colony_months = int(e[1])
	p.natives = float(e[2])


static func nation_save(n) -> Dictionary:
	return {"seas": n.known_seas.keys(), "nw": n.known_nw.keys(), "exp": n.expedition}


static func nation_load(g, n, d: Dictionary) -> void:
	if d.is_empty():
		return  # older save: keep the start knowledge from setup
	n.known_seas = {}
	for s in d.get("seas", []):
		n.known_seas[str(s)] = true
	n.known_nw = {}
	for pid in d.get("nw", []):
		n.known_nw[int(pid)] = true
	var e: Dictionary = d.get("exp", {})
	n.expedition = {} if e.is_empty() else {"sea": str(e.sea), "months": int(e.months)}
