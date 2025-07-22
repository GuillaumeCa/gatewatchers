extends Node3D

const PLANET_MAX = 8

@export var system_seed = 42
@export var colors: Array[Color]
@export var planet_archetypes: Array[PlanetArchetype] = []

@export var planet_scene: PackedScene
@export var asteroid_spawner_scene: PackedScene
@export var warp_gate: PackedScene
@export var station_scene: PackedScene


func generate():
	seed(system_seed)
	var star_color = colors.pick_random()
	$Star/OmniLight3D.light_color = star_color
	$Star/DirectionalLight3D.light_color = star_color
	
	$Star.set_color(star_color)
	
	generate_env(star_color)
	generate_planets()
	generate_gates()


func generate_env(star_color: Color):
	var env = get_tree().get_first_node_in_group("environment") as WorldEnvironment
	var sky_mat = env.environment.sky.sky_material as ShaderMaterial
	sky_mat.set_shader_parameter("nebula_seed", randf_range(0, 2))
	
	var nebula_color = Color(star_color)
	nebula_color.s = 0.4
	nebula_color.v = .95
	nebula_color.h += 0.2
	sky_mat.set_shader_parameter("nebula_primary", nebula_color)
	var secondary = Color(nebula_color)
	secondary.h += 0.2
	sky_mat.set_shader_parameter("nebula_secondary", nebula_color)

func generate_planets():
	var planet_count = randi_range(2, PLANET_MAX)
	var pnames = generate_planet_names()
	var hub_ids = SimulationManager.hubs.keys()
	
	for i in planet_count:
		var archetype = planet_archetypes.pick_random()
		var pname = pnames[i]
		prints(Time.get_ticks_msec(), "creating planet", pname)
		var root = Node3D.new()
		
		var planet: Planet = planet_scene.instantiate()
		planet.name = pname
		planet.radius = randf_range(3000, 4500)
		prints(Time.get_ticks_msec(), "arch", archetype)
		planet.archetype = archetype
		planet.sun = $Star
		planet.position.z = -randf_range(150, 400) * 1000
		root.add_child(planet)
		root.rotation_degrees.y = (i * 360 / planet_count) + randf_range(0, 10)
		
		if randf() < 0.2:
			prints(Time.get_ticks_msec(), "Generating asteroid ring")
			var asteroid_spawner: AsteroidSpawner = asteroid_spawner_scene.instantiate()
			asteroid_spawner.position = planet.position
			asteroid_spawner.inner_range = planet.radius + 1000
			asteroid_spawner.range = asteroid_spawner.inner_range + 500
			root.add_child(asteroid_spawner)
			prints(Time.get_ticks_msec(), "Added asteroid ring")
		
		if hub_ids.size() > 0:
			var hubid = hub_ids.pop_back()
			var station: Station = station_scene.instantiate()
			station.position = planet.position + (Vector3.BACK * randf_range(2, 10) * 1000)
			station.hub_id = hubid
			station.name = "Station" + hubid
			station.rotation_degrees.x += randf_range(-60, 60)
			station.rotation_degrees.y += randf_range(-60, 60)
			root.add_child(station)
			
		$Objects.add_child(root)
		

var planet_prefixes = ["Ar", "Al", "El", "Er", "Ot", "Pr", "Aj", "R", "Ev", "An"]
var planet_suffixes = ["ia", "us", "el", "isa", "ot", "um", "et", "am", "il", "op"]

func generate_planet_names():
	var combinations = []
	for pref in planet_prefixes:
		for suf in planet_suffixes:
			combinations.append(pref + suf)
	combinations.shuffle()
	
	return combinations


func generate_gates():
	for target_key in SpaceManager.systems[system_seed]["gates"].keys():
		var gate = warp_gate.instantiate()
		gate.target_system = target_key
		gate.global_position = Vector3(randf(), randf(), randf()) * randf_range(50_000, 400_000)
		gate.open = true#randf() < 0.2
		$Objects.add_child(gate)


func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("human")
	if player:
		$Star/DirectionalLight3D.look_at(player.global_position)

func _ready() -> void:
	generate()
