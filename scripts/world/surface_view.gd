class_name SurfaceView
extends Node2D
## The very top of the dungeon: the last ceiling, the earth above it, the night
## sky, and the stairway out at exit_x. Local origin is the top floor's surface.

const CAP := 640.0
const EARTH := 260.0

var world: WorldManager
var exit_x := 0.0


func setup(w: WorldManager, ex: float) -> void:
	world = w
	exit_x = ex
	z_index = 1
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _ready() -> void:
	var moon := PointLight2D.new()
	moon.texture = ArtLib.light_texture()
	moon.texture_scale = 4.0
	moon.color = Color(0.7, 0.8, 1.0)
	moon.energy = 1.6
	moon.position = Vector2(exit_x, -GameConst.FLOOR_HEIGHT - 40)
	add_child(moon)


func _draw() -> void:
	var w := GameConst.FLOOR_WIDTH
	var ceiling := -GameConst.FLOOR_HEIGHT
	var ground := ceiling - EARTH
	var gap := 60.0

	# Night sky.
	var sky_top := ground - 1400.0
	_gradient(Rect2(-CAP, sky_top, w + CAP * 2.0, 1400.0), Color(0.05, 0.06, 0.16), Color(0.22, 0.2, 0.38))
	var r := PropArt.rng_for(4242)
	for i in 420:
		var p := Vector2(r.randf_range(-CAP, w + CAP), r.randf_range(sky_top, ground - 40.0))
		var b := r.randf_range(1.5, 4.0)
		draw_rect(Rect2(p, Vector2(1.5, 1.5)), Color(b, b, b * 1.1))
	draw_circle(Vector2(exit_x + 260.0, ground - 520.0), 34.0, Color(3.0, 3.0, 2.6))

	# Earth between the last ceiling and the grass.
	var rock := ArtLib.rock_texture()
	_tiled(Rect2(-CAP, ground, exit_x - gap + CAP, EARTH), rock)
	_tiled(Rect2(exit_x + gap, ground, w + CAP - exit_x - gap, EARTH), rock)
	draw_rect(Rect2(-CAP, ground - 4, w + CAP * 2.0, 6), Color(0.16, 0.32, 0.12))
	for i in 600:
		var gx := r.randf_range(-CAP, w + CAP)
		if absf(gx - exit_x) < gap:
			continue
		draw_line(Vector2(gx, ground), Vector2(gx + r.randf_range(-2, 2), ground - r.randf_range(3, 9)), Color(0.2, 0.42, 0.15), 1.0)

	# Final ceiling slab with the shaft cut through it.
	var slab := ArtLib.slab_texture(GameConst.BAND_COUNT - 1)
	_tiled(Rect2(-CAP, ceiling, exit_x - gap + CAP, GameConst.SLAB), slab)
	_tiled(Rect2(exit_x + gap, ceiling, w + CAP - exit_x - gap, GameConst.SLAB), slab)

	# Shaft walls and steps up to daylight.
	draw_rect(Rect2(exit_x - gap, ground, gap * 2.0, EARTH + GameConst.SLAB), Color(0.05, 0.05, 0.09))
	var steps := 14
	for i in steps:
		var t := float(i) / steps
		var y := lerpf(0.0, ground, t)
		var sx := exit_x - gap + (i % 2) * gap
		draw_rect(Rect2(sx + 4.0, y - 10.0, gap - 8.0, 6.0), Color(0.42, 0.4, 0.38))
	var beam := PackedVector2Array([Vector2(exit_x - gap, ground), Vector2(exit_x + gap, ground), Vector2(exit_x + gap * 1.8, 0), Vector2(exit_x - gap * 1.8, 0)])
	draw_polygon(beam, PackedColorArray([Color(0.6, 0.7, 1.0, 0.35), Color(0.6, 0.7, 1.0, 0.35), Color(0.6, 0.7, 1.0, 0.0), Color(0.6, 0.7, 1.0, 0.0)]))

	# Arch on the back wall marking the way out.
	var arch := Color(0.5, 0.46, 0.4)
	draw_rect(Rect2(exit_x - gap - 14.0, -GameConst.HEADROOM, 10.0, GameConst.HEADROOM - 10.0), arch)
	draw_rect(Rect2(exit_x + gap + 4.0, -GameConst.HEADROOM, 10.0, GameConst.HEADROOM - 10.0), arch)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(exit_x - 60.0, -GameConst.HEADROOM + 22.0), "THE SURFACE", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 14, Color(2.0, 1.8, 1.2))


func _tiled(rect: Rect2, tex: Texture2D) -> void:
	if rect.size.x <= 0.0:
		return
	var poly := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var uvs := PackedVector2Array()
	var ts := tex.get_size()
	for p in poly:
		uvs.append(p / ts)
	draw_colored_polygon(poly, Color.WHITE, uvs, tex)


func _gradient(rect: Rect2, top_color: Color, bottom_color: Color) -> void:
	var pts := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	draw_polygon(pts, PackedColorArray([top_color, top_color, bottom_color, bottom_color]))
