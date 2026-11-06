class_name CharSprite
extends AnimatedSprite2D
## AnimatedSprite2D that keeps a character's feet on its node origin, even
## when flipped (the art isn't centered horizontally inside its frames).

var key := ""
var facing := 1
var _base_offset := Vector2.ZERO


func setup(sprite_key: String) -> void:
	key = sprite_key
	sprite_frames = SpriteLib.frames(sprite_key)
	var fs := SpriteLib.frame_size(sprite_key)
	var foot := SpriteLib.foot(sprite_key)
	_base_offset = Vector2(fs * 0.5 - foot.x, fs * 0.5 - foot.y)
	centered = true
	_apply()


func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing:
		return
	facing = dir
	_apply()


## Plays an animation unless it's already running. restart forces frame 0.
func play_anim(anim: String, restart: bool = false) -> void:
	if restart or animation != anim or not is_playing():
		if restart:
			frame = 0
		play(anim)
		if restart:
			frame = 0


func anim_length(anim: String) -> float:
	return SpriteLib.anim_length(key, anim)


func _apply() -> void:
	flip_h = facing < 0
	offset = Vector2(_base_offset.x * facing, _base_offset.y)
