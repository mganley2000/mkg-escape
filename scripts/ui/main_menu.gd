extends Control
## Title screen: name your hero (or roll a random name) and start the climb.

const VIGNETTE := preload("res://shaders/vignette.gdshader")

var _name_edit: LineEdit


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.025, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var wall := TextureRect.new()
	wall.texture = ArtLib.wall_texture(0)
	wall.stretch_mode = TextureRect.STRETCH_TILE
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.scale = Vector2(3, 3)
	wall.modulate = Color(0.22, 0.2, 0.24)
	add_child(wall)

	_add_actor("warrior", Vector2(0.22, 0.74), 1, 5.0, "idle", "")
	_add_actor("skeleton", Vector2(0.8, 0.74), -1, 5.0, "idle", "rot")
	_add_actor("goblin", Vector2(0.88, 0.74), -1, 4.2, "idle", "")

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE
	mat.set_shader_parameter("strength", 0.85)
	vignette.material = mat
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	var title := UiStyle.label("ESCAPE THE DEPTHS", 92, UiStyle.GOLD, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiStyle.label("Two hundred floors of darkness stand between you and the sky.", 26, UiStyle.TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	col.add_child(spacer)

	var prompt := UiStyle.label("Name your hero", 26, UiStyle.MUTED)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(prompt)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 12)
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(460, 60)
	_name_edit.max_length = 24
	_name_edit.placeholder_text = "Leave blank for a random name"
	_name_edit.add_theme_font_size_override("font_size", 28)
	_name_edit.add_theme_stylebox_override("normal", UiStyle.panel(Color(0.08, 0.07, 0.07, 0.95), UiStyle.TRIM, 12.0))
	_name_edit.add_theme_stylebox_override("focus", UiStyle.panel(Color(0.1, 0.08, 0.07, 0.95), UiStyle.GOLD, 12.0))
	_name_edit.text_submitted.connect(func(_t): _start())
	name_row.add_child(_name_edit)
	var dice := UiStyle.button("Random", 24, 150.0)
	dice.pressed.connect(func(): _name_edit.text = NameGenerator.generate())
	name_row.add_child(dice)
	col.add_child(name_row)

	var start := UiStyle.button("Begin the Climb", 32, 420.0)
	start.pressed.connect(_start)
	col.add_child(_center(start))

	if not OS.has_feature("web"):
		var quit := UiStyle.button("Quit", 24, 220.0)
		quit.pressed.connect(func(): get_tree().quit())
		col.add_child(_center(quit))

	var help := UiStyle.label(
		"A / D  move      W / S  climb ladders and stairs      Space  jump\n" +
		"Click or J  attack      Q / E or 1-7  switch weapon      Mouse wheel or + / -  zoom      Esc  pause",
		18, UiStyle.MUTED, 3)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(help)

	_name_edit.grab_focus()
	Audio.music_menu()
	if GameState.autoshot:
		_name_edit.text = "Tester"
		_autoshot()


func _autoshot() -> void:
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://.screens")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join("00_menu.png"))
	_start()


func _center(c: Control) -> CenterContainer:
	var box := CenterContainer.new()
	box.add_child(c)
	return box


func _add_actor(key: String, anchor: Vector2, facing: int, s: float, anim: String, tint: String) -> void:
	var holder := Control.new()
	holder.anchor_left = anchor.x
	holder.anchor_right = anchor.x
	holder.anchor_top = anchor.y
	holder.anchor_bottom = anchor.y
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var spr := CharSprite.new()
	holder.add_child(spr)
	spr.setup(key)
	spr.scale = Vector2(s, s)
	spr.set_facing(facing)
	spr.modulate = Color(0.75, 0.68, 0.62)
	var mat := ArtLib.tint_material(tint)
	if mat:
		spr.material = mat
	spr.play_anim(anim)


func _start() -> void:
	var hero := _name_edit.text.strip_edges()
	if hero.is_empty():
		hero = NameGenerator.generate()
	GameState.new_run(hero, GameState.AUTOSHOT_SEED if GameState.autoshot else 0)
	Audio.play("ui_confirm")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
