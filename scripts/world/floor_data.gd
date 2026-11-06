class_name FloorData
extends RefCounted
## Everything known about one floor. Generated once from the world seed,
## then mutated by play (kills, pickups, blood) and kept for the whole run,
## so a floor looks the same every time it scrolls back into view.

const MAX_DECALS := 140

var index := 0
var band := 0
## {"t": type, "x": float, "y": float, "s": seed}
var props: Array = []
## {"x": float, "h": float}
var torches: Array = []
## Broken wall sections revealing the deep cavern: {"x", "w", "h", "s"}
var holes: Array = []
## {"id": monster id, "x": float, "alive": bool, "elite": bool}
var spawns: Array = []
## {"kind", "sub", "amount", "x", "alive"}
var pickups: Array = []
## Blood and scorch marks: {"t": "wall"|"floor"|"scorch", "x", "y", "r", "s"}
var decals: Array = []
var visited := false


func add_decal(d: Dictionary) -> void:
	decals.append(d)
	if decals.size() > MAX_DECALS:
		decals.pop_front()


func to_dict() -> Dictionary:
	return {
		"index": index,
		"band": band,
		"props": props,
		"torches": torches,
		"holes": holes,
		"spawns": spawns,
		"pickups": pickups,
		"decals": decals,
		"visited": visited,
	}
