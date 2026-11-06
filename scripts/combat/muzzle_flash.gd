class_name MuzzleFlash
extends Node2D
## A few frames of muzzle fire.

const LIFE := 0.06

var facing := 1
var color := Color(1, 0.85, 0.5)
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / LIFE
	var f := float(facing)
	var pts := PackedVector2Array([
		Vector2(0, -4) * k, Vector2(10 * f, -2) * k, Vector2(18 * f, 0) * k,
		Vector2(10 * f, 2) * k, Vector2(0, 4) * k,
	])
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.85))
	draw_circle(Vector2(3 * f, 0), 3.0 * k, Color(1, 1, 0.9))
