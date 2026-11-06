extends Node
## Global signal bus so gameplay code and UI stay decoupled.

signal health_changed(current: float, maximum: float)
signal hunger_changed(current: float, maximum: float)
signal weapon_changed(weapon_id: String)
signal ammo_changed
signal copper_changed(total: int)
signal floor_changed(floor_index: int)
signal monster_killed(monster_id: String, floor_index: int)
signal toast(text: String, color: Color)
signal hint_changed(text: String)
signal player_hurt(amount: float)
signal player_died
signal player_escaped
