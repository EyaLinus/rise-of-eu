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
const NEW_SEAS := ["guinea", "ocean", "labrador", "st_lawrence", "east_coast", "sargasso", "caribbean", "gulf", "pacific", "hudson", "lakes",
		"south_atlantic", "cape", "mozambique", "swahili", "indian", "af_lakes",
		"guiana", "amazon", "brazil", "plata", "patagonian", "horn", "humboldt", "cortez", "california", "cascadia",
		"beaufort", "nw_passage", "baffin", "chukchi", "gulf_alaska", "east_pacific", "arafura", "coral", "tasman", "south_aus", "melanesia",
		"south_pacific", "east_indian"]
## The seas around Australia, New Guinea and the Pacific islands (and Hawaii's): ships of the Old World only
## dare the long voyage from bal.oceania_year (Mendaña reached the Solomons 1568, the Duyfken Cape York 1606).
const OCEANIA_SEAS := ["arafura", "coral", "tasman", "south_aus", "melanesia", "south_pacific", "east_pacific"]
## Monsoon trade: realms with a coast on one of these known seas also know the Swahili coast from the start.
const MONSOON := {"swahili": ["aden", "arabian", "persian_gulf"]}


static func setup(g, data: Dictionary) -> void:
	# overseas and African provinces by their map.json flags ("nw", "wa"); the blocks are appended over time
	# (Americas + West Africa, the Old World east, Africa, South America, the North American west, the Low
	# Countries), so the first ids below are only landmarks for the UI and tests
	var n_prov: int = g.provinces.size()
	g.nw_mask = PackedByteArray()
	g.nw_mask.resize(n_prov)
	g.wa_mask = PackedByteArray()
	g.wa_mask.resize(n_prov)
	g.nw_first = n_prov
	g.wa_first = n_prov
	g.nw_end = n_prov
	g.af_first = n_prov
	g.sa_first = n_prov
	g.pac_first = n_prov
	for i in mini(n_prov, data.map.provinces.size()):
		var pd: Dictionary = data.map.provinces[i]
		var nw: bool = pd.get("nw", false)
		g.nw_mask[i] = 1 if nw else 0
		g.wa_mask[i] = 1 if pd.get("wa", false) else (2 if pd.get("oc", false) else 0)
		if nw and g.nw_first == n_prov:
			g.nw_first = i
		if pd.get("wa", false) and g.wa_first == n_prov:
			g.wa_first = i
		if not nw and g.nw_first < n_prov and g.nw_end == n_prov:
			g.nw_end = i  # the Middle East and the Horn ("east") follow the first overseas block: Old World again
		if pd.get("af", false) and g.af_first == n_prov:
			g.af_first = i
		if pd.get("sa", false) and g.sa_first == n_prov:
			g.sa_first = i
		if pd.get("pac", false) and g.pac_first == n_prov:
			g.pac_first = i
	g.overseas = []
	g.africa = []
	for pid in n_prov:
		if is_new_world(g, pid):
			g.overseas.append(pid)
			if region(g, pid) == "africa":
				g.africa.append(pid)
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
		for pid in g.overseas:
			if region(g, pid) == home:
				n.known_nw[pid] = true
		return
	for s in g.seas:
		if not NEW_SEAS.has(s.id):
			n.known_seas[s.id] = true
			for pid in s.provinces:
				if is_new_world(g, pid):
					n.known_nw[pid] = true
	for sea in MONSOON:
		var home := false
		for pid in g.provinces_of(n.tag):
			for s2 in g.province_seas.get(pid, []):
				if MONSOON[sea].has(s2):
					home = true
		if home and g.sea_by_id.has(sea):
			n.known_seas[sea] = true
			for pid in g.sea_by_id[sea].provinces:
				n.known_nw[pid] = true
	# the Sahel and Mali are known from the gold caravans; the forest belt and the Guinea coast are not
	for pid in g.africa:
		if g.provinces[pid].center.y < float(g.bal.wa_known_y):
			n.known_nw[pid] = true
	# caravan routes: the land next to our own (Morocco knows the way to Taghaza)
	for pid in g.provinces_of(n.tag):
		for a in g.provinces[pid].adj:
			if is_new_world(g, a):
				n.known_nw[a] = true


## "old" (Europe, North Africa, the Near East, Asia), "america", "africa" (West Africa and the south) or
## "oceania" (Australia, New Guinea, the Pacific islands; wa_mask 2).
static func region(g, pid: int) -> String:
	if not is_new_world(g, pid):
		return "old"
	var m: int = g.wa_mask[pid]
	return "africa" if m == 1 else ("oceania" if m == 2 else "america")


static func is_native_realm(g, tag: String) -> bool:
	return tag == NATIVE or g.nation_data_native.has(tag)


static func is_new_world(g, pid: int) -> bool:
	return pid < g.nw_mask.size() and g.nw_mask[pid] == 1


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
	var reach := sea_reach(g, tag)
	for s in g.seas:
		if not NEW_SEAS.has(s.id) or n.known_seas.has(s.id):
			continue
		if OCEANIA_SEAS.has(s.id) and g.year() < int(g.bal.oceania_year) and tag != g.player:
			continue  # the player still sees the sea, with the reason why it is too far
		for a in s.get("adj", []):
			if reach.has(a):  # a known sea our ships can sail to (not the Arabian Sea from the Atlantic)
				r.append(s.id)
				break
	return r


## Seas the realm's ships can reach: the known seas at its own coasts and every known sea linked to them.
## Cached per realm until the month or its sea knowledge changes.
static func sea_reach(g, tag: String) -> Dictionary:
	var n = g.nations[tag]
	var key := "%d:%d:%d" % [g.month, n.known_seas.size(), g.owned.get(tag, []).size()]
	var c: Array = g.sea_reach_cache.get(tag, [])
	if not c.is_empty() and c[0] == key:
		return c[1]
	var reach := {}
	var queue := []
	for pid in g.provinces_of(tag):
		for s in g.province_seas.get(pid, []):
			if n.known_seas.has(s) and not reach.has(s):
				reach[s] = true
				queue.append(s)
	var head := 0
	while head < queue.size():
		var cur: String = queue[head]
		head += 1
		for nb in g.sea_by_id[cur].get("adj", []):
			if not reach.has(nb) and n.known_seas.has(nb) and g.sea_by_id.has(nb):
				reach[nb] = true
				queue.append(nb)
	g.sea_reach_cache[tag] = [key, reach]
	return reach


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
	if OCEANIA_SEAS.has(sea) and g.year() < int(g.bal.oceania_year):
		return "Das Südmeer ist noch zu fern: erst ab etwa %d." % int(g.bal.oceania_year)
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
	for pid in g.overseas:
		if g.provinces[pid].colonist == tag:
			r.append(pid)
	return r


static func colony_cost(g, tag: String, pid: int) -> float:
	var n = g.nations[tag]
	var more: float = 1.0 + float(g.bal.colony_cost_per_colony) * colonies_owned(g, tag)  # far-flung empires cost more
	return round(float(g.bal.colony_cost) * (1.0 + 0.1 * g.provinces[pid].dev) * more * maxf(0.5, 1.0 + g.mod(n, "colony_cost"))
			* (1.0 + n.col_exhaust * 0.01 * float(g.bal.col_exhaust_cost)))


## Months a colony needs; strong natives slow it down, and so does the colonizer's exhaustion (`tag`, or
## the realm already settling it).
static func colony_months(g, p, tag: String = "") -> int:
	var who: String = tag if tag != "" else p.colonist
	var ex: float = g.nations[who].col_exhaust if who != "" and g.nations.has(who) else 0.0
	return int(round(float(g.bal.colony_months) * (1.0 + p.natives * float(g.bal.natives_slow))
			* (1.0 + ex * 0.01 * float(g.bal.col_exhaust_slow))))


## A province the realm can reach with settlers: next to its land, or a known coast on a sea its ships
## can reach over known seas (so the realm needs a coast of its own).
static func reachable(g, tag: String, pid: int) -> bool:
	var p = g.provinces[pid]
	for a in p.adj:
		if g.provinces[a].owner == tag:
			return true
	if not p.coastal or not has_coast(g, tag):
		return false
	var reach := sea_reach(g, tag)
	for s in g.province_seas.get(pid, []):
		if reach.has(s):
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
	if region(g, pid) == "oceania" and g.year() < int(g.bal.oceania_year):
		return "Ozeanien ist noch zu fern: Siedler wagen die Fahrt erst ab etwa %d." % int(g.bal.oceania_year)
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
	n.gold -= upkeep(g, n)
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
	n.col_exhaust = minf(100.0, n.col_exhaust + exhaust_gain(g, tag))
	g.log_msg("🏕 %s: Die Kolonie %s ist gewachsen und gehört nun fest zum Reich." % [n.name, p.name], [tag])


## First province of `keys` (map keys, in order of preference) that is still free native land: nobody owns it
## and nobody is settling it. Keys that are not on the map are skipped, so events can list provinces of
## regions that may not exist yet. -1 if none is free.
static func free_target(g, keys: Array) -> int:
	for key in keys:
		var pid: int = g.key_to_pid.get(str(key), -1)
		if pid >= 0 and is_native_land(g, pid) and g.provinces[pid].colonist == "":
			return pid
	return -1


## Event effect "colony_grant": the realm discovers the region (every sea touching the listed provinces and
## its coasts) and receives the first free province of the list as a finished, settled colony.
## Returns the granted province id or -1 (then only the discovery happens).
static func grant(g, tag: String, keys: Array) -> int:
	discover(g, tag, keys)
	var target := free_target(g, keys)
	if target < 0:
		return -1
	var p = g.provinces[target]
	p.colonist = tag
	_finish(g, p)
	g.nations[tag].flags["colony_grant"] = g.month
	return target


## Event effect "discover": every sea touching the listed provinces (map keys) and its coasts become known.
static func discover(g, tag: String, keys: Array) -> void:
	var pids := []
	for key in keys:
		var pid: int = g.key_to_pid.get(str(key), -1)
		if pid >= 0 and is_new_world(g, pid):
			pids.append(pid)
	for s in g.seas:
		for pid in pids:
			if pid in s.provinces:
				reveal_sea(g, tag, s.id)
				break
	for pid in pids:
		reveal(g, tag, pid)


static func colonies_owned(g, tag: String) -> int:
	var c := 0
	for pid in g.provinces_of(tag):
		if is_new_world(g, pid):
			c += 1
	return c


# ---------------------------------------------------------------- colonial exhaustion

## Colonial exhaustion (0..100): every finished colony tires the motherland (settlers, ships, officials),
## the more colonies it already holds the more. It slows new colonies and makes them dearer, and fades
## every month (faster with a high administrative technology).
static func exhaustion(n) -> float:
	return n.col_exhaust


## Exhaustion a new colony adds: base plus a share per colony the realm already holds.
static func exhaust_gain(g, tag: String) -> float:
	var n = g.nations[tag]
	var f: float = maxf(0.25, 1.0 + g.mod(n, "col_exhaust_gain"))
	return (float(g.bal.col_exhaust_gain) + float(g.bal.col_exhaust_per_colony) * colonies_owned(g, tag)) * f


## Monthly decay of the exhaustion.
static func exhaust_decay(g, n) -> float:
	return float(g.bal.col_exhaust_decay) * (1.0 + 0.02 * float(n.tech.adm)) * maxf(0.25, 1.0 + g.mod(n, "col_exhaust_decay"))


## Monthly upkeep of one growing colony (exhaustion makes supplies dearer too).
static func upkeep(g, n) -> float:
	return float(g.bal.colony_upkeep) * (1.0 + n.col_exhaust * 0.01 * float(g.bal.col_exhaust_cost))


## Short label for the UI.
static func exhaust_level(n) -> String:
	if n.col_exhaust >= 60.0:
		return "erschöpft"
	if n.col_exhaust >= 30.0:
		return "angespannt"
	return "frisch"


## Finished colonies of `tag` in one region ("america", "africa", "oceania").
static func colonies_in(g, tag: String, r: String) -> int:
	var c := 0
	for pid in g.provinces_of(tag):
		if is_new_world(g, pid) and region(g, pid) == r:
			c += 1
	return c


# ---------------------------------------------------------------- ticks

static func monthly(g) -> void:
	if g.overseas.is_empty():
		return
	for pid in g.overseas:
		var p = g.provinces[pid]
		if p.colonist != "":
			_colony_tick(g, p)
	for tag in g.order:
		var n = g.nations[tag]
		if n.col_exhaust > 0.0:
			n.col_exhaust = maxf(0.0, n.col_exhaust - exhaust_decay(g, n))
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
	if g.overseas.is_empty():
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
	# an exhausted motherland rests before it sends the next settlers
	if n.col_exhaust > float(g.bal.ai_col_exhaust_pause) and g.rng.randf() < 0.75:
		return
	if running_colonies(g, n.tag).size() >= colonists(g, n) or g.rng.randf() > 0.5 * drive:
		for pid in running_colonies(g, n.tag):
			if g.provinces[pid].natives >= 3.0 and n.dip > float(g.bal.treaty_dip) + 60.0:
				native_treaty(g, n.tag, pid)
		return
	var best := -1
	var best_v := -1e9
	var early_oceania: bool = g.year() < int(g.bal.oceania_year)
	for pid in n.known_nw:
		var p = g.provinces[pid]
		if p.owner != NATIVE or p.colonist != "" or not reachable(g, n.tag, pid):
			continue
		if early_oceania and region(g, pid) == "oceania":
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
	return {"seas": n.known_seas.keys(), "nw": n.known_nw.keys(), "exp": n.expedition, "ex": snappedf(n.col_exhaust, 0.01)}


static func nation_load(g, n, d: Dictionary) -> void:
	if d.is_empty():
		return  # older save: keep the start knowledge from setup
	n.known_seas = {}
	for s in d.get("seas", []):
		n.known_seas[str(s)] = true
	n.known_nw = {}
	for pid in d.get("nw", []):
		n.known_nw[int(pid)] = true
	n.col_exhaust = float(d.get("ex", 0.0))
	var e: Dictionary = d.get("exp", {})
	n.expedition = {} if e.is_empty() else {"sea": str(e.sea), "months": int(e.months)}
