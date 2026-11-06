class_name SlabStrip
extends Node2D
## The stone floor under one floor's walkway (which is also the ceiling of the
## floor below), trapdoor openings for ladders/stairs arriving from below,
## the solid rock past both ends of the floor, and bedrock under floor 1.

const CAP := 640.0

var chunk: FloorChunk


func setup(c: FloorChunk) -> void:
	chunk = c
	z_index = 0
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	var w := GameConst.FLOOR_WIDTH
	var band := chunk.data.band
	var top := -GameConst.HEADROOM
	_tiled(Rect2(-CAP, 0, w + CAP * 2.0, GameConst.SLAB), ArtLib.slab_texture(band), Vector2(0, 0))
	draw_line(Vector2(-CAP, 0.5), Vector2(w + CAP, 0.5), Color(1, 1, 1, 0.06), 1.0)

	var rock := ArtLib.rock_texture()
	_tiled(Rect2(-CAP, top, CAP, GameConst.HEADROOM), rock, Vector2(0, top))
	_tiled(Rect2(w, top, CAP, GameConst.HEADROOM), rock, Vector2(0, top))
	_rock_edge(0.0, 1.0)
	_rock_edge(w, -1.0)

	var opening := Color(0.015, 0.012, 0.012)
	var frame := Color(0.3, 0.2, 0.11)
	for c in chunk.world.connectors_down(chunk.index):
		var tx: float = c["top_x"]
		if c["type"] == "ladder":
			draw_rect(Rect2(tx - 16, -9, 32, 25), opening)
			draw_rect(Rect2(tx - 18, -10, 36, 3), frame)
			draw_rect(Rect2(tx - 18, -10, 3, 26), frame.darkened(0.3))
			draw_rect(Rect2(tx + 15, -10, 3, 26), frame.darkened(0.3))
		else:
			var dir: float = c["dir"]
			var a := tx - dir * 62.0
			var lo := minf(a, tx)
			draw_rect(Rect2(lo, -9, 62, 25), opening)
			draw_rect(Rect2(lo - 2, -10, 66, 2), frame.darkened(0.2))

	if chunk.index == 0:
		_tiled(Rect2(-CAP, GameConst.SLAB, w + CAP * 2.0, 520), rock, Vector2(0, GameConst.SLAB))
		_gradient(Rect2(-CAP, GameConst.SLAB, w + CAP * 2.0, 40), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0))


func _rock_edge(x: float, dir: float) -> void:
	var r := PropArt.rng_for(chunk.index * 31 + int(x))
	var pts := PackedVector2Array()
	var top := -GameConst.HEADROOM
	pts.append(Vector2(x, top))
	var y := top
	while y < 0.0:
		pts.append(Vector2(x + dir * r.randf_range(2.0, 14.0), y))
		y += r.randf_range(8.0, 18.0)
	pts.append(Vector2(x, 0))
	draw_colored_polygon(pts, Color(0.16, 0.14, 0.13))
	draw_polyline(pts, Color(0.32, 0.29, 0.27), 1.5)


func _tiled(rect: Rect2, tex: Texture2D, origin: Vector2) -> void:
	var poly := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var uvs := PackedVector2Array()
	var ts := tex.get_size()
	for p in poly:
		uvs.append((p - origin) / ts)
	draw_colored_polygon(poly, Color.WHITE, uvs, tex)


func _gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	var pts := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	draw_polygon(pts, PackedColorArray([top_color, top_color, bottom_color, bottom_color]))
