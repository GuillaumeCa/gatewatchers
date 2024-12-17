extends Node3D

const PLANET_MAX = 8

@export var system_seed = 42
@export var colors: Array[Color]
@export var planet_archetypes: Array[PlanetArchetype] = []

@export var planet_scene: PackedScene
@export var asteroid_spawner_scene: PackedScene
@export var warp_gate: PackedScene


func generate():
	seed(system_seed)
	var star_color = colors.pick_random()
	$Star/OmniLight3D.light_color = star_color
	$Star.material_override.set_shader_parameter("sun_color", star_color)
	$Star.position = Vector3.ZERO
	
	for obj in $Objects.get_children():
		obj.queue_free()
	
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
	for i in planet_count:
		var pname = generate_planet_name()
		prints("creating planet", pname)
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
			print("Generating asteroid ring")
			var asteroids: Node3D = asteroid_spawner_scene.instantiate()
			asteroids.position = planet.position
			root.add_child(asteroids)
		
		$Objects.add_child(root)

var planet_prefixes = ["Ar", "Al", "El", "Er", "Ot", "Pr", "Aj", "Er", "Ev", "An"]
var planet_suffixes = ["ia", "us", "el", "isa", "ot", "um", "et", "am", "il", "op"]

func generate_planet_name():
	var prefix = planet_prefixes.pick_random()
	var suffix = planet_suffixes.pick_random()
	return prefix + suffix


func generate_gates():
	for target_key in SpaceManager.systems[system_seed]["gates"].keys():
		var gate = warp_gate.instantiate()
		gate.target_system = target_key
		gate.global_position = Vector3(randf(), randf(), randf()) * randf_range(50_000, 400_000)
		$Objects.add_child(gate)

func _ready() -> void:
	generate()
