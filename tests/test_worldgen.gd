extends SceneTree
## Headless checks for world generation. Run with:
##   godot --headless --path . -s res://tests/test_worldgen.gd

const SEEDS := [1, 42, 12345, 987654321, -77]

var _failures := 0


func _init() -> void:
	for seed_value in SEEDS:
		_check_seed(seed_value)
	if _failures == 0:
		print("worldgen: PASS (%d seeds)" % SEEDS.size())
	else:
		print("worldgen: FAIL (%d problems)" % _failures)
	quit(1 if _failures > 0 else 0)


func _fail(msg: String) -> void:
	_failures += 1
	printerr("  ", msg)


func _check_seed(seed_value: int) -> void:
	var layout := FloorGenerator.generate_layout(seed_value)
	var boundaries: Array = layout["boundaries"]
	if boundaries.size() != GameConst.FLOOR_COUNT - 1:
		_fail("seed %d: expected %d boundaries, got %d" % [seed_value, GameConst.FLOOR_COUNT - 1, boundaries.size()])

	var min_travel := INF
	var arrivals: Array = [layout["start_x"]]
	for b in boundaries.size():
		var conns: Array = boundaries[b]
		if conns.is_empty():
			_fail("seed %d: floor %d has no way up" % [seed_value, b + 1])
		for c in conns:
			for key in ["bottom_x", "top_x"]:
				var x: float = c[key]
				if x < 0.0 or x > GameConst.FLOOR_WIDTH:
					_fail("seed %d: connector out of bounds on boundary %d" % [seed_value, b])
			for a in arrivals:
				min_travel = minf(min_travel, absf(float(c["bottom_x"]) - float(a)))
		arrivals = conns.map(func(c): return c["top_x"])

	var exit_x: float = layout["exit_x"]
	if exit_x < 0.0 or exit_x > GameConst.FLOOR_WIDTH:
		_fail("seed %d: exit out of bounds" % seed_value)

	if layout != FloorGenerator.generate_layout(seed_value):
		_fail("seed %d: layout is not deterministic" % seed_value)

	for fi in [0, 1, 39, 40, 120, 160, GameConst.TOP_FLOOR]:
		var a := FloorGenerator.generate_floor(seed_value, fi, layout).to_dict()
		var b := FloorGenerator.generate_floor(seed_value, fi, layout).to_dict()
		if a != b:
			_fail("seed %d: floor %d is not deterministic" % [seed_value, fi])
		if (a["spawns"] as Array).is_empty():
			_fail("seed %d: floor %d has no monsters" % [seed_value, fi])
		for s in a["spawns"]:
			if not Tables.MONSTER_BANDS[GameConst.band_of(fi)].any(func(e): return e[0] == s["id"]):
				_fail("seed %d: floor %d spawned out-of-band monster %s" % [seed_value, fi, s["id"]])

	print("seed %d: %d boundaries, closest up-connector to an arrival = %.0f px" % [seed_value, boundaries.size(), min_travel])
