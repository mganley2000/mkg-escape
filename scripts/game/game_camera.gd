class_name GameCamera
extends Camera2D
## Character-centered follow camera with look-ahead, smoothing, shake, and a
## zoom limit that never shows more than MAX_VISIBLE_FLOORS floors.

const MAX_ZOOM := 3.2
const DEFAULT_ZOOM := 1.9
const LOOK_AHEAD := 110.0

var target: Node2D
var zoom_level := DEFAULT_ZOOM
var _look := 0.0
var _shake := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	limit_left = int(-260)
	limit_right = int(GameConst.FLOOR_WIDTH + 260.0)
	limit_bottom = int(GameConst.SLAB + 320.0)
	limit_top = int(GameConst.floor_y(GameConst.TOP_FLOOR) - GameConst.FLOOR_HEIGHT - 900.0)
	zoom = Vector2(zoom_level, zoom_level)
	make_current()


func min_zoom() -> float:
	var h := get_viewport_rect().size.y
	return h / (GameConst.MAX_VISIBLE_FLOORS * GameConst.FLOOR_HEIGHT) * 1.001


func set_zoom_level(z: float, instant: bool = false) -> void:
	zoom_level = clampf(z, min_zoom(), MAX_ZOOM)
	if instant:
		zoom = Vector2(zoom_level, zoom_level)


func snap() -> void:
	if target:
		global_position = _desired()
	reset_smoothing()


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func view_rect() -> Rect2:
	var size := get_viewport_rect().size / zoom
	var c := get_screen_center_position()
	return Rect2(c - size * 0.5, size)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_level *= 1.15
	if Input.is_action_just_pressed("zoom_out"):
		zoom_level /= 1.15
	zoom_level = clampf(zoom_level, min_zoom(), MAX_ZOOM)
	var z := lerpf(zoom.x, zoom_level, 1.0 - exp(-10.0 * delta))
	zoom = Vector2(z, z)

	if target:
		var facing := 1.0
		if target is Player:
			facing = float((target as Player).facing)
		_look = lerpf(_look, facing * LOOK_AHEAD, 1.0 - exp(-2.5 * delta))
		global_position = _desired()

	if _shake > 0.0:
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 30.0)
	else:
		offset = Vector2.ZERO


func _desired() -> Vector2:
	return target.global_position + Vector2(_look, -46.0)
