extends RefCounted
## Subject types (EU5-style), static helpers on the game `g`. Every subject has `overlord`; `Nation.subject`
## says what kind it is:
##   ""          Vasall: pays tribute, takes a diplomatic slot, can be annexed after some years.
##   "colony"    Kolonialnation: formed by itself from a realm's overseas colonies (one per connected colonial
##               area), settles further land on its own, pays a colonial tariff, takes no diplomatic slot,
##               can never be annexed and drifts towards independence over the decades (the road to the USA).
##   "dominion"  Dominion (English style): a big, self-governing subject. Little tribute, very loyal, gives its
##               overlord manpower, cannot be annexed. Made from a large vassal or a grown colonial nation.
##   "appanage"  Apanage (French style): land handed to a cadet branch of the ruling house. Loyal, pays good
##               tribute, takes no diplomatic slot, lowers the realm's administrative burden and returns to the
##               crown cheaply after a few years.
## Colonial nations and appanages are pool nations (data/nations.json "dormant": "colony" / "appanage"): dead
## from the start and brought to life with a name, colour and land when needed. Their flag is the overlord's.

const TYPES := {
	"": {"name": "Vasall", "icon": "⛓️"},
	"colony": {"name": "Kolonialnation", "icon": "🏕"},
	"dominion": {"name": "Dominion", "icon": "👑"},
	"appanage": {"name": "Apanage", "icon": "🏰"},
}
## Historical names of colonial nations, given in order of formation (fallback: "Kolonie <capital province>").
const CN_NAMES := {
	"SPA": {"america": ["Neuspanien", "Neugranada", "Peru", "La Plata", "Kuba"], "africa": ["Spanisch-Guinea"], "oceania": ["Spanisch-Ozeanien"]},
	"CAS": {"america": ["Neuspanien", "Neugranada", "Peru", "La Plata"]},
	"POR": {"america": ["Brasilien", "Grão-Pará"], "africa": ["Angola", "Mosambik", "Guinea"], "oceania": ["Timor"]},
	"ENG": {"america": ["Neuengland", "Virginia", "Kanada", "Karolina", "Westindien"], "africa": ["Kapkolonie", "Goldküste"], "oceania": ["Australien", "Neuseeland"]},
	"SCO": {"america": ["Neuschottland"]},
	"FRA": {"america": ["Neufrankreich", "Louisiana", "Saint-Domingue"], "africa": ["Senegal", "Madagaskar"], "oceania": ["Polynesien"]},
	"NED": {"america": ["Neu-Niederland", "Surinam"], "africa": ["Kapland", "Goldküste"], "oceania": ["Neuholland"]},
	"DAN": {"america": ["Dänisch-Westindien", "Grönland"], "africa": ["Dänisch-Guinea"]},
	"SWE": {"america": ["Neuschweden"]},
	"VEN": {"america": ["Neu-Venedig"]},
	"GEN": {"america": ["Neu-Genua"]},
	"BUR": {"america": ["Neu-Burgund"]},
	"HAB": {"america": ["Neu-Österreich"]},
	"TUR": {"africa": ["Osmanisch-Ostafrika"]},
}
const APPANAGE_DRIVE := {"FRA": 1.0}  # AI realms that like to endow cadet branches (EU5 France)
const DOMINION_HOMES := {"ENG": true, "SCO": true}  # cheaper dominions (the British way)


static func setup(g, data: Dictionary) -> void:
	g.subject_pool = {"colony": [], "appanage": []}
	for tag in data.nations:
		var kind: String = str(data.nations[tag].get("dormant", ""))
		if kind == "":
			continue
		g.subject_pool[kind].append(tag)
		var n = g.nations[tag]
		n.alive = false
		n.ships = 0.0
		n.merchants = []
		for a in g.armies.duplicate():
			if a.owner == tag:
				g.armies.erase(a)
				g.armies_dirty()
		var cap = g.provinces[n.capital]
		if cap.owner != tag and g.nations[cap.owner].capital != cap.id:
			cap.fort = 0


static func is_pool(g, tag: String) -> bool:
	return g.subject_pool.get("colony", []).has(tag) or g.subject_pool.get("appanage", []).has(tag)


static func kind(g, tag: String) -> String:
	var n = g.nations[tag]
	return n.subject if n.overlord != "" else ""


static func type_name(g, tag: String) -> String:
	return TYPES[kind(g, tag)].name


static func icon(g, tag: String) -> String:
	return TYPES[kind(g, tag)].icon


## Share of its income a subject pays its overlord every month.
static func tribute_share(g, tag: String) -> float:
	match kind(g, tag):
		"colony":
			return float(g.bal.sub_colony_tribute)
		"dominion":
			return float(g.bal.sub_dominion_tribute)
		"appanage":
			return float(g.bal.sub_appanage_tribute)
	return float(g.bal.vassal_tribute)


## Diplomatic slots the subject takes from its overlord (Game.diplo_used).
static func diplo_slots(g, tag: String) -> int:
	return 1 if kind(g, tag) in ["", "dominion"] else 0


static func can_annex(g, tag: String) -> bool:
	return kind(g, tag) in ["", "appanage"]


static func annex_years(g, tag: String) -> int:
	return int(g.bal.sub_appanage_annex_years) if kind(g, tag) == "appanage" else int(g.bal.vassal_annex_years)


static func annex_mult(g, tag: String) -> float:
	if kind(g, tag) != "appanage":
		return 1.0
	var m := float(g.bal.sub_appanage_annex_mult)
	return m * 0.6 if APPANAGE_DRIVE.has(g.nations[tag].overlord) else m


## Loyalty taken off the liberty desire (Game.liberty). Colonial nations grow restless with the decades.
static func loyalty(g, tag: String) -> float:
	var n = g.nations[tag]
	match kind(g, tag):
		"colony":
			var years: float = float(g.month - n.vassal_since) / 12.0
			return float(g.bal.sub_colony_loyalty) - years * float(g.bal.sub_colony_drift)
		"dominion":
			return float(g.bal.sub_dominion_loyalty)
		"appanage":
			return float(g.bal.sub_appanage_loyalty)
	return 0.0


## Called right before a subject becomes independent (liberty, overlord gone).
static func released(g, tag: String) -> void:
	var n = g.nations[tag]
	if n.subject == "colony":
		n.flags["former_colony"] = g.month
	n.subject = ""


# ---------------------------------------------------------------- bonuses

## Monthly-cached bonuses: what subjects give their overlord (source "subjects") and what a dominion enjoys.
static func refresh_bonus(g) -> void:
	var per := {}
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive:
			continue
		if n.overlord == "":
			n.clear_bonus("subject")
			continue
		var lord: String = n.overlord
		if not per.has(lord):
			per[lord] = {"colony": 0, "dominion": 0, "appanage": 0}
		if n.subject != "":
			per[lord][n.subject] += 1
		if n.subject == "dominion":
			n.set_bonus("subject", {"income": float(g.bal.sub_dominion_income), "manpower": float(g.bal.sub_dominion_income)})
		else:
			n.clear_bonus("subject")
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive:
			continue
		if not per.has(tag):
			n.clear_bonus("subjects")
			continue
		var c: Dictionary = per[tag]
		var b := {}
		if c.colony > 0:
			b["trade"] = minf(float(c.colony) * float(g.bal.sub_colony_lord_trade), 0.15)
		if c.dominion > 0:
			b["manpower"] = minf(float(c.dominion) * float(g.bal.sub_dominion_lord_manpower), 0.2)
		if c.appanage > 0:
			b["unrest"] = -minf(float(c.appanage) * float(g.bal.sub_appanage_lord_unrest), 1.5)
		if b.is_empty():
			n.clear_bonus("subjects")
		else:
			n.set_bonus("subjects", b)


# ---------------------------------------------------------------- pool nations

static func _free_pool_tag(g, kind_: String) -> String:
	for t in g.subject_pool.get(kind_, []):
		if not g.nations[t].alive and g.provinces_of(t).is_empty():
			return t
	return ""


## Brings a pool nation to life as a subject of `lord` with the given land.
static func _activate(g, t: String, lord: String, pids: Array, kind_: String, nm: String, col: Color) -> void:
	var n = g.nations[t]
	var l = g.nations[lord]
	for o in g.nations.values():
		o.relations.erase(t)
		o.truces.erase(t)
		o.coalition.erase(t)
		o.access.erase(t)
		o.guarantees.erase(t)
	n.name = nm
	n.color = col
	n.subject = kind_
	n.sub_name = nm
	n.relations = {}
	n.allies = []
	n.truces = {}
	n.claims = {}
	n.flags = {}
	n.missions_done = {}
	n.coalition = []
	n.rivals = []
	g.rivals_dirty()
	n.embargoes = []
	n.marriages = []
	n.access = {}
	n.guarantees = {}
	n.loans = []
	n.trade_pacts = []
	n.merchants = []
	n.monuments = {}
	n.monument_build = {}
	n.formed = ""
	n.age_picks = {}
	n.tech_queue = []
	n.ships = 0.0
	n.ae = 0.0
	n.we = 0.0
	n.prestige = 0.0
	n.power_proj = 0.0
	n.mods = {"income": 0.0, "combat": 0.0, "manpower": 0.0, "adm": 0.0, "dip": 0.0, "mil": 0.0, "ae_decay": 0.0}
	n.bonus = {}
	n.religion = l.religion
	n.ruler_names = l.ruler_names.duplicate()
	n.name_counts = {}
	n.tech = l.tech.duplicate()
	n.techs = l.techs.duplicate()
	n.known_seas = l.known_seas.duplicate()
	n.known_nw = l.known_nw.duplicate()
	n.expedition = {}
	n.gold = float(g.bal.sub_start_gold)
	n.adm = float(g.bal.sub_start_power)
	n.dip = float(g.bal.sub_start_power)
	n.mil = float(g.bal.sub_start_power)
	n.stability = float(g.bal.stab_start)
	n.rank = 0
	for pid in pids:
		var p = g.provinces[pid]
		p.owner = t
		if p.controller == lord:
			p.controller = t
		p.siege = 0.0
		l.claims.erase(pid)
	var best: int = pids[0]
	for pid in pids:
		if g.provinces[pid].dev > g.provinces[best].dev:
			best = pid
	n.capital = best
	g.provinces[best].fort = maxi(g.provinces[best].fort, 1)
	g._rebuild_owned()
	n.alive = true
	n.overlord = lord
	n.subject = kind_
	n.vassal_since = g.month
	n.flags["flag_of"] = lord  # pool nations fly their founder's flag, also after independence
	g._new_ruler(n)
	g.tree.refresh(n)
	g.tree.forget_shares()
	g.govt.init_nation(n)
	g.govt.ensure_heir(g, n)
	g.govt.refresh(n)
	g.Stability.refresh_bonus(g, n)
	g.add_rel(t, lord, float(g.bal.sub_start_rel))
	if kind_ == "colony":
		g.colonial_drive[t] = float(g.bal.sub_colony_drive)
		if not g.atlantic_tags.has(t):
			g.atlantic_tags.append(t)
	g._update_cached(n)
	n.manpower = n.max_manpower * 0.5
	var regs: float = round(g.force_limit(t) * 0.4)
	if regs >= 1.0:
		g.spawn_army(t, n.capital, regs)
	g.Economy.auto_merchants(g, n)
	g.Progression._set_base(g, n)
	refresh_bonus(g)


static func _shade(c: Color, kind_: String) -> Color:
	return c.lightened(0.3) if kind_ == "colony" else c.darkened(0.25)


# ---------------------------------------------------------------- colonial nations

## Overseas provinces of `tag` (another region than its capital), in connected groups: land neighbours or
## within `sub_colony_link` map units (islands of one sea belong together).
static func colonial_groups(g, tag: String) -> Array:
	var C = g.Colonial
	var home: String = C.region(g, g.nations[tag].capital)
	var pids := []
	for pid in g.provinces_of(tag):
		if C.is_new_world(g, pid) and C.region(g, pid) != home:
			pids.append(pid)
	# land that borders the home region by land is conquest next door (Egypt in Darfur), not a colony
	var out := []
	for grp in _groups(g, pids):
		var by_land := false
		for pid in grp:
			for a in g.provinces[pid].adj:
				if g.provinces[a].owner == tag and C.region(g, a) == home:
					by_land = true
		if not by_land:
			out.append(grp)
	return out


static func _groups(g, pids: Array) -> Array:
	var link := float(g.bal.sub_colony_link)
	var left := {}
	for pid in pids:
		left[pid] = true
	var out := []
	while not left.is_empty():
		var start: int = left.keys()[0]
		left.erase(start)
		var grp := [start]
		var i := 0
		while i < grp.size():
			var p = g.provinces[grp[i]]
			for q in left.keys():
				if p.adj.has(q) or p.center.distance_to(g.provinces[q].center) < link:
					left.erase(q)
					grp.append(q)
			i += 1
		out.append(grp)
	return out


static func _near(g, pid: int, tag: String) -> bool:
	var link := float(g.bal.sub_colony_link)
	var p = g.provinces[pid]
	for a in p.adj:
		if g.provinces[a].owner == tag:
			return true
	for q in g.provinces_of(tag):
		if p.center.distance_to(g.provinces[q].center) < link:
			return true
	return false


## The colonial nation of `lord` next to `pid` (same region), or "".
static func colony_near(g, lord: String, pid: int) -> String:
	var C = g.Colonial
	for v in g.vassals_of(lord):
		var n = g.nations[v]
		if n.subject != "colony" or C.region(g, n.capital) != C.region(g, pid):
			continue
		if _near(g, pid, v):
			return v
	return ""


## Colonial._finish hook: a colony finished next to the colonizer's colonial nation joins that nation.
static func on_colony_finished(g, p) -> void:
	var lord: String = p.owner
	if g.nations[lord].overlord != "":
		return
	var cn := colony_near(g, lord, p.id)
	if cn == "":
		return
	p.owner = cn
	p.controller = cn
	g.owned[lord].erase(p.id)
	g.owned[cn].append(p.id)


## Overseas provinces of `tag` and of its colonial nations (for colonial goals that should not shrink).
static func colonies_with_subjects(g, tag: String) -> int:
	var c: int = g.Colonial.colonies_owned(g, tag)
	for v in g.vassals_of(tag):
		if g.nations[v].subject in ["colony", "dominion"]:
			c += g.Colonial.colonies_owned(g, v)
	return c


static func _cn_name(g, lord: String, pid: int) -> String:
	var reg: String = g.Colonial.region(g, pid)
	var key: String = lord
	var lf: String = g.nations[lord].formed
	if lf == "GBR":
		key = "ENG"
	elif lf == "IBE":
		key = "SPA"
	var used := {}
	for t in g.order:
		if g.nations[t].alive:
			used[g.nations[t].name] = true
	for nm in CN_NAMES.get(key, {}).get(reg, []):
		if not used.has(nm):
			return nm
	return "Kolonie " + g.provinces[pid].name


## Yearly: overseas groups of at least `sub_colony_min` provinces become colonial nations; overseas land next
## to an existing colonial nation of the same lord is handed over to it.
static func yearly(g) -> void:
	if g.overseas.is_empty():
		return
	var changed := false
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or n.overlord != "" or g.Colonial.is_native_realm(g, tag) or is_pool(g, tag) or g.is_at_war(tag):
			continue
		if g.Colonial.colonies_owned(g, tag) < int(g.bal.sub_colony_min):
			continue
		for grp in colonial_groups(g, tag):
			if grp.has(n.capital):
				continue
			var cn := colony_near(g, tag, grp[0])
			if cn != "":
				for pid in grp:
					g.provinces[pid].owner = cn
					if g.provinces[pid].controller == tag:
						g.provinces[pid].controller = cn
				changed = true
				g._rebuild_owned()
				continue
			if grp.size() < int(g.bal.sub_colony_min):
				continue
			if form_colony(g, tag, grp) != "":
				changed = true
	if changed:
		refresh_bonus(g)


## A new colonial nation from `pids` (overseas land of `lord`). Returns its tag or "" if the pool is empty.
static func form_colony(g, lord: String, pids: Array) -> String:
	var t := _free_pool_tag(g, "colony")
	if t == "":
		return ""
	var best: int = pids[0]
	for pid in pids:
		if g.provinces[pid].dev > g.provinces[best].dev:
			best = pid
	var nm := _cn_name(g, lord, best)
	_activate(g, t, lord, pids, "colony", nm, _shade(g.nations[lord].color, "colony"))
	g.stats["colonial_nations"] = int(g.stats.get("colonial_nations", 0)) + 1
	g.world_event("🏕 %s gründet die Kolonialnation %s (%d Provinzen)." % [g.nations[lord].name, nm, pids.size()], [lord, t])
	return t


# ---------------------------------------------------------------- appanages

static func count(g, lord: String, kind_: String) -> int:
	var c := 0
	for v in g.vassals_of(lord):
		if g.nations[v].subject == kind_:
			c += 1
	return c


static func appanage_max(g, lord: String) -> int:
	return int(g.bal.sub_appanage_max) + (2 if APPANAGE_DRIVE.has(lord) else 0)


## The land an appanage around `pid` would get: `pid` and own, cored neighbours (no capital), up to
## `sub_appanage_provinces`.
static func appanage_lands(g, lord: String, pid: int) -> Array:
	var n = g.nations[lord]
	var out := [pid]
	var cap: int = int(g.bal.sub_appanage_provinces)
	var p = g.provinces[pid]
	for a in p.adj:
		if out.size() >= cap:
			break
		var q = g.provinces[a]
		if q.owner == lord and a != n.capital and q.core_months == 0 and q.controller == lord \
				and g.Colonial.region(g, a) == g.Colonial.region(g, pid):
			out.append(a)
	return out


static func appanage_block_reason(g, lord: String, pid: int) -> String:
	var n = g.nations[lord]
	var p = g.provinces[pid]
	if p.owner != lord:
		return "Nicht deine Provinz."
	if n.overlord != "":
		return "Als Untertan kannst du keine Apanagen vergeben."
	if pid == n.capital:
		return "Die Hauptstadt bleibt bei der Krone."
	if g.Colonial.region(g, pid) != g.Colonial.region(g, n.capital):
		return "Nur im Stammland, nicht in Übersee."
	if p.core_months > 0:
		return "Die Provinz muss erst integriert sein."
	if p.controller != lord:
		return "Die Provinz ist besetzt."
	if g.is_at_war(lord):
		return "Nicht während eines Krieges."
	if g.provinces_of(lord).size() < int(g.bal.sub_appanage_min_provinces):
		return "Dein Reich braucht mindestens %d Provinzen." % int(g.bal.sub_appanage_min_provinces)
	if count(g, lord, "appanage") >= appanage_max(g, lord):
		return "Höchstens %d Apanagen." % appanage_max(g, lord)
	if _free_pool_tag(g, "appanage") == "":
		return "Kein Haus mehr frei."
	if n.prestige < float(g.bal.sub_appanage_prestige):
		return "Zu wenig Prestige (%d)." % int(g.bal.sub_appanage_prestige)
	return ""


## Hands `pid` and up to two neighbours to a cadet branch of the house. Returns "" or the reason.
static func create_appanage(g, lord: String, pid: int) -> String:
	var why := appanage_block_reason(g, lord, pid)
	if why != "":
		return why
	var t := _free_pool_tag(g, "appanage")
	var l = g.nations[lord]
	var lands := appanage_lands(g, lord, pid)
	var nm: String = "Hzm. " + g.provinces[pid].name
	l.prestige -= float(g.bal.sub_appanage_prestige)
	_activate(g, t, lord, lands, "appanage", nm, _shade(l.color, "appanage"))
	g.Stability.add(g, lord, float(g.bal.sub_appanage_stability), "Apanage für das Haus")
	g.stats["appanages"] = int(g.stats.get("appanages", 0)) + 1
	g.log_msg("🏰 %s gibt %s als Apanage an eine Nebenlinie des Hauses (%d Provinzen)." % [l.name, g.provinces[pid].name, lands.size()], [lord, t])
	return ""


# ---------------------------------------------------------------- changing the kind of a subject

static func convert_cost(g, lord: String, to: String) -> float:
	var c := float(g.bal.sub_convert_dip)
	if (to == "dominion" and DOMINION_HOMES.has(lord)) or (to == "appanage" and APPANAGE_DRIVE.has(lord)):
		c *= 0.5
	return c


static func convert_block_reason(g, lord: String, tag: String, to: String) -> String:
	var v = g.nations[tag]
	if v.overlord != lord or not v.alive:
		return "%s ist nicht dein Untertan." % v.name
	var cur := kind(g, tag)
	if cur == to:
		return "Ist schon %s." % TYPES[to].name
	if g.is_at_war(lord):
		return "Nicht während eines Krieges."
	match to:
		"dominion":
			if cur == "appanage":
				return "Eine Apanage bleibt beim Haus."
			if cur != "colony" and not overseas(g, lord, tag):
				return "Nur Kolonialnationen und Vasallen in Übersee."
			var need := int(g.bal.sub_dominion_min_dev)
			if v.dev_total < need:
				return "Braucht %d Entwicklung (hat %d)." % [need, v.dev_total]
		"appanage":
			if cur != "":
				return "Nur gewöhnliche Vasallen."
			if v.religion != g.nations[lord].religion:
				return "Braucht denselben Glauben."
			if not _borders(g, lord, tag):
				return "Muss an dein Land grenzen."
			if v.dev_total > int(g.bal.sub_appanage_max_dev):
				return "Zu groß (höchstens %d Entwicklung)." % int(g.bal.sub_appanage_max_dev)
			if count(g, lord, "appanage") >= appanage_max(g, lord):
				return "Höchstens %d Apanagen." % appanage_max(g, lord)
		"":
			return "Zurückstufen ist nicht möglich."
	if g.nations[lord].dip < convert_cost(g, lord, to):
		return "Zu wenig Diplomatie (%d)." % int(convert_cost(g, lord, to))
	return ""


static func convert_subject(g, lord: String, tag: String, to: String) -> String:
	var why := convert_block_reason(g, lord, tag, to)
	if why != "":
		return why
	var v = g.nations[tag]
	g.nations[lord].dip -= convert_cost(g, lord, to)
	v.subject = to
	g.add_rel(tag, lord, 20.0)
	refresh_bonus(g)
	g.log_msg("%s %s ist jetzt %s von %s." % [TYPES[to].icon, v.name, ("ein " if to == "dominion" else "eine ") + TYPES[to].name, g.nations[lord].name], [lord, tag])
	return ""


## The subject's capital lies in another part of the world than its overlord's (Colonial.region).
static func overseas(g, lord: String, tag: String) -> bool:
	var C = g.Colonial
	return C.region(g, g.nations[tag].capital) != C.region(g, g.nations[lord].capital)


static func _borders(g, a: String, b: String) -> bool:
	for pid in g.provinces_of(b):
		for q in g.provinces[pid].adj:
			if g.provinces[q].owner == a:
				return true
	return false


# ---------------------------------------------------------------- AI

## Yearly AI: big or overseas vassals become dominions, appanage-minded crowns endow cadet branches.
static func ai_yearly(g) -> void:
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or tag == g.player or n.overlord != "" or g.is_at_war(tag):
			continue
		for v in g.vassals_of(tag):
			if kind(g, v) in ["", "colony"] and convert_block_reason(g, tag, v, "dominion") == "" \
					and g.rng.randf() < (float(g.bal.sub_ai_dominion_home) if DOMINION_HOMES.has(tag) else float(g.bal.sub_ai_dominion)):
				convert_subject(g, tag, v, "dominion")
		var drive: float = float(APPANAGE_DRIVE.get(tag, g.bal.sub_ai_appanage_drive))
		if drive <= 0.0 or g.rng.randf() > 0.1 * drive:
			continue
		if g.provinces_of(tag).size() < int(g.bal.sub_appanage_min_provinces) * 2:
			continue
		# the province farthest from the capital that has some own land around it
		var capc: Vector2 = g.provinces[n.capital].center
		var best := -1
		var best_d := 0.0
		for pid in g.provinces_of(tag):
			if appanage_block_reason(g, tag, pid) != "" or appanage_lands(g, tag, pid).size() < 2:
				continue
			var d: float = g.provinces[pid].center.distance_to(capc)
			if d > best_d:
				best_d = d
				best = pid
		if best >= 0:
			create_appanage(g, tag, best)


# ---------------------------------------------------------------- save

static func nation_save(g, n) -> Dictionary:
	if n.subject == "" and not is_pool(g, n.tag):
		return {}
	return {"kind": n.subject, "name": n.name, "color": n.color.to_html(false), "drive": float(g.colonial_drive.get(n.tag, 0.0))}


static func nation_load(g, n, d: Dictionary) -> void:
	n.subject = str(d.get("kind", ""))
	if d.is_empty() or not is_pool(g, n.tag):
		return
	n.name = str(d.get("name", n.name))
	n.sub_name = n.name
	n.color = Color(str(d.get("color", n.color.to_html(false))))
	if float(d.get("drive", 0.0)) > 0.0:
		g.colonial_drive[n.tag] = float(d.drive)
		if n.alive and not g.atlantic_tags.has(n.tag):
			g.atlantic_tags.append(n.tag)
