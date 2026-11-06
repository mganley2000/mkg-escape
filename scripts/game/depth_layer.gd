class_name DepthLayer
extends Node2D
## Manual parallax layer living inside a CanvasLayer that follows the camera.
## FAR is the deep cavern seen through broken walls (moves slower than the
## world); FOREGROUND is dark pillars passing in front of the hero (moves
## faster), which is what makes him read as standing inside the scene.

enum Mode { FAR, FOREGROUND }

const FAR_FACTOR := 0.55
const FG_FACTOR := 1.3
const FG_COLUMN := 1500.0

var mode := Mode.FAR
var camera: GameCamera


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(_delta: float) -> void:
	if camera == null:
		return
	var factor := FAR_FACTOR if mode == Mode.FAR else FG_FACTOR
	position = camera.get_screen_center_position() * (1.0 - factor)
	queue_redraw()


func _draw() -> void:
	if camera == null:
		return
	var view := camera.view_rect()
	var local := Rect2(view.position - position, view.size)
	if mode == Mode.FAR:
		_draw_far(local)
	else:
		_draw_foreground(local)


func _draw_far(local: Rect2) -> void:
	var tex := ArtLib.far_texture()
	var ts := tex.get_size()
	var start := Vector2(floorf(local.position.x / ts.x) * ts.x, floorf(local.position.y / ts.y) * ts.y)
	var size := Vector2(ceilf((local.end.x - start.x) / ts.x) * ts.x, ceilf((local.end.y - start.y) / ts.y) * ts.y)
	draw_texture_rect(tex, Rect2(start, size), true)


func _draw_foreground(local: Rect2) -> void:
	var first := int(floorf(local.position.x / FG_COLUMN)) - 1
	var last := int(ceilf(local.end.x / FG_COLUMN)) + 1
	var top := local.position.y - 20.0
	var height := local.size.y + 40.0
	for col in range(first, last + 1):
		var r := PropArt.rng_for(hash([col, "pillar"]))
		if r.randf() > 0.55:
			continue
		var x := col * FG_COLUMN + r.randf_range(100.0, FG_COLUMN - 200.0)
		var w := r.randf_range(22.0, 44.0)
		var body := Color(0.012, 0.01, 0.016, 0.82)
		draw_rect(Rect2(x, top, w, height), body)
		draw_rect(Rect2(x + w - 3.0, top, 3.0, height), Color(0.14, 0.12, 0.18, 0.5))
		draw_rect(Rect2(x, top, 2.0, height), Color(0.06, 0.05, 0.08, 0.6))
		# Rough knuckles along the pillar so it doesn't read as a flat bar.
		var y := floorf(top / 90.0) * 90.0
		while y < top + height:
			var k := PropArt.rng_for(hash([col, int(y)]))
			var bulge := k.randf_range(2.0, 8.0)
			draw_rect(Rect2(x - bulge, y, w + bulge * 2.0, k.randf_range(6.0, 14.0)), body)
			y += 90.0
