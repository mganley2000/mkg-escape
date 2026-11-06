class_name GunView
extends Node2D
## The ranged weapon held at the hero's hand, with recoil kick.

var weapon_id := ""
var facing := 1
var _kick := 0.0


func set_weapon(id: String) -> void:
	weapon_id = id
	queue_redraw()


func kick(amount: float) -> void:
	_kick = amount
	queue_redraw()


func muzzle_offset() -> Vector2:
	return Vector2(float(PropArt.MUZZLE.get(weapon_id, 16.0)) * facing, 0)


func _process(delta: float) -> void:
	if _kick > 0.0:
		_kick = move_toward(_kick, 0.0, delta * 40.0)
		queue_redraw()


func _draw() -> void:
	if weapon_id == "":
		return
	PropArt.draw_weapon(self, weapon_id, Vector2(-_kick * facing, -_kick * 0.3), 1.0, facing)
