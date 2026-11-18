extends RefCounted
## Government-type mechanics on top of the forms of government (data/council.json, tools/content/council.py).
## - Hereditary monarchies: the heir takes the throne (Government.succession, unchanged).
## - Republics: the ruler serves a term of republic_term years, then the factions put up candidates and an
##   election picks the next one; the incumbent may run again (up to republic_max_terms terms) at the cost of
##   republican tradition. Tradition (0..100) rises every year and gives tax/unrest/prestige above 50,
##   penalties below.
## - Theocracies/orders, tribes and elective monarchies: when the ruler dies, an election among the factions'
##   candidates decides the successor (the designated "Nachfolger" runs for one of them).
## The winner's faction sets an agenda (modifiers for his reign, n.bonus["gov"] via Government.gov_sources).
## The player decides in an event popup (dynamic event "gov_election", effect {"elect": index}); the AI picks
## at once. State in n.gov: election = {cands: [...], incumbent: bool}, agenda = faction id, terms, tradition.

const Tech = preload("res://scripts/core/tech.gd")

const EVENT_ID := "gov_election"


static func cfg(g) -> Dictionary:
	return g.govt.council_cfg


static func family(g, n) -> String:
	var f: String = g.govt.form_family(g.govt.form_name(n.tag))
	return f if f != "" else "monarchie"


## "republic" (elections every term), "elective" (election when the ruler dies) or "hereditary".
static func kind(g, n) -> String:
	var fam := family(g, n)
	if fam == "republik":
		return "republic"
	if cfg(g).get("elective_families", []).has(fam) or cfg(g).get("elective_forms", []).has(g.govt.form_name(n.tag)):
		return "elective"
	return "hereditary"


static func term_years(g) -> int:
	return int(cfg(g).get("republic_term", 4))


static func factions(g, n) -> Array:
	return cfg(g).get("factions", {}).get(family(g, n), [])


static func faction(g, n, id: String) -> Dictionary:
	for f in factions(g, n):
		if f.id == id:
			return f
	for fam in cfg(g).get("factions", {}):
		for f in cfg(g).factions[fam]:
			if f.id == id:
				return f
	return {}


static func tradition(n) -> float:
	return float(n.gov.get("tradition", 50.0))


## Republican tradition effects: tradition_effects at 100, nothing at 50, mirrored at 0.
static func tradition_effects(g, n) -> Dictionary:
	if kind(g, n) != "republic":
		return {}
	var f: float = (tradition(n) - 50.0) / 50.0
	var r := {}
	var te: Dictionary = cfg(g).get("tradition_effects", {})
	for k in te:
		r[k] = float(te[k]) * f
	return r


static func agenda_effects(g, n) -> Dictionary:
	var a: String = str(n.gov.get("agenda", ""))
	if a == "" or kind(g, n) == "hereditary":
		return {}
	return faction(g, n, a).get("agenda", {})


## New game: republics start mid-term (first election within one term), every elective realm gets an agenda.
static func setup(g) -> void:
	for tag in g.nations:
		var n = g.nations[tag]
		var k := kind(g, n)
		if k == "republic":
			n.ruler.years = mini(int(n.ruler.years), g.rng.randi_range(1, term_years(g)))
			n.gov.tradition = float(cfg(g).get("tradition_start", 50))
			n.gov.terms = 1
			n.ruler_name = strip_number(n.ruler_name)  # doges and gonfalonieri carry no regnal numbers
		if k != "hereditary" and not factions(g, n).is_empty():
			var fs: Array = factions(g, n)
			n.gov.agenda = fs[g.rng.randi_range(0, fs.size() - 1)].id
		g.govt.refresh(n)


static func yearly(g, n) -> void:
	if kind(g, n) == "republic":
		n.gov.tradition = clampf(tradition(n) + float(cfg(g).get("tradition_year", 2)), 0.0, 100.0)


## Years until the next election in a republic (-1 otherwise).
static func next_election(g, n) -> int:
	return int(n.ruler.years) if kind(g, n) == "republic" else -1


static func pending(n) -> bool:
	return n.gov.has("election")


## Called instead of the heir's succession when the ruler's years run out in an elective realm.
static func start_election(g, n) -> void:
	if pending(n):
		if n.tag == g.player:
			register_event(g, n)
		return
	var fs: Array = factions(g, n)
	var cands := []
	var heir_slot := -1
	var h: Dictionary = n.gov.get("heir", {})
	if not h.is_empty() and not fs.is_empty():
		heir_slot = g.rng.randi_range(0, fs.size() - 1)
	for i in fs.size():
		var c: Dictionary
		if i == heir_slot:
			var hn: String = str(h.get("name", ""))
			c = {"adm": int(h.adm), "dip": int(h.dip), "mil": int(h.mil), "base": strip_number(hn) if kind(g, n) == "republic" else hn, "trait": str(h.get("trait", "")), "heir": true}
		else:
			c = _roll(g, n)
		c["faction"] = fs[i].id
		cands.append(c)
	var inc := kind(g, n) == "republic" and int(n.gov.get("terms", 1)) < int(cfg(g).get("republic_max_terms", 3))
	n.gov.election = {"cands": cands, "incumbent": inc}
	if n.tag == g.player:
		register_event(g, n)
	else:
		elect(g, n.tag, ai_pick(g, n))


static func _roll(g, n) -> Dictionary:
	var lo := int(g.bal.ruler_min)
	var hi := int(g.bal.ruler_max)
	var base := ""
	if not n.ruler_names.is_empty():
		base = n.ruler_names[g.rng.randi_range(0, n.ruler_names.size() - 1)]
	return {"adm": g.rng.randi_range(lo, hi), "dip": g.rng.randi_range(lo, hi), "mil": g.rng.randi_range(lo, hi),
			"base": base, "trait": g.govt.roll_trait(g)}


## Index of the option: candidates first, then (republics) the incumbent at the end.
static func options(n) -> Array:
	var e: Dictionary = n.gov.get("election", {})
	var r: Array = e.get("cands", []).duplicate()
	if bool(e.get("incumbent", false)):
		r.append({"incumbent": true})
	return r


static func candidate_value(g, n, c: Dictionary) -> float:
	if c.get("incumbent", false):
		var keep: float = n.ruler.adm + n.ruler.dip + n.ruler.mil + Tech.effect_value(agenda_effects(g, n)) / 20.0
		return keep + float(cfg(g).get("tradition_reelect", -15)) * (0.08 if tradition(n) > 40.0 else 0.3)
	return float(c.adm + c.dip + c.mil) + Tech.effect_value(faction(g, n, str(c.faction)).get("agenda", {}), n.aggression) / 20.0 \
			+ Tech.effect_value(g.govt.trait_effects(str(c.get("trait", ""))), n.aggression) / 20.0


static func ai_pick(g, n) -> int:
	var opts := options(n)
	var best := 0
	for i in opts.size():
		if candidate_value(g, n, opts[i]) > candidate_value(g, n, opts[best]):
			best = i
	return best


## Elects option `idx` (effect "elect"). Republic terms last republic_term years, other rulers for life.
static func elect(g, tag: String, idx: int) -> void:
	var n = g.nations[tag]
	if not pending(n):
		return
	var opts := options(n)
	var c: Dictionary = opts[clampi(idx, 0, opts.size() - 1)]
	var rep := kind(g, n) == "republic"
	n.gov.erase("election")
	if tag == g.player:
		g.pending_events.erase(EVENT_ID)
	if c.get("incumbent", false):
		n.ruler.years = term_years(g)
		n.gov.terms = int(n.gov.get("terms", 1)) + 1
		n.gov.tradition = clampf(tradition(n) + float(cfg(g).get("tradition_reelect", -15)), 0.0, 100.0)
		if tag == g.player:
			g.log_msg("🏛 %s bleibt im Amt (%d. Amtszeit)." % [n.ruler_name, int(n.gov.terms)], [tag])
		g.govt.refresh(n)
		return
	var years: int = term_years(g) if rep else g.rng.randi_range(8, 30)
	n.ruler = {"adm": int(c.adm), "dip": int(c.dip), "mil": int(c.mil), "years": years}
	n.ruler_name = _ruler_name(g, n, c, rep)
	n.gov.ruler_trait = str(c.get("trait", ""))
	n.gov.agenda = str(c.faction)
	n.gov.terms = 1
	n.gov.erase("regency_until")
	n.gov.heir = {}  # the designated successor either won or lost: the court names a new one
	g.govt.ensure_heir(g, n)
	g.govt.refresh(n)
	var tr: String = g.govt.trait_name(n.gov.ruler_trait)
	g.log_msg("🏛 %s (%s) regiert nun %s (📜%d 🕊️%d ⚔️%d%s)." % [n.ruler_name, faction(g, n, n.gov.agenda).get("name", ""),
			"für %d Jahre" % years if rep else "auf Lebenszeit", n.ruler.adm, n.ruler.dip, n.ruler.mil, ", " + tr if tr != "" else ""], [tag])


## "Agostino III" -> "Agostino" (republics have no regnal numbers).
static func strip_number(name: String) -> String:
	var parts := name.split(" ")
	if parts.size() > 1:
		var last: String = parts[parts.size() - 1]
		var roman := last != ""
		for ch in last:
			if not "IVXL".contains(ch):
				roman = false
		if roman:
			parts.remove_at(parts.size() - 1)
			return " ".join(parts)
	return name


static func _ruler_name(g, n, c: Dictionary, rep: bool) -> String:
	var base: String = str(c.get("base", ""))
	if c.get("heir", false) or base == "":
		return base
	if rep:
		var own: Array = g.provinces_of(n.tag)
		return base if own.is_empty() else "%s aus %s" % [base, g.provinces[own[g.rng.randi_range(0, own.size() - 1)]].name]
	var num: int = int(n.name_counts.get(base, 0)) + 1
	n.name_counts[base] = num
	return "%s %s" % [base, g._roman(num)]


static func candidate_title(g, n, c: Dictionary) -> String:
	if c.get("incumbent", false):
		return "%s wiederwählen" % (n.ruler_name if n.ruler_name != "" else "Den Amtsinhaber")
	var f: Dictionary = faction(g, n, str(c.faction))
	var who: String = str(c.base) if str(c.base) != "" else "Ein Bewerber"
	return "%s (%s)%s" % [who, f.get("name", ""), " · Nachfolger" if c.get("heir", false) else ""]


## The election as a dynamic event (rebuilt after loading a save; never stored in events.json).
static func register_event(g, n) -> void:
	var opts := options(n)
	var o := []
	for i in opts.size():
		o.append({"text": candidate_title(g, n, opts[i]), "effects": {"elect": i}})
	var fam := family(g, n)
	g.event_by_id[EVENT_ID] = {"id": EVENT_ID, "title": str(cfg(g).get("election_title", {}).get(fam, "Wahl")),
			"text": str(cfg(g).get("election_text", {}).get(fam, "")), "image": "court", "manual": true, "options": o}
	if not g.pending_events.has(EVENT_ID):
		g.pending_events.append(EVENT_ID)


## After loading: the pending election of the player needs its event again.
static func after_load(g) -> void:
	if g.player != "" and g.nations.has(g.player) and pending(g.nations[g.player]):
		register_event(g, g.nations[g.player])
	else:
		g.pending_events.erase(EVENT_ID)


static func load_save(n, d: Dictionary) -> void:
	if d.has("tradition"):
		n.gov.tradition = clampf(float(d.tradition), 0.0, 100.0)
	if d.has("terms"):
		n.gov.terms = int(d.terms)
	if d.has("agenda"):
		n.gov.agenda = str(d.agenda)
	var e: Dictionary = d.get("election", {})
	if not e.is_empty():
		var cs := []
		for c in e.get("cands", []):
			cs.append({"adm": int(c.get("adm", 1)), "dip": int(c.get("dip", 1)), "mil": int(c.get("mil", 1)), "base": str(c.get("base", "")),
					"trait": str(c.get("trait", "")), "faction": str(c.get("faction", "")), "heir": bool(c.get("heir", false))})
		n.gov.election = {"cands": cs, "incumbent": bool(e.get("incumbent", false))}
