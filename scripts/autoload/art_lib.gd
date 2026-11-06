extends Node
## Procedurally generated textures and shared materials. Everything is cached,
## so each texture is built once on first use. Swap any of these for hand-made
## art later by returning a loaded texture instead.

const PALETTE_SHADER := preload("res://shaders/palette.gdshader")

## One style per 40-floor band, bottom (0) to top (4).
const WALL_STYLES := [
	{"base": Color(0.34, 0.35, 0.29), "mortar": Color(0.13, 0.14, 0.11), "bw": 32, "bh": 16, "grime": Color(0.17, 0.30, 0.10)},
	{"base": Color(0.42, 0.31, 0.22), "mortar": Color(0.17, 0.12, 0.08), "bw": 32, "bh": 16, "grime": Color(0.24, 0.17, 0.09)},
	{"base": Color(0.37, 0.37, 0.41), "mortar": Color(0.14, 0.14, 0.17), "bw": 64, "bh": 32, "grime": Color(0.20, 0.20, 0.26)},
	{"base": Color(0.28, 0.28, 0.38), "mortar": Color(0.0, 0.0, 0.0), "bw": 0, "bh": 0, "grime": Color(0.12, 0.30, 0.34)},
	{"base": Color(0.42, 0.23, 0.22), "mortar": Color(0.16, 0.07, 0.07), "bw": 32, "bh": 16, "grime": Color(0.30, 0.04, 0.05)},
]

const TORCH_COLORS := [
	Color(1.0, 0.62, 0.30),
	Color(1.0, 0.56, 0.26),
	Color(1.0, 0.72, 0.38),
	Color(0.45, 0.68, 1.0),
	Color(1.0, 0.38, 0.30),
]

var _cache: Dictionary = {}


func wall_texture(band: int) -> Texture2D:
	return _cached("wall%d" % band, _make_wall.bind(band))


func walkway_texture(band: int) -> Texture2D:
	return _cached("walk%d" % band, _make_walkway.bind(band))


func slab_texture(band: int) -> Texture2D:
	return _cached("slab%d" % band, _make_slab.bind(band))


func rock_texture() -> Texture2D:
	return _cached("rock", _make_rock_fill)


func far_texture() -> Texture2D:
	return _cached("far", _make_far)


func light_texture() -> Texture2D:
	return _cached("light", _make_light)


func torch_color(band: int) -> Color:
	return TORCH_COLORS[clampi(band, 0, TORCH_COLORS.size() - 1)]


## Shared tint material for a monster tier ("rot", "elite"); null for none.
func tint_material(kind: String) -> ShaderMaterial:
	if kind == "" or kind == "none":
		return null
	var key := "tint_" + kind
	if not _cache.has(key):
		var m := ShaderMaterial.new()
		m.shader = PALETTE_SHADER
		match kind:
			"rot":
				m.set_shader_parameter("tint", Color(0.55, 0.82, 0.42))
				m.set_shader_parameter("tint_amount", 0.75)
				m.set_shader_parameter("desaturate", 0.6)
			"elite":
				m.set_shader_parameter("tint", Color(1.0, 0.32, 0.30))
				m.set_shader_parameter("tint_amount", 0.7)
				m.set_shader_parameter("desaturate", 0.35)
		_cache[key] = m
	return _cache[key]


## Unique material instance (for per-actor hit flashes).
func new_flash_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PALETTE_SHADER
	return m


func _cached(key: String, maker: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]


func _noise(seed_value: int, frequency: float, octaves: int = 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = frequency
	n.fractal_octaves = octaves
	return n


static func _hashf(v: int) -> float:
	return float(posmod(hash(v), 10007)) / 10007.0


static func _shade(c: Color, amount: float) -> Color:
	return c.lightened(amount) if amount > 0.0 else c.darkened(-amount)


func _make_wall(band: int) -> ImageTexture:
	var style: Dictionary = WALL_STYLES[band]
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var detail := _noise(1000 + band, 0.09).get_seamless_image(size, size)
	var grime_img := _noise(2000 + band, 0.03, 3).get_seamless_image(size, size)
	var crack_img := _noise(3000 + band, 0.05, 2).get_seamless_image(size, size)
	var base: Color = style["base"]
	var mortar: Color = style["mortar"]
	var grime: Color = style["grime"]
	var bw: int = style["bw"]
	var bh: int = style["bh"]
	for y in size:
		for x in size:
			var n := detail.get_pixel(x, y).r - 0.5
			var c: Color
			if bw == 0:
				c = _shade(base, n * 0.7)
				var cr := absf(crack_img.get_pixel(x, y).r - 0.5)
				if cr < 0.018:
					c = c.darkened(0.55)
				elif cr < 0.03:
					c = c.lightened(0.06)
			else:
				var row := y / bh
				var ox := (row % 2) * (bw / 2)
				var bx := posmod(x + ox, bw)
				var by := y % bh
				var brick_id := posmod(x + ox, size) / bw + row * 17 + band * 131
				var shade := _hashf(brick_id) * 0.24 - 0.12
				if bx == 0 or by == 0:
					c = mortar
				else:
					c = _shade(base, shade)
					c = _shade(c, n * 0.45)
					if by == 1:
						c = c.lightened(0.10)
					elif by == bh - 1 or bx == bw - 1:
						c = c.darkened(0.25)
					if absf(crack_img.get_pixel(x, y).r - 0.5) < 0.012:
						c = c.darkened(0.45)
			var g := grime_img.get_pixel(x, y).r
			if g > 0.6:
				c = c.lerp(grime, minf((g - 0.6) * 1.8, 0.7))
			c.a = 1.0
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_walkway(band: int) -> ImageTexture:
	var style: Dictionary = WALL_STYLES[band]
	var base: Color = style["base"]
	base = base.lightened(0.08)
	var w := 64
	var h := 10
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var detail := _noise(4000 + band, 0.2, 2).get_seamless_image(w, h)
	for y in h:
		for x in w:
			var n := detail.get_pixel(x, y).r - 0.5
			var c := _shade(base, n * 0.35)
			# Joints slant to fake a receding floor plane.
			var jx := posmod(x + int(y * 0.6), 32)
			if jx == 0:
				c = c.darkened(0.45)
			if y <= 1:
				c = c.darkened(0.45 - y * 0.2)
			elif y == h - 1:
				c = c.lightened(0.18)
			c.a = 1.0
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_slab(band: int) -> ImageTexture:
	var style: Dictionary = WALL_STYLES[band]
	var base: Color = style["base"]
	base = base.darkened(0.25)
	var w := 64
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var detail := _noise(5000 + band, 0.15, 3).get_seamless_image(w, h)
	for y in h:
		for x in w:
			var n := detail.get_pixel(x, y).r - 0.5
			var block := x / 32
			var c := _shade(base, n * 0.4 + (_hashf(block + band * 7) - 0.5) * 0.15)
			if x % 32 == 0:
				c = c.darkened(0.5)
			if y == 0:
				c = c.lightened(0.25)
			elif y == 1:
				c = c.lightened(0.1)
			elif y >= h - 3:
				c = c.darkened(0.25 + (y - (h - 3)) * 0.15)
			c.a = 1.0
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_rock_fill() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var detail := _noise(6000, 0.05).get_seamless_image(size, size)
	var crack_img := _noise(6001, 0.04, 2).get_seamless_image(size, size)
	var base := Color(0.2, 0.18, 0.17)
	for y in size:
		for x in size:
			var n := detail.get_pixel(x, y).r - 0.5
			var c := _shade(base, n * 0.8)
			if absf(crack_img.get_pixel(x, y).r - 0.5) < 0.02:
				c = c.darkened(0.6)
			c.a = 1.0
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_far() -> ImageTexture:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var broad := _noise(7000, 0.012, 5).get_seamless_image(size, size)
	var fine := _noise(7001, 0.05, 3).get_seamless_image(size, size)
	var dark := Color(0.03, 0.034, 0.05)
	var light := Color(0.19, 0.19, 0.26)
	for y in size:
		for x in size:
			var v := broad.get_pixel(x, y).r * 0.65 + fine.get_pixel(x, y).r * 0.35
			var c := dark.lerp(light, clampf((v - 0.3) * 1.6, 0.0, 1.0))
			if absf(fine.get_pixel(x, y).r - 0.5) < 0.012:
				c = c.darkened(0.6)
			c.a = 1.0
			img.set_pixel(x, y, c)
	# Faint glowing crystals and fungi in the deep caverns.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7002
	var glow_colors := [Color(0.3, 0.8, 0.9), Color(0.5, 0.9, 0.4), Color(0.7, 0.45, 0.95)]
	for i in 34:
		var cx := rng.randi_range(0, size - 1)
		var cy := rng.randi_range(0, size - 1)
		var gc: Color = glow_colors[rng.randi() % glow_colors.size()]
		var strength := rng.randf_range(0.25, 0.6)
		for oy in range(-2, 3):
			for ox in range(-2, 3):
				var d := sqrt(float(ox * ox + oy * oy))
				if d > 2.3:
					continue
				var px := posmod(cx + ox, size)
				var py := posmod(cy + oy, size)
				var k := strength * (1.0 - d / 2.4)
				img.set_pixel(px, py, img.get_pixel(px, py).lerp(gc, k))
	return ImageTexture.create_from_image(img)


func _make_light() -> ImageTexture:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var v := 0.0
			if d < 1.0:
				v = pow(1.0 - d, 1.7)
			img.set_pixel(x, y, Color(v, v, v, v))
	return ImageTexture.create_from_image(img)
