extends SceneTree
## Headless check that sound banks and music streams loaded.
##   godot --headless --path . -s tests/test_audio.gd


func _init() -> void:
	var audio: Node = load("res://scripts/autoload/audio.gd").new()
	root.add_child(audio)
	call_deferred("_check", audio)


func _check(audio: Node) -> void:
	var needed := [
		"step", "ladder", "land", "jump", "swing", "thud", "gore", "hurt",
		"revolver", "smg", "shotgun", "crossbow", "plasma", "rumble",
		"rocket_thrust", "explosion", "ricochet", "dry_fire", "weapon_switch",
		"unsheathe", "coin", "eat", "potion", "ammo_pickup", "weapon_pickup",
		"voice_rotter", "voice_goblin", "voice_skeleton", "voice_mushroom", "voice_eye",
		"death_rotter", "death_goblin", "death_skeleton", "death_mushroom", "death_eye",
	]
	var missing: Array[String] = []
	for bank in needed:
		if not audio.has_bank(bank):
			missing.append(bank)
	var music_ok := audio.MUSIC_AMBIENT != null and audio.MUSIC_COMBAT != null and audio.AMBIENCE_BED != null
	if not music_ok:
		push_error("audio: missing music streams")
		quit(1)
		return
	if not missing.is_empty():
		push_error("audio: missing banks %s" % ", ".join(missing))
		quit(1)
		return
	print("audio: PASS (%d required banks, music streams present)" % needed.size())
	quit()
