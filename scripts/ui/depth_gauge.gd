class_name DepthGauge
extends Control
## Vertical progress bar on the right edge: how far up the 200 floors you are.

var floor_index := 0
var best := 0


func _init() -> void:
	custom_minimum_size = Vector2(26, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_floor(i: int, best_floor: int) -> void:
	floor_index = i
	best = best_floor
	queue_redraw()


func _draw() -> void:
	var bar := Rect2(6, 0, 14, size.y)
	draw_rect(bar, Color(0.05, 0.045, 0.06, 0.85))
	var n := float(GameConst.FLOOR_COUNT - 1)
	for b in GameConst.BAND_COUNT:
		var y0 := bar.end.y - bar.size.y * (b * GameConst.BAND_SIZE) / n
		draw_line(Vector2(bar.position.x - 3, y0), Vector2(bar.end.x + 3, y0), UiStyle.TRIM, 1.0)
	var best_y := bar.end.y - bar.size.y * best / n
	draw_rect(Rect2(bar.position.x + 2, best_y, bar.size.x - 4, bar.end.y - best_y), Color(0.45, 0.3, 0.15, 0.6))
	var y := bar.end.y - bar.size.y * floor_index / n
	draw_colored_polygon(PackedVector2Array([Vector2(0, y - 6), Vector2(8, y), Vector2(0, y + 6)]), UiStyle.GOLD)
	draw_rect(Rect2(bar.position.x + 1, y - 1.5, bar.size.x - 2, 3), UiStyle.GOLD)
	draw_rect(bar, UiStyle.TRIM, false, 2.0)
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(-20, -8), "SKY", HORIZONTAL_ALIGNMENT_CENTER, 66, 13, 3, Color.BLACK)
	draw_string(font, Vector2(-20, -8), "SKY", HORIZONTAL_ALIGNMENT_CENTER, 66, 13, Color(0.6, 0.75, 1.0))
