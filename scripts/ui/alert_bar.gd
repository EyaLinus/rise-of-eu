extends RefCounted
## Alert bar: the advisor's to-dos (main._advice) pinned as small icons right under the top bar, so the
## player sees at a glance that something waits, without opening the 💡 advisor. Each icon is framed by
## its kind (red = trouble, green = a reward waiting, plain = a hint); hovering (long press on a phone)
## tells what is going on and what to do; a click opens the panel where it is handled. Right click hides
## one alert until its cause is gone. When the row does not fit next to the side panel, the last icon
## becomes "+N" and opens the advisor list.
## `m` is the main UI (scripts/ui/main.gd).

const UiTheme = preload("res://scripts/ui/ui_theme.gd")

const KIND_ORDER := {"bad": 0, "good": 1, "": 2}
const GAP := 6.0

var m
var bar: HBoxContainer
var dismissed := {}  # alert id -> true, forgotten once the alert is gone
var seen := {}  # ids shown last time, to make new ones blink once
var _items: Array = []
var _sig := ""
static var _glyphs := {}  # code point -> pixel glyph texture (assets/art/emoji)


func _init(main) -> void:
	m = main


func build(hud: Control) -> void:
	bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", int(GAP))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2(150, 70)
	hud.add_child(bar)
	m.get_viewport().size_changed.connect(_relayout)
	m.side_panel.visibility_changed.connect(_relayout)
	m.side_panel.resized.connect(_relayout)
	m.left_tabs.resized.connect(_relayout)


func icon_size() -> float:
	return 52.0 if m._big() else 44.0


## Alerts as shown: dismissed ones dropped, trouble first, then rewards, then hints (stable within a kind).
static func order(items: Array, hidden: Dictionary) -> Array:
	var r := []
	for i in items.size():
		if not hidden.has(items[i].id):
			r.append([KIND_ORDER.get(items[i].kind, 2), i, items[i]])
	r.sort()
	var out := []
	for e in r:
		out.append(e[2])
	return out


## How many icons fit into `room` px; with more alerts than that, the last slot is the "+N" button.
static func fit_count(total: int, room: float, w: float, gap: float) -> int:
	var slots := int(floor((room + gap) / (w + gap)))
	if slots <= 0:
		return 0
	return total if total <= slots else maxi(0, slots - 1)


## Tooltip: the alert, why it matters, what to do and how the icon reacts.
static func tip_text(it: Dictionary, desktop: bool) -> String:
	return "%s\n\nWarum: %s\nWas tun: %s\n\n%s" % [it.text, it.why, it.todo,
			"Klick: Fenster öffnen · Rechtsklick: ausblenden" if desktop else "Antippen: Fenster öffnen"]


func update(items: Array) -> void:
	# a dismissed alert comes back when it was gone in between
	var ids := {}
	for it in items:
		ids[it.id] = true
	for id in dismissed.keys():
		if not ids.has(id):
			dismissed.erase(id)
	_items = order(items, dismissed)
	_rebuild()


func _relayout() -> void:
	_rebuild.call_deferred()


## Just under the top bar, which grows taller than its 64 px with a large UI size.
func _top() -> float:
	var top: Control = m.top_labels.date.get_parent().get_parent()
	return top.get_global_rect().end.y + 4.0


func _room() -> Array:
	var vp: Vector2 = m.get_viewport_rect().size
	var left: float = 8.0 + (m.left_tabs.size.x if m.left_tabs != null else 128.0) + 12.0
	var right: float = vp.x - 12.0
	if m.side_panel.visible:
		right = vp.x - m.side_panel.size.x - 12.0
	return [left, maxf(0.0, right - left)]


func _rebuild() -> void:
	if bar == null:
		return
	var on: bool = m.game != null and bool(m.settings.get("alerts", true))
	bar.visible = on and not _items.is_empty()
	if not bar.visible:
		_sig = ""
		return
	var lr: Array = _room()
	var w: float = icon_size()
	var n: int = fit_count(_items.size(), lr[1], w, GAP)
	var sig := "%d|%d|%d" % [n, int(w), _items.size()]
	for i in n:
		sig += "|" + _items[i].id + _items[i].text + _items[i].kind
	bar.position = Vector2(lr[0], _top())
	if sig == _sig:
		return
	_sig = sig
	for c in bar.get_children():
		bar.remove_child(c)
		c.queue_free()
	var desktop: bool = not OS.has_feature("mobile")
	var now := {}
	for i in n:
		var it: Dictionary = _items[i]
		var b: Button = _icon(it, w, desktop)
		bar.add_child(b)
		now[it.id] = true
		if not seen.has(it.id) and not seen.is_empty():
			_blink(b)
	if n < _items.size():
		var rest: int = _items.size() - n
		var more: Button = m._btn("+%d" % rest, func(): m._open_panel("advice"), "Noch %d Hinweise: alle im 💡 Ratgeber." % rest)
		more.custom_minimum_size = Vector2(w, w)
		more.clip_text = true
		more.autowrap_mode = TextServer.AUTOWRAP_OFF
		more.add_theme_font_size_override("font_size", 16)
		bar.add_child(more)
	seen = now if not now.is_empty() else {"_": true}
	bar.reset_size()


## The pixel glyph of an alert's leading emoji as a texture (null: none, the emoji is then drawn as text).
static func glyph_texture(glyph: String) -> Texture2D:
	if _glyphs.is_empty():
		var f := FileAccess.open("res://assets/art/emoji/emoji.json", FileAccess.READ)
		if f != null:
			var map: Dictionary = JSON.parse_string(f.get_as_text())
			for hex in map:
				_glyphs[hex.hex_to_int()] = "res://assets/art/emoji/%s.png" % map[hex]
	if glyph == "":
		return null
	var path = _glyphs.get(glyph.unicode_at(0))
	return load(path) if path != null and ResourceLoader.exists(path) else null


func _icon(it: Dictionary, w: float, desktop: bool) -> Button:
	var glyph: String = it.text.get_slice(" ", 0)
	var tex := glyph_texture(glyph)
	var b: Button = m._btn("" if tex != null else glyph, m.advice_go.bind(it), tip_text(it, desktop))
	if tex != null:
		b.icon = tex
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.name = "alert_" + it.id
	b.custom_minimum_size = Vector2(w, w)
	b.clip_text = true
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.add_theme_font_size_override("font_size", 22 if w < 50.0 else 26)
	# every state gets the slim card frame: the theme's button boxes have wide margins and would make
	# the icon taller than the bar (a Button sizes itself by its largest state box)
	var sb: StyleBox = UiTheme.card(it.kind, 6)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	b.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			dismissed[it.id] = true
			_items = order(_items, dismissed)
			_rebuild())
	return b


## A new alert flashes once so it is noticed.
func _blink(b: Button) -> void:
	b.modulate = Color(1.8, 1.6, 1.1)
	var tw := b.create_tween()
	tw.tween_property(b, "modulate", Color.WHITE, 0.8)
