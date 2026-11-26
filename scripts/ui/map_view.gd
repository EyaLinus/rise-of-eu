extends Control
## Zoomable/pannable 2D province map. Touch (drag, pinch, tap) and mouse (drag, wheel, click).

signal province_tapped(pid: int)
signal army_tapped(army_id: int)
signal province_long_pressed(pid: int)
signal province_context(pid: int, at: Vector2)  # right click (PC): quick actions

const SEA := Color("1d3a5c")
const SEA_DEEP := Color("132a45")  # open sea where no terrain tile is painted (art palette sea_deep)
const WASTE := Color("55574d")
const ARMY_R := 15.0
const Icons = preload("res://scripts/ui/icons.gd")
const PixelEmoji = preload("res://scripts/ui/pixel_emoji.gd")
const Warfare = preload("res://scripts/core/warfare.gd")
const Naval = preload("res://scripts/core/naval.gd")
const Colonial = preload("res://scripts/core/colonial.gd")
const Vision = preload("res://scripts/core/vision.gd")
## Fog of war (Vision): drifting pixel-art mist over known land the player cannot see right now. It is a
## pattern, not a flat dark veil, so a realm half in sight and half in the fog still reads as one colour.
const MistArt = preload("res://scripts/ui/map_mist.gd")
## Terra incognita (data/fog.json from tools/gen_seas.py): a coarse grid of New World regions, drawn by
## a shader (map_mist.gd) as ragged clouds at map resolution instead of the blurry grid itself.
const FOG_PATH := "res://data/fog.json"
## Painted base map (tools/art/map_terrain.py). Without it the map falls back to flat SEA/WASTE.

## The map below the Gulf of Guinea is cut into tiles (Africa, South America; map.json "terrain_tiles"):
## Android caps textures at 4096 px.
const TERRAIN_DIR := "res://assets/art/map/"
const FILL_ALPHA := 0.7
const NATIVE_ALPHA := 0.1
## Borders are quiet pixel lines: they separate, the colours and names carry the map.
const PROV_BORDER := Color(0.12, 0.09, 0.06, 0.17)
const NATION_BORDER := Color(0.07, 0.05, 0.09, 0.6)
const COAST := Color(0.03, 0.09, 0.16, 0.8)
const COUNTER_SIZE := Vector2(48, 28)
const SELECT := Color("f4d35e")  # selection and the player's realm border (gold from the art palette)
## war map mode: our side, our co-belligerents, enemies, everyone else
const WAR_US := Color("3a9d4a")
const WAR_ALLY := Color("4a7fd0")
const WAR_ENEMY := Color("c0392b")
const WAR_NEUTRAL := Color("5a5a52")

var game
var polys: Array = []
var bboxes: Array = []
var background: Array = []
var has_terrain := false  # the painted map texture is there (else plain polygons on a flat sea)
var _terrain_tiles: Array = []  # TextureRects of the painted map (map.json "terrain_tiles", a 2048 px grid)
var terrain_tile_defs: Array = []  # [file, x, y, w, h] in map pixels; open sea without a tile is plain SEA_DEEP
var _world: Node2D  # container of the world layer pieces (map_world_layer.gd)
var _world_zoom := -1.0
const WorldLayer = preload("res://scripts/ui/map_world_layer.gd")
var _layers: Array = []  # every piece of the world layer, in draw order
var _prov_layers: Array = []  # pid -> its fill piece
var world_redraws := 0  # pieces redrawn by the last refresh (debug, tests)
## nation labels: [tag, world anchor, province count], rebuilt with the world layer
var _realm_labels: Array = []
var _sea_rect: ColorRect
var _fog: Dictionary = {}  # parsed fog.json: cell, w, h, ids, cells (PackedInt32Array, 0 = never fogged)
var _fog_sprite: Sprite2D
var _fog_sig := ""
var _mist_tex: Texture2D  # fog of war pattern (tileable, MistArt)
var _veil_mat: ShaderMaterial  # shared by the province pieces: scales the mist with the zoom
var _sight := PackedByteArray()  # Vision.player_sight, empty = no fog of war (everything visible)
## Border segments in world space: points 2e and 2e+1 between provinces edge_l[e] and edge_r[e] (-1 = sea)
var edge_pts := PackedVector2Array()
var edge_l := PackedInt32Array()
var edge_r := PackedInt32Array()
var world_size := Vector2(2000, 1300)
var zoom := 0.8
var offset := Vector2.ZERO
var selected_pid := -1
var selected_army := -1
## province under the mouse pointer (desktop only; touch has no hover)
var hover_pid := -1
var _hover_pos := Vector2.ZERO
## war map mode: tag -> 1 us, 2 co-belligerent, -1 enemy (rebuilt every draw)
var _war_side := {}
var font: Font
## 0 political, 1 diplomatic (player view), 2 development, 3 unrest, 4 war, 5 goods, 6 trade (markets)
var map_mode := 0
var label_scale := 1.0  # >1 on phones / big UI: larger map text
const MODE_NAMES := ["Politisch", "Diplomatisch", "Entwicklung", "Unruhe", "Krieg", "Güter", "Handel", "Bauten", "Glaube", "Reich"]
const MODE_WAR := 4
const MODE_GOODS := 5
const MODE_TRADE := 6
const MODE_BUILD := 7
const MODE_FAITH := 8
const MODE_HRE := 9
## Holy Roman Empire map mode: tag -> "emperor", "elector" or "member" (rebuilt every draw)
var _hre_role := {}
const Faith = preload("res://scripts/core/religion.gd")
const MARKET_COLORS := ["c0392b", "2e5bd4", "e3b21b", "1e8449", "8e44ad", "d35400", "16a085", "7f8c8d", "e84393",
		"6c5ce7", "00b894", "fdcb6e", "a0522d"]

var _touches := {}
var _pinch_dist := 0.0
var _press_pos := Vector2.ZERO
var _moved := false
var _mouse_down := false
# touch comfort: long press, double tap, fling
const LONG_PRESS_S := 0.5
const DOUBLE_TAP_S := 0.3
var _press_time := 0.0
var _long_fired := false
var _last_tap_time := -10.0
var _last_tap_pos := Vector2.ZERO
var _velocity := Vector2.ZERO
var _touch_used := false


func setup(g, map_data: Dictionary) -> void:
	game = g
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = get_theme_default_font()
	polys.clear()
	bboxes.clear()
	background.clear()
	world_size = Vector2(map_data.size[0], map_data.size[1])
	terrain_tile_defs = map_data.get("terrain_tiles", [])
	for pd in map_data.provinces:
		var list := []
		var bb := Rect2()
		var first := true
		for poly in pd.polys:
			var arr := PackedVector2Array()
			for pt in poly:
				arr.append(Vector2(pt[0], pt[1]))
			list.append(arr)
			var r := _rect_of(arr)
			bb = r if first else bb.merge(r)
			first = false
		polys.append(list)
		bboxes.append(bb)
	for poly in map_data.background:
		var arr := PackedVector2Array()
		for pt in poly:
			arr.append(Vector2(pt[0], pt[1]))
		background.append(arr)
	_build_edges()
	_road_gates = {}
	_setup_terrain()
	if _world == null:
		_world = Node2D.new()
		_world.show_behind_parent = true
		add_child(_world)
	if _mist_tex == null:
		_mist_tex = MistArt.veil_texture()
		_veil_mat = MistArt.veil_material()
	if _prov_layers.size() != polys.size():
		for l in _layers:
			l.free()
		_layers.clear()
		_prov_layers.clear()
		_add_layer("bg")
		for pid in polys.size():
			_prov_layers.append(_add_layer("prov", pid))
		for k in ["terrain", "borders", "roads", "cities", "sea"]:
			_add_layer(k)
		if _fog_sprite != null:
			_world.move_child(_fog_sprite, -1)
	_setup_fog()
	if not resized.is_connected(_sync_terrain):
		resized.connect(_sync_terrain)
	_sync_terrain()
	refresh()


func _setup_fog() -> void:
	_fog = {}
	_fog_sig = ""
	if not FileAccess.file_exists(FOG_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(FOG_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	var run_id := PackedInt32Array()  # the grid as runs (id, length), row after row
	var run_len := PackedInt32Array()
	for row in d.rows:
		for i in range(0, row.size(), 2):
			run_id.append(int(row[i]))
			run_len.append(int(row[i + 1]))
	_fog = {"cell": float(d.cell), "w": int(d.w), "h": int(d.h), "ids": d.ids, "run_id": run_id, "run_len": run_len}
	if _fog_sprite == null:
		_fog_sprite = Sprite2D.new()
		_fog_sprite.centered = false
		_fog_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_world.add_child(_fog_sprite)
	_fog_sprite.scale = Vector2(_fog.cell, _fog.cell)
	_fog_sprite.material = MistArt.fog_material(_fog.w, _fog.h, _fog.cell)


## Fog over every New World sea and province the player has not discovered (rebuilt when that changes).
func _update_fog() -> void:
	if _fog.is_empty() or _fog_sprite == null:
		return
	var me: String = game.player
	var sig := "none"
	if me != "" and game.nations.has(me):
		var n = game.nations[me]
		sig = "%s:%d:%d" % [me, n.known_seas.size(), n.known_nw.size()]
	if sig == _fog_sig:
		return
	_fog_sig = sig
	if me == "":
		_fog_sprite.visible = false
		return
	var ids: Array = _fog.ids
	var known := PackedByteArray()
	known.resize(ids.size() + 1)
	known[0] = 1
	for i in ids.size():
		var key: String = ids[i]
		var ok: bool
		if key.begins_with("s:"):
			ok = Colonial.knows_sea(game, me, key.substr(2))
		else:
			ok = Colonial.knows(game, me, int(key.substr(2)))
		known[i + 1] = 1 if ok else 0
	# a one-byte mask (255 = unknown) built run by run; the shader turns it into clouds
	var w: int = _fog.w
	var h: int = _fog.h
	var run_id: PackedInt32Array = _fog.run_id
	var run_len: PackedInt32Array = _fog.run_len
	var full := PackedByteArray()
	full.resize(w)
	full.fill(255)
	var empty := PackedByteArray()
	empty.resize(w)
	var data := PackedByteArray()
	var any := false
	for r in run_id.size():
		var k: int = run_len[r]
		if known[run_id[r]] == 0:
			data.append_array(full.slice(0, k))
			any = true
		else:
			data.append_array(empty.slice(0, k))
	_fog_sprite.visible = any
	if any and data.size() == w * h:
		var img := Image.create_from_data(w, h, false, Image.FORMAT_L8, data)
		img.generate_mipmaps()  # the shader blurs the grid by reading a smaller mip level
		_fog_sprite.texture = ImageTexture.create_from_image(img)


## Fog of war: the player sees this province right now (own land, allies, armies, fleets, one province around).
func sees(pid: int) -> bool:
	return _sight.is_empty() or pid < 0 or pid >= _sight.size() or _sight[pid] != Vision.HIDDEN


func _update_sight() -> void:
	if game == null or game.player == "" or not game.fog_of_war:
		_sight = PackedByteArray()
	else:
		_sight = Vision.player_sight(game)


## The player has seen this province (always true in the Old World and without a player).
func known(pid: int) -> bool:
	return game == null or Colonial.knows(game, game.player, pid)


## Map pixels per texel of the fog of war mist: about two screen pixels at every zoom (powers of two,
## so the pattern stays crisp pixel art). Only shader uniforms follow it, no piece is redrawn.
func _mist_texel() -> float:
	var t := 2.0 / maxf(zoom, 0.05)
	return pow(2.0, roundf(log(t) / log(2.0)))


func _add_layer(kind: String, pid: int = -1) -> Node2D:
	var l := Node2D.new()
	l.set_script(WorldLayer)
	if kind == "prov":
		l.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		l.material = _veil_mat
	l.map = self
	l.kind = kind
	l.pid = pid
	_world.add_child(l)
	_layers.append(l)
	return l


## Redraws everything, including the whole world layer. Call this (not queue_redraw) after the game
## state, the map mode or the selection changed; queue_redraw() alone only redraws the screen-space overlay.
func refresh() -> void:
	_refresh_world(true)
	queue_redraw()


## Monthly tick: armies and labels are redrawn, of the costly world layer (hundreds of polygons,
## borders, roads) only the pieces that show something new. Most months that is a handful of provinces.
func refresh_after_tick() -> void:
	_refresh_world(false)
	queue_redraw()


func _refresh_world(force: bool) -> void:
	if _world == null or game == null:
		return
	_build_mode_data()
	_update_sight()
	world_redraws = 0
	for l in _layers:
		var sig = _layer_sig(l)
		if force or typeof(sig) != typeof(l.sig) or sig != l.sig:
			if l.kind == "borders":
				_build_realm_labels()
			l.sig = sig
			l.queue_redraw()
			world_redraws += 1
	_update_fog()


## What a piece of the world layer shows, as a value to compare with next month's.
func _layer_sig(l) -> Variant:
	match l.kind:
		"prov":
			var p = game.provinces[l.pid]
			var c := province_color(p)
			var hatch = _hatch_color(p)
			return [map_mode, c, hatch, zoom if hatch != null else 0.0, sees(l.pid)]
		"terrain":  # rivers + landscape sprites: only the zoom band (level of detail) and war mode change them
			return [map_mode == MODE_WAR, _terrain_lod()]
		"borders":
			var parts := [map_mode, zoom, game.player]
			for p in game.provinces:
				parts.append(p.owner)
			if map_mode == MODE_WAR:
				parts.append(_war_side.duplicate())
			var alive := 0
			for tag in game.order:
				if game.nations[tag].alive:
					alive += 1
			parts.append(alive)
			return hash(parts)
		"roads":
			var parts := [map_mode, zoom]
			for p in game.provinces:
				if int(p.buildings.get("road", 0)) > 0:
					parts.append([p.id, p.buildings.road, p.owner, p.controller])
			return hash(parts)
		"cities":
			var parts := [map_mode, zoom]
			for p in game.provinces:
				parts.append([p.urban, p.dev >= CITY_VILLAGE_DEV, p.dev >= CITY_BIG_DEV, p.buildings.get("harbor", 0) > 0, p.buildings.get("fortress", 0) > 0])
			parts.append(game.lm_ver)
			return hash(parts)
		"sea":
			return hash([zoom, game.player, game.sea_blocked.get(game.player, {})])
	return 0  # "bg" never changes


## Stripes over a province: another faith (faith mode), a colony being founded, an occupier. null = none.
func _hatch_color(p) -> Variant:
	if map_mode == MODE_FAITH:
		var own: String = game.nations[p.owner].religion
		if p.religion != own:
			return Color(Faith.FAITHS[own].color)
	elif p.colonist != "" and known(p.id):
		var sc: Color = game.nations[p.colonist].color
		sc.a = 0.8
		return sc
	elif p.controller != p.owner:
		var cc: Color = _occupier_color(p.controller)
		cc.a = 0.6 if map_mode != MODE_WAR else 0.9
		return cc
	return null


func _build_realm_labels() -> void:
	_realm_labels.clear()
	for tag in game.order:
		var owned: Array = game.provinces_of(tag)
		if game.nations[tag].alive and owned.size() >= 2:
			_realm_labels.append([tag, _realm_center(tag, owned), owned.size()])


## Terrain lives in child nodes drawn behind this one, so it can use linear filtering while the
## pixel-art icons on top keep nearest filtering. _sync_terrain() follows pan and zoom. The painted map is a
## grid of tiles (Android caps textures at 4096 px); tiles off screen are hidden.
func _setup_terrain() -> void:
	if _sea_rect == null:
		_sea_rect = ColorRect.new()
		_sea_rect.show_behind_parent = true
		_sea_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sea_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_sea_rect)
	if _terrain_tiles.is_empty():
		for td in terrain_tile_defs:
			var path: String = TERRAIN_DIR + str(td[0])
			if not ResourceLoader.exists(path):
				continue
			var r := TextureRect.new()
			r.show_behind_parent = true
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # VRAM-compressed with mipmaps (no shimmer when zoomed out)
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_SCALE
			r.texture = load(path)
			r.set_meta("rect", Rect2(td[1], td[2], td[3], td[4]))
			add_child(r)
			_terrain_tiles.append(r)
	has_terrain = not _terrain_tiles.is_empty()
	_sea_rect.color = SEA_DEEP if has_terrain else SEA
	_sync_terrain()


func _sync_terrain() -> void:
	if _world != null:
		_world.position = offset
		_world.scale = Vector2(zoom, zoom)
		if zoom != _world_zoom:  # line widths and zoom thresholds depend on it (plain fills do not)
			_world_zoom = zoom
			_refresh_world(false)
	var view := Rect2(-offset / zoom, size / zoom).grow(8.0)
	for r in _terrain_tiles:
		var rc: Rect2 = r.get_meta("rect")
		r.visible = view.intersects(rc)
		r.position = offset + rc.position * zoom
		# overlap the next tile by ~1.5 screen pixels: rounding at fractional zoom left hairline seams
		r.size = rc.size + Vector2.ONE * (1.5 / zoom)
		r.scale = Vector2(zoom, zoom)


func _edge_key(a: Vector2, b: Vector2) -> String:
	var ka := Vector2i(roundi(a.x * 10.0), roundi(a.y * 10.0))
	var kb := Vector2i(roundi(b.x * 10.0), roundi(b.y * 10.0))
	if ka.x > kb.x or (ka.x == kb.x and ka.y > kb.y):
		var t := ka
		ka = kb
		kb = t
	return "%d,%d,%d,%d" % [ka.x, ka.y, kb.x, kb.y]


## Splits all polygon outlines into unique segments and finds the province on the other side.
func _build_edges() -> void:
	var seen := {}
	edge_pts = PackedVector2Array()
	edge_l = PackedInt32Array()
	edge_r = PackedInt32Array()
	for pid in polys.size():
		for poly in polys[pid]:
			var n: int = poly.size()
			for i in n:
				var a: Vector2 = poly[i]
				var b: Vector2 = poly[(i + 1) % n]
				var k := _edge_key(a, b)
				if seen.has(k):
					var e: int = seen[k]
					if edge_r[e] == -1 and edge_l[e] != pid:
						edge_r[e] = pid
					continue
				seen[k] = edge_l.size()
				edge_pts.append(a)
				edge_pts.append(b)
				edge_l.append(pid)
				edge_r.append(-1)
	# segments whose vertices differ slightly between neighbours: probe both sides
	for e in edge_l.size():
		if edge_r[e] != -1:
			continue
		var a := edge_pts[e * 2]
		var b := edge_pts[e * 2 + 1]
		var nrm := (b - a).orthogonal().normalized() * 1.5
		for probe in [(a + b) / 2 + nrm, (a + b) / 2 - nrm]:
			var q := world_province_at(probe)
			if q >= 0 and q != edge_l[e]:
				edge_r[e] = q
				break


func world_province_at(w: Vector2) -> int:
	for pid in polys.size():
		if not bboxes[pid].has_point(w):
			continue
		for poly in polys[pid]:
			if Geometry2D.is_point_in_polygon(w, poly):
				return pid
	return -1


func _rect_of(arr: PackedVector2Array) -> Rect2:
	var r := Rect2(arr[0], Vector2.ZERO)
	for p in arr:
		r = r.expand(p)
	return r


func focus(world_pos: Vector2, z: float = -1.0) -> void:
	if z > 0:
		zoom = z
	offset = size / 2 - world_pos * zoom
	_clamp()
	queue_redraw()


func to_screen(w: Vector2) -> Vector2:
	return offset + w * zoom


func to_world(s: Vector2) -> Vector2:
	return (s - offset) / zoom


func zoom_by(factor: float, at: Vector2 = Vector2(-1, -1)) -> void:
	if at.x < 0:
		at = size / 2
	var before := to_world(at)
	zoom = clampf(zoom * factor, 0.3, 4.0)
	offset = at - before * zoom
	_clamp()
	queue_redraw()


## Moves the map by `delta` screen pixels (arrow keys).
func pan_by(delta: Vector2) -> void:
	offset += delta
	_clamp()
	queue_redraw()


func _clamp() -> void:
	var margin := 200.0
	var ws := world_size * zoom
	offset.x = (size.x - ws.x) / 2 if ws.x < size.x else clampf(offset.x, size.x - ws.x - margin, margin)
	offset.y = (size.y - ws.y) / 2 if ws.y < size.y else clampf(offset.y, size.y - ws.y - margin, margin)
	_sync_terrain()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if game == null:
		return
	_build_mode_data()
	_update_sight()
	var texel := _mist_texel()
	if _veil_mat != null:
		_veil_mat.set_shader_parameter("tile", MistArt.SIZE * texel)
	if _fog_sprite != null and _fog_sprite.material != null:
		_fog_sprite.material.set_shader_parameter("px", clampf(texel, 1.0, 8.0))
	draw_set_transform(offset, 0.0, Vector2(zoom, zoom))
	# hover / selection tint on top of the world layer's fill
	for pid in [hover_pid, selected_pid]:
		if pid >= 0 and pid < polys.size():
			var tint := Color(1, 1, 1, 0.24 if pid == selected_pid else 0.14)
			for poly in polys[pid]:
				draw_colored_polygon(poly, tint)
	if hover_pid >= 0 and hover_pid != selected_pid:
		# with an army selected the pointer shows the march target
		_outline(hover_pid, SELECT if selected_army >= 0 else Color(1, 1, 1, 0.7), 2.0)
	if selected_pid >= 0:
		_outline(selected_pid, Color(0, 0, 0, 0.75), 6.0)
		_outline(selected_pid, SELECT, 3.0)
	for f in _flashes:
		var age: float = (_now() - float(f.t0)) / FLASH_S
		if age < 1.0 and not f.has("off"):
			var gc: Color = f.color
			gc.a = 0.9 * (1.0 - age)
			_outline(f.pid, gc, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_badges()
	_draw_labels()
	_draw_colonies()
	_draw_seas()
	_draw_voyages()
	_draw_armies()
	_draw_hover_tip()


## War sides and HRE roles for the current map mode (used by fills, borders and counters).
func _build_mode_data() -> void:
	if map_mode == MODE_WAR:
		_build_war_sides()
	elif map_mode == MODE_HRE:
		_hre_role = {}
		for t in game.hre:
			_hre_role[t] = "member"
		for t in game.current_electors():
			_hre_role[t] = "elector"
		if game.emperor != "":
			_hre_role[game.emperor] = "emperor"


## Draws one piece of the world (no view culling, so panning never needs a redraw).
func _draw_layer(ci) -> void:
	if game == null:
		return
	match ci.kind:
		"bg":
			if not has_terrain:
				for bg in background:
					ci.draw_colored_polygon(bg, WASTE)
		"prov":
			var p = game.provinces[ci.pid]
			var c := province_color(p)
			if has_terrain:
				c.a = FILL_ALPHA if map_mode < 2 else 0.86
				if map_mode < 2 and p.owner == Colonial.NATIVE:
					c.a = NATIVE_ALPHA  # open land of its peoples: the painted forests, deserts and hills show through
			for poly in polys[p.id]:
				ci.draw_colored_polygon(poly, c)
			var hatch = _hatch_color(p)
			if hatch != null:
				for poly in polys[p.id]:
					_draw_hatch(ci, poly, bboxes[p.id], hatch)
			if not sees(p.id) and known(p.id):
				for poly in polys[p.id]:
					ci.draw_colored_polygon(poly, Color.WHITE, poly, _mist_tex)  # UV = map px, see _veil_mat
		"terrain":
			_draw_rivers(ci)
			_draw_terrain_glyphs(ci)
		"borders":
			_draw_borders(ci)
		"roads":
			_draw_roads(ci)
		"cities":
			_draw_cities(ci)
		"sea":
			_draw_sea_routes(ci)


## Roads are drawn faintly, like pencil lines on an old map: they should hint at the network without
## competing with borders, names and counters. Each one is a procedural path from one province centre
## through the shared border ("gate") to the next, bent by a little value noise seeded per road, and
## clipped to the land of the two provinces, so a road never runs across a bay or the sea. Only land
## neighbours get a road. Level 1 is a dotted track, 2 a thin line, 3 a slightly stronger royal road.
## The geometry is cached per province pair, so zooming only restyles the lines.
const ROAD_INK := Color(0.22, 0.14, 0.08)
const ROAD_ALPHA := [0.0, 0.32, 0.45, 0.58]
const ROAD_WIDTH := [0.0, 1.0, 1.25, 1.7]
const ROAD_ZOOM := 0.7  # below this the network is noise: no roads at all
var _road_gates := {}  # Vector2i(lo, hi) -> point on their shared land border
var _road_paths := {}  # Vector2i(lo, hi) -> Array of PackedVector2Array (pieces on land)


func _build_road_gates() -> void:
	_road_gates = {}
	_road_paths = {}
	var acc := {}  # key -> [weighted sum, total length, edge midpoints]
	for e in edge_l.size():
		var r := edge_r[e]
		if r < 0 or r == edge_l[e]:
			continue
		var a := edge_pts[e * 2]
		var b := edge_pts[e * 2 + 1]
		var k := Vector2i(mini(edge_l[e], r), maxi(edge_l[e], r))
		if not acc.has(k):
			acc[k] = [Vector2.ZERO, 0.0, []]
		var ln := a.distance_to(b)
		acc[k][0] += (a + b) * 0.5 * ln
		acc[k][1] += ln
		acc[k][2].append((a + b) * 0.5)
	for k in acc:
		if acc[k][1] < 6.0:  # a corner touch, not a real border
			continue
		var avg: Vector2 = acc[k][0] / acc[k][1]
		var best: Vector2 = acc[k][2][0]
		for m in acc[k][2]:  # snap onto the border itself (concave borders)
			if m.distance_squared_to(avg) < best.distance_squared_to(avg):
				best = m
		_road_gates[k] = best


## Smooth 1D value noise in [-1, 1] (hash per integer step, smoothstep between).
static func _vnoise(x: float, salt: int) -> float:
	var i := floori(x)
	var f := x - i
	var a := float(hash(Vector2i(i, salt)) % 2001) / 1000.0 - 1.0
	var b := float(hash(Vector2i(i + 1, salt)) % 2001) / 1000.0 - 1.0
	return lerpf(a, b, f * f * (3.0 - 2.0 * f))


## Points of a curve from a over the gate g to b, bent by two octaves of noise (never at the ends or
## the gate, so neighbouring roads still meet).
func _road_curve(a: Vector2, g: Vector2, b: Vector2, salt: int) -> PackedVector2Array:
	var c := 2.0 * g - (a + b) * 0.5  # quadratic Bezier through g at t = 0.5
	var ln := a.distance_to(b)
	var steps := clampi(int(ln / 7.0), 8, 32)
	var nrm := (b - a).orthogonal().normalized()
	var amp := clampf(ln * 0.035, 1.0, 4.0)
	var pts := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		var pt := (1.0 - t) * (1.0 - t) * a + 2.0 * (1.0 - t) * t * c + t * t * b
		var env := absf(sin(t * TAU))  # zero at both ends and at the gate
		var n := _vnoise(t * 4.0, salt) * 0.7 + _vnoise(t * 11.0, salt + 7) * 0.3
		pts.append(pt + nrm * n * amp * env)
	return pts


## The road between p and q as pieces that stay on their land. A curve that would leave it (bays,
## crescent-shaped coasts) first falls back to straight legs over the gate; whatever still lies on water
## is cut out, so at worst a road ends at the shore.
func _road_path(p, q, k: Vector2i) -> Array:
	if _road_paths.has(k):
		return _road_paths[k]
	var g: Vector2 = _road_gates[k]
	var on_land := func(pt: Vector2) -> bool: return _in_province(p.id, pt) or _in_province(q.id, pt)
	var pts := _road_curve(p.center, g, q.center, p.id * 31 + q.id)
	var ok := true
	for pt in pts:
		if not on_land.call(pt):
			ok = false
			break
	var out := []
	if ok:
		out.append(pts)
	else:
		var legs := PackedVector2Array()
		var ends := [p.center, g, q.center]
		for li in 2:
			var n := maxi(2, int(ends[li].distance_to(ends[li + 1]) / 4.0))
			for i in range(1 if li == 1 else 0, n + 1):
				legs.append(ends[li].lerp(ends[li + 1], float(i) / n))
		var run := PackedVector2Array()
		for pt in legs:
			if on_land.call(pt):
				run.append(pt)
			else:
				if run.size() >= 2:
					out.append(run)
				run = PackedVector2Array()
		if run.size() >= 2:
			out.append(run)
	_road_paths[k] = out
	return out


func _dashed_polyline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, dash: float, gap: float) -> void:
	var on := true
	var left := dash
	var seg := PackedVector2Array([pts[0]])
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var d := a.distance_to(b)
		var pos := 0.0
		while d - pos > left:
			pos += left
			var q := a.lerp(b, pos / d)
			if on:
				seg.append(q)
				ci.draw_polyline(seg, col, w)
			seg = PackedVector2Array([q])
			on = not on
			left = dash if on else gap
		left -= d - pos
		if on:
			seg.append(b)
	if on and seg.size() > 1:
		ci.draw_polyline(seg, col, w)


func _draw_roads(ci: CanvasItem) -> void:
	if zoom < ROAD_ZOOM or map_mode == MODE_WAR:
		return
	if _road_gates.is_empty() and not edge_l.is_empty():
		_build_road_gates()
	var px := 1.0 / zoom * clampf(zoom, 0.8, 1.5)  # one screen pixel, growing a little when zoomed in
	var by_lv := [[], [], [], []]
	for p in game.provinces:
		var lv: int = int(p.buildings.get("road", 0))
		if lv <= 0:
			continue
		for q in p.adj:
			if q < p.id:
				continue
			var o = game.provinces[q]
			var lo: int = int(o.buildings.get("road", 0))
			var k := Vector2i(p.id, q)
			if lo <= 0 or not _road_gates.has(k):
				continue
			by_lv[clampi(mini(lv, lo), 1, 3)].append_array(_road_path(p, o, k))
	for lv in [1, 2, 3]:
		var col := Color(ROAD_INK, ROAD_ALPHA[lv])
		var w: float = ROAD_WIDTH[lv] * px
		for pts in by_lv[lv]:
			if lv == 1:
				_dashed_polyline(ci, pts, col, w, 3.0 * px, 3.0 * px)
			else:
				ci.draw_polyline(pts, col, w, true)


## Settlements: a walled city, a town or a village sprite in every province that has grown enough
## (urban provinces always, countryside from `city_village_dev`), so development shows on the map.
const CITY_VILLAGE_DEV := 8
const CITY_BIG_DEV := 16
const CITY_VILLAGE_ZOOM := 0.9  # villages only once single provinces matter; towns and cities from 0.55
const CITY_HARBOR_ZOOM := 1.2
const CITY_TINT := Color(0.95, 0.92, 0.86, 0.94)  # a touch of the parchment tone, so sprites sit in the map
## Major rivers (tools/art/rivers.py), drawn over the province colours so the land reads like an old atlas.
## Close up they are pixel art on the same grid as the terrain glyphs: the generator rasterises them
## once into the 32 px tiles that hold river pixels, packed in one atlas texture (data/river_tiles.json),
## so this is a few hundred rects from one texture (one batch). Zoomed out, where single pixels would
## flicker, the same meandered courses (data/rivers.json) are thin smooth lines.
var _rivers: Array = []
var _river_tiles: Array = []  # [Rect2 on the map, Rect2 in the atlas]
var _river_atlas: Texture2D
var _rivers_loaded := false
const RIVER_INK := Color(0.16, 0.3, 0.45, 0.85)
const RIVER_PIXEL_ZOOM := 0.8  # from here on the pixel-art rivers


## Level of detail of the "terrain" layer: 0 rivers as lines only, 1 + landscape sprites, 2 pixel rivers.
func _terrain_lod() -> int:
	return 2 if zoom >= RIVER_PIXEL_ZOOM else (1 if zoom >= 0.55 else 0)


func _load_rivers() -> void:
	_rivers_loaded = true
	var f := FileAccess.open("res://data/rivers.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		if d is Array:
			for r in d:
				var pts := PackedVector2Array()
				for q in r.pts:
					pts.append(Vector2(q[0], q[1]))
				_rivers.append([pts, float(r.get("w", 2))])
	const ATLAS := "res://assets/art/map/rivers_atlas.png"
	var tf := FileAccess.open("res://data/river_tiles.json", FileAccess.READ)
	if tf != null and ResourceLoader.exists(ATLAS):
		var td = JSON.parse_string(tf.get_as_text())
		if td is Dictionary:
			_river_atlas = load(ATLAS)
			var ts := float(td.get("tile", 32))
			for t in td.get("tiles", []):
				_river_tiles.append([Rect2(t[0], t[1], ts, ts), Rect2(t[2], t[3], ts, ts)])


func _draw_rivers(ci: CanvasItem) -> void:
	if not _rivers_loaded:
		_load_rivers()
	if map_mode == MODE_WAR:
		return
	if _terrain_lod() == 2 and _river_atlas != null:
		for t in _river_tiles:
			ci.draw_texture_rect_region(_river_atlas, t[0], t[1])
		return
	for r in _rivers:
		ci.draw_polyline(r[0], RIVER_INK, 1.0 + 0.6 * r[1], true)


## Small landscape sprites (tools/art/terrain_glyphs.py): woods, dunes or an oasis palm, reeds, hills.
## Placed once per province at fixed spots inside its outline, away from the centre (city, labels).
var _glyph_spots := {}  # pid -> Array of [texture key, world position]
const GLYPH_OFFSETS := [Vector2(-30, -20), Vector2(26, -22), Vector2(-32, 14), Vector2(28, 16), Vector2(0, -30)]

func _glyphs_for(p) -> Array:
	if _glyph_spots.has(p.id):
		return _glyph_spots[p.id]
	var keys: Array = []
	match p.terrain:
		"forest":
			keys = ["terr_forest", "terr_forest"]
		"desert":
			keys = ["terr_oasis" if p.dev >= 5 else "terr_dunes", "terr_dunes"]
		"marsh":
			keys = ["terr_marsh"]
		"hills":
			keys = ["terr_hills"]
	var bb: Rect2 = bboxes[p.id]
	if bb.size.x * bb.size.y < 9000.0:
		keys = keys.slice(0, 1)
	var out := []
	var oi := 0
	var badge := Rect2(_badge_spot(p) - BADGE_MAP / 2.0, BADGE_MAP).grow(9.0)
	for k in keys:
		while oi < GLYPH_OFFSETS.size():
			var at: Vector2 = p.center + GLYPH_OFFSETS[oi]
			oi += 1
			if badge.has_point(at):
				continue
			var inside := false
			for poly in polys[p.id]:
				if Geometry2D.is_point_in_polygon(at, poly):
					inside = true
					break
			if inside:
				out.append([k, at])
				break
	_glyph_spots[p.id] = out
	return out


const GLYPH_TINT := Color(0.96, 0.94, 0.88, 0.72)  # landscape sprites sit in the terrain, not on top of it


func _draw_terrain_glyphs(ci: CanvasItem) -> void:
	if zoom < 0.55 or map_mode == MODE_WAR:
		return
	for p in game.provinces:
		for g in _glyphs_for(p):
			var tex := Icons.texture(g[0])
			if tex == null:
				continue
			var sz: Vector2 = tex.get_size() * 0.5
			ci.draw_texture_rect(tex, Rect2(g[1] - sz / 2.0, sz), false, GLYPH_TINT)


func _draw_cities(ci: CanvasItem) -> void:
	if zoom < 0.55 or map_mode == MODE_WAR:
		return
	var village := Icons.texture("city_village")
	var town := Icons.texture("city_town")
	var city := Icons.texture("city_city")
	var harbor := Icons.texture("city_harbor")
	if village == null or town == null or city == null:
		return
	var show_villages := zoom >= CITY_VILLAGE_ZOOM
	var show_harbors := zoom >= CITY_HARBOR_ZOOM
	for p in game.provinces:
		if show_harbors and harbor != null and p.buildings.get("harbor", 0) > 0:
			var hs: Vector2 = harbor.get_size() * 0.5
			ci.draw_texture_rect(harbor, Rect2(p.center + Vector2(-hs.x - 14.0, 8.0), hs), false, CITY_TINT)
		var tex: Texture2D = null
		if p.urban:
			tex = city if p.dev >= CITY_BIG_DEV or p.buildings.get("fortress", 0) > 0 else town
		elif p.dev >= CITY_VILLAGE_DEV and show_villages:
			tex = village
		if tex == null:
			continue
		var sz: Vector2 = tex.get_size() * 0.5
		var pos: Vector2 = p.center + Vector2(-sz.x / 2.0, 6.0)
		ci.draw_rect(Rect2(pos + Vector2(1, sz.y - 1), Vector2(sz.x, 2)), Color(0, 0, 0, 0.18))
		ci.draw_texture_rect(tex, Rect2(pos, sz), false, CITY_TINT)
	_draw_landmarks(ci)


## Historical landmarks (scripts/core/landmarks.gd): the highest built one of a province as a small
## sprite right of the settlement, with one gold pip per level underneath.
const LM_PIP := Color(0.973, 0.871, 0.494)
const LM_PIP_EDGE := Color(0.106, 0.086, 0.133, 0.85)


func _draw_landmarks(ci: CanvasItem) -> void:
	for pid in game.lm_at:
		var id: String = game.Landmarks.shown(game, pid)
		if id == "":
			continue
		var tex := Icons.texture("lm_" + str(game.lm_defs[id].kind))
		if tex == null:
			continue
		var p = game.provinces[pid]
		var sz: Vector2 = tex.get_size() * 0.625  # 12 grid px drawn as 15 map px, about a town
		var pos: Vector2 = p.center + Vector2(6.0, 12.0 - sz.y)  # right of the settlement, same baseline
		ci.draw_rect(Rect2(pos + Vector2(1, sz.y - 1), Vector2(sz.x, 2)), Color(0, 0, 0, 0.35))
		ci.draw_texture_rect(tex, Rect2(pos, sz), false)
		var lvl: int = game.Landmarks.level(game, id)
		var x0: float = pos.x + sz.x * 0.5 - (lvl * 2.5 - 0.5) * 0.5
		for i in lvl:
			var r := Rect2(Vector2(x0 + i * 2.5, pos.y + sz.y + 0.8), Vector2(2, 2))
			ci.draw_rect(r.grow(0.4), LM_PIP_EDGE)
			ci.draw_rect(r, LM_PIP)


## Province badges: a small dark plaque beside the province centre with its terrain (tools/art/terrain_glyphs.py,
## tico_*) and its trade good (the good's pixel emoji). Drawn in screen space at a fixed size (16 px icons
## times the label scale), so they stay crisp pixel art and small at any zoom, and only for provinces on
## screen. Shown together with the province names (BADGE_ZOOM), in the goods map mode earlier; hidden in
## the war mode. Grouped by texture (plaques, terrain icons, goods), so it is a few dozen batches.
const BADGE_ZOOM := 1.5  # plain trade-good icon, no plaque (the terrain shows on the map itself)
const BADGE_ZOOM_GOODS := 0.7  # goods map mode: the full plaque with terrain + good
const BADGE_PLAIN := Color(1, 1, 1, 0.8)
const BADGE_MAP := Vector2(34, 17)  # the plaque's footprint in map px (for the fit test and the glyphs)
const BADGE_SPOTS := [Vector2(40, 3), Vector2(-40, 3), Vector2(0, -40), Vector2(0, 42)]
const BADGE_BACK := Color(0.106, 0.086, 0.133, 0.62)
const BADGE_EDGE := Color(0.937, 0.894, 0.784, 0.35)
var _badge_spots := {}  # pid -> plaque centre (map px)
var _good_tex := {}  # good -> its pixel emoji texture (or null)


func _badges_shown() -> bool:
	return map_mode != MODE_WAR and zoom >= (BADGE_ZOOM_GOODS if map_mode == MODE_GOODS else BADGE_ZOOM)


## Centre of the plaque: the first spot beside the centre (right, left, above, below) that fits inside
## the province, so it keeps clear of the name, the city sprite and the army counters.
func _badge_spot(p) -> Vector2:
	if _badge_spots.has(p.id):
		return _badge_spots[p.id]
	var best: Vector2 = p.center + BADGE_SPOTS[0]
	var found := false
	for off in BADGE_SPOTS:
		var c: Vector2 = p.center + off
		var ok := true
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2.ZERO]:
			if not _in_province(p.id, c + corner * BADGE_MAP / 2.0):
				ok = false
				break
		if ok:
			best = c
			found = true
			break
	if not found:  # small province: at least the plaque's centre inside it
		for off in BADGE_SPOTS:
			if _in_province(p.id, p.center + off * 0.75):
				best = p.center + off * 0.75
				break
	_badge_spots[p.id] = best
	return best


func _in_province(pid: int, q: Vector2) -> bool:
	for poly in polys[pid]:
		if Geometry2D.is_point_in_polygon(q, poly):
			return true
	return false


func _good_texture(good: String) -> Texture2D:
	if _good_tex.has(good):
		return _good_tex[good]
	var tex: Texture2D = null
	var gd: Dictionary = game.goods_def.get(good, {})
	var e: String = gd.get("emoji", "")
	if e != "":
		var name: String = PixelEmoji.glyph_name(e.unicode_at(0))
		var path := "res://assets/art/emoji/%s.png" % name
		if name != "" and ResourceLoader.exists(path):
			tex = load(path)
	_good_tex[good] = tex
	return tex


## The part of an icon texture that holds pixels, cached (the plaque hugs the icons, no empty margins).
var _used_rects := {}

func _used_rect(tex: Texture2D) -> Rect2:
	if not _used_rects.has(tex):
		var r := Rect2(Vector2.ZERO, tex.get_size())
		var img := tex.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var u := img.get_used_rect()
			if u.size.x > 0:
				r = Rect2(u)
		_used_rects[tex] = r
	return _used_rects[tex]


func _draw_badges() -> void:
	if not _badges_shown():
		return
	var plaque := map_mode == MODE_GOODS
	var u := maxf(1.5, roundf(label_scale * 3.0) / 2.0)  # screen px per art pixel (half steps)
	var view := Rect2(Vector2.ZERO, size).grow(60.0)
	var by_tex := {}  # texture -> Array of [source rect, screen rect]
	for p in game.provinces:
		var c := to_screen(_badge_spot(p))
		if not view.has_point(c) or not known(p.id):
			continue
		var parts := []
		var w := u
		var h := 0.0
		for tex in ([Icons.texture("tico_" + p.terrain), _good_texture(p.good)] if plaque else [_good_texture(p.good)]):
			if tex == null:
				continue
			var src := _used_rect(tex)
			var sz: Vector2 = src.size * (16.0 / tex.get_width()) * u
			parts.append([tex, src, sz])
			w += sz.x + u
			h = maxf(h, sz.y)
		if parts.is_empty():
			continue
		var r := Rect2((c - Vector2(w, h + 2.0 * u) / 2.0).round(), Vector2(w, h + 2.0 * u).round())
		if plaque:
			draw_rect(r, BADGE_BACK)
			draw_rect(r, BADGE_EDGE, false, 1.0)
		var x := r.position.x + u
		for part in parts:
			var at: Vector2 = Vector2(x, r.position.y + u + (h - part[2].y) / 2.0).round()
			if not by_tex.has(part[0]):
				by_tex[part[0]] = []
			by_tex[part[0]].append([part[1], Rect2(at, part[2])])
			x += part[2].x + u
	for tex in by_tex:
		for q in by_tex[tex]:
			draw_texture_rect_region(tex, q[1], q[0], Color.WHITE if plaque else BADGE_PLAIN)


## Sea crossings: a dotted ferry line; red while an enemy fleet rules that sea for the player.
func _draw_sea_routes(ci: CanvasItem) -> void:
	if zoom < 0.45:
		return
	for k in game.straits:
		var a: int = int(k / 10000)
		var b: int = int(k % 10000)
		var pa: Vector2 = game.provinces[a].center
		var pb: Vector2 = game.provinces[b].center
		var blocked: bool = game.player != "" and not Naval.can_cross(game, game.player, a, b)
		if blocked:
			ci.draw_dashed_line(pa, pb, Color(0, 0, 0, 0.45), 3.5 / zoom, 6.0 / zoom)
			ci.draw_dashed_line(pa, pb, Color(0.95, 0.3, 0.25, 0.95), 2.0 / zoom, 6.0 / zoom)
		else:  # a light dotted ferry line: it must not read as a road over the water
			ci.draw_dashed_line(pa, pb, Color(0.85, 0.93, 1.0, 0.42), 1.4 / zoom, 2.5 / zoom)


## Sea names; while the player is at war also who rules each sea (our ships : enemy ships). Fleets show
## as ship badges under the sea name (ours always, enemy fleets in war), sea battles flash where they happen.
func _draw_seas() -> void:
	var me: String = game.player
	var war: bool = me != "" and game.is_at_war(me)
	_check_sea_fights()
	var ours := [me]
	for w in game.wars_of(me):
		for t in game.side_tags(w, game.is_attacker(w, me)):
			if not ours.has(t):
				ours.append(t)
	var foes: Array = game.enemies_of(me) if war else []
	for s in game.seas:
		if me != "" and not Colonial.knows_sea(game, me, s.id):
			continue
		var sp := to_screen(s.center)
		if not Rect2(Vector2(-80, -40), size + Vector2(160, 80)).has_point(sp):
			continue
		var us := Naval.side_power(game, ours, s.id) if me != "" else 0.0
		var them := Naval.side_power(game, foes, s.id) if war else 0.0
		if war or map_mode == MODE_WAR:
			var txt: String = "⚓ " + s.name
			var col := Color(0.8, 0.9, 1.0, 0.85)
			if war and (us > 0.0 or them > 0.0):
				txt += "  %s : %s" % [Naval.fmt(us), Naval.fmt(them)]
				if game.sea_blocked.get(me, {}).has(s.id):
					col = Color(1.0, 0.45, 0.4)
				elif us > 0.0 and us >= them * float(game.bal.sea_control_ratio):
					col = Color(0.5, 1.0, 0.5)
				else:
					col = Color(1.0, 0.9, 0.5)
			var fs := 15
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string_outline(font, sp - Vector2(w / 2, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.85))
			draw_string(font, sp - Vector2(w / 2, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if zoom < 0.45:
			continue
		# fleet badges: our own ships, and in war the enemy's
		var mine: float = float(game._fleet.get(me, {}).get(s.id, 0.0)) if me != "" else 0.0
		var enemy := 0.0
		var enemy_tag := ""
		for t in foes:
			var e: float = float(game._fleet.get(t, {}).get(s.id, 0.0))
			if e > enemy:
				enemy_tag = t
			enemy += e
		var badges := []
		if mine >= 0.5:
			badges.append([me, mine, false])
		if enemy >= 0.5:
			badges.append([enemy_tag, enemy, true])
		for i in badges.size():
			var bp: Vector2 = sp + Vector2((i - (badges.size() - 1) / 2.0) * 58.0, 24.0)
			_draw_fleet_badge(bp, badges[i][0], badges[i][1], badges[i][2])
	_draw_blockades()
	_draw_sea_fights()


## Blockaded coasts the player cares about (own land, or the enemy's in war): a red anchor badge.
func _draw_blockades() -> void:
	if zoom < 0.45 or game.blockaded.is_empty():
		return
	var me: String = game.player
	for pid in game.blockaded:
		var p = game.provinces[pid]
		if me != "" and p.owner != me and not game.at_war(me, p.owner):
			continue
		var sp := to_screen(p.center) + Vector2(-30, -16)
		if not Rect2(Vector2(-30, -30), size + Vector2(60, 60)).has_point(sp):
			continue
		draw_circle(sp, 11.0, Color(0, 0, 0, 0.85))
		draw_circle(sp, 9.5, Color(0.75, 0.15, 0.12, 0.95) if p.owner == me else Color(0.2, 0.45, 0.8, 0.95))
		draw_string(font, sp + Vector2(-7, 5), "⚓", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


## A ship badge: nation colour, ship glyph and the number of ships (red ring for an enemy fleet).
func _draw_fleet_badge(at: Vector2, tag: String, ships: float, enemy: bool) -> void:
	var c: Color = game.nations[tag].color
	var r := Rect2(at - Vector2(26, 11), Vector2(52, 22))
	draw_rect(r.grow(2.0), Color(0.85, 0.2, 0.15, 0.95) if enemy else Color(0, 0, 0, 0.9))
	draw_rect(r, c.darkened(0.25))
	var bob := sin(_now() * 2.0 + at.x * 0.01) * 1.5
	draw_string(font, at + Vector2(-23, 6 + bob), "⛵", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	var txt := "%d" % int(round(ships))
	draw_string_outline(font, at + Vector2(-2, 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 3, Color.BLACK)
	draw_string(font, at + Vector2(-2, 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)


const SEA_FIGHT_S := 3.5
var _sea_fight_seen := {}  # fight dictionary -> wall clock when first shown


## New sea battles this month (Naval records them in game.sea_fights): start their map animation.
func _check_sea_fights() -> void:
	for f in game.sea_fights:
		if not _sea_fight_seen.has(f):
			_sea_fight_seen[f] = _now()
	for f in _sea_fight_seen.keys():
		if _now() - float(_sea_fight_seen[f]) > SEA_FIGHT_S:
			_sea_fight_seen.erase(f)


## Sea battle: pulsing cannon smoke over the sea and the ships each side lost floating up.
func _draw_sea_fights() -> void:
	var me: String = game.player
	for f in _sea_fight_seen:
		var sea = null
		for s in game.seas:
			if s.id == f.sea:
				sea = s
				break
		if sea == null or (me != "" and not Colonial.knows_sea(game, me, f.sea)):
			continue
		var age: float = (_now() - float(_sea_fight_seen[f])) / SEA_FIGHT_S
		var sp := to_screen(sea.center) + Vector2(0, -34)
		if not Rect2(Vector2(-60, -60), size + Vector2(120, 120)).has_point(sp):
			continue
		var a := 1.0 - age * age
		for k in 4:
			var ang: float = k * TAU / 4.0 + _now() * 1.5
			draw_circle(sp + Vector2(cos(ang), sin(ang)) * (8.0 + 10.0 * age), 7.0 + 6.0 * age, Color(0.85, 0.85, 0.8, 0.45 * a))
		draw_circle(sp, 16.0, Color(0, 0, 0, 0.85 * a))
		draw_circle(sp, 14.0, Color(0.15, 0.3, 0.6, a))
		draw_string(font, sp + Vector2(-9, 6), "⚓", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, a))
		var lines := [["-%.1f ⛵" % float(f.lost), game.nations[f.lose].color.lightened(0.35)], ["-%.1f ⛵" % float(f.won_lost), game.nations[f.win].color.lightened(0.35)]]
		for i in 2:
			var tp: Vector2 = sp + Vector2(-34 if i == 0 else 34, -20 - age * 30)
			var t: String = lines[i][0]
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			var c: Color = lines[i][1]
			c.a = a
			draw_string_outline(font, tp - Vector2(w / 2, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 3, Color(0, 0, 0, a))
			draw_string(font, tp - Vector2(w / 2, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)
	if not _sea_fight_seen.is_empty():
		queue_redraw()


## Province outline with a constant on-screen width (world-space transform must be active).
func _outline(pid: int, c: Color, px: float) -> void:
	for poly in polys[pid]:
		var closed: PackedVector2Array = poly.duplicate()
		closed.append(poly[0])
		draw_polyline(closed, c, px / zoom)


func _build_war_sides() -> void:
	_war_side.clear()
	var me: String = game.player
	if me == "":
		return
	_war_side[me] = 1
	for w in game.wars_of(me):
		var att: bool = game.is_attacker(w, me)
		for t in game.side_tags(w, att):
			if t != me:
				_war_side[t] = 2
		for t in game.side_tags(w, not att):
			_war_side[t] = -1


func _war_color(tag: String) -> Color:
	match _war_side.get(tag, 0):
		1:
			return WAR_US
		2:
			return WAR_ALLY
		-1:
			return WAR_ENEMY
	return WAR_NEUTRAL


## Stripe colour for occupied provinces: the occupier's colour, or its war side in the war map mode.
func _occupier_color(tag: String) -> Color:
	if map_mode == MODE_WAR:
		return _war_color(tag).lightened(0.15)
	return game.nations[tag].color


## Small label next to the mouse pointer: province, owner flag and name, siege progress.
func _draw_hover_tip() -> void:
	if hover_pid < 0 or game == null:
		return
	var p = game.provinces[hover_pid]
	if not known(hover_pid):
		_draw_tip_box(["Terra incognita", "Unerforschtes Land: erst eine Expedition aussenden."])
		return
	var txt := "%s · %s %s" % [p.name, PixelEmoji.nation(p.owner, game.nations[p.owner].emoji), game.nations[p.owner].name]
	if p.owner == Colonial.NATIVE:
		txt = "%s · 🪶 Ureinwohner (%d)" % [p.name, int(p.natives)]
		if p.colonist != "":
			txt += " · 🏕 Kolonie %s %d %%" % [game.nations[p.colonist].name, int(Colonial.progress(game, p.id) * 100.0)]
	if p.controller != p.owner:
		txt += " (besetzt: %s)" % game.nations[p.controller].name
	var line2 := "Entwicklung %d · %s" % [p.dev, Warfare.terrain_name(game, p.id)]
	var fight = Warfare.battle_at(game, p.id) if sees(p.id) else null
	if not sees(p.id):
		line2 += " · 🌫 Nebel: Truppen unbekannt"
	if fight != null:
		line2 += " · ⚔️ Schlacht (%s)" % Warfare.phase(fight)
	if Naval.is_blockaded(game, p.id):
		line2 += " · ⚓ blockiert"
	for bid in p.buildings:
		var lv: int = int(p.buildings[bid])
		if lv > 0 and game.buildings_def.has(bid):
			line2 += "  %s%d" % [game.buildings_def[bid].get("emoji", "🏠"), lv]
	var fs := 15
	var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var sz2 := font.get_string_size(line2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2)
	var w := maxf(sz.x, sz2.x)
	var lh := sz.y + 2.0
	var pos := _hover_pos + Vector2(16, 26)
	pos.x = minf(pos.x, size.x - w - 12)
	pos.y = minf(pos.y, size.y - 12 - lh)
	draw_rect(Rect2(pos - Vector2(6, sz.y - 2), Vector2(w + 12, sz.y + 6 + lh)), Color(0.09, 0.1, 0.13, 0.88))
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	draw_string(font, pos + Vector2(0, lh), line2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, Color(0.85, 0.85, 0.8))


func _draw_tip_box(lines: Array) -> void:
	var fs := 15
	var sz := font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var sz2 := font.get_string_size(lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2)
	var w := maxf(sz.x, sz2.x)
	var lh := sz.y + 2.0
	var pos := _hover_pos + Vector2(16, 26)
	pos.x = minf(pos.x, size.x - w - 12)
	pos.y = minf(pos.y, size.y - 12 - lh)
	draw_rect(Rect2(pos - Vector2(6, sz.y - 2), Vector2(w + 12, sz.y + 6 + lh)), Color(0.09, 0.1, 0.13, 0.88))
	draw_string(font, pos, lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	draw_string(font, pos + Vector2(0, lh), lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, Color(0.85, 0.85, 0.8))


## Province borders thin, coasts medium, borders between different owners thick.
func _draw_borders(ci: CanvasItem) -> void:
	if edge_l.is_empty():
		return
	var thin := PackedVector2Array()
	var coast := PackedVector2Array()
	var nation := PackedVector2Array()
	var realm := PackedVector2Array()  # outer border of the player's realm (political mode)
	var front := PackedVector2Array()  # borders between enemies (war mode)
	var me: String = game.player
	for e in edge_l.size():
		var a := edge_pts[e * 2]
		var b := edge_pts[e * 2 + 1]
		var r := edge_r[e]
		if r < 0:
			coast.append(a)
			coast.append(b)
		elif game.provinces[edge_l[e]].owner != game.provinces[r].owner:
			nation.append(a)
			nation.append(b)
			var ol: String = game.provinces[edge_l[e]].owner
			var orr: String = game.provinces[r].owner
			if map_mode == 0 and me != "" and (ol == me or orr == me):
				realm.append(a)
				realm.append(b)
			elif map_mode == MODE_WAR and _war_side.get(ol, 0) * _war_side.get(orr, 0) < 0:
				front.append(a)
				front.append(b)
		else:
			thin.append(a)
			thin.append(b)
	if zoom >= 0.6 and not thin.is_empty():
		ci.draw_multiline(thin, PROV_BORDER, 1.0 / zoom)
	if not coast.is_empty():
		ci.draw_multiline(coast, COAST, 1.5 / zoom)
	var nw := 2.0 if zoom < 1.3 else 3.0  # whole screen pixels: crisp pixel-art strokes
	if not nation.is_empty():
		ci.draw_multiline(nation, NATION_BORDER, nw / zoom)
	if not realm.is_empty():
		ci.draw_multiline(realm, Color(SELECT, 0.85), (nw * 0.6) / zoom)
	if not front.is_empty():
		ci.draw_multiline(front, Color("ff6a4a"), (nw * 0.75) / zoom)


func province_color(p) -> Color:
	match map_mode:
		1:
			var me: String = game.player
			if me == "":
				return game.nations[p.owner].color
			var n = game.nations[me]
			if p.owner == me:
				return Color("3a9d4a")
			if game.nations[p.owner].overlord == me:
				return Color("7fc98a")
			if game.is_allied(me, p.owner):
				return Color("4a7fd0")
			if game.at_war(me, p.owner):
				return Color("c0392b")
			if n.claims.has(p.id):
				return Color("e0a030")
			if n.coalition.has(p.owner):
				return Color("8e3a8e")
			if n.rivals.has(p.owner) or game.nations[p.owner].rivals.has(me):
				return Color("d9742b")
			if n.guarantees.has(p.owner) or game.nations[p.owner].guarantees.has(me):
				return Color("3fae9e")
			if n.marriages.has(p.owner):
				return Color("c08ab8")
			if n.access.has(p.owner):
				return Color("b09a62")
			if game.has_truce(me, p.owner):
				return Color("9aa7b0")
			return Color("6b6b62")
		2:
			var t := clampf((p.dev - 3.0) / 37.0, 0.0, 1.0)
			if p.urban:  # cities in a warm brick tone, the countryside in green-gold
				return Color("4a1e1e").lerp(Color("f08a4a"), t)
			return Color("1e3a2a").lerp(Color("d8d35e"), t)
		3:
			if p.owner != game.player:
				return Color("4a4a44")
			var u := clampf(game.unrest(p.id) / float(game.bal.revolt_threshold), 0.0, 1.0)
			return Color("3a9d4a").lerp(Color("d03a2a"), u)
		MODE_WAR:
			return _war_color(p.owner)
		MODE_GOODS:
			var gc := Color(game.goods_def[p.good].get("color", "#888888"))
			return gc if p.owner == game.player or game.player == "" else gc.darkened(0.25)
		MODE_FAITH:
			var fcol := Color(Faith.FAITHS.get(p.religion, {"color": "888888"}).color)
			return fcol if p.owner == game.player or game.player == "" else fcol.darkened(0.2)
		MODE_BUILD:
			var lv := 0
			for b in p.buildings:
				lv += int(p.buildings[b])
			var bc := Color("2b2a33").lerp(Color("e3b21b"), clampf(lv / 10.0, 0.0, 1.0))
			if not p.constructing.is_empty():
				bc = bc.lerp(Color("4a9fd0"), 0.35)
			return bc if p.owner == game.player or game.player == "" else bc.darkened(0.4)
		MODE_HRE:
			var hc := Color("3b3a40")
			match _hre_role.get(p.owner, ""):
				"emperor":
					hc = Color("f0c040")
				"elector":
					hc = Color("c87a2a")
				"member":
					hc = Color("7a5a9a")
			return hc.lightened(0.15) if p.owner == game.player else hc
		MODE_TRADE:
			var i: int = game.markets.find(p.market)
			var mc := Color(MARKET_COLORS[i % MARKET_COLORS.size()])
			if p.id == p.market:
				return mc.lightened(0.45)
			return mc if p.owner == game.player else mc.darkened(0.35)
	var n = game.nations[p.owner]
	var c: Color = n.color
	# subjects read as part of their overlord's realm, with a hint of their own colour
	if n.overlord != "" and game.nations.has(n.overlord):
		c = c.lerp(game.nations[n.overlord].color, 0.55)
	if p.owner == game.player:
		c = c.lightened(0.1)
	return c


func _draw_hatch(ci: CanvasItem, poly: PackedVector2Array, bb: Rect2, c: Color) -> void:
	# diagonal stripes clipped to the province polygon
	var step := 10.0
	var x := bb.position.x - bb.size.y
	while x < bb.end.x:
		var line := PackedVector2Array([Vector2(x, bb.position.y), Vector2(x + bb.size.y, bb.end.y)])
		for seg in Geometry2D.intersect_polyline_with_polygon(line, poly):
			if seg.size() >= 2:
				ci.draw_line(seg[0], seg[seg.size() - 1], c, 3.0 / zoom)
		x += step


func _draw_labels() -> void:
	if zoom >= 1.1:
		var fs := int(clampf(11.0 * zoom, 12.0, 18.0) * label_scale)
		for p in game.provinces:
			var s := to_screen(p.center)
			if not Rect2(Vector2.ZERO, size).has_point(s) or not known(p.id):
				continue
			var txt: String = p.name
			if p.siege > 0.0:
				txt += " 🔥%d%%" % int(p.siege)
			var marks := ""
			if zoom >= 1.6:  # only close up, harbors are everywhere on the coasts later on
				if p.buildings.get("fortress", 0) > 0:
					marks += "🏰"
			if p.colonist != "":
				marks += "🏕"
			if marks != "":
				txt += " " + marks
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := s + Vector2(-w / 2, -ARMY_R - 4)
			draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.85))
			draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	else:
		var fs := int(clampf(16.0 * zoom + 4.0, 10.0, 22.0))
		for rl in _realm_labels:
			var tag: String = rl[0]
			var s := to_screen(rl[1])
			if not Rect2(Vector2(-300, -60), size + Vector2(600, 120)).has_point(s) or not known(game.nations[tag].capital):
				continue
			var txt: String = game.nations[tag].name
			var big := clampf(sqrt(float(rl[2])) / 3.0, 1.0, 1.6)
			fs = int(clampf((16.0 * zoom + 4.0) * big, 12.0, 30.0) * label_scale)
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := s + Vector2(-w / 2, -ARMY_R - 4)
			var flag := Icons.flag(tag)
			if flag != null:
				var fsz := Vector2(fs * 1.5, fs)
				draw_texture_rect(flag, Rect2(pos + Vector2(-fsz.x - 4, -fs * 0.85), fsz), false)
			draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
			draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Label anchor for a nation: the owned province closest to the development-weighted center of its land
## (so the label sits on the realm even for crescent-shaped or split territories).
func _realm_center(tag: String, owned: Array) -> Vector2:
	var sum := Vector2.ZERO
	var w := 0.0
	for pid in owned:
		var p = game.provinces[pid]
		sum += p.center * (p.dev + 5.0)
		w += p.dev + 5.0
	var c := sum / maxf(w, 0.001)
	var best: Vector2 = game.provinces[game.nations[tag].capital].center
	var best_d := INF
	for pid in owned:
		var d: float = game.provinces[pid].center.distance_squared_to(c)
		if d < best_d:
			best_d = d
			best = game.provinces[pid].center
	return best


const STACK_SHOWN := 3  # army counters drawn per province; the rest fold into a "+N" badge
var _stack_rest := {}  # pid -> [hidden armies, their regiments, badge position]
var _army_rel := {}  # army id -> true when it matters to the player (see _army_relevant)
const ARMY_BG_ZOOM := 0.8  # below this, armies that do not concern the player are not drawn at all
const ARMY_BG_TINT := Color(1, 1, 1, 0.68)


## Armies that concern the player: their own, the selected one, enemies and allies in the player's
## wars, and any army inside or next to the player's land. All others are background: drawn as a small
## translucent plate without general, march arrow or morale bar, and hidden when zoomed out.
func _army_relevant(a) -> bool:
	var me: String = game.player
	if me == "" or a.owner == me or a.id == selected_army:
		return true
	if game.at_war(me, a.owner):
		return true
	if game.is_allied(me, a.owner) and game.is_at_war(me):
		return true
	var p = game.provinces[a.pid]
	if p.owner == me or p.controller == me:
		return true
	for q in p.adj:
		if game.provinces[q].owner == me:
			return true
	return false


## Screen position of every army counter that is drawn. Crowded provinces show the selected army, the
## player's and then the biggest ones; the others fold into one badge (see _stack_rest).
func army_positions() -> Dictionary:
	var per := {}
	_army_rel = {}
	for a in game.armies:
		if not sees(a.pid) and a.owner != game.player:
			continue  # fog of war: foreign armies out of sight are not drawn (and cannot be tapped)
		var rel := _army_relevant(a)
		_army_rel[a.id] = rel
		if not rel and zoom < ARMY_BG_ZOOM:
			continue
		if not per.has(a.pid):
			per[a.pid] = []
		per[a.pid].append(a)
	var out := {}
	_stack_rest = {}
	var step := 17.0 if zoom < 0.8 else 31.0  # counter height plus its morale bar: stacked counters do not overlap
	for pid in per:
		var arms: Array = per[pid]
		if arms.size() > STACK_SHOWN:
			var me: String = game.player
			var sel := selected_army
			arms.sort_custom(func(x, y):
				var kx: float = (1e6 if x.id == sel else 0.0) + (1e5 if x.owner == me else 0.0) + (1e4 if _army_rel[x.id] else 0.0) + x.regs
				var ky: float = (1e6 if y.id == sel else 0.0) + (1e5 if y.owner == me else 0.0) + (1e4 if _army_rel[y.id] else 0.0) + y.regs
				return kx > ky if kx != ky else x.id < y.id)
		for i in arms.size():
			var a = arms[i]
			if i >= STACK_SHOWN:
				if not _stack_rest.has(pid):
					_stack_rest[pid] = [0, 0.0, to_screen(game.provinces[pid].center) + Vector2(0, 8 + i * step - step * 0.1)]
				_stack_rest[pid][0] += 1
				_stack_rest[pid][1] += a.regs
				continue
			var c: Vector2 = game.provinces[pid].center
			if a.path.size() >= 2 and a.path[0] == a.pid:
				# on the march: the counter slides up to halfway towards the next province
				c = c.lerp(game.provinces[a.path[1]].center, 0.5 * Warfare.step_progress(game, a))
			out[a.id] = to_screen(c) + Vector2(0, 8 + i * step)
	return out


func _draw_armies() -> void:
	var pos := army_positions()
	for a in game.armies:
		if pos.has(a.id) and a.target >= 0 and (a.owner == game.player or a.id == selected_army):
			var pts := PackedVector2Array([pos[a.id]])
			for pid in a.path:
				pts.append(to_screen(game.provinces[pid].center))
			if pts.size() < 2:
				pts.append(to_screen(game.provinces[a.target].center))
			draw_polyline(pts, Color(1, 1, 1, 0.8), 2.0)
	for a in game.armies:
		if not pos.has(a.id):
			continue
		var s: Vector2 = pos[a.id]
		if not Rect2(Vector2(-20, -20), size + Vector2(40, 40)).has_point(s) or not known(a.pid):
			continue
		var c: Color = game.nations[a.owner].color
		var ring := Color.WHITE if a.id == selected_army else Color(0, 0, 0, 0.9)
		var counter := Icons.texture("army_counter")
		var marker := Icons.texture("army_marker")
		if counter != null:
			_draw_counter(a, s, c, counter)
			continue
		if marker != null:
			# pixel-art shield already has an outline: no circle, tint with the nation colour
			if a.id == selected_army:
				draw_circle(s, ARMY_R + 4, Color(1, 1, 1, 0.5))
			draw_texture_rect(marker, Rect2(s - Vector2(ARMY_R, ARMY_R) * 1.4, Vector2(ARMY_R, ARMY_R) * 2.8), false, c)
		else:
			draw_circle(s, ARMY_R + 2, ring)
			draw_circle(s, ARMY_R, c.darkened(0.15))
		var txt := str(int(round(a.regs)))
		var fs := 15
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := s + Vector2(-w / 2, 5)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		_draw_power_bar(a, Rect2(s.x - ARMY_R, s.y + ARMY_R + 3, ARMY_R * 2, 4))
	for pid in _stack_rest:
		var rest: Array = _stack_rest[pid]
		var s: Vector2 = rest[2]
		if not Rect2(Vector2(-20, -20), size + Vector2(40, 40)).has_point(s) or not known(pid):
			continue
		var txt := "+%d · %d" % [rest[0], int(round(rest[1]))]
		var fs := 10 if zoom < 0.8 else 13
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var r := Rect2(s.x - w / 2 - 4, s.y - fs * 0.6, w + 8, fs + 4)
		draw_rect(r.grow(1.0), Color(0, 0, 0, 0.9))
		draw_rect(r, Color(0.25, 0.23, 0.2, 0.95))
		draw_string(font, Vector2(s.x - w / 2, r.position.y + fs), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	_draw_battles()
	_draw_flashes()


## Armies at sea (Naval.transport): a dashed course over the seas and a ship with the regiments.
func _draw_voyages() -> void:
	for v in game.voyages:
		var a = v.army
		var mine: bool = a.owner == game.player
		if not mine and not (known(int(v.to)) and known(int(v.from))):
			continue
		if not mine and not sees(int(v.to)) and not sees(int(v.from)):
			continue
		var pts: Array = Naval.voyage_points(game, v)
		var sp := PackedVector2Array()
		for w in pts:
			sp.append(to_screen(w))
		var c: Color = game.nations[a.owner].color
		if mine:
			for i in sp.size() - 1:
				draw_dashed_line(sp[i], sp[i + 1], Color(1, 1, 1, 0.7), 2.0, 8.0)
		# position along the course
		var total := 0.0
		for i in sp.size() - 1:
			total += sp[i].distance_to(sp[i + 1])
		var want: float = total * Naval.voyage_done(v)
		var at: Vector2 = sp[0]
		for i in sp.size() - 1:
			var seg: float = sp[i].distance_to(sp[i + 1])
			if want <= seg or i == sp.size() - 2:
				at = sp[i].lerp(sp[i + 1], clampf(want / maxf(seg, 0.01), 0.0, 1.0))
				break
			want -= seg
		if not Rect2(Vector2(-30, -30), size + Vector2(60, 60)).has_point(at):
			continue
		draw_circle(at, 15.0, Color(0, 0, 0, 0.85))
		draw_circle(at, 13.0, c.darkened(0.1))
		var fs := 15
		var g := "⛵"
		draw_string(font, at + Vector2(-9, 6), g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		var txt := "%d · %d Mon." % [int(round(a.regs)), int(v.left)]
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string_outline(font, at + Vector2(-w / 2, 30), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color.BLACK)
		draw_string(font, at + Vector2(-w / 2, 30), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


## Colonies being settled: the settler nation's flag over the province and a progress bar with percent
## (at every zoom level, so the race for the New World and Africa can be followed on the map).
func _draw_colonies() -> void:
	var fs := 12 if zoom < 0.8 else 14
	for pid in game.overseas:
		var p = game.provinces[pid]
		if p.colonist == "" or not known(pid):
			continue
		var s := to_screen(p.center)
		if not Rect2(Vector2(-40, -40), size + Vector2(80, 80)).has_point(s):
			continue
		var c: Color = game.nations[p.colonist].color
		var prog: float = Colonial.progress(game, pid)
		var bw := 44.0 if zoom >= 0.8 else 32.0
		var top := s + Vector2(-bw / 2, 10.0)
		var flag := Icons.flag(p.colonist)
		var fsz := Vector2(bw * 0.5, bw * 0.34)
		if flag != null:
			draw_rect(Rect2(s + Vector2(-fsz.x / 2 - 1, -fsz.y - 1), fsz + Vector2(2, 2)), Color(0, 0, 0, 0.9))
			draw_texture_rect(flag, Rect2(s + Vector2(-fsz.x / 2, -fsz.y), fsz), false)
		var bar := Rect2(top, Vector2(bw, 6.0))
		draw_rect(bar.grow(1.5), Color(0, 0, 0, 0.9))
		draw_rect(bar, Color(0.2, 0.2, 0.2, 0.9))
		draw_rect(Rect2(bar.position, Vector2(bw * prog, bar.size.y)), c.lightened(0.15))
		var txt := "🏕 %d %%" % int(prog * 100.0)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := Vector2(s.x - tw / 2, bar.end.y + fs + 2)
		draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
		draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Running battles: crossed swords over the province, both sides' battle morale as bars.
func _draw_battles() -> void:
	for b in game.battles:
		if not sees(b.pid):
			continue
		# right of the army counters, so the province name stays readable
		var s := to_screen(game.provinces[b.pid].center) + _battle_anchor()
		if not Rect2(Vector2(-60, -60), size + Vector2(120, 120)).has_point(s):
			continue
		var pulse := 0.75 + 0.25 * sin(_now() * 6.0)
		draw_circle(s, 17.0, Color(0, 0, 0, 0.9))
		draw_circle(s, 15.0, Color(0.6, 0.1, 0.05, pulse))
		var fs := 20
		var w := font.get_string_size("⚔️", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, s + Vector2(-w / 2, 7), "⚔️", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
		# battle morale: attacker on top, defender below, in their nation colours
		var bw := 40.0
		for i in 2:
			var arms: Array = b.att if i == 0 else b.def
			var col: Color = game.nations[arms[0].owner].color if not arms.is_empty() else Color.GRAY
			var m: float = clampf(b.morale_att if i == 0 else b.morale_def, 0.0, 1.0)
			var r := Rect2(s.x - bw / 2, s.y + 20 + i * 8, bw, 6)
			draw_rect(r.grow(1.0), Color(0, 0, 0, 0.9))
			draw_rect(Rect2(r.position, Vector2(bw * m, 6)), col.lightened(0.15))
		if zoom >= 0.8:
			var rt := "R%d · %s" % [b.round + 1, Warfare.phase(b)]
			var rw := font.get_string_size(rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string_outline(font, s + Vector2(-rw / 2, 50), rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
			draw_string(font, s + Vector2(-rw / 2, 50), rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.7))


# ---------------------------------------------------------------- development feedback

const FLASH_S := 2.2
var _dev_seen := {}  # pid -> last seen development
var _flashes: Array = []  # {pid, text, color, t0}


## Call after every tick or action: a floating "+1 🏘️" and a glowing outline on the player's provinces that grew.
func check_dev_changes() -> void:
	if game == null:
		return
	var first: bool = _dev_seen.is_empty()
	for p in game.provinces:
		var old: int = _dev_seen.get(p.id, p.dev)
		_dev_seen[p.id] = p.dev
		if first or p.dev == old or p.owner != game.player:
			continue
		var up: bool = p.dev > old
		_flashes.append({"pid": p.id, "text": "%+d 🏘️" % (p.dev - old), "color": Color(0.55, 1.0, 0.45) if up else Color(1.0, 0.4, 0.3), "t0": _now()})
	_check_battle_rounds()
	if not _flashes.is_empty():
		queue_redraw()


func reset_dev_seen() -> void:
	_dev_seen.clear()
	_flashes.clear()
	_battle_seen.clear()


var _battle_seen := {}  # Warfare.Battle -> rounds already shown


## Every new battle round in view: both sides' losses float up beside the battle marker (attacker left,
## defender right, in their colours), so a fight can be followed round by round.
func _check_battle_rounds() -> void:
	var keep := {}
	for b in game.battles:
		var seen: int = _battle_seen.get(b, 0)
		keep[b] = b.log.size()
		if seen >= b.log.size() or b.att.is_empty() or b.def.is_empty():
			continue
		if not ((known(b.pid) and sees(b.pid)) or _involves_player(b)):
			continue
		var e: Array = b.log[-1]
		for i in 2:
			var arms: Array = b.att if i == 0 else b.def
			var lost: float = float(e[1 + i])
			_flashes.append({"pid": b.pid, "text": "-%.1f" % lost, "color": game.nations[arms[0].owner].color.lightened(0.35),
					"t0": _now(), "off": _battle_anchor() + Vector2(-26 if i == 0 else 26, -6)})
	_battle_seen = keep


func _involves_player(b) -> bool:
	for a in b.att + b.def:
		if a.owner == game.player:
			return true
	return false


## Screen offset of the battle marker from the province centre (right of the army counters).
func _battle_anchor() -> Vector2:
	return Vector2(66, 4) if zoom >= 0.8 else Vector2(34, 4)


func _draw_flashes() -> void:
	var now := _now()
	var keep: Array = []
	for f in _flashes:
		var age: float = (now - float(f.t0)) / FLASH_S
		if age >= 1.0:
			continue
		keep.append(f)
		var c: Color = f.color
		c.a = 1.0 - age * age
		var s: Vector2 = to_screen(game.provinces[f.pid].center) + f.get("off", Vector2.ZERO) - Vector2(0, 26 + age * 34)
		var fs := int(20 * label_scale)
		var w := font.get_string_size(f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(font, s - Vector2(w / 2, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, c.a))
		draw_string(font, s - Vector2(w / 2, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
	_flashes = keep


# ---------------------------------------------------------------- input

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	if not _flashes.is_empty():
		queue_redraw()
	# long press: hold still on a province to open its info (even while an army is selected)
	var holding: bool = (_touches.size() == 1 or _mouse_down) and not _moved and not _long_fired
	if holding and _now() - _press_time >= LONG_PRESS_S:
		_long_fired = true
		var pid := province_at(_press_pos)
		if pid >= 0:
			Input.vibrate_handheld(30)
			province_long_pressed.emit(pid)
	# fling: the map keeps gliding after a quick swipe
	if _velocity.length() > 20.0 and _touches.is_empty() and not _mouse_down:
		offset += _velocity * delta
		_velocity *= pow(0.04, delta)
		_clamp()
		queue_redraw()
	elif _touches.is_empty() and not _mouse_down:
		_velocity = Vector2.ZERO


func _release_tap(pos: Vector2) -> void:
	if _long_fired:
		return
	var t := _now()
	if t - _last_tap_time < DOUBLE_TAP_S and pos.distance_to(_last_tap_pos) < 40.0:
		_last_tap_time = -10.0
		zoom_by(1.7, pos)
		return
	_last_tap_time = t
	_last_tap_pos = pos
	_tap(pos)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_used = true
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_press_pos = event.position
				_press_time = _now()
				_moved = false
				_long_fired = false
				_velocity = Vector2.ZERO
		else:
			if _touches.size() == 1 and not _moved:
				_release_tap(event.position)
			_touches.erase(event.index)
			_pinch_dist = 0.0
		accept_event()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			if _moved or event.position.distance_to(_press_pos) > 14.0:
				_moved = true
				offset += event.relative
				_velocity = event.velocity
				_clamp()
		elif _touches.size() >= 2:
			_moved = true
			var keys := _touches.keys()
			var p0: Vector2 = _touches[keys[0]]
			var p1: Vector2 = _touches[keys[1]]
			var d := p0.distance_to(p1)
			if _pinch_dist > 0.0 and d > 0.0:
				zoom_by(d / _pinch_dist, (p0 + p1) / 2)
			_pinch_dist = d
		queue_redraw()
		accept_event()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_by(1.12, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_by(1.0 / 1.12, event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var rp := province_at(event.position)
			if rp >= 0 and known(rp):
				province_context.emit(rp, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_down = true
				_press_pos = event.position
				_press_time = _now()
				_moved = false
				_long_fired = false
				_velocity = Vector2.ZERO
			else:
				_mouse_down = false
				if not _moved:
					_release_tap(event.position)
		accept_event()
	elif event is InputEventMouseMotion and not _mouse_down and event.device != InputEvent.DEVICE_ID_EMULATION and not _touch_used:
		_hover_pos = event.position
		var pid := province_at(event.position)
		if pid != hover_pid or pid >= 0:
			hover_pid = pid
			queue_redraw()
	elif event is InputEventMouseMotion and _mouse_down and event.device != InputEvent.DEVICE_ID_EMULATION:
		if _moved or event.position.distance_to(_press_pos) > 6.0:
			_moved = true
			offset += event.relative
			_clamp()
			queue_redraw()
	elif event is InputEventMagnifyGesture:
		zoom_by(event.factor, event.position)
	elif event is InputEventPanGesture:
		offset -= event.delta * 12.0
		_clamp()
		queue_redraw()


func _tap(screen_pos: Vector2) -> void:
	var pos := army_positions()
	var best := -1
	# fingers are less precise than a mouse pointer
	var best_d := ARMY_R + (22.0 if _touch_used else 8.0)
	for id in pos:
		var d: float = pos[id].distance_to(screen_pos)
		if d < best_d and known(game.army_by_id(id).pid):
			best_d = d
			best = id
	if best >= 0:
		army_tapped.emit(best)
		return
	var pid := province_at(screen_pos)
	if pid >= 0 and known(pid):
		province_tapped.emit(pid)


func province_at(screen_pos: Vector2) -> int:
	if game == null:
		return -1
	var w := to_world(screen_pos)
	for p in game.provinces:
		if not bboxes[p.id].has_point(w):
			continue
		for poly in polys[p.id]:
			if Geometry2D.is_point_in_polygon(w, poly):
				return p.id
	return -1


## Army counter: nation-tinted plate, steel pikeman, regiment count, march arrow when moving.
func _draw_counter(a, s: Vector2, c: Color, counter: Texture2D) -> void:
	# zoomed out: native 1x plate with just the number, so Europe stays readable;
	# armies that do not concern the player always use the small translucent plate
	var bg: bool = not _army_rel.get(a.id, true)
	var compact := zoom < 0.8 or bg
	var csz := COUNTER_SIZE / 2 if compact else COUNTER_SIZE
	var r := Rect2(s - csz / 2, csz)
	if a.id == selected_army:
		draw_rect(r.grow(3.0), Color(1, 1, 1, 0.9))
	if bg:
		c.a = ARMY_BG_TINT.a
	draw_texture_rect(counter, r, false, c)
	var unit := Icons.texture("army_unit")
	if unit != null and not compact:
		draw_texture_rect(unit, Rect2(r.position, Vector2(20, 28)), false)
	if a.general > 0 and not compact:
		var star: String = "⭐" if a.general == 1 else "⭐%d" % a.general
		draw_string_outline(font, Vector2(r.position.x - 6, r.position.y + 4), star, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color.BLACK)
		draw_string(font, Vector2(r.position.x - 6, r.position.y + 4), star, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	if a.target >= 0 and not compact:
		var arrow := Icons.texture("army_moving")
		if arrow != null:
			draw_texture_rect(arrow, Rect2(Vector2(r.end.x - 10, r.position.y - 8), Vector2(18, 14)), false)
	var txt := str(int(round(a.regs)))
	var fs := (15 if txt.length() < 3 else 13) if not compact else 10
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var cx := r.get_center().x if compact else r.position.x + 33
	var tp := Vector2(cx - w / 2, s.y + fs * 0.36)
	var ink := Color(1, 1, 1, ARMY_BG_TINT.a + 0.2) if bg else Color.WHITE
	draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2 if compact else 3, Color(0, 0, 0, ink.a))
	draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	if not bg:
		_draw_power_bar(a, Rect2(r.position.x, r.end.y + 1, r.size.x, 3.0 if compact else 5.0))


## Fighting power under each army: green full, yellow worn, red exhausted.
func _draw_power_bar(a, r: Rect2) -> void:
	var f: float = clampf(a.power / maxf(0.01, game.power_max(a.owner)), 0.0, 1.0)
	draw_rect(r.grow(1.0), Color(0, 0, 0, 0.85))
	var col := Color(0.85, 0.2, 0.15).lerp(Color(0.95, 0.8, 0.2), clampf(f * 2.0, 0.0, 1.0)) if f < 0.5 \
			else Color(0.95, 0.8, 0.2).lerp(Color(0.3, 0.85, 0.3), (f - 0.5) * 2.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hover_pid >= 0:
		hover_pid = -1
		queue_redraw()
