extends RefCounted
## Stability: a main stat from -100 to +100 per realm (Nation.stability).
## It drifts slowly toward a target (base, laws, rank) that war exhaustion, unrest, debt and uncored land pull down;
## one-off shocks (succession, lost wars, revolts, faith changes, events) move it at once, and the realm can buy
## stability with administration. Positive stability: more taxes and manpower, less unrest, cheaper techs;
## negative stability: all of that turns against the realm. Effects go through the bonus source "stability".
## Static helpers on the game `g` (like Progression), balance keys stab_* in data/balance.json.

## Display levels (icons assets/art/icons/stab_<i>.png): lower bound, name, colour hint
const LEVELS := [
	{"min": -100.0, "name": "Krise", "icon": "stab_0", "kind": "bad"},
	{"min": -50.0, "name": "Unruhig", "icon": "stab_1", "kind": "bad"},
	{"min": 0.0, "name": "Stabil", "icon": "stab_2", "kind": ""},
	{"min": 50.0, "name": "Blütezeit", "icon": "stab_3", "kind": "good"},
]


static func level(v: float) -> int:
	var r := 0
	for i in LEVELS.size():
		if v >= float(LEVELS[i].min):
			r = i
	return r


static func level_name(v: float) -> String:
	return LEVELS[level(v)].name


static func icon(v: float) -> String:
	return LEVELS[level(v)].icon


## Instant change (events, wars, successions); clamped to -100..100.
static func add(g, tag: String, v: float, why: String = "") -> void:
	var n = g.nations[tag]
	var before: float = n.stability
	n.stability = clampf(n.stability + v, -100.0, 100.0)
	refresh_bonus(g, n)
	if tag == g.player and why != "" and absf(n.stability - before) >= 1.0:
		g.log_msg("%s %s: Stabilität %+d (jetzt %d)." % ["⚖️", why, roundi(n.stability - before), roundi(n.stability)], [tag])
	if before > -50.0 and n.stability <= -50.0 and tag == g.player:
		g.log_msg("🔥 Staatskrise! Die Stabilität ist auf %d gefallen: Unruhe steigt, Steuern brechen ein." % roundi(n.stability), [tag])


## Where stability drifts to, part by part (UI tooltip); "total" is the sum, clamped to -100..100.
static func target_parts(g, n) -> Dictionary:
	var b: Dictionary = g.bal
	var r := {"base": float(b.stab_base_target), "policy": g.mod(n, "stability") * 100.0}
	r.war = -n.we * float(b.stab_per_we)
	r.debt = -float(b.stab_debt) if n.gold < 0.0 else 0.0
	r.debt -= float(b.stab_per_loan) * n.loans.size()
	var own: Array = g.provinces_of(n.tag)
	var uncored := 0
	for pid in own:
		if g.provinces[pid].core_months > 0:
			uncored += 1
	r.uncored = -float(b.stab_uncored) * (float(uncored) / maxf(1.0, own.size()))
	r.ae = -maxf(0.0, n.ae - float(b.ae_coalition_threshold) * 0.5) * float(b.stab_per_ae)
	r.diplo = -float(b.stab_diplo_over) * g.diplo_over(n.tag)
	var t: float = 0.0
	for k in r:
		t += r[k]
	r.total = clampf(t, -100.0, 100.0)
	return r


static func target(g, n) -> float:
	return target_parts(g, n).total


## Monthly drift toward the target (stab_drift points a month, half as fast upward), then refresh effects.
static func monthly(g, n) -> void:
	var t := target(g, n)
	var step: float = float(g.bal.stab_drift)
	if n.stability < t:
		n.stability = minf(t, n.stability + step * 0.5)
	elif n.stability > t:
		n.stability = maxf(t, n.stability - step)
	refresh_bonus(g, n)
	if n.tag != g.player and (g.month + n.tag.hash()) % 6 == 0:
		_ai(g, n)


## Effects at stability v: every key scales linearly from -max at -100 to +max at +100.
static func effects(g, v: float) -> Dictionary:
	var s: float = clampf(v, -100.0, 100.0) / 100.0
	var b: Dictionary = g.bal
	if absf(s) < 0.005:
		return {}
	return {"tax": s * float(b.stab_tax), "manpower": s * float(b.stab_manpower), "unrest": -s * float(b.stab_unrest),
			"tech_cost": -s * float(b.stab_tech_cost), "prestige": s * float(b.stab_prestige)}


static func refresh_bonus(g, n) -> void:
	var e := effects(g, n.stability)
	if e.is_empty():
		n.clear_bonus("stability")
	else:
		n.set_bonus("stability", e)


## Administration to raise stability by stab_raise; dearer the higher it already is.
static func raise_cost(g, tag: String) -> float:
	var n = g.nations[tag]
	return float(g.bal.stab_raise_cost) + maxf(0.0, n.stability) * float(g.bal.stab_raise_cost_per_point)


static func raise_block_reason(g, tag: String) -> String:
	var n = g.nations[tag]
	if n.stability >= 100.0:
		return "Die Stabilität ist schon am Höchstwert."
	var c := raise_cost(g, tag)
	if n.adm < c:
		return "Zu wenig Verwaltung (%d)." % int(c)
	return ""


static func raise(g, tag: String) -> String:
	var r := raise_block_reason(g, tag)
	if r != "":
		return r
	var n = g.nations[tag]
	n.adm -= raise_cost(g, tag)
	add(g, tag, float(g.bal.stab_raise))
	return ""


## AI: shore up stability when it falls below zero (or below what the next rank needs) and administration is to spare.
static func _ai(g, n) -> void:
	var want: float = float(g.bal.stab_ai_floor)
	var nxt: int = n.rank + 1
	if nxt < g.Progression.RANKS.size():  # a rank within reach that only lacks stability
		want = maxf(want, float(g.Progression.RANKS[nxt].need.get("stability", -100.0)))
	if n.stability >= want:
		return
	if n.adm >= raise_cost(g, n.tag) + float(g.bal.stab_ai_reserve):
		raise(g, n.tag)
