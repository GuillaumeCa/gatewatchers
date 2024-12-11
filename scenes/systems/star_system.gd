extends Node3D

const PLANET_MAX = 8

@export var system_seed = 42
@export var colors: Array[Color]
@export var planet_archetypes: Array[PlanetArchetype] = []

@export var planet_scene: PackedScene
@export var asteroid_spawner_scene: PackedScene

func generate():
	var star_color = colors.pick_random()
	$Star/OmniLight3D.light_color = star_color
	$Star.material_override.set_shader_parameter("sun_color", star_color)
	#$Star.name = generate_star_name()
	print("creating star", $Star.name)
	
	var planets = {}
	var planet_count = randi_range(2, PLANET_MAX)
	for i in planet_count:
		var pname = generate_planet_name()
		print("creating planet", pname)
		var archetype = planet_archetypes.pick_random()
		
		var root = Node3D.new()
		
		var planet: Planet = planet_scene.instantiate()
		planet.name = pname
		planet.radius = randf_range(3000, 7000)
		planet.archetype = archetype
		planet.sun = $Star
		planet.position.z = -randf_range(150, 400) * 1000
		planet.radius = randf_range(3000, 4500)
		root.add_child(planet)
		root.rotation_degrees.y = (i * 360 / planet_count) + randf_range(0, 10)
		
		if randf() < 0.2:
			var asteroids: Node3D = asteroid_spawner_scene.instantiate()
			asteroids.position = planet.position
			root.add_child(asteroids)
		
		add_child(root)


var star_prefixes = ["Alt", "Bet", "Can", "Del", "Eps", "Gam", "Zet", "Tau", "Rig", "Prox"]
var star_suffixes = ["ara", "ion", "ius", "ara", "ora", "eus", "ix", "an", "on", "us"]

func generate_star_name():
	var prefix = star_prefixes.pick_random()
	var suffix = star_suffixes.pick_random()
	return prefix + suffix

var planet_prefixes = ["Ar", "Al", "El", "Er", "Ot", "Pr", "Aj", "Er", "Ev", "An"]
var planet_suffixes = ["ia", "us", "el", "isa", "ot", "um", "et", "am", "il", "op"]

func generate_planet_name():
	var prefix = planet_prefixes.pick_random()
	var suffix = planet_suffixes.pick_random()
	return prefix + suffix


func _ready() -> void:
	seed(system_seed)
	generate()
