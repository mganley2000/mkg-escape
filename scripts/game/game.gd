extends Node2D
## Root of a run. Builds the layered scene:
##   CanvasLayer -1  far cavern parallax (not darkened)
##   layer 0         world: floors, actors, blood, lights, darkness
##   CanvasLayer 1   bright effects (tracers, explosions, floating text)
##   CanvasLayer 2   foreground pillars (parallax faster than the world)
##   CanvasLayer 5   vignette / hurt pulse
##   CanvasLayer 10  HUD, 20 pause and end screens

const VIGNETTE := preload("res://shaders/vignette.gdshader")
const DARKNESS := Color(0.2, 0.19, 0.25)

var world: WorldManager
var player: Player
var camera: GameCamera
var hud: Hud
var overlay: GameOverlay
var _vignette_mat: ShaderMaterial
var _hurt := 0.0
var _dust: CPUParticles2D
var _ended := false


func _ready() -> void:
	var darkness := CanvasModulate.new()
	darkness.color = DARKNESS
	add_child(darkness)

	var far_layer := CanvasLayer.new()
	far_layer.layer = -1
	far_layer.follow_viewport_enabled = true
	add_child(far_layer)
	var far_view := DepthLayer.new()
	far_view.mode = DepthLayer.Mode.FAR
	far_layer.add_child(far_view)

	camera = GameCamera.new()
	add_child(camera)

	var glow_canvas := CanvasLayer.new()
	glow_canvas.layer = 1
	glow_canvas.follow_viewport_enabled = true
	add_child(glow_canvas)
	var glow_root := Node2D.new()
	glow_canvas.add_child(glow_root)

	var fg_layer := CanvasLayer.new()
	fg_layer.layer = 2
	fg_layer.follow_viewport_enabled = true
	add_child(fg_layer)
	var fg_view := DepthLayer.new()
	fg_view.mode = DepthLayer.Mode.FOREGROUND
	fg_layer.add_child(fg_view)

	world = WorldManager.new()
	world.name = "World"
	add_child(world)
	player = Player.new()
	world.setup(GameState.world_seed, player, camera, glow_root, self)
	player.setup(world)
	world.add_child(player)

	camera.target = player
	camera.snap()
	far_view.camera = camera
	fg_view.camera = camera

	_dust = CPUParticles2D.new()
	_dust.amount = 70
	_dust.lifetime = 9.0
	_dust.preprocess = 9.0
	_dust.local_coords = false
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(900, 500)
	_dust.direction = Vector2(1, -0.2)
	_dust.spread = 180.0
	_dust.gravity = Vector2(0, 3)
	_dust.initial_velocity_min = 2.0
	_dust.initial_velocity_max = 9.0
	_dust.scale_amount_min = 0.8
	_dust.scale_amount_max = 1.8
	_dust.color = Color(0.9, 0.82, 0.7, 0.55)
	_dust.z_index = 7
	add_child(_dust)

	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 5
	add_child(vignette_layer)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = VIGNETTE
	vignette.material = _vignette_mat
	vignette_layer.add_child(vignette)

	hud = Hud.new()
	hud.player = player
	add_child(hud)

	overlay = GameOverlay.new()
	add_child(overlay)
	overlay.resume_requested.connect(_resume)
	overlay.restart_requested.connect(_restart)
	overlay.menu_requested.connect(_to_menu)

	Events.player_hurt.connect(func(_a): _hurt = 1.0)
	Events.player_died.connect(_on_player_died)
	Events.player_escaped.connect(_on_player_escaped)

	world.update_streaming()
	Audio.music_game()
	Events.toast.emit("%s awakens on the lowest floor." % GameState.player_name, UiStyle.GOLD)
	Events.toast.emit("Climb 200 floors to reach the surface.", UiStyle.TEXT)

	if GameState.autoshot:
		_run_autoshot()


func _process(delta: float) -> void:
	_dust.global_position = camera.get_screen_center_position()
	_hurt = move_toward(_hurt, 0.0, delta * 1.6)
	var low := 0.0
	if player.health < Player.MAX_HEALTH * 0.3 and player.state != Player.State.DEAD:
		low = (0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.5) * 0.35
	_vignette_mat.set_shader_parameter("hurt", maxf(_hurt * 0.8, low))
	if not _ended:
		Audio.set_threat(world.threat_count())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _ended:
		if get_tree().paused:
			_resume()
		else:
			get_tree().paused = true
			overlay.show_pause()
			Audio.set_paused(true)
		get_viewport().set_input_as_handled()
	elif OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_F1:
				_debug_arsenal()
			KEY_F2:
				debug_teleport(mini(player.floor_idx + 10, GameConst.TOP_FLOOR), player.position.x)


func _resume() -> void:
	get_tree().paused = false
	overlay.hide_overlay()
	Audio.set_paused(false)


func _restart() -> void:
	get_tree().paused = false
	Audio.set_paused(false)
	GameState.new_run(GameState.player_name)
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	Audio.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_player_died() -> void:
	_ended = true
	Audio.set_threat(0)
	Audio.music_end(false)
	await get_tree().create_timer(1.8).timeout
	overlay.show_end(false)


func _on_player_escaped() -> void:
	_ended = true
	Audio.set_threat(0)
	Audio.music_end(true)
	await get_tree().create_timer(0.6).timeout
	overlay.show_end(true)


# --- Debug helpers (debug builds only, also used by --autoshot) ----------------

func _debug_arsenal() -> void:
	for id in Database.weapons:
		if id != "rusty_sword":
			player.give_weapon(id)
	for t in player.ammo:
		player.ammo[t] = int(player.ammo[t]) + 50
	Events.ammo_changed.emit()
	Events.toast.emit("Debug: all weapons granted", Color(0.6, 0.9, 1.0))


func debug_teleport(fi: int, x: float) -> void:
	player.state = Player.State.GROUND
	player._climb = {}
	player._set_floor(fi)
	player.position = Vector2(x, GameConst.floor_y(fi))
	camera.snap()
	world.update_streaming()


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://.screens")
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(file_name))
	print("autoshot: saved ", file_name)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _nearest_monster(fi: int) -> Monster:
	var best: Monster = null
	var best_d := INF
	for m in world.get_monsters(fi):
		var d := absf(m.position.x - player.position.x)
		if d < best_d:
			best_d = d
			best = m
	return best


func _run_autoshot() -> void:
	await _wait(2.0)
	await _shot("01_start.png")

	camera.set_zoom_level(0.0, true)
	await _wait(1.0)
	await _shot("02_zoomed_out_10_floors.png")

	camera.set_zoom_level(2.4, true)
	_debug_arsenal()
	var target := _nearest_monster(0)
	if target:
		var side := -1.0 if target.position.x > 400.0 else 1.0
		debug_teleport(0, target.position.x + side * 150.0)
		player.facing = int(-side)
		player._equip(player.weapons.find("shotgun"))
		await _wait(0.5)
		player._fire(player.current_weapon())
		await _wait(0.08)
		await _shot("03_shotgun.png")
		await _wait(1.3)
		await _shot("04_blood_and_loot.png")

	target = _nearest_monster(0)
	if target:
		debug_teleport(0, target.position.x - 40.0)
		player.facing = 1
		player._equip(0)
		await _wait(0.3)
		player._melee(player.current_weapon())
		await _wait(0.2)
		await _shot("05_sword.png")

	var c: Dictionary = world.connectors_up(44)[0]
	debug_teleport(44, float(c["bottom_x"]) + 60.0)
	camera.set_zoom_level(1.7, true)
	await _wait(1.0)
	await _shot("06_goblin_warrens.png")

	debug_teleport(124, player.position.x)
	player._equip(player.weapons.find("plasma_gun"))
	await _wait(0.8)
	player._fire(player.current_weapon())
	await _wait(0.1)
	await _shot("07_caverns_plasma.png")

	debug_teleport(185, player.position.x)
	player._equip(player.weapons.find("missile_launcher"))
	await _wait(0.8)
	player._fire(player.current_weapon())
	await _wait(0.6)
	await _shot("08_elite_rocket.png")

	debug_teleport(GameConst.TOP_FLOOR, world.exit_x() - 140.0)
	camera.set_zoom_level(1.2, true)
	await _wait(1.0)
	await _shot("09_surface_exit.png")

	print("autoshot: done")
	get_tree().quit()
