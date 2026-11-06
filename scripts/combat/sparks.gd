class_name Sparks
extends Node2D
## Tiny bright particles (ricochets, rocket exhaust, explosion debris).

var _parts: Array = []
var _t := 0.0
var _life := 0.4
var _color := Color.WHITE


func setup(pos: Vector2, color: Color, count: int) -> void:
	position = pos
	_color = color
	_life = 0.35 if count > 1 else 0.5
	var lo := 40.0 if count > 1 else 5.0
	var hi := 260.0 if count > 1 else 20.0
	for i in count:
		var v := Vector2.from_angle(randf() * TAU) * randf_range(lo, hi)
		_parts.append([Vector2.ZERO, v])


func _process(delta: float) -> void:
	_t += delta
	if _t >= _life:
		queue_free()
		return
	for p in _parts:
		var v: Vector2 = p[1]
		v.y += 500.0 * delta
		p[1] = v
		p[0] = p[0] + v * delta
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - _t / _life
	var c := Color(_color.r, _color.g, _color.b, _color.a * a)
	for p in _parts:
		var pos: Vector2 = p[0]
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), c)
