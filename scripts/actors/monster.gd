class_name Monster
extends Node2D
## Generic monster driven by a MonsterData resource. Wanders its floor, chases
## the hero when they share a floor and are close enough, and attacks in melee.
## Every monster dies in one hit; depth makes them faster, deadlier and more
## alert rather than tougher.

enum State { IDLE, WANDER, CHASE, WINDUP, ATTACK, DEAD }

var world: WorldManager
var chunk: FloorChunk
var spawn_index := 0
var data: MonsterData
var elite := false
var state := State.IDLE
var facing := 1
var sprite: CharSprite
var shadow: ShadowBlob

var _rng := RandomNumberGenerator.new()
var _state_time := 0.0
var _wander_target := 0.0
var _home_x := 0.0
var _attack_cd := 0.0
var _hit_done := false
var _speed_mult := 1.0
var _damage := 1.0
var _detect := 300.0
var _cooldown := 1.0
var _reach_jitter := 0.0
var _hover_phase := 0.0
var _hover := 0.0
var _scale := 1.0


func setup(w: WorldManager, c: FloorChunk, idx: int, spawn: Dictionary) -> void:
	world = w
	chunk = c
	spawn_index = idx
	data = Database.monster(spawn["id"])
	elite = spawn["elite"]
	position = Vector2(float(spawn["x"]), 0.0)
	_home_x = position.x
	_rng.seed = hash([w.world_seed, c.index, idx, "monster"])
	var depth := float(c.index)
	_speed_mult = 1.0 + depth * 0.005
	_damage = data.damage * (1.0 + depth * 0.012)
	_detect = data.detect_range + depth * 1.5
	_cooldown = maxf(data.attack_cooldown * (1.0 - depth * 0.0025), 0.45)
	if elite:
		_speed_mult *= 1.15
		_damage *= 1.25
	_reach_jitter = _rng.randf_range(-6.0, 4.0)
	_hover_phase = _rng.randf() * TAU
	facing = 1 if _rng.randf() < 0.5 else -1
	_scale = data.sprite_scale * (1.15 if elite else 1.0)
	z_index = 4


func _ready() -> void:
	shadow = ShadowBlob.new()
	shadow.radius = data.hit_half_width * _scale
	shadow.position.y = GameConst.FOOT_Y
	add_child(shadow)
	sprite = CharSprite.new()
	add_child(sprite)
	sprite.setup(data.sprite_key)
	sprite.position.y = GameConst.FOOT_Y
	sprite.scale = Vector2(_scale, _scale)
	var mat := ArtLib.tint_material("elite" if elite else data.tint)
	if mat:
		sprite.material = mat
	sprite.set_facing(facing)
	sprite.play_anim("idle")
	sprite.frame = _rng.randi() % maxi(sprite.sprite_frames.get_frame_count("idle"), 1)
	sprite.animation_finished.connect(_on_animation_finished)
	_state_time = _rng.randf_range(0.5, 2.5)


func is_alive() -> bool:
	return state != State.DEAD


func is_hunting() -> bool:
	return state == State.CHASE or state == State.WINDUP or state == State.ATTACK


func hit_half_width() -> float:
	return data.hit_half_width * _scale


## Vertical extent of the body measured upward from the floor (min, max).
func body_band() -> Vector2:
	var lo := _hover
	return Vector2(lo, lo + data.body_height * _scale)


func center() -> Vector2:
	var band := body_band()
	return global_position + Vector2(0, GameConst.FOOT_Y - (band.x + band.y) * 0.5)


func _process(delta: float) -> void:
	_update_hover(delta)
	if state == State.DEAD:
		return
	_state_time -= delta
	_attack_cd -= delta

	var p := world.player
	var engaged := p.can_be_targeted() and p.target_floor() == chunk.index
	var dx := p.global_position.x - position.x
	var dist := absf(dx)
	var sees := engaged and dist < _detect

	match state:
		State.IDLE:
			sprite.play_anim("idle")
			if sees:
				_set_state(State.CHASE)
			elif _state_time <= 0.0:
				_pick_wander()
		State.WANDER:
			if sees:
				_set_state(State.CHASE)
			else:
				var to_target := _wander_target - position.x
				if absf(to_target) < 4.0 or _state_time <= 0.0:
					_set_state(State.IDLE)
					_state_time = _rng.randf_range(1.0, 3.5)
				else:
					_move(signf(to_target) * data.speed * _speed_mult, delta)
					sprite.play_anim("walk")
		State.CHASE:
			if not engaged or dist > _detect * 1.6:
				_pick_wander()
			else:
				_face(int(signf(dx)))
				if dist <= data.attack_range + _reach_jitter:
					if _attack_cd <= 0.0:
						_start_attack()
					else:
						sprite.play_anim("idle")
				else:
					_move(signf(dx) * data.chase_speed * _speed_mult, delta)
					sprite.play_anim("walk")
		State.WINDUP:
			if _state_time <= 0.0:
				_begin_strike()
		State.ATTACK:
			if not _hit_done and _state_time <= 0.0:
				_hit_done = true
				if engaged and dist <= data.attack_range + 16.0 and (signf(dx) == float(facing) or dist < 10.0):
					p.take_damage(_damage, position.x)


func _update_hover(delta: float) -> void:
	if data.hover_height <= 0.0:
		return
	_hover_phase += delta * 3.0
	var target := data.hover_height + sin(_hover_phase) * 5.0
	if state == State.ATTACK:
		target = 6.0
	elif state == State.DEAD:
		target = 0.0
	_hover = lerpf(_hover, target, 1.0 - exp(-8.0 * delta))
	sprite.position.y = GameConst.FOOT_Y - _hover
	shadow.scale = Vector2.ONE * clampf(1.0 - _hover / 80.0, 0.4, 1.0)


func _set_state(s: State) -> void:
	var was := state
	state = s
	if s == State.CHASE and was != State.CHASE and was != State.WINDUP and was != State.ATTACK:
		_growl()


func _pick_wander() -> void:
	_wander_target = clampf(_home_x + _rng.randf_range(-420.0, 420.0), 40.0, GameConst.FLOOR_WIDTH - 40.0)
	_state_time = _rng.randf_range(3.0, 7.0)
	_set_state(State.WANDER)


func _move(velocity: float, delta: float) -> void:
	position.x = clampf(position.x + velocity * delta, 30.0, GameConst.FLOOR_WIDTH - 30.0)
	_face(int(signf(velocity)))


func _face(dir: int) -> void:
	if dir != 0:
		facing = dir
		sprite.set_facing(dir)


func _start_attack() -> void:
	_growl()
	if data.windup_anim != "":
		_set_state(State.WINDUP)
		sprite.play_anim(data.windup_anim, true)
		_state_time = data.windup_time
	else:
		_begin_strike()


func _begin_strike() -> void:
	_set_state(State.ATTACK)
	sprite.play_anim("attack", true)
	_hit_done = false
	_state_time = data.attack_hit_time


func _on_animation_finished() -> void:
	if state == State.ATTACK and sprite.animation == "attack":
		_attack_cd = _cooldown * _rng.randf_range(0.85, 1.2)
		_set_state(State.CHASE)
	elif state == State.DEAD and sprite.animation == "death":
		var tw := create_tween()
		tw.tween_interval(2.5)
		tw.tween_property(self, "modulate:a", 0.0, 1.5)
		tw.tween_callback(queue_free)


func _growl() -> void:
	if data.voice != "":
		Audio.play("voice_%s" % data.voice, global_position)


## One hit from any weapon is fatal.
func take_hit(dir: float) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	chunk.on_monster_died(self)
	_face(-int(signf(dir)) if dir != 0.0 else facing)
	sprite.play_anim("death", true)
	var push := create_tween()
	push.tween_property(self, "position:x", clampf(position.x + dir * 14.0, 30.0, GameConst.FLOOR_WIDTH - 30.0), 0.25).set_ease(Tween.EASE_OUT)
	world.spawn_blood(chunk.index, center(), dir, 34 if elite else 26)
	world.drop_loot(chunk.index, position.x)
	world.shake(2.5)
	if data.voice != "":
		Audio.play("death_%s" % data.voice, global_position)
	Audio.play("gore", global_position)
	GameState.kills += 1
	Events.monster_killed.emit(data.id, chunk.index)
