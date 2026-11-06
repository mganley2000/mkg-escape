class_name StatBar
extends Control
## Labeled segmented bar used for health and hunger.

var title := ""
var fill_color := Color.RED
var value := 1.0
var max_value := 1.0
var _t := 0.0


func _init(bar_title: String = "", color: Color = Color.RED, width: float = 280.0) -> void:
	title = bar_title
	fill_color = color
	custom_minimum_size = Vector2(width, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_value(v: float, m: float) -> void:
	value = v
	max_value = m
	queue_redraw()


func _process(delta: float) -> void:
	if value / max_value < 0.25:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(0, 17), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(0, 17), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiStyle.MUTED)
	var bar := Rect2(0, 24, size.x, 26)
	draw_rect(bar, Color(0.07, 0.06, 0.07))
	var k := clampf(value / max_value, 0.0, 1.0)
	var fc := fill_color
	if k < 0.25:
		fc = fc.lerp(Color.WHITE, (sin(_t * 8.0) * 0.5 + 0.5) * 0.35)
	if k > 0.0:
		var inner := Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6.0) * k, bar.size.y - 6.0))
		draw_rect(inner, fc.darkened(0.25))
		draw_rect(Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.45)), fc)
		draw_rect(Rect2(inner.position, Vector2(inner.size.x, 2)), fc.lightened(0.35))
	for i in range(1, 10):
		var x := bar.position.x + bar.size.x * i / 10.0
		draw_line(Vector2(x, bar.position.y + 3), Vector2(x, bar.end.y - 3), Color(0, 0, 0, 0.35), 1.0)
	draw_rect(bar, UiStyle.TRIM, false, 2.0)
	var txt := "%d / %d" % [int(ceilf(value)), int(max_value)]
	draw_string_outline(font, Vector2(0, bar.position.y + 19), txt, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 10.0, 16, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(0, bar.position.y + 19), txt, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 10.0, 16, Color.WHITE)
