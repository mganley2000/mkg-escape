class_name FloorGenerator
extends RefCounted
## Deterministic world generation. The same seed always produces the same
## dungeon: the layout (all ladders/stairs) is built up front because it's tiny,
## and each floor's contents are generated lazily the first time it's needed.

## Up-connectors are kept at least this far from where the player arrives on a
## floor, so every floor has to be crossed.
const MIN_TRAVEL := 1500.0
const SAME_BOUNDARY_GAP := 600.0

const PROP_WEIGHTS := [
	{"bones": 6, "skull": 4, "mold": 7, "crack": 3, "cobweb": 4, "rubble": 3, "puddle": 3, "crate": 1, "barrel": 1, "chains": 2, "moss": 4},
	{"crate": 6, "crates": 3, "barrel": 5, "pots": 3, "bones": 3, "mold": 2, "cobweb": 2, "rubble": 3, "banner": 2, "chains": 1, "crack": 2},
	{"banner": 5, "chains": 5, "shackles": 3, "bones": 4, "skull": 3, "crack": 3, "cobweb": 4, "crate": 2, "rubble": 2},
	{"stalactites": 6, "crack": 5, "mold": 4, "moss": 4, "rubble": 4, "puddle": 4, "bones": 2, "cobweb": 3},
	{"banner": 3, "chains": 4, "shackles": 3, "skull": 4, "bones": 4, "crack": 3, "crate": 2, "barrel": 2, "cobweb": 3, "mold": 2},
]

## Props that hug the wall surface and can sit behind ladders and stairs.
const FLAT_WALL_PROPS := ["mold", "crack", "moss"]


static func make_rng(world_seed: int, index: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([world_seed, index, salt])
	return r


## Returns {"boundaries": Array, "start_x": float, "exit_x": float}.
## boundaries[b] lists the ladders/stairs joining floor b to floor b + 1.
static func generate_layout(world_seed: int) -> Dictionary:
	var r := make_rng(world_seed, -1, 1)
	var start_x := r.randf_range(320.0, 900.0)
	if r.randf() < 0.5:
		start_x = GameConst.FLOOR_WIDTH - start_x
	var boundaries: Array = []
	var arrivals: Array = [start_x]
	for b in range(GameConst.FLOOR_COUNT - 1):
		var conns := make_boundary(world_seed, b, arrivals)
		boundaries.append(conns)
		arrivals = []
		for c in conns:
			arrivals.append(c["top_x"])
	var exit_x := far_x(make_rng(world_seed, GameConst.TOP_FLOOR, 3), arrivals)
	return {"boundaries": boundaries, "start_x": start_x, "exit_x": exit_x}


## A random x at least MIN_TRAVEL from every point in avoid (or the farthest found).
static func far_x(r: RandomNumberGenerator, avoid: Array) -> float:
	var lo := GameConst.EDGE_MARGIN + 120.0
	var hi := GameConst.FLOOR_WIDTH - GameConst.EDGE_MARGIN - 120.0
	var best := (lo + hi) * 0.5
	var best_d := -1.0
	for i in 40:
		var x := r.randf_range(lo, hi)
		var d := INF
		for a in avoid:
			d = minf(d, absf(x - float(a)))
		if d >= MIN_TRAVEL:
			return x
		if d > best_d:
			best_d = d
			best = x
	return best


static func make_boundary(world_seed: int, b: int, arrivals: Array) -> Array:
	var r := make_rng(world_seed, b, 101)
	var count := 1
	if r.randf() < 0.5:
		count += 1
	if r.randf() < 0.25:
		count += 1
	var out: Array = []
	var lo := GameConst.EDGE_MARGIN
	var hi := GameConst.FLOOR_WIDTH - GameConst.EDGE_MARGIN
	for attempt in 300:
		if out.size() >= count:
			break
		var min_travel := MIN_TRAVEL if attempt < 200 else MIN_TRAVEL * 0.5
		var is_ladder := r.randf() < 0.55
		var dir := 1 if r.randf() < 0.5 else -1
		var bx := r.randf_range(lo, hi)
		var tx := bx if is_ladder else bx + dir * GameConst.STAIRS_RUN
		if tx < lo or tx > hi:
			continue
		if not _clear_of(bx, arrivals, min_travel) or not _clear_of(tx, arrivals, min_travel):
			continue
		var ok := true
		for c in out:
			if absf(float(c["bottom_x"]) - bx) < SAME_BOUNDARY_GAP:
				ok = false
		if not ok:
			continue
		out.append({
			"type": "ladder" if is_ladder else "stairs",
			"bottom_x": bx,
			"top_x": tx,
			"dir": dir,
			"b": b,
		})
	if out.is_empty():
		var x := far_x(r, arrivals)
		out.append({"type": "ladder", "bottom_x": x, "top_x": x, "dir": 1, "b": b})
	return out


static func _clear_of(x: float, points: Array, dist: float) -> bool:
	for p in points:
		if absf(x - float(p)) < dist:
			return false
	return true


static func _is_blocked(x: float, half_w: float, blocked: Array) -> bool:
	for v in blocked:
		var span: Vector2 = v
		if x + half_w > span.x and x - half_w < span.y:
			return true
	return false


static func generate_floor(world_seed: int, fi: int, layout: Dictionary) -> FloorData:
	var r := make_rng(world_seed, fi, 7)
	var d := FloorData.new()
	d.index = fi
	d.band = GameConst.band_of(fi)
	var boundaries: Array = layout["boundaries"]
	var up: Array = boundaries[fi] if fi < GameConst.TOP_FLOOR else []
	var down: Array = boundaries[fi - 1] if fi > 0 else []

	var blocked: Array = []
	var arrivals: Array = []
	for c in up:
		var bx: float = c["bottom_x"]
		var tx: float = c["top_x"]
		blocked.append(Vector2(minf(bx, tx) - 60.0, maxf(bx, tx) + 60.0))
	for c in down:
		var tx: float = c["top_x"]
		blocked.append(Vector2(tx - 70.0, tx + 70.0))
		arrivals.append(tx)
	if fi == 0:
		var sx: float = layout["start_x"]
		arrivals.append(sx)
	if fi == GameConst.TOP_FLOOR:
		var ex: float = layout["exit_x"]
		blocked.append(Vector2(ex - 150.0, ex + 150.0))

	_gen_holes(r, d, blocked)
	_gen_torches(r, d, blocked)
	_gen_props(r, d, blocked)
	_gen_spawns(r, d, arrivals, fi)
	_gen_pickups(r, d, fi)
	return d


static func _gen_holes(r: RandomNumberGenerator, d: FloorData, blocked: Array) -> void:
	var n := r.randi_range(0, 2)
	for i in n:
		var w := r.randf_range(120.0, 260.0)
		var x := r.randf_range(400.0, GameConst.FLOOR_WIDTH - 400.0)
		if _is_blocked(x, w * 0.5 + 40.0, blocked):
			continue
		d.holes.append({"x": x, "w": w, "h": r.randf_range(50.0, 90.0), "s": r.randi()})
		blocked.append(Vector2(x - w * 0.5 - 20.0, x + w * 0.5 + 20.0))


static func _gen_torches(r: RandomNumberGenerator, d: FloorData, blocked: Array) -> void:
	var x := r.randf_range(150.0, 420.0)
	while x < GameConst.FLOOR_WIDTH - 150.0:
		if not _is_blocked(x, 24.0, blocked):
			d.torches.append({"x": x, "h": -74.0})
		x += r.randf_range(380.0, 720.0)


static func _gen_props(r: RandomNumberGenerator, d: FloorData, blocked: Array) -> void:
	var weights: Dictionary = PROP_WEIGHTS[d.band]
	var entries: Array = []
	for k in weights:
		entries.append([k, weights[k]])
	var x := r.randf_range(40.0, 160.0)
	while x < GameConst.FLOOR_WIDTH - 40.0:
		var t := Tables.pick_weighted(r, entries)
		if FLAT_WALL_PROPS.has(t) or not _is_blocked(x, 24.0, blocked):
			var y := 0.0
			match t:
				"mold":
					y = -r.randf_range(14.0, 92.0)
				"crack":
					y = -r.randf_range(24.0, 96.0)
				"shackles":
					y = -r.randf_range(56.0, 72.0)
			d.props.append({"t": t, "x": x, "y": y, "s": r.randi()})
		x += r.randf_range(50.0, 190.0)


static func _gen_spawns(r: RandomNumberGenerator, d: FloorData, arrivals: Array, fi: int) -> void:
	var n := clampi(3 + fi / 8 + r.randi_range(0, 2), 3, 28)
	var safe := 700.0 if fi == 0 else 360.0
	for i in n:
		for attempt in 8:
			var x := r.randf_range(GameConst.EDGE_MARGIN, GameConst.FLOOR_WIDTH - GameConst.EDGE_MARGIN)
			if not _clear_of(x, arrivals, safe):
				continue
			d.spawns.append({
				"id": Tables.pick_monster(r, d.band),
				"x": x,
				"alive": true,
				"elite": d.band == Tables.ELITE_BAND,
			})
			break


static func _gen_pickups(r: RandomNumberGenerator, d: FloorData, fi: int) -> void:
	var lo := GameConst.EDGE_MARGIN
	var hi := GameConst.FLOOR_WIDTH - GameConst.EDGE_MARGIN
	for i in r.randi_range(1, 3):
		var kind := Tables.pick_weighted(r, Tables.FLOOR_PICKUP_KINDS)
		var p := Tables.make_pickup(r, kind, fi, [])
		p["x"] = r.randf_range(lo, hi)
		p["alive"] = true
		d.pickups.append(p)
	var weapon_chance := 0.35 if fi < 5 else 0.12
	if r.randf() < weapon_chance:
		var w := Tables.make_pickup(r, "weapon", fi, [])
		w["x"] = r.randf_range(lo, hi)
		w["alive"] = true
		d.pickups.append(w)
