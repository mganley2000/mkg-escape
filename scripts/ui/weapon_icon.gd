class_name WeaponIcon
extends Control
## Enlarged weapon drawing for the HUD, plus a strip of owned weapon slots.

var weapon_id := "rusty_sword"
var owned: Array = []


func _init() -> void:
	custom_minimum_size = Vector2(150, 70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(id: String, owned_ids: Array) -> void:
	weapon_id = id
	owned = owned_ids
	queue_redraw()


func _draw() -> void:
	var box := Rect2(0, 0, size.x, 50)
	draw_rect(box, Color(0.08, 0.07, 0.07))
	draw_rect(box, UiStyle.TRIM, false, 2.0)
	PropArt.draw_weapon(self, weapon_id, Vector2(size.x * 0.5 - 10.0, 27.0), 3.0)
	var slots := Controls.WEAPON_SLOTS
	var sw := size.x / slots
	var font := get_theme_default_font()
	for i in slots:
		var r := Rect2(i * sw + 1.0, 54, sw - 2.0, 14)
		var has := false
		var current := false
		for id in owned:
			var w := Database.weapon(id)
			if w.slot == i + 1:
				has = true
				current = id == weapon_id
		var c := Color(0.15, 0.13, 0.12)
		if current:
			c = UiStyle.GOLD
		elif has:
			c = Color(0.45, 0.36, 0.25)
		draw_rect(r, c)
		draw_string(font, Vector2(r.position.x, r.end.y - 2), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color(0, 0, 0, 0.8) if current else UiStyle.MUTED)
