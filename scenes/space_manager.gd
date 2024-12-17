extends Node

const STAR_SYSTEM = preload("res://scenes/systems/star_system.tscn")

const SYSTEM_COUNT = 100
const BASE_SEED = 134

var systems = {}
var current_system: Node3D

func init_systems() -> void:
	seed(BASE_SEED)
	generate_systems()
	generate_connections()
	
	var system_key = systems.keys().pick_random()
	load_system(system_key)
	
	print(systems)
	print(systems[system_key])

func generate_connections():
	var system_keys = systems.keys()
	for key in systems.keys():
		var gates = randi_range(1, 3)
		var close_systems = get_close_systems(systems[key]["pos"], key, gates)
		close_systems.shuffle()
		for target_sys in close_systems:
			var target = target_sys["id"]
			systems[key]["gates"][target] = null
			systems[target]["gates"][key] = null

func get_close_systems(position: Vector3, exclude, max = 3):
	var pos = []
	
	for key in systems.keys():
		if key != exclude:
			var system_pos = systems[key]["pos"]
			pos.append({
				"id": key,
				"dist": position.distance_to(system_pos),
			})
	
	pos.sort_custom(func(a, b):
		return a["dist"] < b["dist"]
	)
	
	return pos.slice(0, max)

func generate_systems():
	for i in SYSTEM_COUNT:
		var key = BASE_SEED + i
		systems[key] = {
			"pos": Vector3(
				randf_range(-100, 100),
				randf_range(-100, 100),
				randf_range(-100, 100)
			),
			"name": generate_star_name(),
			"gates": {}
		}


var star_prefixes = ["Alt", "Bet", "Can", "Del", "Eps", "Gam", "Zet", "Tau", "Rig", "Prox"]
var star_suffixes = ["ara", "ion", "ius", "ara", "ora", "eus", "ix", "an", "on", "us"]

func generate_star_name():
	var prefix = star_prefixes.pick_random()
	var suffix = star_suffixes.pick_random()
	return prefix + suffix

func load_system(key = 0):
	if !current_system:
		var system = STAR_SYSTEM.instantiate()
		system.system_seed = key
		current_system = system
		add_child(system)
	else:
		current_system.system_seed = key
		current_system.generate()
