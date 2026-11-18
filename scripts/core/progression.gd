extends RefCounted
## Progression: realm rank (Stadtstaat -> Grafschaft -> Herzogtum -> Königreich -> Imperium -> Hegemonie) and
## one-time milestones (economy, trade, conquest) that pay out rewards. Static helpers on the game `g`.
## A rank is bought (gold, administration, prestige) once the realm meets its conditions; every rank improves the
## bonuses of the one before slightly and adds one new bonus. Ranks are titles: they are never lost again.

## need: provinces, dev (total development), stability (minimum); cost: gold, adm, prestige;
## bonus: the full bonus at this rank (source "rank"); new: the key this rank adds (UI highlight)
const RANKS := [
	{"id": "city", "name": "Stadtstaat", "icon": "🏘️", "need": {}, "cost": {},
		"bonus": {"trade": 0.05}, "new": "trade"},
	{"id": "county", "name": "Grafschaft", "icon": "🛡️", "need": {"provinces": 2, "dev": 15}, "cost": {"gold": 50.0, "adm": 25.0},
		"bonus": {"trade": 0.05, "tax": 0.03, "manpower": 0.05}, "new": "manpower"},
	{"id": "duchy", "name": "Herzogtum", "icon": "🏰", "need": {"provinces": 5, "dev": 45}, "cost": {"gold": 150.0, "adm": 50.0, "prestige": 25.0},
		"bonus": {"trade": 0.06, "tax": 0.05, "manpower": 0.08, "force_limit": 2.0}, "new": "force_limit"},
	{"id": "kingdom", "name": "Königreich", "icon": "👑", "need": {"provinces": 10, "dev": 110}, "cost": {"gold": 400.0, "adm": 100.0, "prestige": 75.0},
		"bonus": {"trade": 0.07, "tax": 0.07, "manpower": 0.10, "force_limit": 3.0, "diplo_cap": 1.0}, "new": "diplo_cap"},
	{"id": "empire", "name": "Imperium", "icon": "🏛️", "need": {"provinces": 20, "dev": 280, "stability": 0.0}, "cost": {"gold": 1500.0, "adm": 200.0, "prestige": 200.0},
		"bonus": {"trade": 0.08, "tax": 0.09, "manpower": 0.12, "force_limit": 5.0, "diplo_cap": 1.0, "merchants": 1.0, "ae_decay": 0.15}, "new": "ae_decay"},
	{"id": "hegemon", "name": "Hegemonie", "icon": "🌍", "need": {"provinces": 40, "dev": 600, "stability": 25.0}, "cost": {"gold": 5000.0, "adm": 300.0, "prestige": 500.0},
		"bonus": {"trade": 0.10, "tax": 0.11, "manpower": 0.15, "force_limit": 8.0, "diplo_cap": 2.0, "merchants": 2.0, "ae_decay": 0.25, "stability": 0.10}, "new": "stability"},
]

## Historical titles at the start (at least this rank; bigger realms start higher by their size, up to Herzogtum).
const START_RANKS := {
	"TUR": 4,
	"FRA": 3, "ENG": 3, "SPA": 3, "POR": 3, "ARA": 3, "NAP": 3, "HUN": 3, "POL": 3, "BOH": 3, "DAN": 3, "SCO": 3,
	"NAV": 3, "CYP": 3, "MAM": 3, "QAR": 3, "ETH": 3, "TIM": 3, "MOR": 3, "TUN": 3, "BYZ": 3, "GRA": 3,
	"HAB": 2, "BUR": 2, "RUS": 2, "LIT": 2, "MLO": 2, "SAV": 2, "BAV": 2, "SAX": 2, "BRA": 2, "LOR": 2, "BRI": 2,
	"VEN": 1, "GEN": 1,
}

## Bonus names for the rank window and tooltips: key -> [label, percent?]
const BONUS_NAMES := {
	"trade": ["Handel", true], "tax": ["Steuern", true], "manpower": ["Mannschaften", true], "force_limit": ["Truppenlimit", false],
	"diplo_cap": ["Diplomatische Kapazität", false], "merchants": ["Händler", false], "ae_decay": ["Abbau Aggr. Expansion", true],
	"stability": ["Stabilitätsziel", true],
}


static func rank(g, tag: String) -> int:
	return int(g.nations[tag].rank)


static func rank_name(g, tag: String) -> String:
	return RANKS[rank(g, tag)].name


## Highest rank whose conditions the realm meets by size alone (start ranks).
static func size_rank(g, tag: String) -> int:
	var r := 0
	for i in range(1, RANKS.size()):
		if _meets(g, tag, i, false):
			r = i
	return r


## Start of a new game: historical title or what the realm's size gives, whichever is higher (size up to Herzogtum).
static func start_ranks(g) -> void:
	for tag in g.order:
		var n = g.nations[tag]
		if g.nation_data_native.has(tag):
			n.rank = 0 if tag == "NAT" else mini(size_rank(g, tag), 2)
		else:
			n.rank = maxi(int(START_RANKS.get(tag, 0)), mini(size_rank(g, tag), 2))
	refresh(g)


## Rank bonuses without news (game start, after loading).
static func refresh(g) -> void:
	for tag in g.order:
		var n = g.nations[tag]
		n.rank = clampi(int(n.rank), 0, RANKS.size() - 1)
		n.set_bonus("rank", RANKS[n.rank].bonus)


static func _meets(g, tag: String, r: int, with_stability: bool = true) -> bool:
	var need: Dictionary = RANKS[r].need
	var n = g.nations[tag]
	if g.provinces_of(tag).size() < int(need.get("provinces", 0)):
		return false
	if n.dev_total < int(need.get("dev", 0)) and g.nation_dev(tag) < int(need.get("dev", 0)):
		return false
	if with_stability and need.has("stability") and n.stability < float(need.stability):
		return false
	return true


## Why the next rank can't be taken yet ("" = it can). Lists every missing condition / resource.
static func upgrade_block_reason(g, tag: String) -> String:
	var n = g.nations[tag]
	var r: int = n.rank + 1
	if r >= RANKS.size():
		return "Höchster Rang erreicht."
	if n.overlord != "":
		return "Vasallen können ihren Rang nicht erhöhen."
	var miss := []
	var need: Dictionary = RANKS[r].need
	var prov: int = g.provinces_of(tag).size()
	if prov < int(need.get("provinces", 0)):
		miss.append("%d/%d Provinzen" % [prov, int(need.provinces)])
	if n.dev_total < int(need.get("dev", 0)):
		miss.append("%d/%d Entwicklung" % [n.dev_total, int(need.dev)])
	if need.has("stability") and n.stability < float(need.stability):
		miss.append("Stabilität %d/%d" % [roundi(n.stability), int(need.stability)])
	var cost: Dictionary = RANKS[r].cost
	for k in ["gold", "adm", "prestige"]:
		if cost.has(k) and float(n.get(k)) < float(cost[k]):
			miss.append("%d/%d %s" % [int(n.get(k)), int(cost[k]), {"gold": "💰", "adm": "📜", "prestige": "⭐"}[k]])
	if miss.is_empty():
		return ""
	return "Fehlt: " + ", ".join(miss)


static func can_upgrade(g, tag: String) -> bool:
	return upgrade_block_reason(g, tag) == ""


static func upgrade(g, tag: String) -> String:
	var why := upgrade_block_reason(g, tag)
	if why != "":
		return why
	var n = g.nations[tag]
	var r: int = n.rank + 1
	for k in RANKS[r].cost:
		n.set(k, float(n.get(k)) - float(RANKS[r].cost[k]))
	n.rank = r
	n.set_bonus("rank", RANKS[r].bonus)
	g.Stability.add(g, tag, float(g.bal.stab_rank_up))
	if tag == g.player:
		g.log_msg("%s %s ist jetzt ein %s!" % [RANKS[r].icon, n.name, RANKS[r].name], [tag])
		if r >= 3:
			n.flags.erase("ev_stab_crowned")  # a coronation for every crown from the kingdom on
			g.fire_event(tag, "stab_crowned")
	if r >= 4:
		g.world_event("%s %s erhebt sich zum %s." % [RANKS[r].icon, n.name, RANKS[r].name], [tag])
	return ""


## Bonus text "+5 % Handel, +2 Truppenlimit" (rank window, tooltips).
static func bonus_text(b: Dictionary, highlight: String = "") -> String:
	var parts := []
	for k in b:
		var nm: Array = BONUS_NAMES.get(k, [k, false])
		var v: float = float(b[k])
		var t: String = ("%+d %%" % roundi(v * 100.0)) if nm[1] else ("%+d" % roundi(v) if absf(v - roundf(v)) < 0.01 else "%+.1f" % v)
		parts.append(("✨ " if k == highlight else "") + t + " " + nm[0])
	return ", ".join(parts)


static func cost_text(c: Dictionary) -> String:
	var parts := []
	for k in ["gold", "adm", "prestige"]:
		if c.has(k):
			parts.append("%d %s" % [int(c[k]), {"gold": "💰", "adm": "📜", "prestige": "⭐"}[k]])
	return " ".join(parts) if not parts.is_empty() else "kostenlos"


static func need_text(nd: Dictionary) -> String:
	var parts := []
	if nd.has("provinces"):
		parts.append("%d Provinzen" % int(nd.provinces))
	if nd.has("dev"):
		parts.append("%d Entwicklung" % int(nd.dev))
	if nd.has("stability"):
		parts.append("Stabilität ab %d" % int(nd.stability))
	return ", ".join(parts) if not parts.is_empty() else "keine"


## id, title, text, reward effects; checked yearly for the player via `_reached`.
const MILESTONES := [
	{"id": "first_building", "title": "Baumeister", "text": "Das erste Gebäude fertigstellen.", "reward": {"gold": 30}},
	{"id": "manufactory", "title": "Manufakturwesen", "text": "Eine Manufaktur besitzen.", "reward": {"adm": 40}},
	{"id": "buildings_25", "title": "Blühendes Land", "text": "25 Gebäudestufen im Reich.", "reward": {"prestige": 10}},
	{"id": "goods_leader", "title": "Marktführer", "text": "Bei einem Gut Marktführer sein.", "reward": {"dip": 40}},
	{"id": "goods_leader_3", "title": "Handelsmonopol", "text": "Bei drei Gütern Marktführer sein.", "reward": {"prestige": 15}},
	{"id": "market_half", "title": "Herr der Märkte", "text": "In zwei Märkten die Hälfte der Handelsmacht halten.", "reward": {"gold": 80}},
	{"id": "trade_5", "title": "Handelsmacht", "text": "5 Gold Handelseinnahmen im Monat.", "reward": {"mods": {"income": 0.03}}},
	{"id": "income_20", "title": "Reiche Kassen", "text": "20 Gold Einnahmen im Monat.", "reward": {"prestige": 10}},
	{"id": "kingdom", "title": "Königreich", "text": "Den Rang Königreich erreichen.", "reward": {"prestige": 10}},
	{"id": "empire", "title": "Imperium", "text": "Den Rang Imperium erreichen.", "reward": {"prestige": 25}},
	{"id": "provinces_20", "title": "Großreich", "text": "20 Provinzen besitzen.", "reward": {"mil": 50}},
	{"id": "vassal", "title": "Lehnsherr", "text": "Einen Vasallen haben.", "reward": {"dip": 30}},
	{"id": "dev_30", "title": "Metropole", "text": "Eine Provinz mit 30 Entwicklung.", "reward": {"mods": {"production": 0.05}}},
	{"id": "harbors_5", "title": "Seefahrernation", "text": "5 Hafenstufen im Reich.", "reward": {"mods": {"trade": 0.05}}},
	{"id": "pacts_2", "title": "Handelsnetz", "text": "Zwei Handelsabkommen gleichzeitig.", "reward": {"dip": 50}},
	{"id": "trade_15", "title": "Handelsimperium", "text": "15 Gold Handelseinnahmen im Monat.", "reward": {"prestige": 15}},
	{"id": "buildings_60", "title": "Baumeister des Reiches", "text": "60 Gebäudestufen im Reich.", "reward": {"mods": {"build_cost": -0.1}}},
]


## Yearly for every nation: AI realms take the next rank when they can afford it with room to spare;
## the player gets milestones (taking a rank is the player's own decision).
static func yearly(g) -> void:
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive:
			continue
		if tag == g.player:
			check_milestones(g, tag)
		elif tag != "NAT" and n.rank + 1 < RANKS.size() and can_upgrade(g, tag):
			var c: Dictionary = RANKS[n.rank + 1].cost
			if n.gold >= float(c.get("gold", 0.0)) * float(g.bal.rank_ai_gold_mult):
				upgrade(g, tag)


static func check_milestones(g, tag: String) -> Array:
	var n = g.nations[tag]
	var got: Array = []
	for m in MILESTONES:
		var f: String = "ms_" + m.id
		if n.flags.has(f) or not _reached(g, tag, m.id):
			continue
		n.flags[f] = true
		g.apply_effects(tag, m.reward)
		got.append(m)
		g.log_msg("🏆 Meilenstein: %s" % m.title)
	return got


static func done(g, tag: String, id: String) -> bool:
	return g.nations[tag].flags.has("ms_" + id)


static func _reached(g, tag: String, id: String) -> bool:
	var Eco = g.Economy
	var n = g.nations[tag]
	match id:
		"first_building":
			return _levels(g, tag) >= 1
		"manufactory":
			for pid in g.provinces_of(tag):
				if g.provinces[pid].buildings.has("manufactory"):
					return true
			return false
		"buildings_25":
			return _levels(g, tag) >= 25
		"goods_leader":
			return g.goods_leader.values().count(tag) >= 1
		"goods_leader_3":
			return g.goods_leader.values().count(tag) >= 3
		"market_half":
			var c := 0
			for m in g.markets:
				if Eco.trade_share(g, tag, m) >= 0.5:
					c += 1
			return c >= 2
		"trade_5":
			return n.trade_income >= 5.0
		"income_20":
			return n.income >= 20.0
		"kingdom":
			return rank(g, tag) >= 3
		"empire":
			return rank(g, tag) >= 4
		"provinces_20":
			return g.provinces_of(tag).size() >= 20
		"vassal":
			return not g.vassals_of(tag).is_empty()
		"dev_30":
			for pid in g.provinces_of(tag):
				if g.provinces[pid].dev >= 30:
					return true
			return false
	return false


static func _levels(g, tag: String) -> int:
	var v := 0
	for pid in g.provinces_of(tag):
		for b in g.provinces[pid].buildings:
			v += int(g.provinces[pid].buildings[b])
	return v
