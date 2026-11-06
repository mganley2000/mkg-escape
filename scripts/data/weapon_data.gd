class_name WeaponData
extends Resource
## One weapon definition. Instances live in res://data/weapons/*.tres.

@export var id := ""
@export var display_name := ""
## melee | bullet | bolt | rocket | plasma
@export_enum("melee", "bullet", "bolt", "rocket", "plasma") var kind := "melee"
## Empty for melee weapons.
@export var ammo_type := ""
## Hotkey slot (1-7) and HUD order.
@export var slot := 1
@export var fire_interval := 0.4
@export var pellets := 1
@export var spread_deg := 0.0
@export var projectile_speed := 1200.0
@export var max_range := 900.0
## How many extra monsters a projectile passes through.
@export var pierce := 0
@export var splash_radius := 0.0
@export var melee_reach := 0.0
@export var recoil := 3.0
@export var shake := 0.0
@export var color := Color(1, 0.85, 0.5)
## Sound bank (folder under res://assets/audio/sfx/) played per shot or swing.
@export var fire_sound := ""
@export var fire_pitch := 1.0
## Ammo granted when the weapon is picked up.
@export var start_ammo := 0
