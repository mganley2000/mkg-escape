extends Node
## Loads the data-driven weapon and monster definitions from res://data.
## To add content: create a new .tres next to the others and list it here.

const WEAPON_PATHS := [
	"res://data/weapons/rusty_sword.tres",
	"res://data/weapons/revolver.tres",
	"res://data/weapons/crossbow.tres",
	"res://data/weapons/shotgun.tres",
	"res://data/weapons/smg.tres",
	"res://data/weapons/missile_launcher.tres",
	"res://data/weapons/plasma_gun.tres",
]

const MONSTER_PATHS := [
	"res://data/monsters/rotter_mushroom.tres",
	"res://data/monsters/rotter_skeleton.tres",
	"res://data/monsters/goblin.tres",
	"res://data/monsters/skeleton.tres",
	"res://data/monsters/flying_eye.tres",
	"res://data/monsters/mushroom.tres",
]

var weapons: Dictionary = {}
var monsters: Dictionary = {}


func _ready() -> void:
	for path in WEAPON_PATHS:
		var w: WeaponData = load(path)
		weapons[w.id] = w
	for path in MONSTER_PATHS:
		var m: MonsterData = load(path)
		monsters[m.id] = m


func weapon(id: String) -> WeaponData:
	return weapons[id]


func monster(id: String) -> MonsterData:
	return monsters[id]
