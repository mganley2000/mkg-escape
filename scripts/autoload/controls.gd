extends Node
## Registers the input map in code so bindings live in one readable place.

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"climb_up": [KEY_W, KEY_UP],
	"climb_down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE],
	"attack": [KEY_J, KEY_CTRL],
	"weapon_next": [KEY_E],
	"weapon_prev": [KEY_Q],
	"zoom_in": [KEY_EQUAL, KEY_KP_ADD],
	"zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
	"pause": [KEY_ESCAPE, KEY_P],
}

const PAD_BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"climb_up": [JOY_BUTTON_DPAD_UP],
	"climb_down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"attack": [JOY_BUTTON_X],
	"weapon_next": [JOY_BUTTON_RIGHT_SHOULDER],
	"weapon_prev": [JOY_BUTTON_LEFT_SHOULDER],
	"pause": [JOY_BUTTON_START],
}

const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"climb_up": [JOY_AXIS_LEFT_Y, -1.0],
	"climb_down": [JOY_AXIS_LEFT_Y, 1.0],
}

const WEAPON_SLOTS := 7


func _ready() -> void:
	for action in KEYS:
		_ensure(action)
		for key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

	for i in range(1, WEAPON_SLOTS + 1):
		var action_name := "weapon_%d" % i
		_ensure(action_name)
		var ev := InputEventKey.new()
		ev.physical_keycode = (KEY_0 + i) as Key
		InputMap.action_add_event(action_name, ev)

	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_mouse("zoom_in", MOUSE_BUTTON_WHEEL_UP)
	_add_mouse("zoom_out", MOUSE_BUTTON_WHEEL_DOWN)

	for action in PAD_BUTTONS:
		for button in PAD_BUTTONS[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)

	for action in PAD_AXES:
		var spec: Array = PAD_AXES[action]
		var ev := InputEventJoypadMotion.new()
		ev.axis = spec[0]
		ev.axis_value = spec[1]
		InputMap.action_add_event(action, ev)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)


func _add_mouse(action: String, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
