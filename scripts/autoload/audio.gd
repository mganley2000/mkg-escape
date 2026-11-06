extends Node
## Sound effects and adaptive music.
##
## Sound banks are folders under res://assets/audio/sfx/; every audio file in a
## folder is one variation, picked at random per play. Drop more files into a
## folder to add variety. MIX tunes each bank.
##
## Music is two layers on the Music bus: a gloomy ambient track that always
## plays, and a combat track that fades in while monsters are hunting the hero
## (see set_threat) and lingers a few seconds after the fight. A wind-and-drips
## bed plays on the Ambience bus underneath both.

const SFX_DIR := "res://assets/audio/sfx/"
const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_AMBIENT := preload("res://assets/audio/music/ambient_dungeon.ogg")
const MUSIC_COMBAT := preload("res://assets/audio/music/combat_heavy_dungeon.ogg")
const AMBIENCE_BED := preload("res://assets/audio/music/ambience_drips.ogg")

## bank: [volume_db, pitch_min, pitch_max, max_voices, min_gap_seconds]
const MIX := {
	"step": [-17.0, 0.85, 1.1, 2, 0.08],
	"ladder": [-15.0, 0.9, 1.1, 2, 0.1],
	"land": [-12.0, 0.9, 1.05, 1, 0.1],
	"jump": [-16.0, 0.95, 1.1, 1, 0.1],
	"swing": [-6.0, 0.9, 1.1, 3, 0.05],
	"thud": [-6.0, 0.85, 1.05, 3, 0.04],
	"gore": [-5.0, 0.85, 1.1, 4, 0.03],
	"hurt": [-3.0, 0.9, 1.05, 2, 0.1],
	"revolver": [-4.0, 0.95, 1.05, 3, 0.05],
	"smg": [-8.0, 0.95, 1.1, 4, 0.03],
	"shotgun": [-3.0, 0.92, 1.04, 2, 0.1],
	"crossbow": [-6.0, 0.95, 1.1, 2, 0.05],
	"plasma": [-9.0, 0.95, 1.05, 3, 0.05],
	"rumble": [-4.0, 0.95, 1.05, 2, 0.05],
	"rocket_thrust": [-12.0, 0.95, 1.1, 3, 0.0],
	"explosion": [-2.0, 0.9, 1.05, 3, 0.05],
	"ricochet": [-15.0, 0.85, 1.2, 3, 0.04],
	"dry_fire": [-8.0, 1.0, 1.0, 1, 0.1],
	"weapon_switch": [-12.0, 0.95, 1.05, 1, 0.05],
	"unsheathe": [-10.0, 0.95, 1.05, 1, 0.05],
	"coin": [-11.0, 0.95, 1.15, 2, 0.06],
	"eat": [-6.0, 0.9, 1.1, 1, 0.1],
	"potion": [-8.0, 0.95, 1.1, 1, 0.1],
	"ammo_pickup": [-9.0, 0.95, 1.1, 2, 0.06],
	"weapon_pickup": [-7.0, 1.0, 1.0, 1, 0.1],
	"ui_hover": [-18.0, 0.95, 1.05, 2, 0.04],
	"ui_click": [-10.0, 1.0, 1.0, 2, 0.04],
	"ui_confirm": [-8.0, 1.0, 1.0, 1, 0.1],
	"ui_open": [-12.0, 1.0, 1.0, 1, 0.1],
	"ui_close": [-12.0, 1.0, 1.0, 1, 0.1],
	"victory": [-4.0, 1.0, 1.0, 1, 0.5],
	"voice_rotter": [-11.0, 0.85, 1.1, 2, 0.55],
	"voice_goblin": [-10.0, 0.9, 1.15, 2, 0.45],
	"voice_skeleton": [-10.0, 0.88, 1.12, 2, 0.5],
	"voice_mushroom": [-11.0, 0.85, 1.1, 2, 0.5],
	"voice_eye": [-12.0, 0.9, 1.2, 2, 0.6],
	"death_rotter": [-6.0, 0.9, 1.1, 3, 0.04],
	"death_goblin": [-6.0, 0.9, 1.12, 3, 0.04],
	"death_skeleton": [-6.0, 0.88, 1.1, 3, 0.04],
	"death_mushroom": [-6.0, 0.9, 1.1, 3, 0.04],
	"death_eye": [-7.0, 0.9, 1.15, 3, 0.04],
}
const DEFAULT_MIX := [-8.0, 0.9, 1.1, 3, 0.05]
const UI_BANKS := ["ui_hover", "ui_click", "ui_confirm", "ui_open", "ui_close", "victory"]

## Distant groans picked by depth band while exploring (index = GameConst.band_of).
const BAND_VOICES := ["voice_rotter", "voice_goblin", "voice_skeleton", "voice_eye", ""]

const POOL_SIZE := 32
const HEARING_RANGE := 1400.0

const AMBIENT_DB := -9.0
const COMBAT_DB := -7.0
const BED_DB := -11.0
## Seconds for the combat layer to swell in / fade out.
const COMBAT_RISE := 0.7
const COMBAT_FALL := 4.0
## Combat keeps playing this long after the last monster stops hunting.
const COMBAT_HOLD := 5.0
const MODE_FADE := 2.5

enum Mode { OFF, MENU, GAME, DEAD, ESCAPED }

var music_volume := 0.8
var sfx_volume := 0.9

var _banks: Dictionary = {}
var _last_play: Dictionary = {}
var _pool: Array[AudioStreamPlayer2D] = []
var _flat: Array[AudioStreamPlayer] = []
var _ambient: AudioStreamPlayer
var _combat: AudioStreamPlayer
var _bed: AudioStreamPlayer
var _mode := Mode.OFF
var _mode_gain := 0.0
var _threat := 0
var _hold := 0.0
var _held := 0.0
var _intensity := 0.0
var _paused := false
var _band := 0
var _distant_t := 20.0
var _music_bus := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_load_banks()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer2D.new()
		p.bus = "SFX"
		p.max_distance = HEARING_RANGE
		p.attenuation = 1.4
		p.panning_strength = 0.6
		add_child(p)
		_pool.append(p)
	for i in 6:
		var f := AudioStreamPlayer.new()
		f.bus = "UI"
		add_child(f)
		_flat.append(f)
	_ambient = _music_player(MUSIC_AMBIENT, "Music")
	_combat = _music_player(MUSIC_COMBAT, "Music")
	_bed = _music_player(AMBIENCE_BED, "Ambience")
	_load_settings()
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.autoshot:
		music_volume = 0.0
		sfx_volume = 0.0
		_apply_volumes()
	var events := get_node_or_null("/root/Events")
	if events:
		events.player_hurt.connect(func(_a): _hold = maxf(_hold, COMBAT_HOLD * 0.6))
		events.floor_changed.connect(func(fi): _band = GameConst.band_of(fi))
	get_tree().node_added.connect(_on_node_added)


# --- Sound effects -------------------------------------------------------------

func has_bank(bank: String) -> bool:
	return _banks.has(bank)


## Plays one random variation of a bank. Pass a world position for positional
## sound; omit it for UI / listener-centred sound. Returns null when skipped.
func play(bank: String, at: Variant = null, volume_db := 0.0, pitch := 1.0) -> Node:
	var streams: Array = _banks.get(bank, [])
	if streams.is_empty():
		return null
	var mix: Array = MIX.get(bank, DEFAULT_MIX)
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_play.get(bank, -10.0)) < mix[4]:
		return null
	_last_play[bank] = now
	var stream: AudioStream = streams[randi() % streams.size()]
	var db: float = mix[0] + volume_db
	var pitch_scale: float = randf_range(mix[1], mix[2]) * pitch
	if at == null or bank in UI_BANKS:
		var f := _take_flat()
		f.bus = "UI" if bank in UI_BANKS else "SFX"
		_start(f, bank, stream, db, pitch_scale)
		return f
	if _voices(bank) >= int(mix[3]):
		return null
	var p := _take_2d()
	p.global_position = at
	_start(p, bank, stream, db, pitch_scale)
	return p


## Plays a sound that travels with a node (e.g. a rocket's thruster) and dies with it.
func play_attached(bank: String, node: Node2D, volume_db := 0.0) -> AudioStreamPlayer2D:
	var streams: Array = _banks.get(bank, [])
	if streams.is_empty():
		return null
	var mix: Array = MIX.get(bank, DEFAULT_MIX)
	var p := AudioStreamPlayer2D.new()
	p.bus = "SFX"
	p.max_distance = HEARING_RANGE
	p.attenuation = 1.4
	p.panning_strength = 0.6
	p.stream = streams[randi() % streams.size()]
	p.volume_db = mix[0] + volume_db
	p.pitch_scale = randf_range(mix[1], mix[2])
	if "loop" in p.stream:
		var dup: AudioStream = p.stream.duplicate()
		dup.set("loop", true)
		p.stream = dup
	else:
		p.finished.connect(p.play)
	node.add_child(p)
	p.play()
	return p


func _start(p: Node, bank: String, stream: AudioStream, db: float, pitch_scale: float) -> void:
	p.stop()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch_scale
	p.set_meta("bank", bank)
	p.set_meta("t", Time.get_ticks_msec())
	p.play()


func _voices(bank: String) -> int:
	var n := 0
	for p in _pool:
		if p.playing and p.get_meta("bank", "") == bank:
			n += 1
	return n


func _take_2d() -> AudioStreamPlayer2D:
	var oldest: AudioStreamPlayer2D = _pool[0]
	for p in _pool:
		if not p.playing:
			return p
		if int(p.get_meta("t", 0)) < int(oldest.get_meta("t", 0)):
			oldest = p
	return oldest


func _take_flat() -> AudioStreamPlayer:
	var oldest: AudioStreamPlayer = _flat[0]
	for f in _flat:
		if not f.playing:
			return f
		if int(f.get_meta("t", 0)) < int(oldest.get_meta("t", 0)):
			oldest = f
	return oldest


func _load_banks() -> void:
	for bank in _list_subdirs(SFX_DIR):
		var streams: Array[AudioStream] = []
		var path := SFX_DIR + bank + "/"
		for file in _list_files(path):
			var name := file.trim_suffix(".import")
			if name.get_extension().to_lower() not in ["wav", "ogg", "mp3"]:
				continue
			var s := load(path + name) as AudioStream
			if s:
				streams.append(s)
		if not streams.is_empty():
			_banks[bank] = streams


func _list_subdirs(path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for entry in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			out.append(entry.trim_suffix("/"))
	if not out.is_empty():
		return out
	var da := DirAccess.open(path)
	if da == null:
		return out
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		if da.current_is_dir() and not name.begins_with("."):
			out.append(name)
		name = da.get_next()
	return out


func _list_files(path: String) -> PackedStringArray:
	var listed := ResourceLoader.list_directory(path)
	if not listed.is_empty():
		return listed
	var da := DirAccess.open(path)
	if da == null:
		return PackedStringArray()
	return da.get_files()


# --- UI ------------------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var b := node as BaseButton
		b.mouse_entered.connect(func(): if not b.disabled: play("ui_hover"))
		b.pressed.connect(func(): play("ui_click"))


# --- Music ---------------------------------------------------------------------

func music_menu() -> void:
	_set_mode(Mode.MENU)


func music_game() -> void:
	_set_mode(Mode.GAME)
	_threat = 0
	_hold = 0.0
	_intensity = 0.0
	_distant_t = randf_range(12.0, 25.0)


func music_end(escaped: bool) -> void:
	_set_mode(Mode.ESCAPED if escaped else Mode.DEAD)
	if escaped:
		play("victory")


## Number of monsters actively hunting the hero right now (call every frame).
func set_threat(count: int) -> void:
	_threat = count


func set_paused(paused: bool) -> void:
	_paused = paused
	AudioServer.set_bus_effect_enabled(_music_bus, 0, paused)
	play("ui_open" if paused else "ui_close")


func _set_mode(m: Mode) -> void:
	_mode = m
	if not _ambient.playing:
		_ambient.play()
	if not _bed.playing:
		_bed.play()


func _process(delta: float) -> void:
	var target_gain := 1.0
	match _mode:
		Mode.OFF:
			target_gain = 0.0
		Mode.MENU:
			target_gain = 0.8
		Mode.DEAD:
			target_gain = 0.35
		Mode.ESCAPED:
			target_gain = 0.0
	_mode_gain = move_toward(_mode_gain, target_gain, delta / MODE_FADE)

	var want := 0.0
	if _mode == Mode.GAME and not _paused:
		if _threat > 0:
			want = clampf(0.65 + 0.2 * (_threat - 1), 0.65, 1.0)
			_held = maxf(_held, want) if _intensity > 0.3 else want
			_hold = COMBAT_HOLD
		elif _hold > 0.0:
			_hold -= delta
			want = maxf(_held, 0.65)
		else:
			_held = 0.0
	elif _mode == Mode.GAME:
		want = _intensity
	var rate := COMBAT_RISE if want > _intensity else COMBAT_FALL
	_intensity = move_toward(_intensity, want, delta / rate)

	if _intensity > 0.0 and not _combat.playing:
		_combat.play()
	elif _intensity <= 0.0 and _combat.playing:
		_combat.stop()

	var duck := 0.6 if _paused else 1.0
	_ambient.volume_db = AMBIENT_DB + _lin_db(lerpf(1.0, 0.2, _intensity) * _mode_gain * duck)
	_combat.volume_db = COMBAT_DB + _lin_db(_intensity * duck)
	_bed.volume_db = BED_DB + _lin_db(lerpf(1.0, 0.45, _intensity) * (1.0 if _mode == Mode.GAME else _mode_gain) * duck)

	if _mode == Mode.GAME and not _paused:
		_distant_groans(delta)


## Every so often, something unseen moans somewhere off in the dark.
func _distant_groans(delta: float) -> void:
	_distant_t -= delta
	if _distant_t > 0.0:
		return
	_distant_t = randf_range(14.0, 32.0)
	if _intensity > 0.2:
		return
	var bank: String = BAND_VOICES[clampi(_band, 0, BAND_VOICES.size() - 1)]
	if bank == "":
		bank = BAND_VOICES[randi() % 4]
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var side := -1.0 if randf() < 0.5 else 1.0
	var at := cam.get_screen_center_position() + Vector2(side * randf_range(700.0, 1000.0), randf_range(-300.0, 300.0))
	play(bank, at, -4.0, randf_range(0.62, 0.78))


func _lin_db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(v)


func _music_player(stream: AudioStream, bus: String) -> AudioStreamPlayer:
	if "loop" in stream:
		stream.set("loop", true)
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = -80.0
	add_child(p)
	p.finished.connect(p.play)
	return p


# --- Buses & settings ----------------------------------------------------------

func _setup_buses() -> void:
	for bus_name in ["Music", "Ambience", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
	_music_bus = AudioServer.get_bus_index("Music")
	var muffle := AudioEffectLowPassFilter.new()
	muffle.cutoff_hz = 700.0
	AudioServer.add_bus_effect(_music_bus, muffle)
	AudioServer.set_bus_effect_enabled(_music_bus, 0, false)
	AudioServer.add_bus_effect(0, AudioEffectHardLimiter.new())


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func _apply_volumes() -> void:
	for bus_name in ["Music", "Ambience"]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), _lin_db(music_volume))
	for bus_name in ["SFX", "UI"]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), _lin_db(sfx_volume))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_volume = float(cfg.get_value("audio", "music", music_volume))
		sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	_apply_volumes()


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)
