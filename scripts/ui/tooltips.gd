extends Node
## Rich tooltips for the whole UI (replaces Godot's plain tooltip popup, which project.godot switches off
## with a huge gui/timers/tooltip_delay_sec).
##
## Every Control keeps using `tooltip_text`. This node turns that plain text into a short, structured tip:
## - first short line (or "Titel: …") becomes a gold headline
## - sentences and " · " parts go on their own lines (no long horizontal text)
## - lines with a TAB ("Steuern\t+4.2") become a two-column table, values right-aligned
## - numbers are highlighted, game terms (GLOSSARY) get their pixel icon and are links
##
## Handling (mouse): the tip opens after a short delay next to the cursor. Staying on the control fills the
## bar at the bottom; then the tip locks (gold frame) and the mouse can move into it. Hovering a term in a
## locked tip opens a nested tip with its explanation; clicking a term opens its screen (2 clicks to any
## panel from any tip). Touch: a long press opens the tip already locked; tapping a term opens the nested
## tip, its "▶" line opens the screen; a tap anywhere else closes all tips.

const UiTheme = preload("res://scripts/ui/ui_theme.gd")

const DELAYS := [0.15, 0.35, 0.7]  # settings "tip_delay": 0 fast, 1 normal, 2 slow
const LOCK_S := 0.9  # time on the control until the tip locks
const GRACE_S := 0.3  # a locked tip survives the mouse leaving it this long (diagonal moves)
const MAX_W := 340.0
const MIN_W := 150.0
const NUM_COL := "f8de7e"
const KW_COL := "9fd3ff"

## Game terms: [id, regex (German inflections), icon, title, explanation, panel to open ("" none)].
## Explanations stay short: 2-3 lines, they are tips of a tip.
const GLOSSARY := [
	["gold", "Gold", "💰", "Gold", "Kasse für Gebäude, Truppen und Söldner.\nEinnahmen: Steuern, Güter, Handel.\nUnter 0 drohen Kredite und Bankrott.", "economy"],
	["adm", "Verwaltung|Verwaltungs-Macht", "📜", "Verwaltung", "Monatliche Macht.\nFür Technologie, Reformen und Entwickeln.", "tech"],
	["dip", "Diplomatie|Diplo-Macht|Diplomatie-Macht", "🕊️", "Diplomatie", "Monatliche Macht.\nFür Bündnisse, Ansprüche, Integration und Entwickeln.", "diplomacy"],
	["mil", "Militär|Militär-Macht", "⚔️", "Militär", "Monatliche Macht.\nFür Militärtechnik, Generäle und Unruhe unterdrücken.", "tech"],
	["manpower", "Mannschaften", "👥", "Mannschaften", "Rekruten für neue Regimenter.\nFüllen sich jeden Monat auf.\nGutshöfe und Kasernen erhöhen das Maximum.", "nation"],
	["dev", "Entwicklung", "🏘️", "Entwicklung", "Wert einer Provinz.\nMehr Steuern, Güter, Handelsmacht, Mannschaften.\nSteigt durch Gebäude oder Entwickeln.", ""],
	["unrest", "Unruhe", "✊", "Unruhe", "Zu hoch: Aufstände.\nSenken: Truppen vor Ort, Unterdrücken, Gerichtshof, Gesetze, zufriedene Stände.", ""],
	["ae", "Aggressive Expansion", "😠", "Aggressive Expansion", "Entsteht durch Eroberungen und sinkt langsam.\nAb der Koalitionsgrenze verbünden sich Nachbarn gegen dich.", "diplomacy"],
	["coalition", "Koalition|Koalitionen", "⚠️", "Koalition", "Bündnis vieler Nachbarn gegen einen Eroberer.\nEntsteht durch hohe Aggressive Expansion.", "diplomacy"],
	["forcelimit", "Truppenlimit", "🛡️", "Truppenlimit", "So viele Regimenter kannst du unterhalten.\nKasernen, Technik und Ränge erhöhen es.", "nation"],
	["trade", "Handelsmacht", "🏬", "Handelsmacht", "Dein Anteil an der Handelsmacht eines Marktes ergibt deinen Anteil an seinem Wert.\nMarktplatz, Hafen und Händler steigern sie.", "economy"],
	["market", "Markt|Marktes|Märkte|Märkten", "🪙", "Markt", "Gebiet, dessen Güter zusammen gehandelt werden.\nPreise ändern sich jährlich mit Angebot und Nachfrage.", "economy"],
	["exhaustion", "Kriegsmüdigkeit", "😩", "Kriegsmüdigkeit", "Wächst in langen, verlustreichen Kriegen.\nErhöht die Unruhe in allen Provinzen.\nSinkt im Frieden.", "wars"],
	["prestige", "Prestige", "⭐", "Prestige", "Ansehen deines Reiches.\nSiege, Monumente und Ereignisse bringen es, Niederlagen kosten es.", "nation"],
	["claim", "Anspruch|Ansprüche|Ansprüchen", "🎯", "Anspruch", "Kriegsgrund auf eine Provinz.\nMacht sie im Frieden billiger.", ""],
	["cb", "Kriegsgrund|Kriegsgründe", "🎯", "Kriegsgrund", "Ohne Kriegsgrund kostet eine Kriegserklärung Stabilität und Ansehen.\nAnsprüche und Rivalitäten sind Kriegsgründe.", ""],
	["core", "Kernland|integriert|Integration", "🔨", "Integration", "Erobertes Land bringt weniger Einkommen und mehr Unruhe, bis es integriert ist.", ""],
	["stability", "Stabilität", "⚖️", "Stabilität", "Von −100 % bis +100 %. Hohe Stabilität bringt Steuern und Mannschaften und senkt Unruhe und Technikkosten, niedrige kehrt das um.\nSie wandert langsam zu ihrem Zielwert; Kriegsmüdigkeit, Schulden und neue Provinzen drücken ihn.", "nation"],
	["realm_rank", "Rang des Reiches|Reichsrang", "👑", "Rang des Reiches", "Stadtstaat, Grafschaft, Herzogtum, Königreich, Imperium, Hegemonie.\nJeder Aufstieg kostet Gold, Verwaltung und Prestige, braucht Provinzen und Entwicklung und verbessert die Boni.", "nation"],
	["estates", "Stände|Ständen", "⚖️", "Stände", "Adel, Klerus und Bürger.\nZufriedene Stände geben Boni, zornige drohen mit Unruhe.", "government"],
	["laws", "Gesetz|Gesetze|Gesetzen", "⚖️", "Gesetze", "Dauerhafte Boni und Mali deiner Regierung.\nÄndern kostet Macht.", "government"],
	["reforms", "Reform|Reformen", "📜", "Reformen", "Stufen der Regierungsform.\nJede Stufe schaltet neue Boni frei.", "government"],
	["warscore", "Kriegspunkte", "🔥", "Kriegspunkte", "Besetzte Provinzen, Siege und Seeherrschaft.\nBestimmen, was du im Frieden fordern kannst.", "wars"],
	["supply", "Versorgung", "🌾", "Versorgung", "So viele Regimenter ernährt eine Provinz.\nMehr Truppen dort: Verluste, kein Nachschub.", ""],
	["fort", "Festung|Festungen", "🏰", "Festung", "Belagerungen dauern deutlich länger.", ""],
	["siege", "Belagerung|Belagerungen", "🔥", "Belagerung", "Bei 100 % fällt die Provinz an den Belagerer (bis zum Frieden).", "wars"],
	["morale", "Kampfkraft|Moral", "⚔️", "Kampfkraft", "Wie gut eine Armee kämpft.\nSinkt in Schlachten, erholt sich mit Versorgung und Straßen.", ""],
	["navallimit", "Flottenlimit", "⚓", "Flottenlimit", "So viele Schiffe kannst du unterhalten.\nHäfen und Küstenentwicklung erhöhen es.", "navy"],
	["port", "Hafen|Häfen", "⚓", "Hafen", "Mehr Handel und Güter, erhöht das Flottenlimit.\nNur an der Küste.", ""],
	["settler", "Siedler|Kolonisten", "🧭", "Siedler", "Gründen Kolonien in unbesiedeltem Land.", "nation"],
	["vassal", "Vasall|Vasallen", "⛓️", "Vasall", "Abhängiges Reich: zahlt Tribut, kämpft mit dir.\nKann nach Jahren annektiert werden.", "diplomacy"],
	["alliance", "Bündnis|Bündnisse|Bündnissen", "🤝", "Bündnis", "Verbündete treten deinen Kriegen bei.\nZu viele Bündnisse überlasten deine Diplomaten.", "diplomacy"],
	["rival", "Rivale|Rivalen|Rivalität", "🎯", "Rivale", "Höchstens 2.\nBringt Machtprojektion und einen Kriegsgrund.", "diplomacy"],
	["power", "Machtprojektion", "⭐", "Machtprojektion", "Wächst, wenn du gegen Rivalen bestehst.\nGibt Boni auf Militär und Prestige.", "nation"],
	["faith", "Glaube|Glauben|Glaubens", "⛪", "Glaube", "Fremder Glaube in einer Provinz: mehr Unruhe.\nMissionare bekehren sie.", ""],
	["relations", "Beziehung|Beziehungen", "❤️", "Beziehung", "Bessere Beziehungen machen Bündnisse, Heiraten und Durchmarsch leichter.", "diplomacy"],
	["access", "Durchmarsch|Durchmarschrecht", "🚶", "Durchmarschrecht", "Deine Armeen dürfen durch fremdes Land ziehen.", "diplomacy"],
	["age", "Zeitalter", "📅", "Zeitalter", "Abschnitte der Geschichte mit eigenen Zielen und Entscheidungen.", "government"],
	["slots", "Bauplatz|Bauplätze|Bauplätzen", "🏗️", "Bauplätze", "Jede Provinz hat begrenzte Plätze.\nMehr Entwicklung oder eine Stadt bringen mehr.", ""],
	["tax", "Steuer|Steuern", "💰", "Steuern", "Monatliches Gold aus Entwicklung.\nMarktplatz, Gesetze und Technik erhöhen sie.", "economy"],
	["regiment", "Regiment|Regimenter|Regimentern", "🛡️", "Regiment", "Grundeinheit einer Armee.\nKostet Gold, Mannschaften und Unterhalt.", ""],
]

## "Panel" names for the "▶ open" line of a term (main._open_panel modes).
const PANEL_NAMES := {"economy": "Wirtschaft", "tech": "Technologie", "diplomacy": "Diplomatie", "nation": "Nation",
	"government": "Regierung", "wars": "Kriege", "navy": "Marine"}

var host: Control  # main.gd: tips are its children (above HUD and popups), it opens panels
var _rx: RegEx
var _by_id := {}
var _group_ids: Array = []  # regex capture group -> glossary id ("" = number)
var tips: Array = []  # open tips, [0] from a control, [k] nested from a term in tips[k-1]
var _hover_src: Control = null  # control under the mouse that carries a tooltip
var _hover_since := 0.0
var fake_hover: Control = null  # tools/tip_test.gd: headless Godot tracks no hovered control
var fake_mouse := Vector2(-1, -1)
var _skip_id := ""  # term whose explanation is being built: it does not link to itself


func _init(h: Control) -> void:
	host = h
	var alts := []
	for e in GLOSSARY:
		_by_id[e[0]] = e
		alts.append("(" + e[1] + ")")
		_group_ids.append(e[0])
	alts.append("([+−-]?\\d+(?:[.,]\\d+)?(?: ?%)?)")
	_group_ids.append("")
	_rx = RegEx.new()
	# not inside a word: "Militärtechnik" is no "Militär", "Gold" in "Goldküste" stays plain
	_rx.compile("(?<![\\p{L}\\p{N}])(?:" + "|".join(alts) + ")(?![\\p{L}])")


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func delay() -> float:
	if host.settings.has("tip_show_ms"):
		return clampf(float(host.settings.tip_show_ms), 0.0, 3000.0) / 1000.0
	return DELAYS[clampi(int(host.settings.get("tip_delay", 1)), 0, DELAYS.size() - 1)]


## Time on the control until the tip locks (settings slider "tip_lock_ms", ms).
func lock_s() -> float:
	return clampf(float(host.settings.get("tip_lock_ms", LOCK_S * 1000.0)), 100.0, 5000.0) / 1000.0


func is_open() -> bool:
	return not tips.is_empty()


## True if `pos` (host coordinates) lies on an open, locked tip: the press belongs to the tip.
func owns_point(pos: Vector2) -> bool:
	for t in tips:
		if t.locked and t.panel.get_global_rect().has_point(pos):
			return true
	return false


func close_all() -> void:
	for t in tips:
		t.panel.queue_free()
	tips.clear()


func _close_from(level: int) -> void:
	while tips.size() > level:
		tips.pop_back().panel.queue_free()


# ---------------------------------------------------------------- formatting

static func _esc(s: String) -> String:
	return s.replace("[", "[lb]")


## Splits a paragraph into short lines: sentences and " · " parts.
static func _split_lines(par: String) -> Array:
	var out := []
	for part in par.split(" · ", false):
		var rx := RegEx.create_from_string("(?<=[.!?;])\\s+(?=[A-ZÄÖÜ0-9+−„(\\x{1F000}-\\x{1FFFF}\\x{2600}-\\x{27BF}])")
		var last := 0
		for m in rx.search_all(part):
			out.append(part.substr(last, m.get_start() - last).strip_edges())
			last = m.get_end()
		out.append(part.substr(last).strip_edges())
	# "+20 % Steuern, +15 % Handel, ein Bauplatz mehr, aber 10 % weniger …": one modifier per line
	var lines := []
	for sent in out:
		var segs: Array = Array(sent.split(", "))
		var numeric := segs.filter(func(x): return _has_digit(x)).size()
		if segs.size() >= 3 and numeric >= 2:
			var carry := ""  # a part without a number stays with the next one ("wer sie hält, kämpft mit +15 %")
			for seg in segs:
				seg = carry + seg
				carry = ""
				if not _has_digit(seg):
					carry = seg + ", "
					continue
				for sub in _split_und(seg):
					lines.append(sub)
			if carry != "":
				lines.append(carry.trim_suffix(", "))
		else:
			lines.append(sent)
	return lines.filter(func(x): return x != "")


static func _has_digit(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if c >= 48 and c <= 57:
			return true
	return false


## "10 % weniger Mannschaften und +1.0 Unruhe." -> two lines when both halves carry a number.
static func _split_und(seg: String) -> Array:
	seg = seg.strip_edges()
	for lead in ["aber ", "und ", "sowie "]:
		if seg.begins_with(lead):
			seg = seg.substr(lead.length())
	var i := seg.find(" und ")
	if i > 0 and _has_digit(seg.left(i)) and _has_digit(seg.substr(i + 5)):
		return [seg.left(i), seg.substr(i + 5)]
	return [seg]


## Highlights numbers and marks game terms (icon on first use, link to its explanation).
func _mark(line: String, seen: Dictionary, links: bool) -> String:
	var out := ""
	var last := 0
	for m in _rx.search_all(line):
		out += _esc(line.substr(last, m.get_start() - last))
		var txt: String = m.get_string()
		var gi := 1
		while gi <= _group_ids.size() and m.get_string(gi) == "":
			gi += 1
		var id: String = _group_ids[gi - 1] if gi <= _group_ids.size() else ""
		if id == "":
			out += "[color=#%s]%s[/color]" % [NUM_COL, _esc(txt)]
		else:
			if id == _skip_id:
				out += _esc(txt)
				last = m.get_end()
				continue
			var icon: String = _by_id[id][2]
			var before := line.substr(maxi(0, m.get_start() - 4), mini(4, m.get_start()))
			var show_icon: bool = not seen.has(id) and not before.contains(icon.left(1))
			seen[id] = true
			var t := ("%s %s" % [icon, txt]) if show_icon else txt
			out += ("[url=kw:%s][color=#%s]%s[/color][/url]" % [id, KW_COL, _esc(t)]) if links else "[color=#%s]%s[/color]" % [KW_COL, _esc(t)]
		last = m.get_end()
	return out + _esc(line.substr(last))


## Plain tooltip text -> BBCode. `links` false for the term explanations themselves (no endless nesting).
func format(text: String, links: bool = true) -> String:
	var pars: Array = Array(text.strip_edges().split("\n"))
	var title := ""
	if pars.size() > 1 and pars[0].length() <= 48 and not pars[0].contains("\t"):
		title = pars.pop_front()
	elif pars.size() >= 1:
		# "Gelände: Marschzeit ×1.2, …" -> headline "Gelände"
		var c: int = pars[0].find(": ")
		if c > 0 and c <= 28 and pars[0].length() > 50 and not pars[0].left(c).contains("."):
			title = pars[0].left(c)
			pars[0] = pars[0].substr(c + 2)
	var seen := {}
	var bb := ""
	if title != "":
		bb += "[font_size={hs}][color=#%s]%s[/color][/font_size]\n" % [UiTheme.GOLD.to_html(false), _esc(title)]
	var rows: Array = []  # pending table rows
	var lines: Array = []
	for par in pars:
		par = par.strip_edges(false, true)
		if par.strip_edges() == "":
			continue
		if par.contains("\t"):
			lines.append(par)
			continue
		var indent: bool = par.begins_with("  ")
		var parts := _split_lines(par.strip_edges())
		for i in parts.size():
			lines.append(("  " if indent else "") + parts[i])
	var body := []
	for l in lines:
		if l.contains("\t"):
			rows.append(l.split("\t"))
			continue
		if not rows.is_empty():
			body.append(_table(rows, seen, links))
			rows = []
		var s: String = l.strip_edges()
		var col := ""
		if s.begins_with("❌"):
			col = UiTheme.BAD.to_html(false)
		elif s.begins_with("✅") or s.begins_with("✓"):
			col = UiTheme.GOOD.to_html(false)
		elif s.begins_with("Klick") or s.begins_with("Tippen"):
			col = UiTheme.MUTED.to_html(false)  # how-to hints stay quiet
		var bullet: bool = lines.size() > 1 and not _starts_with_symbol(s) and col != UiTheme.MUTED.to_html(false)
		var line: String = ("• " if bullet else "") + _mark(s, seen, links)
		if l.begins_with("  "):
			line = "[indent]" + line + "[/indent]"
		body.append(("[color=#%s]%s[/color]" % [col, line]) if col != "" else line)
	if not rows.is_empty():
		body.append(_table(rows, seen, links))
	return bb + "\n".join(body)


func _table(rows: Array, seen: Dictionary, links: bool) -> String:
	var t := "[table=2]"
	for r in rows:
		t += "[cell][color=#%s]%s[/color]  [/cell][cell][right]%s[/right][/cell]" % [UiTheme.NEUTRAL.to_html(false), _mark(String(r[0]).strip_edges(), seen, links),
				_mark(String(r[1]).strip_edges() if r.size() > 1 else "", {}, false)]
	return t + "[/table]"


static func _starts_with_symbol(s: String) -> bool:
	if s == "":
		return true
	var c := s.unicode_at(0)
	return c >= 0x2190 or c == 0x2022  # emoji, arrows, a bullet of its own


# ---------------------------------------------------------------- tips

func _font_size() -> int:
	return 19 if host._big() else 16


func _make(text: String, links: bool, extra_bb: String = "") -> Dictionary:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pc.add_theme_stylebox_override("panel", UiTheme.box("tooltip", 10))
	pc.z_index = 100
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	pc.add_child(vb)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.meta_underlined = false
	var fs := _font_size()
	r.add_theme_font_size_override("normal_font_size", fs)
	r.add_theme_color_override("default_color", Color("f4f1e8"))
	r.text = format(text, links).replace("{hs}", str(fs + 3)) + extra_bb
	vb.add_child(r)
	var bar := ColorRect.new()  # lock progress
	bar.color = Color(UiTheme.GOLD, 0.8)
	bar.custom_minimum_size = Vector2(0, 3)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vb.add_child(bar)
	host.add_child(pc)
	# width: the longest line (short lines -> narrow tip), between MIN_W and MAX_W
	var font: Font = r.get_theme_font("normal_font")
	var w := MIN_W
	for line in r.get_parsed_text().split("\n"):
		w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8.0)
	w = minf(w, minf(MAX_W, host.size.x - 32.0))
	_fit_height(r, w)
	pc.reset_size()
	var t := {"panel": pc, "rtl": r, "bar": bar, "text": text, "locked": false, "born": _now(), "left_at": -1.0, "src": null, "src_rect": Rect2(), "key": "", "hover_meta": ""}
	r.meta_hover_started.connect(func(m): t.hover_meta = str(m); _on_meta_hover(t, str(m)))
	r.meta_hover_ended.connect(func(m): if t.hover_meta == str(m): t.hover_meta = "")
	r.meta_clicked.connect(func(m): _on_meta_click(t, str(m)))
	return t


## A fit_content label measures its height at its current width: size it to the final width first,
## else the tip is as tall as the text wrapped at 0 px (a tip down to the screen edge).
static func _fit_height(r: RichTextLabel, w: float) -> void:
	r.custom_minimum_size = Vector2(w, 0)
	r.size = Vector2(w, 0)
	r.custom_minimum_size = Vector2(w, r.get_content_height())


func _place(t: Dictionary, anchor: Vector2, beside: Rect2 = Rect2()) -> void:
	var pc: PanelContainer = t.panel
	pc.reset_size()
	var sz: Vector2 = pc.get_combined_minimum_size()
	var vp: Vector2 = host.size
	sz.y = minf(sz.y, vp.y - 16.0)
	pc.size = sz
	var p: Vector2
	if beside.size != Vector2.ZERO:  # nested: right of the parent tip, else left of it
		p = Vector2(beside.end.x + 6.0, anchor.y - 12.0)
		if p.x + sz.x > vp.x - 8.0:
			p.x = beside.position.x - sz.x - 6.0
	elif host.touch_mode():
		p = Vector2(anchor.x - sz.x / 2.0, anchor.y - sz.y - 40.0)  # above the finger
		if p.y < 8.0:
			p.y = anchor.y + 40.0
	else:
		p = anchor + Vector2(18, 22)
		if p.x + sz.x > vp.x - 8.0:
			p.x = anchor.x - sz.x - 12.0
		if p.y + sz.y > vp.y - 8.0:
			p.y = anchor.y - sz.y - 12.0
	pc.position = Vector2(clampf(p.x, 8.0, maxf(8.0, vp.x - sz.x - 8.0)), clampf(p.y, 8.0, maxf(8.0, vp.y - sz.y - 8.0)))


func _lock(t: Dictionary) -> void:
	if t.locked:
		return
	t.locked = true
	t.bar.visible = false
	t.panel.add_theme_stylebox_override("panel", UiTheme.card("gold", 10))
	t.panel.mouse_filter = Control.MOUSE_FILTER_STOP
	t.rtl.mouse_filter = Control.MOUSE_FILTER_PASS
	t.panel.reset_size()


## Tip for a control (hover or long press). Touch tips start locked.
func show_for(c: Control, at: Vector2, locked: bool = false) -> void:
	close_all()
	var t := _make(c.tooltip_text, true)
	t.src = c
	t.src_rect = c.get_global_rect()
	tips.append(t)
	_place(t, at)
	if locked:
		_lock(t)


## Nested tip with a term's explanation; touch adds a line that opens its screen.
func _show_term(parent_level: int, id: String) -> void:
	if not _by_id.has(id):
		return
	_close_from(parent_level + 1)
	var e: Array = _by_id[id]
	var extra := ""
	if e[5] != "":
		extra = "\n[url=go:%s][color=#%s]▶ %s öffnen[/color][/url]" % [e[5], KW_COL, PANEL_NAMES.get(e[5], e[5])] if host.touch_mode() \
				else "\n[color=#%s]Klick auf den Begriff: %s öffnen[/color]" % [UiTheme.MUTED.to_html(false), PANEL_NAMES.get(e[5], e[5])]
	_skip_id = id
	var t := _make("%s %s\n%s" % [e[2], e[3], e[4]], true, extra)  # terms inside link on: tips nest without a limit
	_skip_id = ""
	t.key = id
	tips.append(t)
	var parent: Dictionary = tips[parent_level]
	_place(t, host.get_local_mouse_position() if not host.touch_mode() else parent.panel.position, parent.panel.get_global_rect())
	_lock(t)  # locked at once (mouse too): its own terms can be hovered for the next level


func _on_meta_hover(t: Dictionary, meta: String) -> void:
	if host.touch_mode() or not t.locked or not meta.begins_with("kw:"):
		return
	_show_term(tips.find(t), meta.substr(3))


func _on_meta_click(t: Dictionary, meta: String) -> void:
	if meta.begins_with("kw:"):
		var id := meta.substr(3)
		if host.touch_mode():
			_show_term(tips.find(t), id)
			return
		_go(String(_by_id.get(id, ["", "", "", "", "", ""])[5]))
	elif meta.begins_with("go:"):
		_go(meta.substr(3))


func _go(panel: String) -> void:
	if panel == "":
		return
	close_all()
	if host.modal.visible:
		host._close_modal()
	host._open_panel(panel)


# ---------------------------------------------------------------- mouse hover loop

## Control under the mouse that carries a tooltip (walks up through PASS parents, like Godot does).
func _hovered_tip_control() -> Control:
	var c: Control = host.get_viewport().gui_get_hovered_control() if fake_hover == null else fake_hover
	while c != null:
		if c.tooltip_text != "":
			return c
		if c.mouse_filter == Control.MOUSE_FILTER_STOP:
			return null
		c = c.get_parent_control()
	return null


func _inside_tip(pos: Vector2) -> int:
	for i in range(tips.size() - 1, -1, -1):
		if tips[i].panel.get_global_rect().grow(4.0).has_point(pos):
			return i
	return -1


func _process(_delta: float) -> void:
	if host.touch_mode():
		# touch tips stay until the next tap (main._input closes them); a rebuilt panel frees the source
		return
	var now := _now()
	var pos: Vector2 = host.get_local_mouse_position() if fake_mouse.x < 0.0 else fake_mouse
	var c := _hovered_tip_control()
	if c != _hover_src:
		_hover_src = c
		_hover_since = now
	var inside := _inside_tip(pos)
	# drop tips from the deepest one up, as long as nothing keeps them alive
	for i in range(tips.size() - 1, -1, -1):
		var t: Dictionary = tips[i]
		var on_anchor: bool
		if i == 0:
			# a rebuilt panel (every few hundred ms while the game runs) frees the control under the mouse:
			# the new one at the same place, or with the same text, keeps the tip open
			on_anchor = c != null and (c == t.src or (not is_instance_valid(t.src)
					and (c.tooltip_text == t.text or c.get_global_rect().position.distance_to(t.src_rect.position) < 2.0)))
			if on_anchor and c != t.src:
				t.src = c
				t.src_rect = c.get_global_rect()
		else:
			on_anchor = tips[i - 1].hover_meta == "kw:" + t.key
		var alive: bool = on_anchor or (t.locked and inside >= i)
		if alive:
			t.left_at = -1.0
			continue
		if t.locked:
			if t.left_at < 0.0:
				t.left_at = now
			if now - t.left_at < GRACE_S:
				continue
		_close_from(i)
	if tips.is_empty():
		if c != null and now - _hover_since >= delay():
			show_for(c, pos)
	elif c != null and c != tips[0].src and not tips[0].locked and inside < 0:
		show_for(c, pos)  # moving from one control to the next while a tip is open: no new delay
	# lock progress and live text (gold, dates change while the tip is open)
	for i in tips.size():
		var t: Dictionary = tips[i]
		if i == 0 and is_instance_valid(t.src) and t.src.tooltip_text != t.text and not t.locked:
			var at: Vector2 = t.panel.position
			t.text = t.src.tooltip_text
			t.rtl.text = format(t.text).replace("{hs}", str(_font_size() + 3))
			_fit_height(t.rtl, t.rtl.custom_minimum_size.x)
			t.panel.reset_size()
			t.panel.position = at
		if not t.locked:
			var p := clampf((now - t.born) / maxf(lock_s(), 0.05), 0.0, 1.0)
			t.bar.custom_minimum_size.x = p * t.rtl.size.x
			if p >= 1.0:
				_lock(t)
