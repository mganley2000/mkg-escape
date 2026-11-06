class_name FloatText
extends Node2D
## Rising, fading label for pickups and damage.

const LIFE := 1.1

var text := ""
var color := Color.WHITE
var _t := 0.0


func setup(pos: Vector2, label: String, c: Color) -> void:
	position = pos
	text = label
	color = c


func _process(delta: float) -> void:
	_t += delta
	position.y -= 28.0 * delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a := clampf(1.5 - _t / LIFE * 1.5, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var pos := Vector2(-60, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, 3, Color(0, 0, 0, a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color(color.r, color.g, color.b, a))
