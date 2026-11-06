class_name TempLight
extends PointLight2D
## Short-lived light that fades out (muzzle flashes, explosions). A negative
## duration means it lives until its owner frees it (projectile glow).

var duration := 0.1
var _t := 0.0
var _start_energy := 1.0


func setup(pos: Vector2, light_color: Color, light_energy: float, scale_value: float, life: float) -> void:
	position = pos
	color = light_color
	energy = light_energy
	_start_energy = light_energy
	texture = ArtLib.light_texture()
	texture_scale = scale_value
	duration = life


func _process(delta: float) -> void:
	if duration < 0.0:
		return
	_t += delta
	energy = _start_energy * clampf(1.0 - _t / duration, 0.0, 1.0)
	if _t >= duration:
		queue_free()
