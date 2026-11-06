class_name Pickup
extends Node2D
## An item lying on a floor: copper, food, potion, ammo or a weapon.
## Freshly dropped loot pops out of the monster with a little bounce.

var chunk: FloorChunk
var data_index := 0
var kind := ""
var sub := ""
var amount := 0
var _t := 0.0
var _pop := 0.0
var _y := 0.0
var _vy := 0.0


func setup(c: FloorChunk, idx: int, d: Dictionary, pop: bool) -> void:
	chunk = c
	data_index = idx
	kind = d["kind"]
	sub = d["sub"]
	amount = d["amount"]
	position = Vector2(float(d["x"]), GameConst.FOOT_Y)
	z_index = 3
	# Overbright so items read in dim light without needing their own lights.
	modulate = Color(1.9, 1.9, 1.9)
	_t = randf() * TAU
	if pop:
		_pop = 0.6
		_y = -20.0
		_vy = -170.0


func ready_to_collect() -> bool:
	return _pop <= 0.0


func _process(delta: float) -> void:
	_t += delta
	if _pop > 0.0:
		_pop -= delta
		_vy += 900.0 * delta
		_y += _vy * delta
		if _y > 0.0:
			_y = 0.0
			_vy = -_vy * 0.35
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 3.0) * 1.5 - 1.5 if _pop <= 0.0 else 0.0
	PropArt.draw_pickup(self, kind, sub, amount, Vector2(0, _y + bob))
