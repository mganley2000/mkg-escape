class_name MonsterData
extends Resource
## One monster archetype. Instances live in res://data/monsters/*.tres.
## Stats here are floor-1 values; Monster scales them by floor depth.

@export var id := ""
@export var display_name := ""
## Key into SpriteLib.DEFS.
@export var sprite_key := ""
## Sound set: plays res://assets/audio/sfx/voice_<voice>/ and death_<voice>/.
@export var voice := ""
## Palette shader preset: none | rot | elite
@export_enum("none", "rot", "elite") var tint := "none"
@export var speed := 40.0
@export var chase_speed := 80.0
@export var damage := 8.0
@export var attack_range := 32.0
@export var detect_range := 300.0
@export var attack_cooldown := 1.2
## Seconds into the attack animation when the blow lands.
@export var attack_hit_time := 0.4
## Optional animation played before attacking (e.g. skeleton raises shield).
@export var windup_anim := ""
@export var windup_time := 0.0
## Hovering monsters float this many pixels above the floor.
@export var hover_height := 0.0
@export var hit_half_width := 12.0
@export var body_height := 40.0
@export var sprite_scale := 1.0
