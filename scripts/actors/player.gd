class_name Player
extends Node2D
## The hero. Walks a floor, hops, climbs ladders and stairs between floors,
## fights with the Rusty Sword or any ranged weapon found, and slowly starves.

const SPEED := 200.0
const CLIMB_SPEED := 130.0
const STAIRS_SPEED := 165.0
const JUMP_VELOCITY := 330.0
const GRAVITY := 1100.0
const MAX_HEALTH := 100.0
const MAX_HUNGER := 100.0
## Hunger points lost per second (full to empty in about 5.5 minutes).
const HUNGER_DRAIN := 0.3
const STARVE_DPS := 2.0
const PICKUP_RANGE := 24.0
const MAGNET_RANGE := 90.0
const MELEE_HIT_DELAY := 0.12
const HAND := Vector2(6, -26)

enum State { GROUND, CLIMB, DEAD, ESCAPED }

var world: WorldManager
var state := State.GROUND
var floor_idx := 0
var facing := 1
var health := MAX_HEALTH
var hunger := MAX_HUNGER
var weapons: Array[String] = ["rusty_sword"]
var weapon_idx := 0
var ammo: Dictionary = {"bullets": 0, "bolts": 0, "shells": 0, "rockets": 0, "cells": 0}

var sprite: CharSprite
var gun: GunView
var lantern: PointLight2D
var shadow: ShadowBlob
var _mat: ShaderMaterial

var _air_y := 0.0
var _air_v := 0.0
var _climb: Dictionary = {}
var _climb_t := 0.0
var _climb_moving := false
var _moving := false
var _fire_cd := 0.0
var _combo := 0
var _combo_timer := 0.0
var _attack_lock := 0.0
var _melee_pending := -1.0
var _melee_reach := 0.0
var _invuln := 0.0
var _hurt_time := 0.0
var _flash := 0.0
var _hint := ""
var _last_hp := -1
var _last_hunger := -1
var _t := 0.0
var _step_t := 0.0


func setup(w: WorldManager) -> void:
	world = w
	floor_idx = 0
	position = Vector2(w.start_x(), GameConst.floor_y(0))
	facing = 1 if w.start_x() < GameConst.FLOOR_WIDTH * 0.5 else -1


func _ready() -> void:
	z_index = 5
	shadow = ShadowBlob.new()
	shadow.position.y = GameConst.FOOT_Y
	add_child(shadow)
	sprite = CharSprite.new()
	add_child(sprite)
	sprite.setup("warrior")
	sprite.position.y = GameConst.FOOT_Y
	_mat = ArtLib.new_flash_material()
	sprite.material = _mat
	gun = GunView.new()
	add_child(gun)
	lantern = PointLight2D.new()
	lantern.texture = ArtLib.light_texture()
	lantern.texture_scale = 3.4
	lantern.energy = 1.05
	lantern.color = Color(1.0, 0.86, 0.66)
	lantern.position = Vector2(0, -34)
	add_child(lantern)
	sprite.set_facing(facing)
	sprite.play_anim("idle")
	_equip(0, true)
	call_deferred("emit_all")


func emit_all() -> void:
	Events.health_changed.emit(health, MAX_HEALTH)
	Events.hunger_changed.emit(hunger, MAX_HUNGER)
	Events.weapon_changed.emit(current_weapon().id)
	Events.ammo_changed.emit()
	Events.copper_changed.emit(GameState.copper)
	Events.floor_changed.emit(floor_idx)


func current_weapon() -> WeaponData:
	return Database.weapon(weapons[weapon_idx])


func ammo_for(w: WeaponData) -> int:
	if w.ammo_type == "":
		return -1
	return int(ammo.get(w.ammo_type, 0))


func owned_ammo_types() -> Array:
	var out: Array = []
	for id in weapons:
		var w := Database.weapon(id)
		if w.ammo_type != "" and not out.has(w.ammo_type):
			out.append(w.ammo_type)
	return out


func can_be_targeted() -> bool:
	return state == State.GROUND or state == State.CLIMB


## The floor monsters consider the hero to be on (-1 while mid-climb).
func target_floor() -> int:
	if state == State.CLIMB:
		var b: int = _climb["b"]
		if _climb_t < 0.3:
			return b
		if _climb_t > 0.85:
			return b + 1
		return -1
	return floor_idx


func _process(delta: float) -> void:
	_t += delta
	if state == State.DEAD or state == State.ESCAPED:
		_update_flash(delta)
		return
	_fire_cd -= delta
	_combo_timer -= delta
	_attack_lock -= delta
	_invuln -= delta
	_hurt_time -= delta
	GameState.run_time += delta

	_survival(delta)
	if state == State.DEAD:
		return
	_weapon_input()
	if state == State.GROUND:
		_ground(delta)
	else:
		_climb_update(delta)
	_attack_input()
	_melee_tick(delta)
	_collect_pickups(delta)
	_update_visuals()
	_update_flash(delta)


# --- Movement ------------------------------------------------------------------

func _ground(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var spd := SPEED * (0.3 if _attack_lock > 0.0 else 1.0)
	position.x = clampf(position.x + dir * spd * delta, 24.0, GameConst.FLOOR_WIDTH - 24.0)
	_moving = absf(dir) > 0.1
	if _moving and _attack_lock <= 0.0:
		facing = 1 if dir > 0.0 else -1

	if _air_y >= 0.0 and Input.is_action_just_pressed("jump"):
		_air_v = -JUMP_VELOCITY
		_air_y = -0.01
		Audio.play("jump", global_position)
	if _air_y < 0.0:
		_air_v += GRAVITY * delta
		_air_y += _air_v * delta
		if _air_y >= 0.0:
			_air_y = 0.0
			_air_v = 0.0
			Audio.play("land", global_position)
	position.y = GameConst.floor_y(floor_idx) + _air_y
	if _moving and _air_y == 0.0 and _attack_lock <= 0.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.32
			Audio.play("step", global_position)
	else:
		_step_t = minf(_step_t, 0.08)

	var hint := ""
	var near := _nearby_connector()
	if not near.is_empty():
		var c: Dictionary = near["conn"]
		var what := "ladder" if c["type"] == "ladder" else "stairs"
		if near["up"]:
			hint = "[W] Climb the %s" % what
		else:
			hint = "[S] Descend the %s" % what
		if _air_y == 0.0:
			if near["up"] and Input.is_action_pressed("climb_up"):
				_begin_climb(c, true)
			elif not near["up"] and Input.is_action_pressed("climb_down"):
				_begin_climb(c, false)
	if floor_idx == GameConst.TOP_FLOOR and absf(position.x - world.exit_x()) < 56.0:
		hint = "[W] Escape to the surface!"
		if Input.is_action_just_pressed("climb_up"):
			_escape()
	_set_hint(hint if state == State.GROUND else "")


func _nearby_connector() -> Dictionary:
	for c in world.connectors_up(floor_idx):
		if absf(position.x - float(c["bottom_x"])) < GameConst.INTERACT_RANGE:
			return {"conn": c, "up": true}
	for c in world.connectors_down(floor_idx):
		if absf(position.x - float(c["top_x"])) < GameConst.INTERACT_RANGE:
			return {"conn": c, "up": false}
	return {}


func _begin_climb(c: Dictionary, going_up: bool) -> void:
	_climb = c
	state = State.CLIMB
	_climb_t = 0.0 if going_up else 1.0
	_air_y = 0.0
	_air_v = 0.0
	_attack_lock = 0.0
	_melee_pending = -1.0
	if c["type"] == "stairs":
		var d: int = c["dir"]
		facing = d if going_up else -d
	_set_hint("")


func _climb_update(delta: float) -> void:
	var b: int = _climb["b"]
	var bottom := Vector2(float(_climb["bottom_x"]), GameConst.floor_y(b))
	var top := Vector2(float(_climb["top_x"]), GameConst.floor_y(b + 1))
	var length := bottom.distance_to(top)
	var is_stairs: bool = _climb["type"] == "stairs"
	var input := -Input.get_axis("climb_up", "climb_down")
	if is_stairs:
		var d: float = _climb["dir"]
		input = clampf(input + Input.get_axis("move_left", "move_right") * d, -1.0, 1.0)
	var spd := STAIRS_SPEED if is_stairs else CLIMB_SPEED
	_climb_t = clampf(_climb_t + input * spd * delta / length, 0.0, 1.0)
	_climb_moving = absf(input) > 0.1
	if _climb_moving:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.28 if is_stairs else 0.34
			Audio.play("step" if is_stairs else "ladder", global_position)
	position = bottom.lerp(top, _climb_t)
	if is_stairs and _climb_moving:
		var d: int = _climb["dir"]
		facing = d if input > 0.0 else -d
	_set_floor(b + (1 if _climb_t >= 0.5 else 0))
	if _climb_t >= 1.0 and input > 0.0:
		_end_climb(top)
	elif _climb_t <= 0.0 and input < 0.0:
		_end_climb(bottom)


func _end_climb(at: Vector2) -> void:
	state = State.GROUND
	position = at
	_climb = {}
	_climb_moving = false


func _set_floor(n: int) -> void:
	if n == floor_idx:
		return
	floor_idx = n
	if n > GameState.highest_floor:
		GameState.highest_floor = n
	Events.floor_changed.emit(n)


func _escape() -> void:
	state = State.ESCAPED
	_set_hint("")
	Events.player_escaped.emit()


func _set_hint(text: String) -> void:
	if text != _hint:
		_hint = text
		Events.hint_changed.emit(text)


# --- Weapons -------------------------------------------------------------------

func _weapon_input() -> void:
	if Input.is_action_just_pressed("weapon_next"):
		_cycle(1)
	elif Input.is_action_just_pressed("weapon_prev"):
		_cycle(-1)
	for slot in range(1, Controls.WEAPON_SLOTS + 1):
		if Input.is_action_just_pressed("weapon_%d" % slot):
			for i in weapons.size():
				if Database.weapon(weapons[i]).slot == slot:
					_equip(i)


func _cycle(dir: int) -> void:
	if weapons.size() > 1:
		_equip(posmod(weapon_idx + dir, weapons.size()))


func _equip(i: int, silent := false) -> void:
	var changed := i != weapon_idx
	weapon_idx = i
	var w := current_weapon()
	gun.set_weapon("" if w.kind == "melee" else w.id)
	_fire_cd = maxf(_fire_cd, 0.12)
	Events.weapon_changed.emit(w.id)
	Events.ammo_changed.emit()
	if not silent and changed:
		Audio.play("unsheathe" if w.kind == "melee" else "weapon_switch", global_position)


func give_weapon(id: String) -> bool:
	var w := Database.weapon(id)
	if w.ammo_type != "":
		ammo[w.ammo_type] = int(ammo[w.ammo_type]) + w.start_ammo
	if weapons.has(id):
		Events.ammo_changed.emit()
		return false
	weapons.append(id)
	weapons.sort_custom(func(a, b): return Database.weapon(a).slot < Database.weapon(b).slot)
	_equip(weapons.find(id), true)
	return true


func _attack_input() -> void:
	if state != State.GROUND or _fire_cd > 0.0:
		return
	if not Input.is_action_pressed("attack"):
		return
	var w := current_weapon()
	if w.kind == "melee":
		_melee(w)
	elif ammo_for(w) > 0:
		_fire(w)
	elif Input.is_action_just_pressed("attack"):
		Audio.play("dry_fire", global_position)
		Events.toast.emit("Out of %s!" % Tables.AMMO_NAMES.get(w.ammo_type, "ammo"), Color(1.0, 0.45, 0.35))
		_fire_cd = 0.3


func _melee(w: WeaponData) -> void:
	_combo = (_combo % 3) + 1 if _combo_timer > 0.0 else 1
	_combo_timer = 0.9
	var anim := "attack%d" % _combo
	sprite.play_anim(anim, true)
	_attack_lock = sprite.anim_length(anim) * 0.85
	_fire_cd = w.fire_interval
	_melee_pending = MELEE_HIT_DELAY
	_melee_reach = w.melee_reach * (1.25 if _combo == 3 else 1.0)
	if w.fire_sound != "":
		Audio.play(w.fire_sound, global_position, 0.0, w.fire_pitch)


func _melee_tick(delta: float) -> void:
	if _melee_pending <= 0.0:
		return
	_melee_pending -= delta
	if _melee_pending > 0.0:
		return
	var hit_any := false
	for m in world.get_monsters(floor_idx).duplicate():
		var dx: float = m.position.x - position.x
		if dx * facing >= -14.0 and absf(dx) <= _melee_reach + m.hit_half_width():
			m.take_hit(float(facing))
			hit_any = true
	if hit_any:
		Audio.play("thud", global_position)
		world.shake(4.0)


func _fire(w: WeaponData) -> void:
	ammo[w.ammo_type] = int(ammo[w.ammo_type]) - 1
	_fire_cd = w.fire_interval
	var muzzle := global_position + gun.position + gun.muzzle_offset()
	for i in w.pellets:
		var ang := deg_to_rad(randf_range(-w.spread_deg, w.spread_deg))
		world.spawn_projectile(w, muzzle, Vector2(facing, 0).rotated(ang), floor_idx)
	world.spawn_muzzle(muzzle, facing, w.color)
	if w.fire_sound != "":
		Audio.play(w.fire_sound, global_position, 0.0, w.fire_pitch)
	gun.kick(w.recoil)
	if w.shake > 0.0:
		world.shake(w.shake)
	Events.ammo_changed.emit()


# --- Health & items ------------------------------------------------------------

func take_damage(amount: float, from_x: float) -> void:
	if not can_be_targeted() or _invuln > 0.0:
		return
	health = maxf(health - amount, 0.0)
	_invuln = 0.6
	_hurt_time = 0.25
	_flash = 1.0
	var dir := signf(position.x - from_x)
	if dir == 0.0:
		dir = -float(facing)
	if state == State.GROUND:
		position.x = clampf(position.x + dir * 14.0, 24.0, GameConst.FLOOR_WIDTH - 24.0)
	world.spawn_blood(floor_idx, global_position + Vector2(0, -26), dir, 12)
	world.shake(5.0)
	Audio.play("hurt", global_position)
	Events.player_hurt.emit(amount)
	_emit_vitals(true)
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	health = minf(health + amount, MAX_HEALTH)
	_emit_vitals(true)


func _survival(delta: float) -> void:
	hunger = maxf(hunger - HUNGER_DRAIN * delta, 0.0)
	if hunger <= 0.0:
		health = maxf(health - STARVE_DPS * delta, 0.0)
		if health <= 0.0:
			_die()
	_emit_vitals(false)


func _emit_vitals(force: bool) -> void:
	var hp := int(ceilf(health))
	var hu := int(ceilf(hunger))
	if force or hp != _last_hp:
		_last_hp = hp
		Events.health_changed.emit(health, MAX_HEALTH)
	if force or hu != _last_hunger:
		_last_hunger = hu
		Events.hunger_changed.emit(hunger, MAX_HUNGER)


func _die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	_set_hint("")
	gun.visible = false
	sprite.play_anim("death", true)
	Events.player_died.emit()


func _collect_pickups(delta: float) -> void:
	if state != State.GROUND or not world.chunks.has(floor_idx):
		return
	var chunk: FloorChunk = world.chunks[floor_idx]
	for p in chunk.pickups.duplicate():
		if not p.ready_to_collect():
			continue
		var dx: float = position.x - p.position.x
		var d := absf(dx)
		if d < PICKUP_RANGE and _air_y > -40.0:
			if _apply_pickup(p):
				chunk.collect_pickup(p)
		elif d < MAGNET_RANGE and p.kind == "copper":
			p.position.x += signf(dx) * 180.0 * delta


func _apply_pickup(p: Pickup) -> bool:
	var pos := global_position + Vector2(0, -50)
	match p.kind:
		"copper":
			GameState.copper += p.amount
			Events.copper_changed.emit(GameState.copper)
			Audio.play("coin", global_position)
			world.float_text(pos, "+%d copper" % p.amount, Color(1.0, 0.7, 0.35))
		"food":
			if hunger >= MAX_HUNGER - 2.0:
				return false
			hunger = minf(hunger + Tables.FOOD_VALUE, MAX_HUNGER)
			_emit_vitals(true)
			Audio.play("eat", global_position)
			world.float_text(pos, Tables.FOOD_NAMES.get(p.sub, "Food"), Color(1.0, 0.85, 0.5))
		"potion":
			if health >= MAX_HEALTH:
				return false
			heal(Tables.POTION_VALUE)
			Audio.play("potion", global_position)
			world.float_text(pos, "+%d health" % int(Tables.POTION_VALUE), Color(1.0, 0.4, 0.45))
		"ammo":
			ammo[p.sub] = int(ammo.get(p.sub, 0)) + p.amount
			Events.ammo_changed.emit()
			Audio.play("ammo_pickup", global_position)
			world.float_text(pos, "+%d %s" % [p.amount, Tables.AMMO_NAMES.get(p.sub, "ammo")], Tables.AMMO_COLORS.get(p.sub, Color.WHITE))
		"weapon":
			var w := Database.weapon(p.sub)
			if give_weapon(p.sub):
				Audio.play("weapon_pickup", global_position)
				Events.toast.emit("You found a %s!" % w.display_name, Color(1.0, 0.85, 0.4))
			else:
				Audio.play("ammo_pickup", global_position)
				world.float_text(pos, "+%d %s" % [w.start_ammo, Tables.AMMO_NAMES.get(w.ammo_type, "ammo")], Color(1.0, 0.85, 0.4))
	return true


# --- Visuals -------------------------------------------------------------------

func _update_visuals() -> void:
	sprite.set_facing(facing)
	gun.facing = facing
	gun.position = Vector2(HAND.x * facing, HAND.y)
	var ranged := current_weapon().kind != "melee"
	gun.visible = ranged and state == State.GROUND and not sprite.animation.begins_with("attack")
	sprite.speed_scale = 1.0

	if state == State.CLIMB:
		if _climb["type"] == "ladder":
			sprite.play_anim("jump" if int(_t * 4.0) % 2 == 0 else "fall")
			sprite.speed_scale = 1.0 if _climb_moving else 0.0
			sprite.position.x = sin(_t * 9.0) * 1.5 if _climb_moving else 0.0
		else:
			sprite.play_anim("run" if _climb_moving else "idle")
			sprite.position.x = 0.0
		shadow.visible = false
		return
	sprite.position.x = 0.0
	shadow.visible = true
	shadow.scale = Vector2.ONE * clampf(1.0 + _air_y / 80.0, 0.5, 1.0)
	shadow.position.y = GameConst.FOOT_Y - _air_y

	if _attack_lock > 0.0 and sprite.animation.begins_with("attack"):
		return
	if _air_y < 0.0:
		sprite.play_anim("jump" if _air_v < 0.0 else "fall")
	elif _hurt_time > 0.0:
		sprite.play_anim("hurt")
	elif _moving:
		sprite.play_anim("run")
	else:
		sprite.play_anim("idle")


func _update_flash(delta: float) -> void:
	_flash = move_toward(_flash, 0.0, delta * 4.0)
	var blink := 0.0
	if _invuln > 0.0 and state != State.DEAD:
		blink = 0.25 if int(_t * 20.0) % 2 == 0 else 0.0
	_mat.set_shader_parameter("flash", maxf(_flash * 0.8, blink))
	lantern.energy = 1.05 + sin(_t * 7.0) * 0.03 + sin(_t * 13.0) * 0.02
