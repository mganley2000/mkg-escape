class_name Hud
extends CanvasLayer
## Bottom-of-screen heads-up display: hero name and floor, health, hunger,
## current weapon with ammo, copper and kills. Also toasts and action hints.

var player: Player

var _health: StatBar
var _hunger: StatBar
var _name: Label
var _floor: Label
var _weapon_icon: WeaponIcon
var _weapon_name: Label
var _ammo: Label
var _copper: Label
var _kills: Label
var _toasts: VBoxContainer
var _hint: Label
var _gauge: DepthGauge


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -124
	panel.offset_bottom = -16
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 34)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)

	var who := VBoxContainer.new()
	who.custom_minimum_size = Vector2(300, 0)
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	_name = UiStyle.label(GameState.player_name, 26, UiStyle.GOLD)
	_floor = UiStyle.label("Floor 1 / 200", 20, UiStyle.TEXT)
	who.add_child(_name)
	who.add_child(_floor)
	row.add_child(who)

	_health = StatBar.new("HEALTH", Color(0.85, 0.12, 0.14), 300.0)
	_hunger = StatBar.new("HUNGER", Color(0.85, 0.55, 0.15), 300.0)
	row.add_child(_wrap_center(_health))
	row.add_child(_wrap_center(_hunger))

	var weapon_box := HBoxContainer.new()
	weapon_box.add_theme_constant_override("separation", 14)
	_weapon_icon = WeaponIcon.new()
	weapon_box.add_child(_wrap_center(_weapon_icon))
	var weapon_text := VBoxContainer.new()
	weapon_text.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_text.custom_minimum_size = Vector2(220, 0)
	_weapon_name = UiStyle.label("Rusty Sword", 20, UiStyle.TEXT)
	_ammo = UiStyle.label("--", 30, UiStyle.GOLD)
	weapon_text.add_child(_weapon_name)
	weapon_text.add_child(_ammo)
	weapon_box.add_child(weapon_text)
	row.add_child(weapon_box)

	var loot := VBoxContainer.new()
	loot.alignment = BoxContainer.ALIGNMENT_CENTER
	_copper = UiStyle.label("Copper  0", 22, Color(0.95, 0.6, 0.3))
	_kills = UiStyle.label("Kills  0", 20, UiStyle.MUTED)
	loot.add_child(_copper)
	loot.add_child(_kills)
	row.add_child(loot)

	_hint = UiStyle.label("", 24, UiStyle.GOLD, 6)
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -300
	_hint.offset_right = 300
	_hint.offset_top = -170
	_hint.offset_bottom = -136
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	_toasts = VBoxContainer.new()
	_toasts.anchor_left = 0.5
	_toasts.anchor_right = 0.5
	_toasts.offset_left = -400
	_toasts.offset_right = 400
	_toasts.offset_top = 40
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toasts)

	_gauge = DepthGauge.new()
	_gauge.anchor_left = 1.0
	_gauge.anchor_right = 1.0
	_gauge.anchor_top = 0.5
	_gauge.anchor_bottom = 0.5
	_gauge.offset_left = -56
	_gauge.offset_right = -30
	_gauge.offset_top = -230
	_gauge.offset_bottom = 130
	root.add_child(_gauge)

	Events.health_changed.connect(func(c, m): _health.set_value(c, m))
	Events.hunger_changed.connect(func(c, m): _hunger.set_value(c, m))
	Events.weapon_changed.connect(_on_weapon_changed)
	Events.ammo_changed.connect(_on_ammo_changed)
	Events.copper_changed.connect(func(t): _copper.text = "Copper  %d" % t)
	Events.floor_changed.connect(_on_floor_changed)
	Events.monster_killed.connect(func(_id, _f): _kills.text = "Kills  %d" % GameState.kills)
	Events.toast.connect(show_toast)
	Events.hint_changed.connect(func(t): _hint.text = t)


func _wrap_center(c: Control) -> Control:
	var box := CenterContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(c)
	return box


func _on_weapon_changed(id: String) -> void:
	var w := Database.weapon(id)
	_weapon_name.text = w.display_name
	_weapon_icon.refresh(id, player.weapons if player else [id])
	_on_ammo_changed()


func _on_ammo_changed() -> void:
	if player == null:
		return
	var w := player.current_weapon()
	if w.ammo_type == "":
		_ammo.text = "Melee"
		_ammo.add_theme_color_override("font_color", UiStyle.MUTED)
	else:
		var n := player.ammo_for(w)
		_ammo.text = "%d  %s" % [n, Tables.AMMO_NAMES.get(w.ammo_type, "")]
		_ammo.add_theme_color_override("font_color", UiStyle.GOLD if n > 0 else Color(1.0, 0.35, 0.3))
	_weapon_icon.refresh(w.id, player.weapons)


func _on_floor_changed(i: int) -> void:
	var band_names := ["The Rotting Deep", "Goblin Warrens", "Halls of Bone", "Weeping Caverns", "The Crimson Gate"]
	_floor.text = "Floor %d / %d  -  %s" % [i + 1, GameConst.FLOOR_COUNT, band_names[GameConst.band_of(i)]]
	_gauge.set_floor(i, GameState.highest_floor)


func show_toast(text: String, color: Color) -> void:
	var l := UiStyle.label(text, 28, color, 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toasts.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
	if _toasts.get_child_count() > 4:
		_toasts.get_child(0).queue_free()
