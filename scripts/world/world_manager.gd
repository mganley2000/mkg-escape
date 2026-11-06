class_name WorldManager
extends Node2D
## Owns the dungeon: the generated layout, the remembered FloorData for every
## floor seen so far, and streaming FloorChunks in and out around the camera.
## Also the spawn point for effects, projectiles and loot.

const LOAD_MARGIN := 1
const UNLOAD_MARGIN := 3
const MAX_TORCH_LIGHTS := 22

var world_seed := 0
var layout: Dictionary = {}
var floors: Dictionary = {}
var chunks: Dictionary = {}
var player: Player
var camera: GameCamera
var game: Node
## Effects drawn under the darkness/lighting (blood, lights).
var fx_layer: Node2D
## Effects drawn above the darkness so they always read clearly.
var glow_layer: Node2D

var _torches: Array = []
var _light_timer := 0.0
var _rng := RandomNumberGenerator.new()


func setup(seed_value: int, p: Player, cam: GameCamera, glow: Node2D, game_node: Node) -> void:
	world_seed = seed_value
	_rng.seed = hash([seed_value, "runtime"])
	layout = FloorGenerator.generate_layout(seed_value)
	player = p
	camera = cam
	glow_layer = glow
	game = game_node
	fx_layer = Node2D.new()
	fx_layer.name = "FX"
	fx_layer.z_index = 6
	add_child(fx_layer)


func start_x() -> float:
	return layout["start_x"]


func exit_x() -> float:
	return layout["exit_x"]


## Ladders/stairs leaving floor fi upward.
func connectors_up(fi: int) -> Array:
	if fi < 0 or fi >= GameConst.TOP_FLOOR:
		return []
	return layout["boundaries"][fi]


## Ladders/stairs arriving on floor fi from below.
func connectors_down(fi: int) -> Array:
	if fi <= 0 or fi > GameConst.TOP_FLOOR:
		return []
	return layout["boundaries"][fi - 1]


func get_floor(fi: int) -> FloorData:
	if not floors.has(fi):
		floors[fi] = FloorGenerator.generate_floor(world_seed, fi, layout)
	return floors[fi]


func _process(delta: float) -> void:
	update_streaming()
	_light_timer -= delta
	if _light_timer <= 0.0:
		_light_timer = 0.12
		_update_lights()


func view_rect() -> Rect2:
	return camera.view_rect()


func update_streaming() -> void:
	var r := view_rect()
	var lo := clampi(GameConst.floor_index_at_y(r.end.y), 0, GameConst.TOP_FLOOR)
	var hi := clampi(GameConst.floor_index_at_y(r.position.y), 0, GameConst.TOP_FLOOR)
	lo = mini(lo, player.floor_idx)
	hi = maxi(hi, player.floor_idx)
	for fi in range(maxi(lo - LOAD_MARGIN, 0), mini(hi + LOAD_MARGIN, GameConst.TOP_FLOOR) + 1):
		if not chunks.has(fi):
			_load_chunk(fi)
	for fi in chunks.keys():
		if fi < lo - UNLOAD_MARGIN or fi > hi + UNLOAD_MARGIN:
			_unload_chunk(fi)


func _load_chunk(fi: int) -> void:
	var d := get_floor(fi)
	d.visited = true
	var c := FloorChunk.new()
	c.name = "Floor%d" % fi
	add_child(c)
	c.build(self, fi, d)
	chunks[fi] = c


func _unload_chunk(fi: int) -> void:
	var c: FloorChunk = chunks[fi]
	c.persist()
	chunks.erase(fi)
	c.queue_free()


func get_monsters(fi: int) -> Array:
	if chunks.has(fi):
		return chunks[fi].monsters
	return []


## Monsters on this floor and the ones next to it that are actively hunting.
func threat_count() -> int:
	if player == null or not player.can_be_targeted():
		return 0
	var n := 0
	var fi := player.floor_idx
	for f in range(maxi(fi - 1, 0), mini(fi + 1, GameConst.TOP_FLOOR) + 1):
		for m in get_monsters(f):
			if m.is_hunting():
				n += 1
	return n


func monsters_near(pos: Vector2, radius: float) -> Array:
	var out: Array = []
	var fi := GameConst.floor_index_at_y(pos.y)
	for f in range(fi - 1, fi + 2):
		for m in get_monsters(f):
			if m.center().distance_to(pos) <= radius + m.data.hit_half_width:
				out.append(m)
	return out


func register_torch(t: Torch) -> void:
	_torches.append(t)


func unregister_torch(t: Torch) -> void:
	_torches.erase(t)


## Only the torches nearest the camera get real lights, to stay fast on WASM.
func _update_lights() -> void:
	var r := view_rect().grow(260.0)
	var center := r.get_center()
	var candidates: Array = []
	for t in _torches:
		if r.has_point(t.global_position):
			candidates.append(t)
		else:
			t.set_lit(false)
	candidates.sort_custom(func(a, b): return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center))
	for i in candidates.size():
		candidates[i].set_lit(i < MAX_TORCH_LIGHTS)


# --- Decals & loot -------------------------------------------------------------

func add_decal(fi: int, d: Dictionary) -> void:
	if fi < 0 or fi > GameConst.TOP_FLOOR:
		return
	get_floor(fi).add_decal(d)
	if chunks.has(fi):
		chunks[fi].refresh_decals(float(d["x"]))


func drop_loot(fi: int, x: float) -> void:
	var items := Tables.roll_loot(_rng, fi, player.owned_ammo_types())
	var d := get_floor(fi)
	for it in items:
		it["x"] = clampf(x + _rng.randf_range(-26.0, 26.0), 30.0, GameConst.FLOOR_WIDTH - 30.0)
		it["alive"] = true
		d.pickups.append(it)
		if chunks.has(fi):
			chunks[fi].spawn_pickup(d.pickups.size() - 1, true)


# --- Effects -------------------------------------------------------------------

func spawn_blood(fi: int, pos: Vector2, dir: float, count: int) -> void:
	var b := BloodBurst.new()
	b.setup(self, fi, pos, dir, count)
	fx_layer.add_child(b)


func spawn_projectile(w: WeaponData, pos: Vector2, dir: Vector2, fi: int) -> void:
	var p := Projectile.new()
	p.setup(self, w, pos, dir, fi)
	glow_layer.add_child(p)


func spawn_muzzle(pos: Vector2, facing: int, color: Color) -> void:
	var m := MuzzleFlash.new()
	m.position = pos
	m.facing = facing
	m.color = color
	glow_layer.add_child(m)
	flash_light(pos, color, 1.4, 1.3, 0.08)


func spawn_explosion(pos: Vector2, radius: float, fi: int) -> void:
	var e := Explosion.new()
	glow_layer.add_child(e)
	e.setup(self, pos, radius, fi)


func spawn_sparks(pos: Vector2, color: Color, count: int = 6) -> void:
	var s := Sparks.new()
	s.setup(pos, color, count)
	glow_layer.add_child(s)


func float_text(pos: Vector2, text: String, color: Color) -> void:
	var f := FloatText.new()
	f.setup(pos, text, color)
	glow_layer.add_child(f)


func flash_light(pos: Vector2, color: Color, energy: float, scale_value: float, duration: float) -> PointLight2D:
	var l := TempLight.new()
	l.setup(pos, color, energy, scale_value, duration)
	fx_layer.add_child(l)
	return l


func shake(amount: float) -> void:
	camera.add_shake(amount)
