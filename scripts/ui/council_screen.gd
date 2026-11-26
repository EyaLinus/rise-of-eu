extends RefCounted
## Council tab of the government screen (scripts/core/council.gd, regime.gd): the government type's loop
## (elections, tradition, programme) on top, then one compact card per seat. A filled seat shows its member,
## level, passive effects, the automation switch and its limits (each limit is a button that cycles through
## the allowed values); an empty seat offers to appoint someone from three candidates.
## `m` is the main UI (scripts/ui/main.gd), `gs` the government screen.

const Tech = preload("res://scripts/core/tech.gd")
const TechScreen = preload("res://scripts/ui/tech_screen.gd")
const Council = preload("res://scripts/core/council.gd")
const Regime = preload("res://scripts/core/regime.gd")
const Icons = preload("res://scripts/ui/icons.gd")

const POWER_NAMES := {"adm": "Verwaltung", "dip": "Diplomatie", "mil": "Militär"}
const MUTED := Color(0.72, 0.75, 0.82)

var m


func _init(main) -> void:
	m = main


## True when an empty seat can be filled right now (tab badge).
static func can_act(g, n) -> bool:
	if g.govt.council_cfg.is_empty():
		return false
	if Council.members(n).size() >= Council.seats(g).size():
		return false
	return n.gold >= Council.hire_cost(g, n, 1) * 2.0


func build(g, n) -> void:
	_regime(g, n)
	var cnt: int = Council.members(n).size()
	var head: Label = m._lbl("👥 %s (%d/%d) · Gehalt %.2f %s/Monat" % [Council.council_name(g, n), cnt, Council.seats(g).size(),
			Council.salary(g, n), Icons.emoji("gold")], 18)
	head.tooltip_text = "Jeder Sitz bringt je Stufe einen kleinen Bonus und schaltet eine Automatik frei, die wiederkehrende Aufgaben übernimmt. " \
			+ "Mit den Grenzen (Reserven, Ziele, Schwellen) behältst du die Kontrolle. Berufen kostet Gold, Fördern Punkte der Art des Sitzes, " \
			+ "nach %d Jahren auf einer Stufe steigt ein Mitglied von selbst auf." % int(Council.cfg(g).get("experience_years", 6))
	head.mouse_filter = Control.MOUSE_FILTER_STOP
	m.side_box.add_child(head)
	# filled seats first (their automations are what you adjust), then the empty ones
	for filled in [true, false]:
		for s in Council.seats(g):
			if Council.member(n, s.id).is_empty() != filled:
				m.side_box.add_child(_seat_card(g, n, s))


func _regime(g, n) -> void:
	var k := Regime.kind(g, n)
	var txt := ""
	var tip := ""
	match k:
		"republic":
			txt = "🏛 Republik · Wahl in %d Jahr(en) · Tradition %d" % [maxi(0, int(n.ruler.years)), int(Regime.tradition(n))]
			tip = "Alle %d Jahre stellen die Parteien Kandidaten auf. Der Sieger regiert nach dem Programm seiner Partei. " % Regime.term_years(g) \
					+ "Den Amtsinhaber wiederzuwählen kostet Tradition (bis zu %d Amtszeiten). Tradition steigt jedes Jahr; über 50 bringt sie Steuern, Ruhe und Prestige, darunter Mali." % int(Regime.cfg(g).get("republic_max_terms", 3))
			var te: Dictionary = Regime.tradition_effects(g, n)
			if not te.is_empty():
				tip += "\nJetzt: " + Tech.effects_text(te)
		"elective":
			txt = "🏛 Wahlherrschaft · nach dem Tod des Herrschers wird gewählt"
			tip = "Kein Erbrecht: Stirbt der Herrscher, stellen die Parteien Kandidaten auf, der Nachfolger kandidiert für eine von ihnen. Der Gewählte regiert auf Lebenszeit nach dem Programm seiner Partei."
		_:
			txt = "👑 Erbmonarchie · der Erbe folgt auf den Thron"
			tip = "Der Erbe übernimmt, wenn die Zeit des Herrschers endet. Der Sitz für Erziehung kann ihn selbstständig unterrichten."
	var ag: String = str(n.gov.get("agenda", ""))
	if k != "hereditary" and ag != "":
		var f: Dictionary = Regime.faction(g, n, ag)
		txt += " · Programm: " + str(f.get("name", ""))
		tip += "\nProgramm der %s: %s (%s)" % [f.get("name", ""), Tech.effects_text(f.get("agenda", {})), f.get("text", "")]
	var l: Label = m._lbl(txt, 15, Color(0.85, 0.82, 0.68))
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	m.side_box.add_child(l)


func _seat_card(g, n, s: Dictionary) -> Control:
	var id: String = s.id
	var mem := Council.member(n, id)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTheme.card("" if mem.is_empty() else "good", 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	pc.add_child(v)
	var title: Label = m._lbl("%s %s" % [s.icon, Council.seat_name(g, n, id)], 17)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.tooltip_text = "%s\n🤖 %s: %s" % [s.text, s.auto.title, s.auto.text]
	pc.mouse_filter = Control.MOUSE_FILTER_STOP
	var me: String = n.tag
	if mem.is_empty():
		var b: Button = m._btn("Berufen", _pick.bind(id), "Drei Kandidaten mit verschiedenen Eigenschaften zur Auswahl")
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.disabled = n.gold < Council.hire_cost(g, n, 1)
		var h := HBoxContainer.new()
		h.add_child(title)
		h.add_child(b)
		v.add_child(h)
		v.add_child(m._lbl("Leer · je Stufe: %s · 🤖 %s" % [Tech.effects_text(Council.seat_effects(g, id, 1)), s.auto.title], 13, MUTED))
		return pc
	var lvl: int = int(mem.skill)
	var exp_left := Council.experience_left(g, n, id)
	var sub := "%s · Stufe %d/%d" % [mem.name, lvl, Council.max_skill(g)]
	var td := Council.trait_def(g, id, Council.trait_of(n, id))
	if not td.is_empty():
		sub += " · %s" % td.name
	if exp_left > 0:
		sub += " · Aufstieg durch Erfahrung in %d J." % exp_left
	var pb: Button = m._btn("➕%d%s" % [int(Council.promote_cost(g, n, id)), Icons.emoji(s.power)], func():
		m._act(Council.promote(g, me, id), "%s %s steigt auf" % [s.icon, mem.name]),
			"Fördern: eine Stufe höher für %d %s" % [int(Council.promote_cost(g, n, id)), POWER_NAMES[s.power]])
	pb.disabled = Council.promote_block(g, me, id) != ""
	pb.add_theme_font_size_override("font_size", 14)
	pb.size_flags_horizontal = Control.SIZE_SHRINK_END
	var xb: Button = m._btn("✖", _dismiss.bind(id), "Entlassen (der Sitz wird frei, die Einstellungen bleiben nicht)")
	xb.size_flags_horizontal = Control.SIZE_SHRINK_END
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(title)
	h.add_child(pb)
	h.add_child(xb)
	v.add_child(h)
	v.add_child(m._lbl(sub, 13, MUTED))
	v.add_child(TechScreen.effects_rich(Council.seat_effects(g, id, lvl, Council.trait_of(n, id)), 14))
	# automation: switch plus one button per limit
	var on := Council.auto_on(n, id)
	var ab: Button = m._btn("🤖 Automatik %s" % ("an" if on else "aus"), func():
		m._act(Council.set_auto(g, me, id, not on)), "%s: %s" % [s.auto.title, s.auto.text])
	ab.add_theme_font_size_override("font_size", 14)
	if on:
		ab.add_theme_color_override("font_color", UiTheme.GOLD)
	var row := [ab]
	if on:
		for key in s.get("options", {}):
			var d: Dictionary = s.options[key]
			var val = Council.opt(g, n, id, key)
			var ob: Button = m._btn("%s: %s" % [d.label, Council.opt_text(g, id, key, val)], func():
				m._act(Council.cycle_opt(g, me, id, key)), "Tippen wechselt den Wert")
			ob.add_theme_font_size_override("font_size", 13)
			row.append(ob)
	v.add_child(m._grid(row, 2) if row.size() > 1 else ab)
	if id == "development" and on:
		v.add_child(m._lbl(_dev_note(g, n), 13, MUTED))
	return pc


func _dev_note(g, n) -> String:
	var pid: int = Council.dev_target(g, n)
	var at: float = Council.dev_threshold(g, n)
	if pid < 0:
		return "Keine Entwicklung: Punkte über dem Maximum verfallen." if Council.dev_mode(g, n) == "off" else "Keine Provinz kann weiter wachsen."
	return "Nächste Entwicklung: %s (%d) ab %d Punkten einer Art." % [g.provinces[pid].name, g.provinces[pid].dev, int(at)]


func _dismiss(id: String) -> void:
	var g = m.game
	Council.dismiss(g, g.player, id)
	m._act("", "Sitz geräumt")


func _pick(id: String) -> void:
	var g = m.game
	var me: String = g.player
	var n = g.nations[me]
	var s := Council.seat_def(g, id)
	m._open_modal()
	m.modal_box.add_child(m._lbl("%s %s berufen" % [s.icon, Council.seat_name(g, n, id)], 26))
	m.modal_box.add_child(m._lbl("%s\n🤖 %s: %s" % [s.text, s.auto.title, s.auto.text], 15, Color(0.85, 0.82, 0.68)))
	var c: Array = Council.pool(g, n, id)
	for i in c.size():
		var p: Dictionary = c[i]
		var cost := Council.hire_cost(g, n, int(p.skill))
		var err := Council.hire_block(g, me, id, i)
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UiTheme.card("", 8))
		var h := HBoxContainer.new()
		pc.add_child(h)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ptd := Council.trait_def(g, id, str(p.get("trait", "")))
		v.add_child(m._lbl("%s · Stufe %d" % [p.name, int(p.skill)] + ("" if ptd.is_empty() else " · " + str(ptd.name)), 17))
		if not ptd.is_empty():
			v.add_child(m._lbl(str(ptd.text), 13, MUTED))
		v.add_child(TechScreen.effects_rich(Council.seat_effects(g, id, int(p.skill), str(p.get("trait", ""))), 14))
		if err != "":
			v.add_child(m._lbl(err, 13, Color(0.95, 0.6, 0.55)))
		h.add_child(v)
		var b: Button = m._btn("%d %s" % [int(cost), Icons.emoji("gold")], func():
			var e: String = Council.hire(g, me, id, i)
			m._close_modal()
			m._act(e, "%s %s tritt in den Rat ein" % [s.icon, p.name]))
		b.disabled = err != ""
		b.set_meta("confirm", true)  # the confirm key hires the first candidate you can afford
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		m.modal_box.add_child(pc)
	m.modal_box.add_child(m._lbl("Neue Kandidaten kommen jedes Jahr. Gehalt: %.2f %s pro Stufe und Monat." % [float(Council.cfg(g).get("salary", 0.15)) * Council._fam_mult(g, n), Icons.emoji("gold")], 13, MUTED))
	m.modal_box.add_child(m._btn("Schließen", m._close_modal))
