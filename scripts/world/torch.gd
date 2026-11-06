class_name Torch
extends Node2D
## Wall sconce with a flickering flame. Its PointLight2D is switched on by
## WorldManager only when the torch is among the closest to the camera.

const LIGHT_SCALE := 2.4

var world: WorldManager
var color := Color(1.0, 0.6, 0.3)
var light: PointLight2D
var lit := false
var _t := 0.0
var _redraw := 0.0


func setup(w: WorldManager, pos: Vector2, light_color: Color) -> void:
	world = w
	position = pos
	color = light_color
	z_index = -5


func _ready() -> void:
	_t = randf() * 10.0
	light = PointLight2D.new()
	light.texture = ArtLib.light_texture()
	light.texture_scale = LIGHT_SCALE
	light.color = color
	light.energy = 1.0
	light.position = Vector2(0, -12)
	light.enabled = false
	add_child(light)
	world.register_torch(self)


func _exit_tree() -> void:
	if world:
		world.unregister_torch(self)


func set_lit(value: bool) -> void:
	if lit == value:
		return
	lit = value
	light.enabled = value


func _process(delta: float) -> void:
	_t += delta
	if lit:
		light.energy = 1.0 + sin(_t * 11.0) * 0.07 + sin(_t * 17.3) * 0.05
		light.texture_scale = LIGHT_SCALE + sin(_t * 5.1) * 0.05
	_redraw -= delta
	if _redraw <= 0.0:
		_redraw = 0.07
		queue_redraw()


func _draw() -> void:
	var iron := Color(0.16, 0.14, 0.13)
	draw_rect(Rect2(-2, -2, 4, 12), iron)
	draw_rect(Rect2(-5, -4, 10, 3), iron.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(3, -8), Vector2(-3, -8)]), iron.lightened(0.05))
	var f := sin(_t * 13.0) * 1.3
	var g := sin(_t * 9.0) * 2.0
	var outer := Color(color.r, color.g * 0.75, color.b * 0.5) * 3.0
	var inner := Color(1.0, 0.92, 0.7) * 3.0
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -8), Vector2(4, -8), Vector2(2.5 + f * 0.5, -15), Vector2(f, -22 - g), Vector2(-2.5 + f * 0.3, -14)]), outer)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -8), Vector2(2, -8), Vector2(f * 0.6, -16 - g * 0.5)]), inner)
