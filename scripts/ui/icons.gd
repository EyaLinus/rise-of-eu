extends RefCounted
## Central icon lookup for the pixel-art pipeline.
## Every icon has an emoji fallback. If res://assets/art/icons/<key>.png exists it is used instead.
## Nation flags: key "flag_<TAG>" (e.g. flag_FRA.png). Army marker on the map: "army_marker".
## Recommended source size: 32x32 or 64x64 PNG, transparent background, nearest-neighbour filtering.

const DIR := "res://assets/art/icons/"
const EMOJI := {
	"gold": "💰", "adm": "📜", "dip": "🕊️", "mil": "⚔️", "manpower": "👥", "army": "🛡️", "ae": "😠",
	"prestige": "⭐", "dev": "🏘️", "fort": "🏰", "date": "📅", "siege": "🔥", "claim": "🎯",
	"tab_nation": "🏛️", "tab_economy": "💰", "tab_tech": "🔬", "tab_government": "⚖️", "tab_diplomacy": "🤝", "tab_wars": "⚔️", "tab_navy": "⚓", "tab_missions": "🎯", "tab_log": "📜",
	"tab_mapmode": "🗺️", "tab_advice": "💡", "event": "📯", "peace": "🕊️", "war": "🔥", "coalition": "⚠️",
	"vassal": "⛓️", "annex": "📜", "settlers": "🏕",
}

static var _cache := {}


static func emoji(key: String) -> String:
	return EMOJI.get(key, "")


static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := DIR + key + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[key] = tex
	return tex


## "💰 " when no texture exists, "" when a texture will be shown next to the text.
static func prefix(key: String) -> String:
	return "" if texture(key) != null else emoji(key) + " "


## Nations that proclaimed a new realm (Formables) show its flag: tag -> formable id, set by main.gd.
static var flag_alias := {}


static func flag_key(tag: String) -> String:
	return flag_alias.get(tag, tag)


static func flag(tag: String) -> Texture2D:
	var key := flag_key(tag)
	if key.begins_with("col:") or key.begins_with("app:"):
		var d := derived_flag(key)
		if d != null:
			return d
	var t := texture("flag_" + key)
	return t if t != null else texture("flag_" + tag)


## Flags of colonial nations ("col:<founder flag key>") and appanages ("app:<key>"), built from the founder's
## flag: a colony flies it as a canton on a field of the founder's main colour with a light stripe (ensign
## style), a cadet branch adds a bordure (the heraldic mark of a younger line) in red, or gold on red flags.
static func derived_flag(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var base: Texture2D = texture("flag_" + key.substr(4))
	if base == null:
		_cache[key] = null
		return null
	var src := base.get_image()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var u := maxi(1, h / 16)  # one grid pixel (flags are 24x16 grids, exported x2)
	var img: Image
	if key.begins_with("col:"):
		var main := _main_colour(src)
		img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(main.lerp(Color(0.92, 0.88, 0.75), 0.1))
		img.fill_rect(Rect2i(0, h - 6 * u, w, 2 * u), Color(0.95, 0.92, 0.8))
		var canton := src.duplicate()
		canton.resize(w / 2, h / 2, Image.INTERPOLATE_NEAREST)
		img.blit_rect(canton, Rect2i(0, 0, w / 2, h / 2), Vector2i.ZERO)
		img.fill_rect(Rect2i(w / 2, 0, u, h / 2 + u), Color(0.15, 0.12, 0.1))
		img.fill_rect(Rect2i(0, h / 2, w / 2, u), Color(0.15, 0.12, 0.1))
	else:
		img = src.duplicate()
		var main := _main_colour(src)
		var border := Color(0.9, 0.75, 0.2) if main.r > 0.55 and main.g < 0.4 else Color(0.75, 0.12, 0.12)
		for r in [Rect2i(u, u, w - 2 * u, 2 * u), Rect2i(u, h - 4 * u, w - 2 * u, 2 * u), Rect2i(u, u, 2 * u, h - 3 * u), Rect2i(w - 4 * u, u, 2 * u, h - 3 * u)]:
			img.fill_rect(r, border)
	# keep the founder flag's frame and shadow (outer two grid pixels)
	for r in [Rect2i(0, 0, w, u), Rect2i(0, 0, u, h), Rect2i(0, h - 2 * u, w, 2 * u), Rect2i(w - 2 * u, 0, 2 * u, h)]:
		img.blit_rect(src, r, r.position)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Most common opaque colour of a flag image.
static func _main_colour(img: Image) -> Color:
	var count := {}
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.s > 0.3 and c.v > 0.25:  # a real colour, not the white field or the dark frame
				var k := c.to_html(false)
				count[k] = count.get(k, 0) + 1
	var best := "808080"
	for k in count:
		if count[k] > count.get(best, 0):
			best = k
	return Color(best)
