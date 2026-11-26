extends RefCounted
## Pixel-art fog for the map, made at start (no asset files, a few milliseconds):
## - veil_texture(): the fog of war mist, a tileable pattern of slate clouds in three dithered tones. It is
##   drawn over known land the player cannot see right now. Being a visible pattern (not a flat dark veil),
##   it reads as weather over the land: a realm half in sight and half in the fog keeps one colour.
## - fog_material(): the shader for terra incognita. data/fog.json is a coarse 8 px grid; the shader reads
##   it as a soft mask, frays its edge with world-space noise and paints clouds in snapped 2 px pixels with
##   a light rim, so the unknown looks like hand-drawn clouds instead of a blurry grid.

const SIZE := 64  ## texels per tile side of both textures
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const VEIL := Color(0.09, 0.1, 0.14)
const VEIL_ALPHA := [0.18, 0.25, 0.32]

static var _noise: PackedFloat32Array


## Tileable fractal value noise, SIZE x SIZE, 0..1 (fixed seed: the same clouds every game).
static func noise() -> PackedFloat32Array:
	if not _noise.is_empty():
		return _noise
	var rng := RandomNumberGenerator.new()
	rng.seed = 1492
	var out := PackedFloat32Array()
	out.resize(SIZE * SIZE)
	var total := 0.0
	for oct in [[4, 0.5], [8, 0.3], [16, 0.2]]:
		var per: int = oct[0]
		var weight: float = oct[1]
		total += weight
		var lat := PackedFloat32Array()
		lat.resize(per * per)
		for i in lat.size():
			lat[i] = rng.randf()
		var cell := float(SIZE) / per
		for y in SIZE:
			var fy := y / cell
			var y0 := int(fy) % per
			var y1 := (y0 + 1) % per
			var ty := smoothstep(0.0, 1.0, fy - floorf(fy))
			for x in SIZE:
				var fx := x / cell
				var x0 := int(fx) % per
				var x1 := (x0 + 1) % per
				var tx := smoothstep(0.0, 1.0, fx - floorf(fx))
				var a := lerpf(lat[y0 * per + x0], lat[y0 * per + x1], tx)
				var b := lerpf(lat[y1 * per + x0], lat[y1 * per + x1], tx)
				out[y * SIZE + x] += lerpf(a, b, ty) * weight
	var lo := 1e9
	var hi := -1e9
	for i in out.size():
		out[i] /= total
		lo = minf(lo, out[i])
		hi = maxf(hi, out[i])
	for i in out.size():
		out[i] = (out[i] - lo) / maxf(hi - lo, 0.001)
	_noise = out
	return out


## The fog of war mist: three slate tones mixed by ordered (Bayer) dithering, like hand-shaded pixel art.
static func veil_texture() -> Texture2D:
	var n := noise()
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var b: float = BAYER[(y % 4) * 4 + (x % 4)] / 16.0
			var lvl := clampi(int(floorf(n[y * SIZE + x] * 2.6 + b - 0.3)), 0, 2)
			img.set_pixel(x, y, Color(VEIL, VEIL_ALPHA[lvl]))
	return ImageTexture.create_from_image(img)


## Material of the province fill pieces: textures are sampled at UV / tile, so the mist polygons (whose UVs
## are their map coordinates) keep about two screen pixels per texel when only the `tile` uniform changes
## with the zoom: no piece is redrawn for it. Plain fills sample the default white texture: unchanged.
const VEIL_SHADER := """
shader_type canvas_item;
uniform float tile = 128.0;
varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, UV / tile) * vcol;
}
"""


static func veil_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = VEIL_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat


static func noise_texture() -> Texture2D:
	var n := noise()
	var data := PackedByteArray()
	data.resize(SIZE * SIZE)
	for i in n.size():
		data[i] = int(n[i] * 255.0)
	return ImageTexture.create_from_image(Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_L8, data))


const FOG_SHADER := """
shader_type canvas_item;
uniform sampler2D mist : repeat_enable, filter_linear;
uniform vec2 world_size;  // the mask in map pixels
uniform float px = 2.0;  // map pixels per pixel-art pixel
uniform vec3 deep : source_color = vec3(0.157, 0.145, 0.125);
uniform vec3 mid : source_color = vec3(0.2, 0.184, 0.157);
uniform vec3 light : source_color = vec3(0.247, 0.227, 0.192);
uniform vec3 rim : source_color = vec3(0.388, 0.353, 0.282);
const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 cell = floor(UV * world_size / px);
	vec2 wp = (cell + 0.5) * px;
	// the 8 px grid, softened over about three cells (a blurry mip level, one fetch), so the noise below
	// can fray the edge freely. Far from any unknown cell no noise can reach the threshold: stop early.
	float m = textureLod(TEXTURE, wp / world_size, 1.6).r;
	if (m < 0.09) {
		discard;
	}
	float n1 = texture(mist, wp / 520.0).r;
	float n2 = texture(mist, wp / 130.0 + vec2(0.37, 0.61)).r;
	float n3 = texture(mist, wp / 45.0 + vec2(0.71, 0.29)).r;
	float e = (m - 0.5) * 2.2 + 0.5 + (n1 - 0.5) * 0.9 + (n2 - 0.5) * 0.6 + (n3 - 0.5) * 0.3;
	if (e < 0.5) {
		discard;
	}
	float body = n1 * 0.4 + n2 * 0.6;
	ivec2 ip = ivec2(mod(cell, 4.0));
	float b = BAYER[ip.y * 4 + ip.x] / 16.0;
	float lvl = floor(body * 2.6 + b - 0.3);
	vec3 col = lvl < 1.0 ? deep : (lvl < 2.0 ? mid : light);
	if (e < 0.56) {  // a pale rim, like the edge of a cloud bank
		col = rim;
	} else if (e < 0.62) {
		col = light;
	}
	COLOR = vec4(col, 0.97);
}
"""


static func fog_material(w: int, h: int, cell: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = FOG_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("mist", noise_texture())
	mat.set_shader_parameter("world_size", Vector2(w, h) * cell)
	return mat
