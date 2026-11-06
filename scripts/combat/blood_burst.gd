class_name BloodBurst
extends Node2D
## Blood droplets with simple ballistics. Droplets that land leave stains on
## the walkway, and the hit itself splatters the wall; both are stored as
## FloorData decals so they persist.

const GRAVITY := 980.0
const COLOR := Color(0.55, 0.03, 0.04)

var world: WorldManager
var floor_idx := 0
var _drops: Array = []
var _t := 0.0


func setup(w: WorldManager, fi: int, origin: Vector2, dir: float, count: int) -> void:
	world = w
	floor_idx = fi
	var d := dir if dir != 0.0 else 1.0
	for i in count:
		var ang := deg_to_rad(randf_range(-75.0, 20.0))
		var spd := randf_range(80.0, 330.0)
		var v := Vector2(cos(ang) * d, sin(ang)) * spd
		_drops.append({"p": origin + Vector2(randf_range(-4, 4), randf_range(-6, 6)), "v": v, "s": randf_range(1.5, 3.5), "l": false})
	var floor_surface := GameConst.floor_y(fi)
	for i in randi_range(1, 2):
		w.add_decal(fi, {
			"t": "wall",
			"x": origin.x + d * randf_range(6.0, 46.0),
			"y": origin.y - floor_surface + randf_range(-14.0, 10.0),
			"r": randf_range(4.0, 9.0),
			"s": randi(),
		})


func _process(delta: float) -> void:
	_t += delta
	var ground := GameConst.floor_y(floor_idx) + GameConst.FOOT_Y
	var active := false
	for d in _drops:
		if d["l"]:
			continue
		active = true
		var v: Vector2 = d["v"]
		v.y += GRAVITY * delta
		d["v"] = v
		var p: Vector2 = d["p"] + v * delta
		if p.y >= ground:
			p.y = ground
			d["l"] = true
			if randf() < 0.3:
				world.add_decal(floor_idx, {"t": "floor", "x": p.x, "r": float(d["s"]) * 1.6, "s": randi()})
		d["p"] = p
	queue_redraw()
	if (not active and _t > 0.1) or _t > 2.0:
		queue_free()


func _draw() -> void:
	for d in _drops:
		if d["l"]:
			continue
		var p: Vector2 = d["p"]
		var s: float = d["s"]
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), COLOR)
