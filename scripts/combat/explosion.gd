class_name Explosion
extends Node2D
## Rocket blast: kills everything in radius (across neighbouring floors too),
## lights up the area, shakes the camera and scorches the wall.

const DURATION := 0.55

var radius := 100.0
var _t := 0.0


func setup(world: WorldManager, pos: Vector2, blast_radius: float, fi: int) -> void:
	position = pos
	radius = blast_radius
	for m in world.monsters_near(pos, radius):
		var dir := signf(m.position.x - pos.x)
		m.take_hit(dir if dir != 0.0 else 1.0)
	world.flash_light(pos, Color(1.0, 0.6, 0.25), 2.4, 4.0, 0.5)
	world.add_decal(fi, {"t": "scorch", "x": pos.x, "y": pos.y - GameConst.floor_y(fi), "r": radius * 0.35, "s": randi()})
	world.spawn_sparks(pos, Color(1.0, 0.7, 0.3), 22)
	world.shake(12.0)
	Audio.play("explosion", pos)


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var grow := 1.0 - pow(1.0 - k, 3.0)
	var fade := 1.0 - k
	draw_circle(Vector2.ZERO, radius * (0.25 + 0.6 * grow), Color(0.35, 0.3, 0.3, 0.45 * fade))
	draw_circle(Vector2.ZERO, radius * (0.2 + 0.45 * grow), Color(1.0, 0.55, 0.15, 0.85 * fade))
	draw_circle(Vector2.ZERO, radius * (0.1 + 0.25 * grow), Color(1.0, 0.9, 0.55, fade))
	draw_arc(Vector2.ZERO, radius * grow * 1.1, 0, TAU, 40, Color(1.0, 0.75, 0.4, 0.6 * fade), 3.0)
	if k < 0.15:
		draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 1, 1.0 - k / 0.15))
