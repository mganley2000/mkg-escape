class_name UiStyle
extends RefCounted
## Shared look for panels, labels and buttons: dark iron with warm brass trim.

const GOLD := Color(0.96, 0.78, 0.42)
const TEXT := Color(0.9, 0.86, 0.78)
const MUTED := Color(0.62, 0.58, 0.52)
const PANEL := Color(0.05, 0.045, 0.06, 0.9)
const TRIM := Color(0.42, 0.32, 0.2)


static func panel(bg: Color = PANEL, border: Color = TRIM, margin: float = 14.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.7
	s.content_margin_bottom = margin * 0.7
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 6
	return s


static func label(text: String, size: int, color: Color = TEXT, outline: int = 4) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("outline_size", outline)
	return l


static func button(text: String, size: int = 28, min_width: float = 320.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, size * 2.1)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD.lightened(0.2))
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_stylebox_override("normal", panel(Color(0.1, 0.08, 0.08, 0.95), TRIM, 12.0))
	b.add_theme_stylebox_override("hover", panel(Color(0.18, 0.12, 0.08, 0.95), GOLD, 12.0))
	b.add_theme_stylebox_override("pressed", panel(Color(0.24, 0.15, 0.08, 0.95), GOLD, 12.0))
	b.add_theme_stylebox_override("focus", panel(Color(0.18, 0.12, 0.08, 0.95), GOLD, 12.0))
	return b
