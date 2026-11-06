class_name PropArt
extends RefCounted
## Procedural pixel-style drawings for dungeon dressing, weapons and pickups.
## All functions draw into the given CanvasItem from inside its _draw().
## Floor props stand on y = 0 (the floor surface); wall props use their own y.

const BONE := Color(0.78, 0.74, 0.62)
const BONE_DARK := Color(0.48, 0.44, 0.36)
const WOOD := Color(0.44, 0.29, 0.16)
const IRON := Color(0.32, 0.32, 0.35)
const BLOOD := Color(0.38, 0.02, 0.03, 0.92)
const FLOOR_BASE := -4.0


static func rng_for(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, segments: int = 18) -> void:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(pts, color)


static func draw_prop(ci: CanvasItem, p: Dictionary) -> void:
	var t: String = p["t"]
	var x: float = p["x"]
	var y: float = p.get("y", 0.0)
	var r := rng_for(int(p["s"]))
	var base := Vector2(x, FLOOR_BASE)
	match t:
		"crate":
			_crate(ci, base, r.randf_range(20.0, 28.0), r)
		"crates":
			var s := r.randf_range(20.0, 24.0)
			_crate(ci, base + Vector2(-s * 0.55, 0), s, r)
			_crate(ci, base + Vector2(s * 0.55, 0), s, r)
			_crate(ci, base + Vector2(r.randf_range(-4, 4), -s), s * 0.9, r)
		"barrel":
			_barrel(ci, base, r)
		"pots":
			for i in r.randi_range(2, 3):
				_pot(ci, base + Vector2(i * 13.0 - 12.0, 0), r)
		"bones":
			_bones(ci, base, r)
		"skull":
			_skull(ci, base + Vector2(0, -5), 1.0, r)
			if r.randf() < 0.5:
				_skull(ci, base + Vector2(10, -4), 0.8, r)
		"rubble":
			_rubble(ci, base, r)
		"puddle":
			ellipse(ci, base + Vector2(0, 1), Vector2(r.randf_range(14, 26), 2.5), Color(0.04, 0.05, 0.07, 0.85))
			ci.draw_line(base + Vector2(-6, 0), base + Vector2(4, 0), Color(0.4, 0.45, 0.55, 0.5), 1.0)
		"mold":
			_mold(ci, Vector2(x, y), r)
		"moss":
			_moss(ci, x, r)
		"crack":
			_crack(ci, Vector2(x, y), r)
		"chains":
			_chains(ci, Vector2(x, -GameConst.HEADROOM), r)
		"cobweb":
			_cobweb(ci, Vector2(x, -GameConst.HEADROOM), r)
		"banner":
			_banner(ci, Vector2(x, -GameConst.HEADROOM + 6), r)
		"stalactites":
			_stalactites(ci, x, r)
		"shackles":
			_shackles(ci, Vector2(x, y), r)


static func draw_decal(ci: CanvasItem, d: Dictionary) -> void:
	var t: String = d["t"]
	var x: float = d["x"]
	var rad: float = d.get("r", 4.0)
	var r := rng_for(int(d.get("s", 0)))
	match t:
		"wall":
			var y: float = d.get("y", -30.0)
			if y > -12.0:
				ellipse(ci, Vector2(x, FLOOR_BASE), Vector2(rad * 1.6, rad * 0.45), BLOOD.darkened(0.15))
				return
			var c := Vector2(x, y)
			ci.draw_circle(c, rad, BLOOD)
			for i in r.randi_range(4, 8):
				var off := Vector2.from_angle(r.randf() * TAU) * rad * r.randf_range(1.0, 2.3)
				ci.draw_circle(c + off, r.randf_range(0.8, maxf(rad * 0.4, 1.0)), BLOOD)
			for i in r.randi_range(0, 2):
				var dx := r.randf_range(-rad * 0.6, rad * 0.6)
				var end_y := minf(y + r.randf_range(rad, rad * 3.5), -10.0)
				ci.draw_line(Vector2(x + dx, y), Vector2(x + dx, end_y), BLOOD, 1.5)
				ci.draw_circle(Vector2(x + dx, end_y), 1.3, BLOOD)
		"floor":
			ellipse(ci, Vector2(x, FLOOR_BASE), Vector2(rad * 1.6, rad * 0.45), BLOOD.darkened(0.15))
		"scorch":
			var y: float = d.get("y", -30.0)
			ellipse(ci, Vector2(x, y), Vector2(rad, rad * 0.8), Color(0.02, 0.02, 0.02, 0.6))
			ellipse(ci, Vector2(x, FLOOR_BASE), Vector2(rad * 1.3, rad * 0.25), Color(0.02, 0.02, 0.02, 0.7))


# --- Floor props -------------------------------------------------------------

static func _crate(ci: CanvasItem, base: Vector2, size: float, r: RandomNumberGenerator) -> void:
	var rect := Rect2(base.x - size * 0.5, base.y - size, size, size)
	var wood := WOOD.darkened(r.randf() * 0.25)
	ci.draw_rect(rect, wood)
	var plank := size / 3.0
	for i in range(1, 3):
		var py := rect.position.y + i * plank
		ci.draw_line(Vector2(rect.position.x, py), Vector2(rect.end.x, py), wood.darkened(0.35), 1.0)
	ci.draw_line(rect.position + Vector2(2, 2), rect.end - Vector2(2, 2), wood.darkened(0.3), 2.0)
	ci.draw_line(Vector2(rect.position.x + 1, rect.position.y + 1), Vector2(rect.end.x - 1, rect.position.y + 1), wood.lightened(0.25), 1.0)
	ci.draw_rect(rect, wood.darkened(0.55), false, 2.0)
	for corner in [rect.position + Vector2(2, 2), Vector2(rect.end.x - 4, rect.position.y + 2), Vector2(rect.position.x + 2, rect.end.y - 4), rect.end - Vector2(4, 4)]:
		ci.draw_rect(Rect2(corner, Vector2(2, 2)), IRON)


static func _barrel(ci: CanvasItem, base: Vector2, r: RandomNumberGenerator) -> void:
	var w := r.randf_range(16.0, 20.0)
	var h := r.randf_range(24.0, 28.0)
	var wood := WOOD.lightened(0.05).darkened(r.randf() * 0.2)
	var rect := Rect2(base.x - w * 0.5, base.y - h, w, h)
	ci.draw_rect(rect.grow_individual(-2, 0, -2, 0), wood)
	ci.draw_rect(Rect2(rect.position.x, rect.position.y + 3, w, h - 6), wood)
	for i in 3:
		var sx := rect.position.x + 4 + i * (w - 8) / 2.0
		ci.draw_line(Vector2(sx, rect.position.y + 1), Vector2(sx, rect.end.y - 1), wood.darkened(0.3), 1.0)
	for by in [rect.position.y + 4, rect.end.y - 6]:
		ci.draw_rect(Rect2(rect.position.x, by, w, 2), IRON)
	ellipse(ci, Vector2(base.x, rect.position.y + 1), Vector2(w * 0.5 - 1, 2), wood.lightened(0.15))
	ci.draw_line(Vector2(rect.position.x + 2, rect.position.y + 4), Vector2(rect.position.x + 2, rect.end.y - 4), wood.lightened(0.2), 1.0)


static func _pot(ci: CanvasItem, base: Vector2, r: RandomNumberGenerator) -> void:
	var clay := Color(0.55, 0.32, 0.2).darkened(r.randf() * 0.3)
	var rad := r.randf_range(5.0, 7.0)
	ellipse(ci, base + Vector2(0, -rad), Vector2(rad, rad), clay)
	ci.draw_rect(Rect2(base.x - 2.5, base.y - rad * 2 - 4, 5, 5), clay.darkened(0.15))
	ci.draw_line(base + Vector2(-rad + 2, -rad - 2), base + Vector2(-rad + 2, -rad + 2), clay.lightened(0.25), 1.0)


static func _bones(ci: CanvasItem, base: Vector2, r: RandomNumberGenerator) -> void:
	for i in r.randi_range(2, 4):
		var c := base + Vector2(r.randf_range(-12, 12), r.randf_range(-2, 0))
		var a := r.randf_range(-0.4, 0.4)
		var half := Vector2.from_angle(a) * r.randf_range(4.0, 8.0)
		ci.draw_line(c - half, c + half, BONE, 2.0)
		ci.draw_circle(c - half, 1.5, BONE)
		ci.draw_circle(c + half, 1.5, BONE)
	if r.randf() < 0.5:
		var rib := base + Vector2(r.randf_range(-6, 6), -2)
		for i in 3:
			ci.draw_arc(rib + Vector2(i * 3, 0), 4.0, PI, TAU, 6, BONE_DARK, 1.0)


static func _skull(ci: CanvasItem, center: Vector2, s: float, r: RandomNumberGenerator) -> void:
	ellipse(ci, center, Vector2(5.5, 5.0) * s, BONE)
	ci.draw_rect(Rect2(center + Vector2(-3, 3) * s, Vector2(6, 3) * s), BONE.darkened(0.1))
	ci.draw_rect(Rect2(center + Vector2(-3.5, -1) * s, Vector2(2.5, 2.5) * s), Color(0.05, 0.04, 0.04))
	ci.draw_rect(Rect2(center + Vector2(1, -1) * s, Vector2(2.5, 2.5) * s), Color(0.05, 0.04, 0.04))
	ci.draw_rect(Rect2(center + Vector2(-0.5, 2) * s, Vector2(1, 1) * s), Color(0.1, 0.08, 0.08))
	ci.draw_line(center + Vector2(-3, -4) * s, center + Vector2(1, -4.5) * s, BONE.lightened(0.2), 1.0)


static func _rubble(ci: CanvasItem, base: Vector2, r: RandomNumberGenerator) -> void:
	var stone := Color(0.32, 0.31, 0.3)
	for i in r.randi_range(4, 7):
		var c := base + Vector2(r.randf_range(-14, 14), 0)
		var w := r.randf_range(3.0, 7.0)
		var h := r.randf_range(2.0, 5.0)
		var shade := stone.darkened(r.randf() * 0.4)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(-w * 0.6, -h), c + Vector2(w * 0.5, -h * 1.1), c + Vector2(w, 0)]), shade)
		ci.draw_line(c + Vector2(-w * 0.6, -h), c + Vector2(w * 0.5, -h * 1.1), shade.lightened(0.25), 1.0)


# --- Wall props --------------------------------------------------------------

static func _mold(ci: CanvasItem, center: Vector2, r: RandomNumberGenerator) -> void:
	var hue := r.randf()
	var base := Color(0.22, 0.42, 0.14, 0.6) if hue < 0.7 else Color(0.18, 0.36, 0.32, 0.6)
	for i in r.randi_range(8, 16):
		var off := Vector2(r.randf_range(-16, 16), r.randf_range(-9, 9))
		ci.draw_circle(center + off, r.randf_range(2.0, 6.5), base.darkened(r.randf() * 0.4))
	for i in r.randi_range(4, 8):
		var off := Vector2(r.randf_range(-14, 14), r.randf_range(-7, 7))
		ci.draw_circle(center + off, r.randf_range(0.8, 1.8), base.lightened(0.35))
	for i in r.randi_range(0, 3):
		var dx := r.randf_range(-10, 10)
		ci.draw_line(center + Vector2(dx, 4), center + Vector2(dx, minf(4 + r.randf_range(8, 24), -center.y - 10)), base.darkened(0.2), 1.0)


static func _moss(ci: CanvasItem, x: float, r: RandomNumberGenerator) -> void:
	var c := Color(0.2, 0.38, 0.12)
	for i in r.randi_range(6, 12):
		var px := x + r.randf_range(-18, 18)
		var h := r.randf_range(2.0, 6.0)
		ci.draw_rect(Rect2(px, -10 - h, 2, h), c.darkened(r.randf() * 0.4))
	if r.randf() < 0.5:
		for i in r.randi_range(4, 8):
			var px := x + r.randf_range(-16, 16)
			ci.draw_rect(Rect2(px, -GameConst.HEADROOM, 2, r.randf_range(3.0, 10.0)), c.darkened(r.randf() * 0.3))


static func _crack(ci: CanvasItem, start: Vector2, r: RandomNumberGenerator) -> void:
	var c := Color(0.04, 0.035, 0.035, 0.9)
	var p := start
	var dir := Vector2.from_angle(r.randf_range(0.3, 2.8))
	for i in r.randi_range(3, 6):
		var nxt := p + dir.rotated(r.randf_range(-0.7, 0.7)) * r.randf_range(5.0, 11.0)
		nxt.y = clampf(nxt.y, -GameConst.HEADROOM + 4, -12)
		ci.draw_line(p, nxt, c, 1.5)
		if r.randf() < 0.35:
			ci.draw_line(nxt, nxt + Vector2.from_angle(r.randf() * TAU) * 5.0, c, 1.0)
		p = nxt


static func _chains(ci: CanvasItem, top: Vector2, r: RandomNumberGenerator) -> void:
	for k in r.randi_range(1, 2):
		var x := top.x + k * 10.0
		var length := r.randf_range(22.0, 62.0)
		var y := top.y
		var link := 0
		while y < top.y + length:
			if link % 2 == 0:
				ci.draw_rect(Rect2(x - 2, y, 4, 6), IRON, false, 1.0)
			else:
				ci.draw_line(Vector2(x, y), Vector2(x, y + 6), IRON.lightened(0.15), 1.5)
			y += 5.0
			link += 1
		if r.randf() < 0.5:
			ci.draw_arc(Vector2(x, y + 3), 3.5, 0, PI, 6, IRON, 1.5)


static func _cobweb(ci: CanvasItem, anchor: Vector2, r: RandomNumberGenerator) -> void:
	var c := Color(0.75, 0.75, 0.78, 0.3)
	var size := r.randf_range(14.0, 26.0)
	var spokes: Array[Vector2] = []
	for i in 5:
		var a := lerpf(0.15, PI - 0.15, float(i) / 4.0)
		spokes.append(anchor + Vector2(cos(a), sin(a)) * size)
		ci.draw_line(anchor, spokes[i], c, 1.0)
	for ring in [0.35, 0.65, 0.95]:
		var pts := PackedVector2Array()
		for s in spokes:
			pts.append(anchor.lerp(s, ring))
		ci.draw_polyline(pts, c, 1.0)


static func _banner(ci: CanvasItem, top: Vector2, r: RandomNumberGenerator) -> void:
	var cloths := [Color(0.42, 0.08, 0.08), Color(0.12, 0.26, 0.14), Color(0.25, 0.12, 0.32), Color(0.35, 0.28, 0.1)]
	var cloth: Color = cloths[r.randi() % cloths.size()]
	var w := r.randf_range(18.0, 24.0)
	var h := r.randf_range(40.0, 58.0)
	ci.draw_line(top + Vector2(-w * 0.5 - 3, 0), top + Vector2(w * 0.5 + 3, 0), WOOD.darkened(0.3), 2.0)
	var pts := PackedVector2Array([
		top + Vector2(-w * 0.5, 1),
		top + Vector2(w * 0.5, 1),
		top + Vector2(w * 0.5, h - r.randf_range(0, 6)),
		top + Vector2(w * 0.15, h - 8 + r.randf_range(-2, 2)),
		top + Vector2(0, h),
		top + Vector2(-w * 0.2, h - 7),
		top + Vector2(-w * 0.5, h - r.randf_range(0, 5)),
	])
	ci.draw_colored_polygon(pts, cloth)
	ci.draw_line(top + Vector2(-w * 0.5 + 2, 3), top + Vector2(-w * 0.5 + 2, h - 8), cloth.lightened(0.15), 1.0)
	ci.draw_line(top + Vector2(w * 0.5 - 2, 3), top + Vector2(w * 0.5 - 2, h - 8), cloth.darkened(0.35), 1.0)
	var emblem := top + Vector2(0, h * 0.42)
	ci.draw_circle(emblem, 5.0, cloth.lightened(0.35))
	_skull(ci, emblem, 0.55, r)


static func _stalactites(ci: CanvasItem, x: float, r: RandomNumberGenerator) -> void:
	var rock := Color(0.3, 0.29, 0.33)
	var top := -GameConst.HEADROOM
	for i in r.randi_range(3, 6):
		var px := x + r.randf_range(-22, 22)
		var w := r.randf_range(3.0, 7.0)
		var h := r.randf_range(8.0, 26.0)
		var shade := rock.darkened(r.randf() * 0.35)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(px - w, top), Vector2(px + w, top), Vector2(px + r.randf_range(-1, 1), top + h)]), shade)
		ci.draw_line(Vector2(px - w + 1, top), Vector2(px, top + h - 2), shade.lightened(0.2), 1.0)


static func _shackles(ci: CanvasItem, center: Vector2, r: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		var ring := center + Vector2(side * 11.0, 0)
		ci.draw_circle(ring, 2.0, IRON.darkened(0.3))
		var y := ring.y
		while y < ring.y + 14.0:
			ci.draw_rect(Rect2(ring.x - 1.5, y, 3, 4), IRON, false, 1.0)
			y += 4.0
		ci.draw_arc(Vector2(ring.x, y + 3), 3.5, 0, TAU, 8, IRON.lightened(0.1), 1.5)
	if r.randf() < 0.4:
		_skull(ci, center + Vector2(0, 22), 0.9, r)


# --- Weapons -----------------------------------------------------------------

## Muzzle distance (in weapon pixels) from the grip, for spawning projectiles.
const MUZZLE := {
	"revolver": 15.0, "crossbow": 16.0, "shotgun": 24.0, "smg": 17.0,
	"missile_launcher": 19.0, "plasma_gun": 20.0,
}


static func draw_weapon(ci: CanvasItem, id: String, origin: Vector2, s: float, facing: int = 1) -> void:
	ci.draw_set_transform(origin, 0.0, Vector2(s * facing, s))
	var steel := Color(0.36, 0.37, 0.4)
	var dark := Color(0.2, 0.2, 0.22)
	var wood := Color(0.42, 0.25, 0.12)
	match id:
		"rusty_sword":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(2, -1.5), Vector2(22, -1.5), Vector2(25, 0), Vector2(22, 1.5), Vector2(2, 1.5)]), Color(0.58, 0.53, 0.48))
			ci.draw_line(Vector2(3, -0.5), Vector2(21, -0.5), Color(0.75, 0.72, 0.68), 1.0)
			ci.draw_rect(Rect2(8, -1, 2, 2), Color(0.52, 0.27, 0.12))
			ci.draw_rect(Rect2(15, 0, 3, 1.5), Color(0.52, 0.27, 0.12))
			ci.draw_rect(Rect2(0, -4, 2, 8), Color(0.45, 0.35, 0.2))
			ci.draw_rect(Rect2(-6, -1, 6, 2), Color(0.3, 0.18, 0.1))
			ci.draw_circle(Vector2(-7, 0), 1.5, Color(0.45, 0.35, 0.2))
		"revolver":
			ci.draw_rect(Rect2(0, -3, 14, 2.5), steel)
			ci.draw_rect(Rect2(-1, -4.5, 6, 5), steel.lightened(0.12))
			ci.draw_line(Vector2(0, -2), Vector2(4, -2), dark, 1.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, -1), Vector2(1, -1), Vector2(0, 6), Vector2(-4, 5)]), wood)
			ci.draw_arc(Vector2(2, 1), 2.0, 0, PI, 5, dark, 1.0)
			ci.draw_rect(Rect2(13, -4, 1, 1), steel)
		"crossbow":
			ci.draw_rect(Rect2(-8, -1.5, 20, 3), wood)
			ci.draw_polyline(PackedVector2Array([Vector2(9, -9), Vector2(12, 0), Vector2(9, 9)]), Color(0.32, 0.2, 0.1), 2.0)
			ci.draw_polyline(PackedVector2Array([Vector2(9, -9), Vector2(3, 0), Vector2(9, 9)]), Color(0.75, 0.75, 0.7), 1.0)
			ci.draw_rect(Rect2(3, -0.5, 13, 1), Color(0.6, 0.45, 0.3))
			ci.draw_rect(Rect2(15, -1, 2, 2), steel)
			ci.draw_rect(Rect2(-4, 1.5, 3, 5), wood.darkened(0.2))
		"shotgun":
			ci.draw_rect(Rect2(0, -3, 24, 2), steel)
			ci.draw_rect(Rect2(2, -1, 18, 1.5), dark)
			ci.draw_rect(Rect2(8, -1.5, 8, 3), wood.lightened(0.1))
			ci.draw_rect(Rect2(-4, -3.5, 6, 5), steel.darkened(0.1))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-4, -3), Vector2(-16, -2), Vector2(-16, 3), Vector2(-4, 1.5)]), wood)
		"smg":
			ci.draw_rect(Rect2(-4, -4, 14, 5), dark)
			ci.draw_rect(Rect2(10, -3, 7, 2), steel)
			ci.draw_rect(Rect2(2, 1, 3, 8), dark.lightened(0.1))
			ci.draw_rect(Rect2(-3, 1, 3, 5), dark)
			ci.draw_polyline(PackedVector2Array([Vector2(-4, -3), Vector2(-12, -3), Vector2(-12, 1), Vector2(-4, 0)]), steel, 1.0)
			ci.draw_line(Vector2(-3, -4), Vector2(9, -4), steel.lightened(0.2), 1.0)
		"missile_launcher":
			var olive := Color(0.3, 0.36, 0.22)
			ci.draw_rect(Rect2(-14, -8, 32, 7), olive)
			ci.draw_rect(Rect2(-10, -8, 2, 7), olive.darkened(0.35))
			ci.draw_rect(Rect2(10, -8, 2, 7), olive.darkened(0.35))
			ci.draw_line(Vector2(-14, -7), Vector2(18, -7), olive.lightened(0.25), 1.0)
			ci.draw_rect(Rect2(18, -6, 2, 3), Color(0.7, 0.15, 0.1))
			ci.draw_rect(Rect2(-2, -1, 3, 6), dark)
			ci.draw_rect(Rect2(0, -11, 4, 3), dark)
		"plasma_gun":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, -4), Vector2(14, -5), Vector2(18, -2), Vector2(14, 1), Vector2(-6, 2)]), Color(0.72, 0.76, 0.82))
			for cx in [2.0, 6.0, 10.0]:
				ci.draw_circle(Vector2(cx, -1.5), 1.6, Color(0.4, 1.0, 1.0) * 2.5)
			ci.draw_rect(Rect2(17, -3, 3, 2), Color(0.4, 1.0, 1.0) * 2.0)
			ci.draw_rect(Rect2(-3, 1, 3, 6), dark)
			ci.draw_line(Vector2(-5, -4), Vector2(13, -5), Color(0.9, 0.95, 1.0), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Pickups -----------------------------------------------------------------

static func draw_pickup(ci: CanvasItem, kind: String, sub: String, amount: int, base: Vector2) -> void:
	match kind:
		"copper":
			var stacks := clampi(1 + amount / 4, 1, 3)
			for i in stacks:
				var c := base + Vector2(i * 4.0 - stacks * 2.0, -4.0 - i * 1.5)
				ellipse(ci, c, Vector2(4.5, 4.5), Color(0.45, 0.24, 0.1))
				ellipse(ci, c, Vector2(3.6, 3.6), Color(0.85, 0.5, 0.22))
				ci.draw_rect(Rect2(c + Vector2(-1.5, -2), Vector2(1, 2)), Color(1.0, 0.8, 0.5))
		"food":
			match sub:
				"meat":
					ellipse(ci, base + Vector2(2, -5), Vector2(6, 4.5), Color(0.55, 0.22, 0.12))
					ellipse(ci, base + Vector2(1, -6), Vector2(4, 2.5), Color(0.7, 0.32, 0.18))
					ci.draw_line(base + Vector2(-3, -4), base + Vector2(-8, -2), BONE, 2.0)
					ci.draw_circle(base + Vector2(-8.5, -2), 1.6, BONE)
				"bread":
					ellipse(ci, base + Vector2(0, -4), Vector2(8, 4), Color(0.65, 0.45, 0.22))
					for i in 3:
						ci.draw_line(base + Vector2(-4 + i * 4, -7), base + Vector2(-2 + i * 4, -5), Color(0.45, 0.28, 0.12), 1.0)
				_:
					ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-7, 0), base + Vector2(7, 0), base + Vector2(7, -6), base + Vector2(-7, -2)]), Color(0.92, 0.78, 0.3))
					ci.draw_circle(base + Vector2(-2, -2), 1.0, Color(0.7, 0.55, 0.15))
					ci.draw_circle(base + Vector2(3, -3), 1.2, Color(0.7, 0.55, 0.15))
		"potion":
			ellipse(ci, base + Vector2(0, -5), Vector2(5.5, 5), Color(0.25, 0.08, 0.1))
			ellipse(ci, base + Vector2(0, -4.5), Vector2(4.5, 4), Color(0.9, 0.1, 0.18))
			ci.draw_rect(Rect2(base + Vector2(-1.5, -13), Vector2(3, 4)), Color(0.6, 0.7, 0.75))
			ci.draw_rect(Rect2(base + Vector2(-2, -15), Vector2(4, 2)), WOOD)
			ci.draw_rect(Rect2(base + Vector2(-3, -7), Vector2(1.5, 1.5)), Color(1, 0.8, 0.8))
		"ammo":
			var col: Color = Tables.AMMO_COLORS.get(sub, Color.WHITE)
			var rect := Rect2(base + Vector2(-7, -10), Vector2(14, 10))
			ci.draw_rect(rect, Color(0.22, 0.2, 0.16))
			ci.draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(12, 3)), col)
			ci.draw_rect(rect, Color(0.08, 0.07, 0.06), false, 1.0)
			for i in 3:
				ci.draw_rect(Rect2(base + Vector2(-5 + i * 4, -14), Vector2(2, 4)), col.lightened(0.2))
		"weapon":
			ci.draw_arc(base + Vector2(0, -8), 13.0, 0, TAU, 20, Color(1.0, 0.85, 0.4, 0.35), 1.5)
			draw_weapon(ci, sub, base + Vector2(-4, -8), 1.0)
