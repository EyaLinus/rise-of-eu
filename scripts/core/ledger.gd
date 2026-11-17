extends RefCounted
## Ledger: compares the living realms by one measure (score, development, provinces, income, army,
## ships, technology, prestige). Used by the ranking panel's sort buttons (scripts/ui/main.gd).

## key -> [label, tooltip]
const KEYS := {
	"score": ["⭐ Punkte", "Gesamtwertung"],
	"dev": ["🏘 Entw.", "Summe der Entwicklung aller Provinzen"],
	"provinces": ["🏰 Prov.", "Anzahl Provinzen"],
	"income": ["💰 Gold", "Einnahmen pro Monat"],
	"army": ["🛡 Armee", "Regimenter"],
	"ships": ["⛵ Flotte", "Schiffe"],
	"tech": ["🔬 Tech", "Summe der Technologiestufen"],
	"prestige": ["👑 Ansehen", "Prestige"],
}


static func value(g, tag: String, key: String) -> float:
	var n = g.nations[tag]
	match key:
		"score":
			return g.score(tag)
		"dev":
			return float(n.dev_total)
		"provinces":
			return float(g.provinces_of(tag).size())
		"income":
			return n.income
		"army":
			return g.army_regs(tag)
		"ships":
			return float(n.ships)
		"tech":
			return float(int(n.tech.adm) + int(n.tech.dip) + int(n.tech.mil))
		"prestige":
			return n.prestige
	return 0.0


## Living realms sorted by `key`, best first: [[tag, value], ...].
static func rows(g, key: String) -> Array:
	var out := []
	for t in g.order:
		if g.nations[t].alive:
			out.append([t, value(g, t, key)])
	out.sort_custom(func(a, b): return a[1] > b[1] or (a[1] == b[1] and String(a[0]) < String(b[0])))
	return out


static func fmt(key: String, v: float) -> String:
	if key == "income":
		return "%.1f" % v
	return "%d" % int(round(v))
