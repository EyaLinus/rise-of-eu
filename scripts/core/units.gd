extends RefCounted
## Unit types, nation unique units and army templates. Static helpers on the game `g`.
##
## An army is still one number of regiments; its `mix` says which share of them is infantry,
## cavalry and artillery ({} = the nation's standard mix, which follows military tech like the AI's).
## Battles (Warfare) weigh each side by phase: the first rounds are the fire fight (artillery and
## infantry), then melee (cavalry hits hardest, but not in rough terrain); cavalry also drives the
## pursuit. Artillery speeds up sieges. Costs and upkeep scale with the mix relative to the standard
## mix, so an AI army with the standard mix costs exactly what it did before unit types existed.
## Some nations field a unique unit (data/units.json, tools/content/units.py) that improves one type.
## Players keep up to MAX_TEMPLATES named templates (Nation.templates) for recruiting and refitting.

const TYPES := ["inf", "cav", "art"]
const MAX_TEMPLATES := 6
const FIRE_ROUNDS := 2  # battle rounds of fire fight before melee
const ROUGH := ["forest", "hills", "mountains", "marsh"]
const PRESETS := [
	["Feldheer", {"inf": 0.6, "cav": 0.3, "art": 0.1}],
	["Reiterheer", {"inf": 0.4, "cav": 0.6, "art": 0.0}],
	["Belagerungsheer", {"inf": 0.6, "cav": 0.1, "art": 0.3}],
	["Fußvolk", {"inf": 0.9, "cav": 0.1, "art": 0.0}],
]


static func setup(g, data: Dictionary) -> void:
	g.units_def = data.get("units", {})
	if g.units_def == null or g.units_def.is_empty():
		g.units_def = {"types": {"inf": {"name": "Infanterie", "emoji": "🛡️", "fire": 1.0, "shock": 1.0, "pursuit": 0.5, "cost": 1.0}},
				"era_mix": [[0, {"inf": 1.0}]], "max_share": {}, "art_tech": 99, "unique": {}}


static func type_def(g, t: String) -> Dictionary:
	return g.units_def.types.get(t, {})


static func type_name(g, t: String) -> String:
	var d := type_def(g, t)
	return "%s %s" % [d.get("emoji", ""), d.get("name", t)]


static func unique(g, tag: String) -> Dictionary:
	return g.units_def.unique.get(tag, {})


static func art_ok(g, tag: String) -> bool:
	return int(g.nations[tag].tech.mil) >= int(g.units_def.get("art_tech", 3))


## The standard mix of a nation at its military tech (AI armies, the "Standard" template).
static func standard_mix(g, tag: String) -> Dictionary:
	var lvl: int = int(g.nations[tag].tech.mil)
	var best: Dictionary = g.units_def.era_mix[0][1]
	for e in g.units_def.era_mix:
		if lvl >= int(e[0]):
			best = e[1]
	return best


## Mix an army fights with: its own, or the nation's standard one.
static func mix_of(g, a) -> Dictionary:
	return a.mix if not a.mix.is_empty() else standard_mix(g, a.owner)


## Clamps shares to the limits (artillery needs tech), infantry takes the rest; returns a new dictionary.
static func clean(g, tag: String, m: Dictionary) -> Dictionary:
	var mx: Dictionary = g.units_def.get("max_share", {})
	var cav: float = clampf(float(m.get("cav", 0.0)), 0.0, float(mx.get("cav", 1.0)))
	var art: float = clampf(float(m.get("art", 0.0)), 0.0, float(mx.get("art", 1.0))) if art_ok(g, tag) else 0.0
	if cav + art > 1.0:
		art = 1.0 - cav
	return {"inf": snappedf(1.0 - cav - art, 0.01), "cav": snappedf(cav, 0.01), "art": snappedf(art, 0.01)}


## A type's stat with the nation's unique unit bonus.
static func stat(g, tag: String, t: String, key: String) -> float:
	var v := float(type_def(g, t).get(key, 0.0))
	var u := unique(g, tag)
	if not u.is_empty() and u.type == t:
		v *= 1.0 + float(u.bonus.get(key, 0.0))
	return v


static func _mix_value(g, tag: String, m: Dictionary, key: String, rough: bool) -> float:
	var v := 0.0
	for t in m:
		var s := stat(g, tag, t, key)
		if rough and key == "shock":
			s *= float(type_def(g, t).get("rough", 1.0))
		v += float(m[t]) * s
	return v


## Reference value of a stat: the plain standard mix at tech 0 (no unique bonus).
static func _base(g, key: String) -> float:
	var v := 0.0
	var m: Dictionary = g.units_def.era_mix[0][1]
	for t in m:
		v += float(m[t]) * float(type_def(g, t).get(key, 0.0))
	return maxf(v, 0.01)


static func is_fire(_g, rnd: int) -> bool:
	return rnd < FIRE_ROUNDS


## Battle multiplier of an army in round `rnd` at `pid`: its mix in that phase against the reference mix.
static func battle_mult(g, a, rnd: int, pid: int) -> float:
	var key := "fire" if is_fire(g, rnd) else "shock"
	var rough: bool = ROUGH.has(str(g.provinces[pid].terrain))
	return _mix_value(g, a.owner, mix_of(g, a), key, rough) / _base(g, key)


## Pursuit strength of the winning side (1.0 = reference mix), weighted by regiments.
static func pursuit_mult(g, arms: Array) -> float:
	var s := 0.0
	var r := 0.0
	for a in arms:
		s += a.regs * _mix_value(g, a.owner, mix_of(g, a), "pursuit", false)
		r += a.regs
	if r <= 0.0:
		return 1.0
	return clampf(s / r / _base(g, "pursuit"), 0.3, 2.0)


## Siege speed from artillery (1.0 without guns).
static func siege_mult(g, arms: Array) -> float:
	var s := 0.0
	var r := 0.0
	for a in arms:
		var m := mix_of(g, a)
		for t in m:
			s += a.regs * float(m[t]) * (float(type_def(g, t).get("siege", 1.0)) - 1.0)
		r += a.regs
	return 1.0 + (s / r if r > 0.0 else 0.0)


## Gold cost factor of a mix against the nation's standard mix (1.0 for the standard mix).
static func cost_mult(g, tag: String, m: Dictionary) -> float:
	if m.is_empty():
		return 1.0
	var c := 0.0
	var b := 0.0
	var std := standard_mix(g, tag)
	for t in TYPES:
		var k := float(type_def(g, t).get("cost", 1.0))
		c += float(m.get(t, 0.0)) * k
		b += float(std.get(t, 0.0)) * k
	return c / maxf(b, 0.01)


## Regiments weighted by their cost (upkeep): equals the plain count when all armies use the standard mix.
static func upkeep_regs(g, tag: String) -> float:
	var s := 0.0
	for a in g.own_armies(tag):
		s += a.regs * cost_mult(g, tag, a.mix)
	for v in g.voyages:
		if v.army.owner == tag:
			s += v.army.regs * cost_mult(g, tag, v.army.mix)
	return s


## Adds `count` fresh regiments with mix `m` ({} = standard) to army `a`, blending the shares.
static func blend(g, a, count: float, m: Dictionary) -> void:
	if a.mix.is_empty() and m.is_empty():
		return
	var old := mix_of(g, a)
	var add: Dictionary = m if not m.is_empty() else standard_mix(g, a.owner)
	var tot: float = a.regs + count
	if tot <= 0.0:
		return
	var r := {}
	for t in TYPES:
		r[t] = (float(old.get(t, 0.0)) * a.regs + float(add.get(t, 0.0)) * count) / tot
	a.mix = clean(g, a.owner, r)


static func mix_text(g, m: Dictionary) -> String:
	var parts := []
	for t in TYPES:
		if float(m.get(t, 0.0)) > 0.0:
			parts.append("%s %d %%" % [type_def(g, t).get("emoji", t), int(round(float(m[t]) * 100.0))])
	return " ".join(parts)


# ---------------------------------------------------------------- templates (player)

static func template_mix(g, tag: String, idx: int) -> Dictionary:
	var ts: Array = g.nations[tag].templates
	if idx < 0 or idx >= ts.size():
		return {}
	return clean(g, tag, ts[idx])


static func template_name(g, tag: String, idx: int) -> String:
	var ts: Array = g.nations[tag].templates
	return str(ts[idx].name) if idx >= 0 and idx < ts.size() else "Standard"


static func add_template(g, tag: String, name: String, m: Dictionary) -> String:
	var n = g.nations[tag]
	if n.templates.size() >= MAX_TEMPLATES:
		return "Höchstens %d Vorlagen." % MAX_TEMPLATES
	var t := clean(g, tag, m)
	t["name"] = name
	n.templates.append(t)
	return ""


static func remove_template(g, tag: String, idx: int) -> void:
	var n = g.nations[tag]
	if idx < 0 or idx >= n.templates.size():
		return
	n.templates.remove_at(idx)
	if n.recruit_tmpl == idx:
		n.recruit_tmpl = -1
	elif n.recruit_tmpl > idx:
		n.recruit_tmpl -= 1
	for a in g.armies:
		if a.owner == tag:
			if a.tmpl == idx:
				a.tmpl = -1
			elif a.tmpl > idx:
				a.tmpl -= 1


## Changes one type's share of a template by `delta` (infantry fills the rest).
static func adjust_template(g, tag: String, idx: int, t: String, delta: float) -> void:
	var ts: Array = g.nations[tag].templates
	if idx < 0 or idx >= ts.size() or t == "inf":
		return
	var m: Dictionary = ts[idx].duplicate()
	m[t] = float(m.get(t, 0.0)) + delta
	var c := clean(g, tag, m)
	for k in TYPES:
		ts[idx][k] = c[k]


## Gold to refit army `a` to template `idx` (-1 = standard): a fee per regiment plus dearer troops.
static func refit_cost(g, a, idx: int) -> float:
	var target := template_mix(g, a.owner, idx)
	var diff: float = maxf(0.0, cost_mult(g, a.owner, target) - cost_mult(g, a.owner, a.mix))
	return a.regs * g.regiment_cost(a.owner) * (float(g.bal.refit_fee) + diff)


static func refit_block_reason(g, a, idx: int) -> String:
	var p = g.provinces[a.pid]
	if p.controller != a.owner and not g.is_allied(a.owner, p.controller):
		return "Umrüsten nur auf eigenem oder verbündetem Gebiet."
	if g.Warfare.in_battle(g, a):
		return "Die Armee steckt in einer Schlacht."
	if g.nations[a.owner].gold < refit_cost(g, a, idx):
		return "Zu wenig Gold (%d benötigt)." % int(ceil(refit_cost(g, a, idx)))
	return ""


## Refits army `a` to template `idx`: pays the cost, the new mix applies at once, the drill costs morale.
static func refit(g, a, idx: int) -> String:
	var why := refit_block_reason(g, a, idx)
	if why != "":
		return why
	g.nations[a.owner].gold -= refit_cost(g, a, idx)
	a.mix = template_mix(g, a.owner, idx)
	a.tmpl = idx
	a.power = maxf(0.0, a.power - g.power_max(a.owner) * float(g.bal.refit_power_loss))
	return ""
