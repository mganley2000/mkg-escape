class_name ConnectorView
extends Node2D
## Draws a ladder or staircase rising from this floor to the one above.
## Local origin is the floor surface of the lower floor.

var conn: Dictionary
var band := 0


func setup(c: Dictionary, floor_band: int) -> void:
	conn = c
	band = floor_band
	z_index = 2
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	if conn["type"] == "ladder":
		_draw_ladder()
	else:
		_draw_stairs()


func _draw_ladder() -> void:
	var bx: float = conn["bottom_x"]
	var top := -GameConst.FLOOR_HEIGHT
	var wood := Color(0.47, 0.31, 0.17)
	var dark := wood.darkened(0.55)
	draw_rect(Rect2(bx - 10, top - 10, 26, -top + 8), Color(0, 0, 0, 0.35))
	for side in [-1.0, 1.0]:
		var rx: float = bx + side * 11.0
		draw_rect(Rect2(rx - 2, top - 14, 4, -top + 12), dark)
		draw_rect(Rect2(rx - 1.5, top - 14, 2.5, -top + 12), wood)
		draw_line(Vector2(rx - 1, top - 14), Vector2(rx - 1, -3), wood.lightened(0.2), 1.0)
	var y := -9.0
	while y > top - 8.0:
		draw_rect(Rect2(bx - 10, y - 1.5, 20, 3), wood.darkened(0.12))
		draw_line(Vector2(bx - 10, y - 1.5), Vector2(bx + 10, y - 1.5), wood.lightened(0.18), 1.0)
		y -= 12.0


func _draw_stairs() -> void:
	var bx: float = conn["bottom_x"]
	var tx: float = conn["top_x"]
	var dir: float = conn["dir"]
	var n := GameConst.STAIRS_STEPS
	var sw := GameConst.STAIRS_RUN / n
	var sh := GameConst.FLOOR_HEIGHT / n
	var tex := ArtLib.slab_texture(band)

	var pts := PackedVector2Array()
	pts.append(Vector2(bx - dir * 4.0, 0))
	for i in n:
		var xa := bx + dir * i * sw
		var ty := -(i + 1) * sh
		pts.append(Vector2(xa, ty))
		pts.append(Vector2(xa + dir * sw, ty))
	pts.append(Vector2(tx, 0))
	var uvs := PackedVector2Array()
	var ts := tex.get_size()
	for p in pts:
		uvs.append(p / ts)
	draw_colored_polygon(pts, Color(0.85, 0.82, 0.8), uvs, tex)

	var under := PackedVector2Array([Vector2(bx, 0), Vector2(tx, -GameConst.FLOOR_HEIGHT + sh), Vector2(tx, 0)])
	draw_colored_polygon(under, Color(0, 0, 0, 0.35))

	for i in n:
		var xa := bx + dir * i * sw
		var ty := -(i + 1) * sh
		draw_line(Vector2(xa, ty), Vector2(xa + dir * sw, ty), Color(0.75, 0.72, 0.68, 0.55), 2.0)
		draw_line(Vector2(xa, ty), Vector2(xa, ty + sh), Color(0, 0, 0, 0.45), 1.0)
	draw_polyline(PackedVector2Array([Vector2(bx, -18), Vector2(tx, -GameConst.FLOOR_HEIGHT - 18)]), Color(0.3, 0.2, 0.12), 2.0)
	for k in 4:
		var t := (k + 0.5) / 4.0
		var p := Vector2(lerpf(bx, tx, t), lerpf(-18, -GameConst.FLOOR_HEIGHT - 18, t))
		draw_line(p, Vector2(p.x, p.y + 16), Color(0.3, 0.2, 0.12), 1.5)
