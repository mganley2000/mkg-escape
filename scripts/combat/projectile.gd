class_name Projectile
extends Node2D
## Bullets, pellets, bolts, plasma bolts and rockets. Projectiles travel along
## one floor and hit-test against that floor's monsters with a swept check, so
## fast bullets can't tunnel through enemies.

var world: WorldManager
var weapon: WeaponData
var velocity := Vector2.ZERO
var floor_idx := 0
var traveled := 0.0
var pierce_left := 0
var _hit: Dictionary = {}
var _light: PointLight2D
var _smoke_timer := 0.0
var _t := 0.0


func setup(w: WorldManager, wd: WeaponData, pos: Vector2, dir: Vector2, fi: int) -> void:
	world = w
	weapon = wd
	position = pos
	velocity = dir.normalized() * wd.projectile_speed
	floor_idx = fi
	pierce_left = wd.pierce
	rotation = velocity.angle()
	if wd.kind == "plasma" or wd.kind == "rocket":
		_light = w.flash_light(pos, wd.color, 0.9, 0.6, -1.0)
	if wd.kind == "rocket":
		Audio.play_attached("rocket_thrust", self)


func _process(delta: float) -> void:
	_t += delta
	if weapon.kind == "rocket":
		velocity *= 1.0 + 2.4 * delta
		if velocity.length() > 1300.0:
			velocity = velocity.normalized() * 1300.0
		_smoke_timer -= delta
		if _smoke_timer <= 0.0:
			_smoke_timer = 0.025
			world.spawn_sparks(position - velocity.normalized() * 10.0, Color(0.6, 0.6, 0.6, 0.5), 1)

	var from := position
	var step := velocity * delta
	position += step
	traveled += step.length()
	if _light:
		_light.global_position = global_position

	var h := GameConst.floor_y(floor_idx) + GameConst.FOOT_Y - position.y
	if h < 0.0 or h > GameConst.HEADROOM - 4.0 or position.x < 0.0 or position.x > GameConst.FLOOR_WIDTH:
		_impact(true)
		return

	var x_lo := minf(from.x, position.x)
	var x_hi := maxf(from.x, position.x)
	for m in world.get_monsters(floor_idx).duplicate():
		var id: int = m.get_instance_id()
		if _hit.has(id) or not m.is_alive():
			continue
		var hw: float = m.hit_half_width()
		var mx: float = m.position.x
		if mx + hw < x_lo or mx - hw > x_hi:
			continue
		var band: Vector2 = m.body_band()
		if h < band.x - 4.0 or h > band.y + 4.0:
			continue
		_hit[id] = true
		if weapon.kind == "rocket":
			position.x = mx
			_impact(false)
			return
		m.take_hit(signf(velocity.x))
		if pierce_left <= 0:
			_impact(false)
			return
		pierce_left -= 1

	if traveled > weapon.max_range:
		if weapon.kind == "rocket":
			_impact(true)
		else:
			_finish()
		return
	queue_redraw()


func _impact(hit_wall: bool) -> void:
	if weapon.kind == "rocket":
		world.spawn_explosion(position, weapon.splash_radius, floor_idx)
	elif hit_wall:
		world.spawn_sparks(position, weapon.color, 5)
		if weapon.kind == "bullet" or weapon.kind == "bolt":
			Audio.play("ricochet", global_position)
	_finish()


func _finish() -> void:
	if _light:
		_light.queue_free()
		_light = null
	queue_free()


func _draw() -> void:
	match weapon.kind:
		"bullet":
			var len := 18.0 if weapon.pellets == 1 else 10.0
			draw_line(Vector2(-len, 0), Vector2.ZERO, Color(weapon.color.r, weapon.color.g, weapon.color.b, 0.45), 2.0)
			draw_line(Vector2(-4, 0), Vector2(1, 0), Color(1.0, 0.97, 0.85), 2.0)
		"bolt":
			draw_line(Vector2(-14, 0), Vector2(0, 0), Color(0.6, 0.45, 0.3), 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(4, 0), Vector2(0, 2)]), Color(0.75, 0.75, 0.8))
			draw_line(Vector2(-14, -2), Vector2(-11, 0), Color(0.85, 0.85, 0.8), 1.0)
			draw_line(Vector2(-14, 2), Vector2(-11, 0), Color(0.85, 0.85, 0.8), 1.0)
		"plasma":
			var pulse := 1.0 + sin(_t * 40.0) * 0.15
			draw_line(Vector2(-16, 0), Vector2.ZERO, Color(weapon.color.r, weapon.color.g, weapon.color.b, 0.25), 6.0)
			draw_circle(Vector2.ZERO, 7.0 * pulse, Color(weapon.color.r, weapon.color.g, weapon.color.b, 0.35))
			draw_circle(Vector2.ZERO, 4.0 * pulse, weapon.color)
			draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
		"rocket":
			var flicker := 4.0 + sin(_t * 60.0) * 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -2), Vector2(-10 - flicker * 2.0, 0), Vector2(-10, 2)]), Color(1.0, 0.6, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -1), Vector2(-10 - flicker, 0), Vector2(-10, 1)]), Color(1.0, 0.95, 0.7))
			draw_rect(Rect2(-10, -2.5, 12, 5), Color(0.55, 0.58, 0.5))
			draw_colored_polygon(PackedVector2Array([Vector2(2, -2.5), Vector2(7, 0), Vector2(2, 2.5)]), Color(0.75, 0.2, 0.15))
			draw_rect(Rect2(-10, -4, 3, 8), Color(0.35, 0.38, 0.32))
