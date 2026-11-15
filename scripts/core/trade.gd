extends RefCounted
## Far trade (Fernhandel) and trade dominance. Static helpers on the game `g`; all state lives in
## `g.east` (one saved dictionary) so the rest of the game only needs a few hooks.
##
## East India trade: an Atlantic realm with enough diplomatic technology sends a voyage around the
## Cape of Good Hope. Whoever comes back first opens the spice route. From then on every realm that
## knows the route sends Indiamen (bought with gold, small upkeep) and founds trading posts (factories)
## at Sofala, Hormuz, Goa ... Each realm's share of the route's value = its power (ships + factories)
## over everyone's power. The route grows richer every year, and once it is open the Levant loses:
## Venice, Alexandria and Constantinople trade less. Rivals at war raid each other's ships and storm
## each other's factories.
##
## Colonial trade: colonized New World land sends its goods to Europe (higher market value), and only
## realms that know a New World market and can reach it by sea may send merchants there.
##
## Trade dominance: holding at least dom_share of a market's trade power makes a realm its master:
## extra income from that market ("staple right") and a little prestige every month.

## Off-map trading posts on the spice route. power = route power for the holder, year = earliest year.
const FACTORIES := [
	{"id": "sofala", "name": "Sofala", "emoji": "🪙", "power": 3.0, "year": 1490, "desc": "Gold und Elfenbein der ostafrikanischen Küste."},
	{"id": "hormuz", "name": "Hormus", "emoji": "🏜️", "power": 4.0, "year": 1500, "desc": "Das Tor zum Persischen Golf."},
	{"id": "goa", "name": "Goa", "emoji": "🏛️", "power": 6.0, "year": 1500, "desc": "Hauptstadt des Gewürzhandels an der Malabarküste."},
	{"id": "calicut", "name": "Kalikut", "emoji": "🫘", "power": 5.0, "year": 1498, "desc": "Pfeffer, Ingwer und Zimt in Hülle und Fülle."},
	{"id": "ceylon", "name": "Ceylon", "emoji": "🌲", "power": 4.0, "year": 1505, "desc": "Die Zimtinsel."},
	{"id": "malacca", "name": "Malakka", "emoji": "⚓", "power": 6.0, "year": 1510, "desc": "Wer Malakka hält, hat Venedig an der Gurgel."},
	{"id": "moluccas", "name": "Molukken", "emoji": "🍬", "power": 5.0, "year": 1515, "desc": "Die Gewürzinseln: Nelken und Muskat."},
	{"id": "macau", "name": "Macau", "emoji": "🧵", "power": 5.0, "year": 1557, "desc": "Seide und Porzellan aus China."},
]
## Market centers that lose value once the Cape route is open (spices bypass the Levant).
const LEVANT := ["venice", "alexandria", "constantinople", "genoa"]


static func setup(g) -> void:
	g.east = {"cape": "", "cape_month": -1, "known": {}, "voyage": {}, "ships": {}, "factories": {}, "dom": {}}
	g.levant = []
	for k in LEVANT:
		if g.key_to_pid.has(k):
			g.levant.append(g.key_to_pid[k])


static func load_save(g, d: Dictionary) -> void:
	setup(g)
	if d.is_empty():
		return
	g.east.cape = str(d.get("cape", ""))
	g.east.cape_month = int(d.get("cape_month", -1))
	for t in d.get("known", {}):
		g.east.known[str(t)] = true
	for t in d.get("voyage", {}):
		g.east.voyage[str(t)] = int(d.voyage[t])
	for t in d.get("ships", {}):
		g.east.ships[str(t)] = int(d.ships[t])
	for f in d.get("factories", {}):
		g.east.factories[str(f)] = str(d.factories[f])
	for m in d.get("dom", {}):
		g.east.dom[int(m)] = str(d.dom[m])


static func to_save(g) -> Dictionary:
	return g.east


static func factory_def(id: String) -> Dictionary:
	for f in FACTORIES:
		if f.id == id:
			return f
	return {}


# ---------------------------------------------------------------- route state

static func is_open(g) -> bool:
	return g.east.cape != ""


static func knows(g, tag: String) -> bool:
	return g.east.known.has(tag)


static func ships(g, tag: String) -> int:
	return int(g.east.ships.get(tag, 0))


static func factories_of(g, tag: String) -> Array:
	var r := []
	for f in FACTORIES:
		if g.east.factories.get(f.id, "") == tag:
			r.append(f.id)
	return r


## Route power of a realm: Indiamen plus its factories.
static func power(g, tag: String) -> float:
	var v: float = ships(g, tag) * float(g.bal.east_ship_power) * (1.0 + g.mod(g.nations[tag], "naval_trade"))
	for id in factories_of(g, tag):
		v += float(factory_def(id).power)
	return v


static func total_power(g) -> float:
	var t := 0.0
	for tag in g.east.known:
		if g.nations[tag].alive:
			t += power(g, tag)
	return t


## Monthly value of the whole spice route (grows every year since the Cape was rounded).
static func route_value(g) -> float:
	if not is_open(g):
		return 0.0
	var years: float = float(g.month - int(g.east.cape_month)) / 12.0
	return minf(float(g.bal.east_value_max), float(g.bal.east_value_base) + float(g.bal.east_value_per_year) * years)


static func share(g, tag: String) -> float:
	var t: float = total_power(g)
	if t <= 0.0 or not knows(g, tag):
		return 0.0
	return power(g, tag) / t


## Raw monthly income from the spice route (before trade modifiers; Economy.trade_income applies them).
static func east_income(g, tag: String) -> float:
	if not knows(g, tag):
		return 0.0
	return route_value(g) * share(g, tag)


static func ship_cap(g, tag: String) -> int:
	var n = g.nations[tag]
	return int(g.bal.east_ship_base_cap) + factories_of(g, tag).size() * int(g.bal.east_ship_per_factory) + int(n.tech.dip / 4)


static func upkeep(g, n) -> float:
	return ships(g, n.tag) * float(g.bal.east_ship_upkeep)


## Market value factor: the Levant loses once the spice route runs around Africa.
static func market_mult(g, m: int) -> float:
	if not is_open(g) or not g.levant.has(m):
		return 1.0
	var years: float = float(g.month - int(g.east.cape_month)) / 12.0
	return 1.0 - minf(float(g.bal.levant_loss_max), years * float(g.bal.levant_loss_per_year))


# ---------------------------------------------------------------- actions

static func voyage_cost(g, tag: String) -> float:
	return float(g.bal.cape_cost) * (1.0 if not is_open(g) else 0.5)


static func voyage_block_reason(g, tag: String) -> String:
	var n = g.nations[tag]
	if knows(g, tag):
		return "Ihr kennt den Seeweg nach Indien schon."
	if not g.atlantic_tags.has(tag) or not n.alive:
		return "Braucht eine Küste am Atlantik, Ärmelkanal oder an der Nordsee."
	if g.east.voyage.has(tag):
		return "Die Flotte ist schon unterwegs."
	if int(n.tech.dip) < int(g.bal.cape_dip_tech):
		return "Braucht Diplomatie-Technologie %d." % int(g.bal.cape_dip_tech)
	if g.year() < int(g.bal.cape_year):
		return "Noch ist niemand bereit, so weit nach Süden zu segeln (ab %d)." % int(g.bal.cape_year)
	if is_open(g) and g.month - int(g.east.cape_month) < int(g.bal.cape_monopoly_years) * 12 and tag != g.east.cape:
		return "%s hütet die Seekarten noch (bis %d)." % [g.nations[g.east.cape].name, int(g.bal.start_year) + (int(g.bal.start_month) - 1 + int(g.east.cape_month)) / 12 + int(g.bal.cape_monopoly_years)]
	if n.gold < voyage_cost(g, tag):
		return "Zu wenig Gold (%d)." % int(voyage_cost(g, tag))
	if n.dip < float(g.bal.cape_dip):
		return "Zu wenig Diplomatie (%d)." % int(g.bal.cape_dip)
	return ""


static func start_voyage(g, tag: String) -> String:
	var why := voyage_block_reason(g, tag)
	if why != "":
		return why
	var n = g.nations[tag]
	n.gold -= voyage_cost(g, tag)
	n.dip -= float(g.bal.cape_dip)
	g.east.voyage[tag] = int(g.bal.cape_months) if not is_open(g) else int(g.bal.cape_months) / 2
	if tag == g.player:
		g.log_msg("⛵ Eine Flotte segelt nach Süden, um Afrika herum, auf der Suche nach dem Seeweg nach Indien.", [tag])
	return ""


static func ship_block_reason(g, tag: String) -> String:
	var n = g.nations[tag]
	if not knows(g, tag):
		return "Erst den Seeweg nach Indien finden."
	if ships(g, tag) >= ship_cap(g, tag):
		return "Höchstens %d Ostindienfahrer (mehr mit Faktoreien und Diplomatie-Technologie)." % ship_cap(g, tag)
	if n.gold < float(g.bal.east_ship_cost):
		return "Zu wenig Gold (%d)." % int(g.bal.east_ship_cost)
	return ""


static func buy_ship(g, tag: String) -> String:
	var why := ship_block_reason(g, tag)
	if why != "":
		return why
	g.nations[tag].gold -= float(g.bal.east_ship_cost)
	g.east.ships[tag] = ships(g, tag) + 1
	return ""


static func sell_ship(g, tag: String) -> void:
	if ships(g, tag) > 0:
		g.east.ships[tag] = ships(g, tag) - 1


static func max_factories(g, tag: String) -> int:
	return int(g.bal.east_max_factories) + int(g.nations[tag].tech.dip / 10)


static func factory_cost(g, tag: String) -> float:
	return float(g.bal.east_factory_cost) * (1.0 + 0.25 * factories_of(g, tag).size())


static func factory_block_reason(g, tag: String, id: String) -> String:
	var f: Dictionary = factory_def(id)
	var n = g.nations[tag]
	if f.is_empty():
		return "Unbekannt."
	if not knows(g, tag):
		return "Erst den Seeweg nach Indien finden."
	if g.year() < int(f.year):
		return "%s ist erst ab %d erreichbar." % [f.name, int(f.year)]
	var holder: String = g.east.factories.get(id, "")
	if holder == tag:
		return "Gehört euch schon."
	if holder != "":
		if not g.at_war(tag, holder):
			return "Gehört %s. Nur im Krieg zu erobern." % g.nations[holder].name
		if ships(g, tag) <= ships(g, holder):
			return "Braucht mehr Ostindienfahrer als %s (%d gegen %d)." % [g.nations[holder].name, ships(g, tag), ships(g, holder)]
		return ""
	if factories_of(g, tag).size() >= max_factories(g, tag):
		return "Höchstens %d Faktoreien (mehr mit Diplomatie-Technologie)." % max_factories(g, tag)
	if ships(g, tag) < int(g.bal.east_factory_ships):
		return "Braucht %d Ostindienfahrer." % int(g.bal.east_factory_ships)
	if n.gold < factory_cost(g, tag):
		return "Zu wenig Gold (%d)." % int(factory_cost(g, tag))
	return ""


## Found a free factory (gold) or storm an enemy's factory in war (no gold, costs a ship).
static func take_factory(g, tag: String, id: String) -> String:
	var why := factory_block_reason(g, tag, id)
	if why != "":
		return why
	var f: Dictionary = factory_def(id)
	var holder: String = g.east.factories.get(id, "")
	if holder == "":
		g.nations[tag].gold -= factory_cost(g, tag)
		g.log_msg("%s %s gründet eine Faktorei in %s." % [f.emoji, g.nations[tag].name, f.name], [tag])
	else:
		g.east.ships[tag] = ships(g, tag) - 1
		g.nations[tag].prestige += float(g.bal.east_storm_prestige)
		g.world_event("%s %s entreißt %s die Faktorei %s." % [f.emoji, g.nations[tag].name, g.nations[holder].name, f.name], [tag, holder])
	g.east.factories[id] = tag
	return ""


# ---------------------------------------------------------------- overseas markets

static func is_overseas_market(g, m: int) -> bool:
	return m >= g.nw_first


## "" if `tag` may trade in market `m`. New World markets need knowledge and a way across the ocean.
static func market_block_reason(g, tag: String, m: int) -> String:
	if not is_overseas_market(g, m):
		return ""
	if not g.Colonial.knows(g, tag, m):
		return "Dieser Markt liegt in unbekannten Landen."
	if g.Colonial.is_native_realm(g, tag) or g.atlantic_tags.has(tag) or g.Colonial.colonies_owned(g, tag) > 0:
		return ""
	return "Überseehandel braucht eine Küste am Atlantik oder eine eigene Kolonie."


## Value factor of a province's goods in its market: colonial goods are worth more in Europe.
static func value_mult(g, p) -> float:
	if p.id >= g.nw_first and p.owner != g.Colonial.NATIVE and not g.Colonial.is_native_realm(g, p.owner):
		return float(g.bal.colonial_trade_mult)
	return 1.0


# ---------------------------------------------------------------- dominance

static func dominant(g, m: int) -> String:
	return g.east.dom.get(m, "")


static func dominated_by(g, tag: String) -> Array:
	var r := []
	for m in g.east.dom:
		if g.east.dom[m] == tag:
			r.append(m)
	return r


static func _update_dominance(g) -> void:
	var share_min: float = float(g.bal.dom_share)
	for m in g.markets:
		var e: Dictionary = g.market_cache.get(m, {})
		var best := ""
		if not e.is_empty() and e.total > 0.0:
			for tag in e.power:
				if e.power[tag] / e.total >= share_min:
					best = tag
					break
		var old: String = g.east.dom.get(m, "")
		if best == old:
			continue
		if best == "":
			g.east.dom.erase(m)
		else:
			g.east.dom[m] = best
		var pname: String = g.provinces[m].name
		if best != "" and best == g.player:
			g.log_msg("👑 Ihr beherrscht jetzt den Markt %s: +%d %% Einnahmen dort, etwas Prestige." % [pname, int(float(g.bal.dom_bonus) * 100)], [best])
		elif old != "" and old == g.player:
			g.log_msg("📉 Ihr habt die Vorherrschaft im Markt %s verloren." % pname, [old])


# ---------------------------------------------------------------- monthly / yearly

static func monthly(g) -> void:
	_update_dominance(g)
	for m in g.east.dom:
		var n = g.nations[g.east.dom[m]]
		n.prestige += float(g.bal.dom_prestige)
	for tag in g.east.voyage.keys():
		if not g.nations[tag].alive:
			g.east.voyage.erase(tag)
			continue
		g.east.voyage[tag] -= 1
		if g.east.voyage[tag] <= 0:
			g.east.voyage.erase(tag)
			_voyage_done(g, tag)
	# dead realms lose ships and factories
	for tag in g.east.ships.keys():
		if not g.nations[tag].alive:
			g.east.ships.erase(tag)
	for id in g.east.factories.keys():
		if not g.nations[g.east.factories[id]].alive:
			g.east.factories.erase(id)
	if g.month % 3 == 0:
		for tag in g.east.known:
			if tag != g.player and g.nations[tag].alive:
				_ai(g, g.nations[tag])
	for tag in g.atlantic_tags:
		if tag != g.player and not knows(g, tag) and g.nations[tag].alive and (g.month + tag.hash()) % 12 == 0:
			_ai_voyage(g, g.nations[tag])


static func _voyage_done(g, tag: String) -> void:
	var n = g.nations[tag]
	var first: bool = not is_open(g)
	if first and g.rng.randf() > float(g.bal.cape_success):
		if tag == g.player:
			g.log_msg("☠️ Die Flotte ist in den Stürmen am Kap verschollen. Ein neuer Versuch kostet wieder Gold.", [tag])
		return
	g.east.known[tag] = true
	if first:
		g.east.cape = tag
		g.east.cape_month = g.month
		n.prestige += float(g.bal.cape_prestige)
		g.world_event("🧭 %s umsegelt das Kap der Guten Hoffnung: der Seeweg nach Indien ist offen!" % n.name, [tag])
	elif tag == g.player:
		g.log_msg("🧭 Eure Flotte hat den Seeweg nach Indien gefunden. Jetzt Ostindienfahrer ausrüsten und Faktoreien gründen.", [tag])


## Storms, pirates and wars on the long way around Africa.
static func yearly(g) -> void:
	if not is_open(g):
		return
	for tag in g.east.ships.keys():
		var s: int = ships(g, tag)
		var lost := 0
		for i in s:
			if g.rng.randf() < float(g.bal.east_loss_chance):
				lost += 1
		# enemies on the route raid each other: the weaker fleet loses ships
		for o in g.east.ships.keys():
			if o != tag and g.at_war(tag, o) and ships(g, o) > s and g.rng.randf() < 0.5:
				lost += 1
		lost = mini(lost, s)
		if lost > 0:
			g.east.ships[tag] = s - lost
			if tag == g.player:
				g.log_msg("☠️ %d Ostindienfahrer gingen auf See verloren (Stürme, Piraten, Feinde)." % lost, [tag])


# ---------------------------------------------------------------- AI

static func _ai_voyage(g, n) -> void:
	var drive: float = float(g.colonial_drive.get(n.tag, g.bal.ai_colonial_drive))
	if g.rng.randf() > drive:
		return
	if n.gold < voyage_cost(g, n.tag) * 2.0 or g.is_at_war(n.tag):
		return
	start_voyage(g, n.tag)


static func _ai(g, n) -> void:
	var tag: String = n.tag
	var reserve: float = float(g.bal.ai_colony_reserve)
	# storm enemy factories in war
	for f in FACTORIES:
		var holder: String = g.east.factories.get(f.id, "")
		if holder != "" and holder != tag and factory_block_reason(g, tag, f.id) == "":
			take_factory(g, tag, f.id)
			return
	# found the best free factory
	if n.gold > factory_cost(g, tag) + reserve:
		for f in FACTORIES:
			if not g.east.factories.has(f.id) and factory_block_reason(g, tag, f.id) == "":
				take_factory(g, tag, f.id)
				return
	# ships pay for themselves when the route is rich
	if n.gold > float(g.bal.east_ship_cost) + reserve and ship_block_reason(g, tag) == "":
		var sp: float = float(g.bal.east_ship_power)
		var gain: float = route_value(g) * (power(g, tag) + sp) / (total_power(g) + sp) - east_income(g, tag)
		gain = gain * maxf(0.0, 1.0 + g.mod(n, "trade") + g.Economy.income_bonus(g, n)) - float(g.bal.east_ship_upkeep)
		if gain * 36.0 > float(g.bal.east_ship_cost) or ships(g, tag) < int(g.bal.east_factory_ships):
			buy_ship(g, tag)
