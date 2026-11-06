class_name Tables
extends RefCounted
## Spawn, drop and loot tables. Kept free of autoloads so world generation
## can run headless in tests.

## Weighted monster ids per 40-floor band.
const MONSTER_BANDS := [
	[["rotter_mushroom", 5], ["rotter_skeleton", 4]],
	[["goblin", 6], ["rotter_skeleton", 2], ["rotter_mushroom", 1]],
	[["skeleton", 6], ["goblin", 3]],
	[["flying_eye", 5], ["goblin", 3], ["skeleton", 2]],
	[["skeleton", 3], ["goblin", 3], ["flying_eye", 3], ["mushroom", 2]],
]
const ELITE_BAND := 4

## [weapon id, first floor index it can appear on, weight]
const WEAPON_DROPS := [
	["revolver", 0, 10],
	["crossbow", 3, 8],
	["shotgun", 8, 8],
	["smg", 20, 7],
	["missile_launcher", 45, 4],
	["plasma_gun", 70, 4],
]

## [ammo type, first floor index, weight]
const AMMO_TYPES := [
	["bullets", 0, 10],
	["bolts", 3, 7],
	["shells", 8, 8],
	["rockets", 45, 3],
	["cells", 70, 5],
]

const AMMO_AMOUNT := {"bullets": 12, "bolts": 6, "shells": 6, "rockets": 2, "cells": 15}
const AMMO_NAMES := {"bullets": "Bullets", "bolts": "Bolts", "shells": "Shells", "rockets": "Rockets", "cells": "Plasma Cells"}
const AMMO_COLORS := {
	"bullets": Color(0.9, 0.72, 0.3),
	"bolts": Color(0.65, 0.48, 0.3),
	"shells": Color(0.9, 0.25, 0.2),
	"rockets": Color(0.45, 0.62, 0.3),
	"cells": Color(0.3, 0.85, 1.0),
}

const FOODS := ["meat", "bread", "cheese"]
const FOOD_NAMES := {"meat": "Roast Meat", "bread": "Stale Bread", "cheese": "Cave Cheese"}
const FOOD_VALUE := 35.0
const POTION_VALUE := 40.0

const FLOOR_PICKUP_KINDS := [["food", 30], ["potion", 16], ["ammo", 34], ["copper", 20]]


## Picks the first element of a weighted entry; the weight is the last element.
static func pick_weighted(rng: RandomNumberGenerator, entries: Array) -> String:
	var total := 0.0
	for e in entries:
		total += float(e[e.size() - 1])
	var roll := rng.randf() * total
	for e in entries:
		roll -= float(e[e.size() - 1])
		if roll <= 0.0:
			return e[0]
	return entries[entries.size() - 1][0]


static func available(entries: Array, floor_index: int) -> Array:
	return entries.filter(func(e): return int(e[1]) <= floor_index)


static func pick_monster(rng: RandomNumberGenerator, band: int) -> String:
	return pick_weighted(rng, MONSTER_BANDS[clampi(band, 0, MONSTER_BANDS.size() - 1)])


static func pick_weapon(rng: RandomNumberGenerator, floor_index: int) -> String:
	return pick_weighted(rng, available(WEAPON_DROPS, floor_index))


static func make_ammo(rng: RandomNumberGenerator, floor_index: int, owned_types: Array) -> Dictionary:
	var sub: String
	if not owned_types.is_empty() and rng.randf() < 0.75:
		sub = owned_types[rng.randi() % owned_types.size()]
	else:
		sub = pick_weighted(rng, available(AMMO_TYPES, floor_index + 10))
	return {"kind": "ammo", "sub": sub, "amount": AMMO_AMOUNT[sub]}


static func make_pickup(rng: RandomNumberGenerator, kind: String, floor_index: int, owned_types: Array) -> Dictionary:
	match kind:
		"copper":
			return {"kind": "copper", "sub": "", "amount": rng.randi_range(2, 6) + floor_index / 12}
		"food":
			return {"kind": "food", "sub": FOODS[rng.randi() % FOODS.size()], "amount": 1}
		"potion":
			return {"kind": "potion", "sub": "", "amount": 1}
		"ammo":
			return make_ammo(rng, floor_index, owned_types)
		"weapon":
			return {"kind": "weapon", "sub": pick_weapon(rng, floor_index), "amount": 1}
	return {}


## Items dropped by a slain monster.
static func roll_loot(rng: RandomNumberGenerator, floor_index: int, owned_types: Array) -> Array:
	var out: Array = []
	if rng.randf() < 0.65:
		var coins := make_pickup(rng, "copper", floor_index, owned_types)
		coins["amount"] = rng.randi_range(1, 4) + floor_index / 15
		out.append(coins)
	if rng.randf() < 0.14:
		out.append(make_pickup(rng, "food", floor_index, owned_types))
	if rng.randf() < 0.10:
		out.append(make_pickup(rng, "potion", floor_index, owned_types))
	if rng.randf() < 0.20:
		out.append(make_ammo(rng, floor_index, owned_types))
	if rng.randf() < 0.025:
		out.append(make_pickup(rng, "weapon", floor_index, owned_types))
	return out
