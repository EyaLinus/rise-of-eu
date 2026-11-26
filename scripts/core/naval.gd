extends RefCounted
## Naval war, kept abstract and readable: every coastal nation has a number of ships. They patrol the
## nation's coastal seas (spread by coastal development, or all in one sea if the player stations them).
## Seas come from data/seas.json (tools/gen_seas.py).
##
## Rules in a war, per sea and war:
## - Sea control: a side with at least sea_control_ratio times the enemy's ships there rules the sea.
## - Crossings: armies cannot cross a strait of a sea the enemy rules (no landing without a fleet).
## - Blockade: coastal provinces on a sea the enemy rules are blockaded: less income for their owner,
##   sieges there go faster (no supply by sea).
## - Fleet battles: where both sides have ships, the fleets may meet; losses as on land, war score for the winner.
## Static helpers on the game `g`.

const Economy = preload("res://scripts/core/economy.gd")
const Warfare = preload("res://scripts/core/warfare.gd")

## Fleet missions (Nation.fleet_mission). Every mission but patrol costs fighting power at sea.
##   patrol   - rule the seas: full power.
##   blockade - close enemy ports: our blockades cost the enemy more income and speed up sieges more.
##   escort   - guard our merchants: blockades against us hurt half as much, some trade income in peace.
const MISSIONS := {
	"patrol": {"name": "🛡️ Seeherrschaft", "tip": "Volle Kampfkraft auf See: Meere beherrschen, Überfahrten sperren, Seeschlachten gewinnen."},
	"blockade": {"name": "⚓ Blockade", "tip": "Feindliche Häfen abriegeln: deine Blockaden kosten den Gegner mehr Einkommen und beschleunigen Belagerungen stärker. Etwas weniger Kampfkraft auf See."},
	"escort": {"name": "🚢 Handelsschutz", "tip": "Geleitzüge für die Händler: feindliche Blockaden treffen dich nur halb so hart, im Frieden etwas mehr Handelseinkommen. Etwas weniger Kampfkraft auf See."},
}


static func mission(g, tag: String) -> String:
	var m: String = g.nations[tag].fleet_mission
	return m if MISSIONS.has(m) else "patrol"


static func set_mission(g, tag: String, m: String) -> String:
	if not MISSIONS.has(m):
		return "Unbekannter Auftrag."
	g.nations[tag].fleet_mission = m
	refresh(g)
	return ""


## Blockade strength on a province: 0 = free, 1 = normal, more if the blockader is on blockade duty.
static func blockade_strength(g, pid: int) -> float:
	return float(g.blockaded.get(pid, 0.0))


static func setup(g, data: Dictionary) -> void:
	g.seas = []
	g.sea_by_id = {}
	g.province_seas = {}
	g.strait_sea = {}
	var sd: Dictionary = data.get("seas", {})
	for e in sd.get("seas", []):
		var s := {"id": str(e.id), "name": str(e.name), "center": Vector2(e.center[0], e.center[1]), "provinces": [],
				"adj": e.get("adj", [])}
		for key in e.provinces:
			var pid: int = g.key_to_pid.get(key, -1)
			if pid < 0:
				continue
			s.provinces.append(pid)
			if not g.province_seas.has(pid):
				g.province_seas[pid] = []
			g.province_seas[pid].append(s.id)
		g.seas.append(s)
		g.sea_by_id[s.id] = s
	var st: Dictionary = sd.get("straits", {})
	for k in st:
		var parts: PackedStringArray = str(k).split("|")
		var a: int = g.key_to_pid.get(parts[0], -1)
		var b: int = g.key_to_pid.get(parts[1], -1)
		if a >= 0 and b >= 0:
			g.strait_sea[Warfare.strait_key(a, b)] = str(st[k])


static func start_fleets(g) -> void:
	for tag in g.order:
		var n = g.nations[tag]
		n.ships = roundf(limit(g, tag) * float(g.bal.navy_start_share))
	refresh(g)


## Ship count for display: one decimal below 10 (fleets spread over several seas).
static func fmt(x: float) -> String:
	return ("%.1f" % x) if x < 9.95 else str(int(round(x)))


static func sea_name(g, sea: String) -> String:
	return g.sea_by_id[sea].name if g.sea_by_id.has(sea) else sea


static func sea_of_strait(g, a: int, b: int) -> String:
	return g.strait_sea.get(Warfare.strait_key(a, b), "")


## Own coastal development per sea: where a nation's fleet patrols, and how its ships spread.
static func coast_weights(g, tag: String) -> Dictionary:
	var w := {}
	for pid in g.provinces_of(tag):
		for s in g.province_seas.get(pid, []):
			w[s] = w.get(s, 0.0) + float(g.provinces[pid].dev)
	return w


static func limit(g, tag: String) -> float:
	var coast := 0.0
	var harbors := 0
	for pid in g.provinces_of(tag):
		var p = g.provinces[pid]
		if g.province_seas.has(pid):
			coast += p.dev
			harbors += Economy.level(p, "harbor")
	if coast <= 0.0:
		return 0.0
	var l: float = float(g.bal.navy_base) + coast * float(g.bal.navy_per_dev) + harbors * float(g.bal.navy_per_harbor)
	return floorf(l * maxf(0.2, 1.0 + g.mod(g.nations[tag], "naval_limit")))


static func ship_cost(g, tag: String) -> float:
	return float(g.bal.ship_cost) * maxf(0.3, 1.0 + g.mod(g.nations[tag], "ship_cost"))


static func upkeep(g, n) -> float:
	var u: float = n.ships * float(g.bal.ship_upkeep)
	return u if g.is_at_war(n.tag) else u * float(g.bal.peace_maintenance_mult)


static func build_block_reason(g, tag: String, count: int) -> String:
	var n = g.nations[tag]
	var l := limit(g, tag)
	if l <= 0.0:
		return "Du hast keine Küste."
	if n.ships + count > l + 0.001:
		return "Flottenlimit %d erreicht. Mehr Küstenentwicklung und Häfen erhöhen es." % int(l)
	if n.gold < ship_cost(g, tag) * count:
		return "Zu wenig Gold."
	if n.mil < float(g.bal.ship_mil) * count:
		return "Zu wenig Militär-Macht."
	return ""


static func build_ships(g, tag: String, count: int) -> String:
	var why := build_block_reason(g, tag, count)
	if why != "":
		return why
	var n = g.nations[tag]
	n.gold -= ship_cost(g, tag) * count
	n.mil -= float(g.bal.ship_mil) * count
	n.ships += count
	refresh(g)
	return ""


static func scrap_ships(g, tag: String, count: int) -> void:
	var n = g.nations[tag]
	n.ships = maxf(0.0, n.ships - count)
	refresh(g)


## Player choice: "" spreads the fleet over all own coastal seas, a sea id keeps it all there.
static func station(g, tag: String, sea: String) -> String:
	if sea != "" and not coast_weights(g, tag).has(sea):
		return "Keine eigene Küste an diesem Meer."
	g.nations[tag].fleet_sea = sea
	refresh(g)
	return ""


## Ships of a nation in each sea.
static func presence(g, tag: String) -> Dictionary:
	var n = g.nations[tag]
	if n.ships <= 0.0:
		return {}
	var w := coast_weights(g, tag)
	if w.is_empty():
		return {}
	if n.fleet_sea != "" and w.has(n.fleet_sea):
		return {n.fleet_sea: n.ships}
	var tot := 0.0
	for s in w:
		tot += w[s]
	var r := {}
	for s in w:
		r[s] = n.ships * w[s] / tot
	return r


static func power_mult(g, tag: String) -> float:
	var n = g.nations[tag]
	var m := maxf(0.2, 1.0 + g.mod(n, "naval") + n.tech.dip * float(g.bal.naval_per_dip_tech))
	if mission(g, tag) != "patrol":
		m *= float(g.bal.fleet_mission_power)
	return m


## Naval strength of a war side in a sea.
static func side_power(g, tags: Array, sea: String) -> float:
	var s := 0.0
	for t in tags:
		if g.nations[t].alive:
			var ships: float = float(g._fleet.get(t, {}).get(sea, 0.0))
			if ships != 0.0:  # (adding 0 * mult changes nothing, so skip the modifier lookups)
				s += ships * power_mult(g, t)
	return s


## Who rules the sea in a war: "att", "def" or "" (contested or empty).
static func control(g, w, sea: String) -> String:
	var pa := side_power(g, w.attackers, sea)
	var pd := side_power(g, w.defenders, sea)
	var ratio := float(g.bal.sea_control_ratio)
	if pa > 0.0 and pa >= pd * ratio:
		return "att"
	if pd > 0.0 and pd >= pa * ratio:
		return "def"
	return ""


## Recomputes fleet positions, sea control, blocked seas and blockades. Call after ships change.
static func refresh(g) -> void:
	g._fleet = {}
	for tag in g.order:
		if g.nations[tag].alive:
			g._fleet[tag] = presence(g, tag)
	g.sea_blocked = {}
	g.blockaded = {}
	for w in g.wars:
		for s in g.seas:
			var c := control(g, w, s.id)
			if c == "":
				continue
			var losers: Array = w.defenders if c == "att" else w.attackers
			var rulers: Array = w.attackers if c == "att" else w.defenders
			var strength := 1.0
			for t in rulers:
				if g.nations[t].alive and float(g._fleet.get(t, {}).get(s.id, 0.0)) > 0.0 and mission(g, t) == "blockade":
					strength = float(g.bal.fleet_blockade_mult)
			for t in losers:
				if not g.sea_blocked.has(t):
					g.sea_blocked[t] = {}
				g.sea_blocked[t][s.id] = true
				for pid in s.provinces:
					if g.provinces[pid].owner == t:
						g.blockaded[pid] = maxf(float(g.blockaded.get(pid, 0.0)), strength)
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive:
			continue
		var bdev := 0.0
		for pid in (g.provinces_of(tag) if not g.blockaded.is_empty() else []):
			if g.blockaded.has(pid):
				bdev += g.provinces[pid].dev * float(g.blockaded[pid])
		var escort: bool = mission(g, tag) == "escort" and n.ships >= 1.0
		if escort:
			bdev *= float(g.bal.fleet_escort_blockade)
		if bdev > 0.0 and n.dev_total > 0:
			n.set_bonus("blockade", {"income": -float(g.bal.blockade_income) * bdev / float(n.dev_total)})
		else:
			n.clear_bonus("blockade")
		# escorts pay off in peace: a share of the limit on guard duty gives trade income
		if escort and not g.is_at_war(tag) and n.ships >= limit(g, tag) * 0.25:
			n.set_bonus("escort", {"trade": float(g.bal.fleet_escort_trade)})
		else:
			n.clear_bonus("escort")


## May `tag`'s armies cross from a to b? Land steps always; straits not when the enemy rules that sea.
static func can_cross(g, tag: String, a: int, b: int) -> bool:
	if not Warfare.is_strait(g, a, b):
		return true
	var sea := sea_of_strait(g, a, b)
	return sea == "" or not g.sea_blocked.get(tag, {}).has(sea)


## Why no path exists although one would without enemy fleets ("" when the sea is not the reason).
static func crossing_block_reason(g, tag: String, from: int, to: int) -> String:
	var blocked: Dictionary = g.sea_blocked.get(tag, {})
	if blocked.is_empty() or not g.can_enter(tag, to):
		return ""
	var prev := {from: -1}
	var queue := [from]
	var head := 0
	while head < queue.size():
		var cur: int = queue[head]
		head += 1
		for a in g.provinces[cur].adj:
			if prev.has(a) or not g.can_enter(tag, a):
				continue
			prev[a] = cur
			if a == to:
				# walk back and name the first ruled sea on the way
				var c: int = a
				while prev[c] != -1:
					var sea := sea_of_strait(g, prev[c], c)
					if sea != "" and blocked.has(sea):
						return "⚓ Die feindliche Flotte beherrscht %s: keine Überfahrt. Baue Schiffe oder stationiere deine Flotte dort." % sea_name(g, sea)
					c = prev[c]
				return ""
			queue.append(a)
	return ""


static func is_blockaded(g, pid: int) -> bool:
	return g.blockaded.has(pid)


static func monthly(g) -> void:
	g.sea_fights = []  # this month's sea battles (map animation)
	refresh(g)
	for w in g.wars.duplicate():
		for s in g.seas:
			var pa := side_power(g, w.attackers, s.id)
			var pd := side_power(g, w.defenders, s.id)
			if pa <= 0.0 or pd <= 0.0 or g.rng.randf() >= float(g.bal.naval_battle_chance):
				continue
			_fleet_battle(g, w, s, pa * g.rng.randf_range(0.8, 1.2), pd * g.rng.randf_range(0.8, 1.2))
	if not g.sea_fights.is_empty():  # only battles change the fleets since the refresh above
		refresh(g)


static func _fleet_battle(g, w, s: Dictionary, pa: float, pd: float) -> void:
	var att_wins := pa >= pd
	var ratio: float = clampf(minf(pa, pd) / maxf(maxf(pa, pd), 0.01), 0.1, 1.0)
	var lose_frac: float = clampf(float(g.bal.naval_loss_lose) / sqrt(ratio), 0.1, 0.7)
	var win_frac: float = float(g.bal.naval_loss_win) * sqrt(ratio)
	var lost := 0.0
	var won_lost := 0.0
	var win_tags: Array = w.attackers if att_wins else w.defenders
	var lose_tags: Array = w.defenders if att_wins else w.attackers
	for t in win_tags + lose_tags:
		var here: float = g._fleet.get(t, {}).get(s.id, 0.0)
		if here <= 0.0:
			continue
		var gone: float = here * (lose_frac if lose_tags.has(t) else win_frac)
		g.nations[t].ships = snappedf(maxf(0.0, g.nations[t].ships - gone), 0.001)  # (exact floats survive saves)
		if lose_tags.has(t):
			lost += gone
		else:
			won_lost += gone
		g.fire_event(t, "nav_first_loss" if lose_tags.has(t) else "nav_first_win")  # once per realm
	var ws: float = lost * float(g.bal.naval_ws_per_ship)
	var cap := float(g.bal.battle_ws_cap)
	w.battle_score = clampf(w.battle_score + (ws if att_wins else -ws), -cap, cap)
	g.stats.naval_battles = g.stats.get("naval_battles", 0) + 1
	g.sea_fights.append({"sea": s.id, "win": win_tags[0], "lose": lose_tags[0], "lost": lost, "won_lost": won_lost, "month": g.month})
	var involved := win_tags + lose_tags
	if involved.has(g.player):
		g.log_msg("⚓ Seeschlacht %s: %s siegt (%.1f Schiffe des Verlierers versenkt)." % [s.name, g.nations[win_tags[0]].name, lost], [g.player])
	g._fleet = {}
	for tag in g.order:
		if g.nations[tag].alive:
			g._fleet[tag] = presence(g, tag)


## AI: keep a fleet of a share of the limit, more in war on contested seas. Cheap, every few months.
static func ai_build(g, n) -> void:
	var l := limit(g, n.tag)
	if l <= 0.0:
		return
	# mission: escort merchants in peace, close enemy ports when we rule a sea in war
	var want_m := "escort"
	if g.is_at_war(n.tag):
		want_m = "patrol"
		for w in g.wars_of(n.tag):
			var side := "att" if g.is_attacker(w, n.tag) else "def"
			for s in g.seas:
				if float(g._fleet.get(n.tag, {}).get(s.id, 0.0)) > 0.0 and control(g, w, s.id) == side:
					want_m = "blockade"
	if n.fleet_mission != want_m:
		n.fleet_mission = want_m
	var want: float = l * float(g.bal.ai_navy_share_war if g.is_at_war(n.tag) else g.bal.ai_navy_share)
	var gap: int = int(floor(want - n.ships))
	if gap <= 0:
		return
	var afford: int = int(floor((n.gold - float(g.bal.ai_navy_gold_reserve)) / ship_cost(g, n.tag)))
	var count: int = mini(gap, mini(afford, int(floor(n.mil / maxf(1.0, float(g.bal.ship_mil))))))
	# only what the budget carries: the monthly surplus must cover twice the new upkeep
	var surplus: float = n.income - n.expenses
	count = mini(count, int(floor(surplus / maxf(0.01, 2.0 * float(g.bal.ship_upkeep)))))
	if count > 0:
		build_ships(g, n.tag, count)


# ---------------------------------------------------------------- troop transport

## Armies board ships in a coastal province and sail to any coast the realm knows: over the seas it knows,
## not through a sea an enemy fleet rules. While at sea an army is out of g.armies (in g.voyages); it
## lands with the landing malus and some lost fighting power. Needs free ships (transport_regs_per_ship
## regiments per ship) and a little gold per regiment.

## Seas from a coast of `from` to a coast of `to` over known, unblocked seas ([] = no way).
static func sea_route(g, tag: String, from: int, to: int) -> Array:
	var n = g.nations[tag]
	var blocked: Dictionary = g.sea_blocked.get(tag, {})
	var goal := {}
	for s in g.province_seas.get(to, []):
		goal[s] = true
	var prev := {}
	var queue := []
	for s in g.province_seas.get(from, []):
		if n.known_seas.has(s) and not blocked.has(s):
			prev[s] = ""
			queue.append(s)
	var head := 0
	while head < queue.size():
		var cur: String = queue[head]
		head += 1
		if goal.has(cur):
			var route := [cur]
			while prev[route[0]] != "":
				route.push_front(prev[route[0]])
			return route
		for nb in g.sea_by_id[cur].adj:
			if prev.has(nb) or not n.known_seas.has(nb) or blocked.has(nb) or not g.sea_by_id.has(nb):
				continue
			prev[nb] = cur
			queue.append(nb)
	return []


## Months at sea: the way from the port over every sea's centre to the landing site.
static func transport_months(g, from: int, to: int, route: Array) -> int:
	var pts := [g.provinces[from].center]
	if route.size() > 1:
		for s in route:
			pts.append(g.sea_by_id[s].center)
	pts.append(g.provinces[to].center)
	var d := 0.0
	for i in pts.size() - 1:
		d += pts[i].distance_to(pts[i + 1])
	return maxi(int(g.bal.transport_min_months), ceili(d / float(g.bal.transport_px_per_month)))


static func ships_needed(g, regs: float) -> int:
	return maxi(1, ceili(regs / float(g.bal.transport_regs_per_ship)))


## Ships not busy carrying another army.
static func free_ships(g, tag: String) -> float:
	var busy := 0.0
	for v in g.voyages:
		if v.army.owner == tag:
			busy += ships_needed(g, v.army.regs)
	return g.nations[tag].ships - busy


static func transport_cost(g, a) -> float:
	return roundf(a.regs * float(g.bal.transport_cost_per_reg))


static func is_port(g, tag: String, pid: int) -> bool:
	if not g.province_seas.has(pid):
		return false
	var c: String = g.provinces[pid].controller
	return c == tag or g.is_allied(tag, c)


static func transport_block_reason(g, a, to: int) -> String:
	var tag: String = a.owner
	if Warfare.in_battle(g, a):
		return "Die Armee steckt in einer Schlacht."
	if not g.province_seas.has(a.pid):
		return "Einschiffen geht nur in einer Küstenprovinz: erst an die Küste marschieren."
	if not is_port(g, tag, a.pid):
		return "Einschiffen nur in einem eigenen oder verbündeten Hafen."
	if to == a.pid or to < 0:
		return "Ungültiges Ziel."
	if not g.province_seas.has(to):
		return "Dort gibt es keine Küste zum Anlanden."
	if not g.Colonial.knows(g, tag, to):
		return "Unbekanntes Land: erst erkunden."
	if not g.can_enter(tag, to):
		return "Dort dürfen wir nicht landen: kein eigenes Land, kein Verbündeter, kein Krieg und kein Durchmarschrecht."
	if sea_route(g, tag, a.pid, to).is_empty():
		if not g.sea_blocked.get(tag, {}).is_empty():
			return "⚓ Kein freier Seeweg: feindliche Flotten beherrschen die Meere dazwischen."
		return "Kein bekannter Seeweg dorthin."
	var need := ships_needed(g, a.regs)
	if free_ships(g, tag) < need:
		return "Zu wenig freie Schiffe: %d nötig (1 Schiff je %d Regimenter), %s frei." % [need, int(g.bal.transport_regs_per_ship), fmt(maxf(0.0, free_ships(g, tag)))]
	if g.nations[tag].gold < transport_cost(g, a):
		return "Zu wenig Gold (%d)." % int(transport_cost(g, a))
	return ""


## Sends army `a` over sea to `to`. Returns "" or the reason it cannot sail.
static func transport(g, a, to: int) -> String:
	var why := transport_block_reason(g, a, to)
	if why != "":
		return why
	var route := sea_route(g, a.owner, a.pid, to)
	var months := transport_months(g, a.pid, to, route)
	g.nations[a.owner].gold -= transport_cost(g, a)
	g.armies.erase(a)
	g.armies_dirty()
	a.target = -1
	a.path = []
	a.move = 0.0
	g.voyages.append({"army": a, "from": a.pid, "to": to, "left": months, "total": months, "route": route})
	g.stats.transports = int(g.stats.get("transports", 0)) + 1
	if a.owner == g.player:
		g.log_msg("⛵ Deine Armee (%d Regimenter) schifft sich in %s ein: Landung in %s in %d Monaten." % [int(a.regs), g.provinces[a.pid].name, g.provinces[to].name, months], [a.owner])
	return ""


## Map points of a voyage (port, the seas on the way, landing site) and the share already sailed.
static func voyage_points(g, v: Dictionary) -> Array:
	var pts := [g.provinces[int(v.from)].center]
	var route: Array = v.get("route", [])
	if route.size() > 1:
		for s in route:
			if g.sea_by_id.has(s):
				pts.append(g.sea_by_id[s].center)
	pts.append(g.provinces[int(v.to)].center)
	return pts


static func voyage_done(v: Dictionary) -> float:
	return clampf(1.0 - float(v.left) / maxf(1.0, float(v.total)), 0.0, 1.0)


## Voyage of army `a` (or {} when it is not at sea).
static func voyage_of(g, a) -> Dictionary:
	for v in g.voyages:
		if v.army == a:
			return v
	return {}


static func voyages_tick(g) -> void:
	for v in g.voyages.duplicate():
		var a = v.army
		if not g.nations[a.owner].alive:
			g.voyages.erase(v)
			continue
		v.left = int(v.left) - 1
		if int(v.left) > 0:
			continue
		g.voyages.erase(v)
		var at: int = int(v.to)
		if not g.can_enter(a.owner, at):  # peace or a lost alliance while at sea: back to the port
			at = int(v.from) if g.can_enter(a.owner, int(v.from)) else g.nations[a.owner].capital
		a.pid = at
		a.landing = at == int(v.to)
		a.power = maxf(0.0, a.power * (1.0 - float(g.bal.transport_power_loss)))
		g.armies.append(a)
		g.armies_dirty()
		if a.owner == g.player:
			g.log_msg("⚓ Deine Armee landet in %s." % g.provinces[at].name, [a.owner])


## AI: an army with nothing to reach by land sails to an enemy coast (or first marches to a port).
static func ai_transport(g, a, enemies: Array, enemy_power: Dictionary, my_power: float) -> bool:
	var tag: String = a.owner
	if tag == g.player or a.regs < 4.0 or g.nations[tag].ships < 1.0 or g.rng.randf() > 0.35:
		return false
	var best := -1
	var best_v := -1e9
	for e in enemies:
		for pid in g.provinces_of(e):
			var p = g.provinces[pid]
			if not g.province_seas.has(pid) or not enemies.has(p.controller) or enemy_power.get(pid, 0.0) > my_power * 0.8:
				continue
			var v: float = p.dev + (10.0 if g.nations[e].capital == pid else 0.0) + g.rng.randf() * 3.0
			if v > best_v and g.Colonial.knows(g, tag, pid):
				best_v = v
				best = pid
	if best < 0:
		return false
	if not is_port(g, tag, a.pid):
		var port: int = -1
		var bd := 1e9
		for pid in g.provinces_of(tag):
			if is_port(g, tag, pid) and g.provinces[pid].controller == tag:
				var d: float = g.provinces[pid].center.distance_to(g.provinces[a.pid].center)
				if d < bd and not g.find_path(tag, a.pid, pid).is_empty():
					bd = d
					port = pid
		if port >= 0 and port != a.target:
			g.move_army(a, port)
			return true
		return false
	return transport(g, a, best) == ""
