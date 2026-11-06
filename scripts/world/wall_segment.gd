class_name WallSegment
extends Node2D
## One horizontal slice of a floor's back wall: bricks (with broken-wall holes
## that reveal the far cavern layer), the walkway strip, wall/floor props and
## blood decals. Floors are split into segments so each canvas item touches
## only a few lights (the Compatibility renderer caps lights per item).

var chunk: FloorChunk
var x0 := 0.0
var x1 := 0.0
var props: Array = []
var hole_polys: Array = []


func setup(c: FloorChunk, a: float, b: float) -> void:
	chunk = c
	x0 = a
	x1 = b
	z_index = -10
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for p in c.data.props:
		var px: float = p["x"]
		if px >= x0 and px < x1:
			props.append(p)
	for h in c.data.holes:
		var hx: float = h["x"]
		var hw: float = h["w"]
		if hx + hw * 0.5 > x0 and hx - hw * 0.5 < x1:
			hole_polys.append(hole_polygon(h))


static func hole_polygon(h: Dictionary) -> PackedVector2Array:
	var r := PropArt.rng_for(int(h["s"]))
	var cx: float = h["x"]
	var w: float = h["w"]
	var ht: float = h["h"]
	var pts := PackedVector2Array()
	pts.append(Vector2(cx - w * 0.5, 14))
	var steps := 12
	for i in steps + 1:
		var a := PI + PI * float(i) / float(steps)
		var rx := w * 0.5 * r.randf_range(0.82, 1.0)
		var ry := ht * r.randf_range(0.85, 1.05)
		pts.append(Vector2(cx + cos(a) * rx, -8.0 + sin(a) * ry))
	pts.append(Vector2(cx + w * 0.5, 14))
	return pts


func _draw() -> void:
	var band := chunk.data.band
	var top := -GameConst.HEADROOM
	var wall_tex := ArtLib.wall_texture(band)

	var polys: Array = [PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, 0), Vector2(x0, 0)])]
	for hp in hole_polys:
		var next: Array = []
		for poly in polys:
			next.append_array(Geometry2D.clip_polygons(poly, hp))
		polys = next
	for poly in polys:
		_tiled(poly, wall_tex, Vector2(0, top))
	for hp in hole_polys:
		_hole_rim(hp)

	_gradient(Rect2(x0, top, x1 - x0, 28), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0))
	_gradient(Rect2(x0, -28, x1 - x0, 18), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))

	var walk := PackedVector2Array([Vector2(x0, -10), Vector2(x1, -10), Vector2(x1, 0), Vector2(x0, 0)])
	_tiled(walk, ArtLib.walkway_texture(band), Vector2(0, -10))

	for p in props:
		PropArt.draw_prop(self, p)
	for d in chunk.data.decals:
		var dx: float = d["x"]
		if dx >= x0 and dx < x1:
			PropArt.draw_decal(self, d)


func _tiled(poly: PackedVector2Array, tex: Texture2D, origin: Vector2) -> void:
	if poly.size() < 3:
		return
	var uvs := PackedVector2Array()
	var ts := tex.get_size()
	for p in poly:
		uvs.append((p - origin) / ts)
	draw_colored_polygon(poly, Color.WHITE, uvs, tex)


func _gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	var pts := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	draw_polygon(pts, PackedColorArray([top_color, top_color, bottom_color, bottom_color]))


func _hole_rim(hp: PackedVector2Array) -> void:
	var rim := hp.slice(1, hp.size() - 1)
	draw_polyline(rim, Color(0.03, 0.025, 0.03), 4.0)
	draw_polyline(rim, Color(0.0, 0.0, 0.0, 0.5), 8.0)
	var r := PropArt.rng_for(int(hp[0].x * 13.0))
	var left := hp[0].x
	var right := hp[hp.size() - 1].x
	var stone := Color(0.26, 0.25, 0.24)
	for i in 9:
		var cx := r.randf_range(left + 6.0, right - 6.0)
		if cx < x0 - 10.0 or cx > x1 + 10.0:
			continue
		var w := r.randf_range(4.0, 10.0)
		var h := r.randf_range(3.0, 9.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - w, -9), Vector2(cx - w * 0.4, -9 - h), Vector2(cx + w * 0.6, -9 - h * 0.8), Vector2(cx + w, -9)]), stone.darkened(r.randf() * 0.4))
