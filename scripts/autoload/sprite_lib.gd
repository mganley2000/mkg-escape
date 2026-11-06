extends Node
## Builds SpriteFrames at runtime from the horizontal sprite strips in
## assets/sprites. Every strip uses square frames (frame size == strip height),
## so adding a new animation only needs a line in DEFS.

const PLAYER_DIR := "res://assets/sprites/player/fantasy_warrior/Sprites/"
const MONSTER_DIR := "res://assets/sprites/monsters/"

## "foot" is the pixel inside a frame that should sit on the floor line.
const DEFS := {
	"warrior": {
		"dir": PLAYER_DIR,
		"foot": Vector2(84, 100),
		"anims": {
			"idle": ["Idle.png", 10.0, true],
			"run": ["Run.png", 13.0, true],
			"attack1": ["Attack1.png", 20.0, false],
			"attack2": ["Attack2.png", 20.0, false],
			"attack3": ["Attack3.png", 20.0, false],
			"death": ["Death.png", 9.0, false],
			"jump": ["Jump.png", 9.0, true],
			"fall": ["Fall.png", 9.0, true],
			"hurt": ["Take hit.png", 12.0, false],
		},
	},
	"skeleton": {
		"dir": MONSTER_DIR + "Skeleton/",
		"foot": Vector2(80, 100),
		"anims": {
			"idle": ["Idle.png", 7.0, true],
			"walk": ["Walk.png", 7.0, true],
			"attack": ["Attack.png", 14.0, false],
			"shield": ["Shield.png", 10.0, false],
			"hurt": ["Take Hit.png", 12.0, false],
			"death": ["Death.png", 8.0, false],
		},
	},
	"goblin": {
		"dir": MONSTER_DIR + "Goblin/",
		"foot": Vector2(74, 100),
		"anims": {
			"idle": ["Idle.png", 8.0, true],
			"walk": ["Run.png", 14.0, true],
			"attack": ["Attack.png", 16.0, false],
			"hurt": ["Take Hit.png", 12.0, false],
			"death": ["Death.png", 8.0, false],
		},
	},
	"mushroom": {
		"dir": MONSTER_DIR + "Mushroom/",
		"foot": Vector2(75, 100),
		"anims": {
			"idle": ["Idle.png", 7.0, true],
			"walk": ["Run.png", 10.0, true],
			"attack": ["Attack.png", 12.0, false],
			"hurt": ["Take Hit.png", 12.0, false],
			"death": ["Death.png", 8.0, false],
		},
	},
	"flying_eye": {
		"dir": MONSTER_DIR + "Flying eye/",
		"foot": Vector2(76, 92),
		"anims": {
			"idle": ["Flight.png", 12.0, true],
			"walk": ["Flight.png", 14.0, true],
			"attack": ["Attack.png", 14.0, false],
			"hurt": ["Take Hit.png", 12.0, false],
			"death": ["Death.png", 8.0, false],
		},
	},
}

var _frames: Dictionary = {}
var _sizes: Dictionary = {}


func frames(key: String) -> SpriteFrames:
	if not _frames.has(key):
		_build(key)
	return _frames[key]


func frame_size(key: String) -> float:
	if not _sizes.has(key):
		_build(key)
	return _sizes[key]


func foot(key: String) -> Vector2:
	return DEFS[key]["foot"]


func anim_length(key: String, anim: String) -> float:
	var sf := frames(key)
	return float(sf.get_frame_count(anim)) / sf.get_animation_speed(anim)


func _build(key: String) -> void:
	var def: Dictionary = DEFS[key]
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var size := 0.0
	var anims: Dictionary = def["anims"]
	for anim_name in anims:
		var spec: Array = anims[anim_name]
		var tex: Texture2D = load(String(def["dir"]) + String(spec[0]))
		var h := tex.get_height()
		var count := tex.get_width() / h
		size = float(h)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(spec[1]))
		sf.set_animation_loop(anim_name, bool(spec[2]))
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * h, 0, h, h)
			sf.add_frame(anim_name, atlas)
	_frames[key] = sf
	_sizes[key] = size
