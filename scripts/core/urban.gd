extends RefCounted
## Town and country: every province is either rural (Land) or urban (Stadt).
## Cities pay more tax, hold more trade power and one extra building slot, but raise fewer soldiers
## and are a little restless; the countryside raises more men and stays calm. Each side also produces
## "its" goods better (bal.urban_goods are city goods, everything else is country produce), and the
## share of cities in the world shifts demand: more cities make cloth, wine and metals dearer and
## grain, wool and timber cheaper. The owner can turn a province into a city (gold, takes months) or
## back into countryside. Static helpers on the game `g` (untyped to avoid a cyclic preload).


## Starting cities: developed provinces, market centres and the capitals of the great powers.
static func setup(g) -> void:
	for p in g.provinces:
		p.urban = default_urban(g, p)
		p.urban_months = 0
	g.urban_start = [count(g, false), count(g, true)]


static func default_urban(g, p) -> bool:
	if p.owner == "NAT":  # uncolonized native land has no towns
		return false
	if p.dev >= int(g.bal.urban_start_dev) or g.markets.has(p.id):
		return true
	var n = g.nations.get(p.owner)
	return n != null and n.major and n.capital == p.id


static func count(g, urban: bool) -> int:
	var c := 0
	for p in g.provinces:
		if p.urban == urban:
			c += 1
	return c


## Cities of one realm.
static func count_of(g, tag: String) -> int:
	var c := 0
	for pid in g.provinces_of(tag):
		if g.provinces[pid].urban:
			c += 1
	return c


static func is_city_good(g, good: String) -> bool:
	return g.bal.urban_goods.has(good)


## Settlement tier: 0 Land, 1 Stadt, 2 Großstadt (dev >= urban_big_dev), 3 Metropole (dev >= urban_metro_dev).
## Derived from development, so it needs no save field.
static func tier(g, p) -> int:
	if not p.urban:
		return 0
	if p.dev >= int(g.bal.urban_metro_dev):
		return 3
	if p.dev >= int(g.bal.urban_big_dev):
		return 2
	return 1


static func tier_name(t: int) -> String:
	return ["Land", "Stadt", "Großstadt", "Metropole"][clampi(t, 0, 3)]


static func name(p) -> String:
	return "Stadt" if p.urban else "Land"


## Progress of countryside towards becoming a city by itself, 0..1 (development / urban_auto_dev).
## Cities show their progress towards the next tier instead.
static func progress(g, p) -> float:
	if not p.urban:
		return clampf(float(p.dev) / float(maxi(1, int(g.bal.urban_auto_dev))), 0.0, 1.0)
	var t := tier(g, p)
	if t >= 3:
		return 1.0
	var lo: int = int(g.bal.urban_min_dev) if t == 1 else int(g.bal.urban_big_dev)
	var hi: int = int(g.bal.urban_big_dev) if t == 1 else int(g.bal.urban_metro_dev)
	return clampf(float(p.dev - lo) / float(maxi(1, hi - lo)), 0.0, 1.0)


## Development points still missing for the next step (0 at the top tier).
static func next_dev(g, p) -> int:
	if not p.urban:
		return maxi(0, int(g.bal.urban_auto_dev) - p.dev)
	var t := tier(g, p)
	if t >= 3:
		return 0
	return maxi(0, (int(g.bal.urban_big_dev) if t == 1 else int(g.bal.urban_metro_dev)) - p.dev)


## Local effects (same keys as building effects, merged into p.loc by Economy.refresh_local).
static func local_effects(g, p) -> Dictionary:
	var out: Dictionary = (g.bal.urban_local if p.urban else g.bal.rural_local).duplicate()
	if is_city_good(g, p.good) == p.urban:
		out["production"] = float(out.get("production", 0.0)) + float(g.bal.goods_fit_production)
	var t := tier(g, p)
	p.tier_seen = t
	if t >= 2:  # Großstadt / Metropole: on top of the plain city
		var extra: Dictionary = g.bal.urban_tier_local[str(t)]
		for k in extra:
			out[k] = float(out.get(k, 0.0)) + float(extra[k])
	return out


## Extra building slots of a city.
static func slot_bonus(g, p) -> int:
	if not p.urban:
		return 0
	return int(g.bal.urban_slots) + (int(g.bal.urban_tier_slots[tier(g, p) - 2]) if tier(g, p) > 1 else 0)


## Demand multiplier of a good from the world's share of cities (1.0 at the start).
## `counts` (optional): [rural, urban] province counts, precomputed for a loop over all goods.
static func demand_mult(g, good: String, counts: Array = []) -> float:
	if g.urban_start.is_empty():
		return 1.0
	var city := is_city_good(g, good)
	var start: int = int(g.urban_start[1 if city else 0])
	if start <= 0:
		return 1.0
	var now: int = int(counts[1 if city else 0]) if counts.size() == 2 else count(g, city)
	return maxf(0.5, 1.0 + float(g.bal.urban_demand_shift) * (float(now) / float(start) - 1.0))


static func change_cost(g, p, to_urban: bool) -> float:
	var n = g.nations[p.owner]
	var m: float = maxf(0.3, 1.0 + g.mod(n, "build_cost"))
	if to_urban:
		return round((float(g.bal.urban_cost_base) + float(g.bal.urban_cost_per_dev) * p.dev) * m)
	return round(float(g.bal.rural_cost) * m)


## Months a change takes; a more developed province becomes a city faster (urban_months_per_dev
## fewer per point above urban_min_dev, never under urban_months_min).
static func change_months(g, to_urban: bool, p = null) -> int:
	if not to_urban:
		return int(g.bal.rural_months)
	var m: int = int(g.bal.urban_months)
	if p != null:
		m -= int(g.bal.get("urban_months_per_dev", 0)) * maxi(0, int(p.dev) - int(g.bal.urban_min_dev))
	return maxi(int(g.bal.get("urban_months_min", m)), m)


## "" when `tag` may turn province `pid` into a city (to_urban) or back into countryside.
static func block_reason(g, tag: String, pid: int, to_urban: bool) -> String:
	var p = g.provinces[pid]
	if p.owner != tag:
		return "Nicht deine Provinz."
	if p.urban == to_urban:
		return "Ist schon eine Stadt." if to_urban else "Ist schon Land."
	if p.urban_months > 0:
		return "Der Umbau läuft noch (%d Monate)." % p.urban_months
	if p.controller != tag:
		return "Die Provinz ist besetzt."
	if to_urban and p.dev < int(g.bal.urban_min_dev):
		return "Braucht Entwicklung %d (hat %d)." % [int(g.bal.urban_min_dev), p.dev]
	if to_urban and p.core_months > 0:
		return "Erst integrieren."
	var n = g.nations[tag]
	var c := change_cost(g, p, to_urban)
	if n.gold < c:
		return "Zu wenig Gold (%d benötigt)." % int(c)
	return ""


## Pays and starts the change; the province flips when the months are up (tick).
static func change(g, tag: String, pid: int, to_urban: bool) -> String:
	var why := block_reason(g, tag, pid, to_urban)
	if why != "":
		return why
	var p = g.provinces[pid]
	g.nations[tag].gold -= change_cost(g, p, to_urban)
	p.urban_months = change_months(g, to_urban, p)
	return ""


## Best province of `tag` to become a city next (most developed, city goods and coasts preferred),
## or -1. Only provinces that may change now (block_reason without the gold check).
static func best_candidate(g, tag: String) -> int:
	var best := -1
	var best_v := -1.0
	for pid in g.provinces_of(tag):
		var p = g.provinces[pid]
		if p.urban or p.urban_months > 0 or p.owner != tag or p.controller != tag or p.core_months > 0:
			continue
		if p.dev < int(g.bal.urban_min_dev):
			continue
		var v: float = p.dev + (4.0 if is_city_good(g, p.good) else 0.0) + (3.0 if p.coastal else 0.0)
		if v > best_v:
			best_v = v
			best = pid
	return best


## Share of `tag`'s provinces that are cities or becoming one.
static func city_share(g, tag: String) -> float:
	var owned: Array = g.provinces_of(tag)
	if owned.is_empty():
		return 0.0
	var c := 0
	for pid in owned:
		if g.provinces[pid].urban or g.provinces[pid].urban_months > 0:
			c += 1
	return float(c) / float(owned.size())


## Player autobuild: starts the best city (one per month, before buildings) while the treasury stays
## at or above the reserve and fewer than `autobuild_urban_share` of the provinces are cities.
## Returns the province or -1.
static func autobuild(g, n) -> int:
	if not n.autobuild or g.is_at_war(n.tag):
		return -1
	if city_share(g, n.tag) >= float(g.bal.get("autobuild_urban_share", 0.5)):
		return -1
	var pid := best_candidate(g, n.tag)
	if pid < 0:
		return -1
	var p = g.provinces[pid]
	if n.gold - change_cost(g, p, true) < n.autobuild_reserve or change(g, n.tag, pid, true) != "":
		return -1
	g.log_msg("🤖 Autobau: %s wird zur Stadt (%d Monate)." % [p.name, p.urban_months], [n.tag])
	return pid


## Yearly: countryside that has grown to urban_auto_dev becomes a city by itself (people move in, no
## gold needed), as long as the owner holds it in peace.
static func auto_grow(g) -> void:
	var need: int = int(g.bal.get("urban_auto_dev", 0))
	if need <= 0:
		return
	for p in g.provinces:
		if p.urban or p.urban_months > 0 or p.dev < need or p.owner == "NAT" or p.controller != p.owner or p.core_months > 0:
			continue
		var n = g.nations.get(p.owner)
		if n == null or not n.alive or g.is_at_war(n.tag):
			continue
		p.urban = true
		g.Economy.refresh_local(g, p)
		if n.tag == g.player:
			g.log_msg("🏙️ %s ist von selbst zur Stadt gewachsen (Entwicklung %d)." % [p.name, p.dev], [n.tag])


## Yearly: cities whose development crossed a tier border get their new local effects.
static func refresh_tiers(g) -> void:
	for p in g.provinces:
		var t := tier(g, p)
		if t != p.tier_seen:
			var up: bool = t > p.tier_seen
			g.Economy.refresh_local(g, p)  # sets p.tier_seen
			if up and t >= 2 and p.owner == g.player:
				g.log_msg("🏙️ %s ist jetzt %s%s." % [p.name, "eine Metropole" if t == 3 else "eine Großstadt", ""], [p.owner])


## Yearly: cities grow by themselves now and then (markets and harbors draw people), up to the soft cap,
## as long as the owner holds them in peace. Countryside only grows when the owner develops it.
static func yearly(g) -> void:
	auto_grow(g)
	refresh_tiers(g)
	var cap: int = int(g.bal.dev_soft_cap)
	for p in g.provinces:
		if not p.urban or p.dev >= cap or p.controller != p.owner or p.siege > 0.0:
			continue
		var n = g.nations[p.owner]
		if not n.alive or g.is_at_war(n.tag):
			continue
		var chance: float = float(g.bal.city_growth_chance) * (1.0 + g.mod(n, "city_growth"))
		if p.market == p.id:
			chance *= 1.5
		if p.buildings.get("harbor", 0) > 0:
			chance *= 1.25
		if g.rng.randf() < chance:
			p.dev += 1
			g._update_cached(n)
			if n.tag == g.player:
				g.log_msg("🏙️ %s wächst: Zuzug vom Land bringt +1 Entwicklung." % p.name, [n.tag])


## Monthly for every realm: finishes running changes, lets the AI found cities now and then.
static func tick(g, n) -> void:
	for pid in g.provinces_of(n.tag):
		var p = g.provinces[pid]
		if p.urban_months <= 0:
			continue
		p.urban_months -= 1
		if p.urban_months == 0:
			p.urban = not p.urban
			g.Economy.refresh_local(g, p)
			if n.tag == g.player:
				if p.urban:
					g.log_msg("🏙️ %s ist jetzt eine Stadt: mehr Steuern, Handel und ein Bauplatz, weniger Mannschaften." % p.name, [n.tag])
				else:
					g.log_msg("🌾 %s ist wieder Land: mehr Mannschaften und Ruhe, weniger Steuern." % p.name, [n.tag])
			g.fire_event(n.tag, "urb_city_founded" if p.urban else "urb_back_to_land")
	if n.tag != g.player and (g.month + n.tag.hash()) % 12 == 5:
		ai_found_city(g, n)


## AI: a city for about every `ai_urban_share` of its provinces, the most developed candidate first,
## provinces that produce city goods preferred; only from a comfortable treasury.
static func ai_found_city(g, n) -> void:
	if g.is_at_war(n.tag):
		return
	var owned: Array = g.provinces_of(n.tag)
	var cities := 0
	for pid in owned:
		if g.provinces[pid].urban or g.provinces[pid].urban_months > 0:
			cities += 1
	if float(cities) >= ceilf(owned.size() * float(g.bal.ai_urban_share)):
		return
	var best := -1
	var best_v := -1.0
	for pid in owned:
		var p = g.provinces[pid]
		if p.urban or block_reason(g, n.tag, pid, true) != "":
			continue
		var v: float = p.dev + (4.0 if is_city_good(g, p.good) else 0.0) + (3.0 if p.coastal else 0.0)
		if v > best_v:
			best_v = v
			best = pid
	if best < 0:
		return
	var c := change_cost(g, g.provinces[best], true)
	if n.gold < c + float(g.bal.ai_develop_reserve):
		return
	change(g, n.tag, best, true)
