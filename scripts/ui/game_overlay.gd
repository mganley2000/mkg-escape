class_name GameOverlay
extends CanvasLayer
## Pause menu and end-of-run screens (death or escape).

signal resume_requested
signal restart_requested
signal menu_requested

var _box: VBoxContainer
var _panel: PanelContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.PANEL, UiStyle.GOLD, 36.0))
	center.add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 18)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_box)


func show_pause() -> void:
	_clear()
	_box.add_child(_centered(UiStyle.label("PAUSED", 56, UiStyle.GOLD, 8)))
	_box.add_child(_centered(UiStyle.label(_stats(), 24, UiStyle.TEXT)))
	var first := _add_button("Resume", resume_requested)
	_add_button("Main Menu", menu_requested)
	first.call_deferred("grab_focus")
	visible = true


func show_end(escaped: bool) -> void:
	_clear()
	if escaped:
		_box.add_child(_centered(UiStyle.label("YOU ESCAPED!", 64, Color(0.7, 0.85, 1.0), 8)))
		_box.add_child(_centered(UiStyle.label("%s breathes the night air at last." % GameState.player_name, 26, UiStyle.TEXT)))
	else:
		_box.add_child(_centered(UiStyle.label("YOU DIED", 64, Color(0.85, 0.12, 0.12), 8)))
		_box.add_child(_centered(UiStyle.label("%s fell on floor %d of %d." % [GameState.player_name, GameState.highest_floor + 1, GameConst.FLOOR_COUNT], 26, UiStyle.TEXT)))
	_box.add_child(_centered(UiStyle.label(_stats(), 24, UiStyle.MUTED)))
	var first := _add_button("Climb Again", restart_requested)
	_add_button("Main Menu", menu_requested)
	first.call_deferred("grab_focus")
	visible = true


func hide_overlay() -> void:
	visible = false


func _stats() -> String:
	var t := int(GameState.run_time)
	return "Highest floor %d   -   Kills %d   -   Copper %d   -   Time %d:%02d" % [GameState.highest_floor + 1, GameState.kills, GameState.copper, t / 60, t % 60]


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func _centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _add_button(text: String, sig: Signal) -> Button:
	var b := UiStyle.button(text, 28, 380.0)
	b.pressed.connect(func(): sig.emit())
	var c := CenterContainer.new()
	c.add_child(b)
	_box.add_child(c)
	return b
