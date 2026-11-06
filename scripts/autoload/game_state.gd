extends Node
## Run-wide state that survives scene changes (hero name, seed, score).

const AUTOSHOT_SEED := 12345

var player_name := ""
var world_seed := 0
var copper := 0
var kills := 0
var highest_floor := 0
var run_time := 0.0
## Set by passing `-- --autoshot` on the command line: the game starts itself,
## captures screenshots into res://.screens/ and quits.
var autoshot := false


func _ready() -> void:
	autoshot = OS.get_cmdline_user_args().has("--autoshot")


func new_run(hero_name: String, seed_value: int = 0) -> void:
	player_name = hero_name
	if seed_value != 0:
		world_seed = seed_value
	else:
		world_seed = int(Time.get_unix_time_from_system() * 1000.0) ^ randi()
	copper = 0
	kills = 0
	highest_floor = 0
	run_time = 0.0
