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


static func is_city_good(g, good: String) -> bool:
	return g.bal.urban_goods.has(good)


static func name(p) -> String:
	return "Stadt" if p.urban else "Land"


## Local effects (same keys as building effects, merged into p.loc by Economy.refresh_local).
static func local_effects(g, p) -> Dictionary:
	var out: Dictionary = (g.bal.urban_local if p.urban else g.bal.rural_local).duplicate()
	if is_city_good(g, p.good) == p.urban:
		out["production"] = float(out.get("production", 0.0)) + float(g.bal.goods_fit_production)
	return out


## Extra building slots of a city.
static func slot_bonus(g, p) -> int:
	return int(g.bal.urban_slots) if p.urban else 0


## Demand multiplier of a good from the world's share of cities (1.0 at the start).
static func demand_mult(g, good: String) -> float:
	if g.urban_start.is_empty():
		return 1.0
	var city := is_city_good(g, good)
	var start: int = int(g.urban_start[1 if city else 0])
	if start <= 0:
		return 1.0
	var now: int = count(g, city)
	return maxf(0.5, 1.0 + float(g.bal.urban_demand_shift) * (float(now) / float(start) - 1.0))


static func change_cost(g, p, to_urban: bool) -> float:
	var n = g.nations[p.owner]
	var m: float = maxf(0.3, 1.0 + g.mod(n, "build_cost"))
	if to_urban:
		return round((float(g.bal.urban_cost_base) + float(g.bal.urban_cost_per_dev) * p.dev) * m)
	return round(float(g.bal.rural_cost) * m)


static func change_months(g, to_urban: bool) -> int:
	return int(g.bal.urban_months if to_urban else g.bal.rural_months)


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
	p.urban_months = change_months(g, to_urban)
	return ""


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
			g.fire_event(n.tag, "urban_city_founded" if p.urban else "urban_back_to_land")
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
