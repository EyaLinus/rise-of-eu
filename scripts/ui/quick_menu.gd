extends PanelContainer
## Quick actions on a province: right click (PC) or long press (phone) on the map opens a small menu next
## to the pointer with the actions that matter there, so the common ones are 2 clicks away instead of
## province -> tab -> button (3-4 clicks):
## - own province: best buildings, develop, recruit, calm unrest, integrate, armies here, the three tabs
## - foreign: march the selected army, owner's diplomacy, relations, claim, war, alliance
## - unclaimed land: found a colony
## Every entry keeps the tooltip of the full panel button (cost, reason why it is blocked).

const UiTheme = preload("res://scripts/ui/ui_theme.gd")
const Colonial = preload("res://scripts/core/colonial.gd")

var m  # main.gd
var pid := -1
var box: VBoxContainer


func _init(main) -> void:
	m = main
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 90
	add_theme_stylebox_override("panel", UiTheme.card("gold", 8))
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(300, 0)  # buttons clip, so the menu needs a width of its own
	add_child(box)
	visible = false


## Opens the menu for province `p` at `at` (main's coordinates).
func open(p: int, at: Vector2) -> void:
	pid = p
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var g = m.game
	var prov = g.provinces[p]
	var me: String = g.player
	var head: Label = m._lbl("📍 " + prov.name + ("" if prov.owner == me or prov.owner == "" or not g.nations.has(prov.owner) else "  ·  " + m.nname(prov.owner)), 17, UiTheme.GOLD)
	head.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.clip_text = true
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.custom_minimum_size.x = 0
	box.add_child(head)
	for e in entries(p):
		_add(e[0], e[1], e[2], e.size() > 3 and e[3])
	visible = true
	reset_size()
	var sz: Vector2 = get_combined_minimum_size()
	size = sz
	var vp: Vector2 = m.size
	var pos := at + Vector2(12, 8)
	if pos.x + sz.x > vp.x - 8.0:
		pos.x = at.x - sz.x - 12.0
	if pos.y + sz.y > vp.y - 8.0:
		pos.y = vp.y - sz.y - 8.0
	position = Vector2(clampf(pos.x, 8.0, maxf(8.0, vp.x - sz.x - 8.0)), clampf(pos.y, 8.0, maxf(8.0, vp.y - sz.y - 8.0)))


func close() -> void:
	visible = false
	pid = -1


func _add(text: String, cb: Callable, tip: String, disabled: bool) -> void:
	var b: Button = m._btn(text, func(): close(); cb.call(), tip, disabled)
	b.clip_text = true
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 17)
	b.custom_minimum_size = Vector2(0, 52 if m._big() else 40)
	box.add_child(b)


## [label, callable, tooltip, disabled] for province `p` (also used by tests).
func entries(p: int) -> Array:
	var g = m.game
	var prov = g.provinces[p]
	var me: String = g.player
	var n = g.nations[me]
	var out := []
	if prov.owner == Colonial.NATIVE or prov.owner == "":
		var why: String = Colonial.colony_block_reason(g, me, p)
		out.append(["🏕 Kolonie gründen %d 💰" % int(Colonial.colony_cost(g, me, p)), func(): m._act(Colonial.start_colony(g, me, p), "🏕 Die Siedler sind unterwegs"),
				"Siedler gründen hier eine Kolonie." + (("\n❌ " + why) if why != "" else ""), why != ""])
		out.append(["📍 Infos", _info.bind(p), "Provinz im Seitenfenster öffnen"])
		return out
	if prov.owner == me:
		var Eco = g.Economy
		# the two buildings with the best gain per gold that can be built now
		var cands := []
		for bid in g.buildings_def:
			if Eco.build_block_reason(g, me, p, bid) != "":
				continue
			var cost: float = Eco.building_cost(g, me, p, bid)
			cands.append([Eco.building_gain(g, prov, bid) / maxf(cost, 1.0), bid, cost])
		cands.sort_custom(func(a, b): return a[0] > b[0])
		for c in cands.slice(0, 2):
			var d: Dictionary = g.buildings_def[c[1]]
			var bid: String = c[1]
			out.append(["%s %s %d 💰" % [d.emoji, d.name, int(c[2])], func(): m._act(g.construct(me, p, bid), "🏗️ Bau begonnen: " + d.name), d.text])
		# develop with the power the realm has most of
		var dc: int = int(g.develop_cost(p))
		var best := "adm"
		for k in ["dip", "mil"]:
			if float(n.get(k)) > float(n.get(best)):
				best = k
		var icon: String = {"adm": "📜", "dip": "🕊️", "mil": "⚔️"}[best]
		out.append(["🏘️ Entwickeln %d %s" % [dc, icon], func(): m._act(g.develop(me, p, best), "🏘️ Entwicklung erhöht"),
				"+1 Entwicklung mit der Macht, von der du am meisten hast.\nMehr Steuer, Güter, Handelsmacht und Mannschaften.", float(n.get(best)) < dc])
		var rc := int(g.regiment_cost(me))
		out.append(["⚔️ +1 Regiment %d 💰" % rc, func(): m._act(g.recruit(me, p, 1), "⚔️ Rekrutiert"),
				"Regimenter %d / %d" % [g.regs_counted(me), g.force_cap(me)], g.force_room(me) <= 0])
		if g.unrest(p) > 0.0 and prov.suppress_months == 0:
			out.append(["✊ Beruhigen %d ⚔️" % int(g.suppress_cost(p)), func(): m._act(g.suppress_unrest(me, p), "✊ Ruhe wiederhergestellt"),
					"Militär einsetzen: die Unruhe sinkt für 2 Jahre."])
		if prov.core_months > 0:
			out.append(["🤝 Integrieren %d 🕊️" % int(g.bal.integrate_cost), func(): m._act(g.integrate(me, p), "🤝 Die Provinz rückt näher"),
					"−%d Monate bis zum Kernland." % int(g.bal.integrate_months)])
		if not g.armies_of(me).is_empty():
			out.append(["🏁 Alle Armeen hierher", func(): m._all_armies_to(p), "Schickt jede eigene Armee hierher."])
		# historical landmarks here (scripts/core/landmarks.gd): the next level, or why not yet
		var L = g.Landmarks
		for id in L.at(g, p):
			var lvl: int = L.level(g, id)
			if lvl >= L.MAX_LEVEL or L.building(g, id):
				continue
			var ld: Dictionary = g.lm_defs[id]
			var lr: String = L.block_reason(g, me, id)
			if lr.begins_with("Nur "):
				continue  # bound to another realm: nothing to do here
			out.append(["%s %s %d→%d %d 💰" % [ld.emoji, ld.name, lvl, lvl + 1, int(L.cost(g, me, id))],
					func(): m._act(L.invest(g, me, id), "%s %s: Ausbau begonnen" % [ld.emoji, ld.name]),
					m._landmark_tip(id) + (("\n❌ " + lr) if lr != "" else ""), lr != ""])
		out.append(["🏗️ Bauen…", _tab.bind(p, "build"), "Alle Gebäude dieser Provinz"])
		out.append(["⚔️ Militär…", _tab.bind(p, "army"), "Rekrutieren, Söldner, Armeen hier"])
		out.append(["📍 Infos", _tab.bind(p, "info"), "Provinz im Seitenfenster öffnen"])
		return out
	var o: String = prov.owner
	if m.selected_army >= 0:
		out.append(["🚶 Armee hierher", func(): m._on_province_tapped(p), "Marschbefehl für die gewählte Armee"])
	out.append(["%s Diplomatie…" % m.nname(o), func(): m._open_panel("other", o), "Alle Aktionen mit %s" % g.nations[o].name])
	out.append(["❤️ Beziehung verbessern", func(): m._act(g.improve_relations(me, o), "❤️ Beziehungen verbessert"),
			"Beziehung zu %s jetzt %d" % [g.nations[o].name, int(g.get_rel(me, o))]])
	var borders := false
	for a in prov.adj:
		if g.provinces[a].owner == me:
			borders = true
	if borders and not n.claims.has(p):
		out.append(["🎯 Anspruch %d 🕊️" % int(g.bal.claim_cost), func(): m._act(g.fabricate_claim(me, p), "🎯 Anspruch erhoben"),
				"Kriegsgrund gegen %s, die Provinz wird im Frieden billiger." % g.nations[o].name])
	if not g.at_war(me, o):
		if not g.is_allied(me, o):
			out.append(["🤝 Bündnis anbieten", func(): m._act(g.propose_alliance(me, o), "🤝 Bündnis geschlossen!"), "Kostet %d 🕊️" % int(g.alliance_cost(me))])
		out.append(["🔥 Krieg…", func(): m._confirm_war(o), "Krieg gegen %s erklären (mit Rückfrage)" % g.nations[o].name])
	out.append(["📍 Infos", _info.bind(p), "Provinz im Seitenfenster öffnen"])
	return out


func _info(p: int) -> void:
	m.selected_army = -1
	m.map.selected_army = -1
	m.map.selected_pid = p
	m._open_panel("province", p)
	m.map.selected_pid = p


func _tab(p: int, tab: String) -> void:
	m.prov_tab = tab
	_info(p)
