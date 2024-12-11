@tool
extends Node3D

class_name Planet

@export var sun: Node3D

@export var archetype: PlanetArchetype
@export var radius = 3000.0

@export var update: bool:
	set(val):
		if is_inside_tree():
			update_planet()

func _enter_tree() -> void:
	archetype = archetype.duplicate(true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_planet()

func get_warp_distance() -> float:
	return radius + 5000.0

func update_planet():
	if not archetype: return
	$Atmosphere.visible = archetype.has_atmo
	var light_intensity = Vector3(archetype.atmo_color.r, archetype.atmo_color.g, archetype.atmo_color.b) * archetype.atmo_intensity
	var atmo_material: ShaderMaterial = $Atmosphere.material_override
	atmo_material.set_shader_parameter("light_intensity", light_intensity)
	if radius:
		atmo_material.set_shader_parameter("planet_radius", radius)
		atmo_material.set_shader_parameter("atmo_radius", radius * 1.3)
		
		# rad  hray mie
		# 3000 59 47.2
		# 4500 70 66.5
		# 5000 75 60.0

		var hray =  (0.8 * (radius / 1000.0) + 3.5) * 10
		atmo_material.set_shader_parameter("height_ray", hray)
		atmo_material.set_shader_parameter("height_mie", hray * 0.8)
		
		
		
		$Surface.mesh.radius = radius
		$Atmosphere.mesh.radius = radius * 1.4
		$Atmosphere.mesh.height = radius * 1.4 * 2

	$Surface.material_override.set_shader_parameter("terrain_height", archetype.terrain_height)
	$Surface.material_override.set_shader_parameter("gradient", archetype.terrain_gradient)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var target = Vector3.FORWARD * 100
	if sun:
		target = global_position - global_position.direction_to(sun.global_position)  * 1000
	$Atmosphere.look_at(target)
	rotation_degrees.y += 0.3 * delta
