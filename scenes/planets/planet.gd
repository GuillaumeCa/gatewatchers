@tool
extends Node3D

class_name Planet

@export var sun: Node3D

@export var archetype: PlanetArchetype
@export var radius = 3000.0
@export var rotation_speed_degrees = 0.3

@export var update: bool:
	set(val):
		if is_inside_tree() and Engine.is_editor_hint():
			update_planet()

@onready var collider_collision_shape = $Collider/CollisionShape3D

var body_entered = []

var close_to_planet = false
var collision_generated = false

var collision_creation_thread: Thread

func _enter_tree() -> void:
	archetype = archetype.duplicate(true)
	collision_creation_thread = Thread.new()

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
		var shape: SphereShape3D = $PlanetGravity/CollisionShape3D.shape
		shape.radius = radius * 1.1
		$PlanetGravity.gravity_point_unit_distance = radius
		
		atmo_material.set_shader_parameter("planet_radius", radius)
		atmo_material.set_shader_parameter("atmo_radius", radius * 1.1)
		
		# rad  hray mie
		# 3000 59 47.2
		# 4500 70 66.5
		# 5000 75 60.0

		#var hray =  (0.8 * (radius / 1000.0) + 3.5) * 10
		var hray =  (0.8 * (radius / 1000.0) + 0.5) * 10
		
		atmo_material.set_shader_parameter("height_ray", hray)
		atmo_material.set_shader_parameter("height_mie", hray * 0.8)
		
		
		var surface_mesh = $Surface.mesh
		if surface_mesh is OctasphereMesh:
			surface_mesh.radius = radius
			surface_mesh.terrain_height = archetype.terrain_height
			surface_mesh.update_async()
		
		$Atmosphere.mesh.radius = radius * 1.4
		$Atmosphere.mesh.height = radius * 1.4 * 2

	$Surface.material_override.set_shader_parameter("terrain_height", archetype.terrain_height)
	$Surface.material_override.set_shader_parameter("planet_radius", radius)
	$Surface.material_override.set_shader_parameter("gradient", archetype.terrain_gradient)


func _exit_tree() -> void:
	pass
	#collision_creation_thread.wait_to_finish()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var target = Vector3.FORWARD * 100
	if sun:
		target = global_position - global_position.direction_to(sun.global_position)  * 1000
	$Atmosphere.look_at(target)
	
	# generate collision when player arrives
	var player: Node3D = get_tree().get_first_node_in_group("human")
	if player:
		var player_close = global_position.distance_to(player.global_position) < get_warp_distance()
		if player_close != close_to_planet:
			close_to_planet = player_close
			$Collider/CollisionShape3D.disabled = !player_close
			if player_close:
				var surface_mesh = $Surface.mesh
				if !collision_generated and !collision_creation_thread.is_started():
					collision_creation_thread.start(generate_collision.bind(surface_mesh), Thread.PRIORITY_HIGH)


func generate_collision(mesh: OctasphereMesh):
	#mesh.changed.connect(func():
	var surface_shape = mesh.create_trimesh_shape() 
	print("added shape", surface_shape, name)
	collider_collision_shape.shape = surface_shape
	#)

func _physics_process(delta: float) -> void:
	# planet rotation
	rotation.y += deg_to_rad(rotation_speed_degrees) * delta
	
	var dist_planet_influence_exit = $PlanetGravity/CollisionShape3D.shape.radius + 1000
	
	for body: Node3D in body_entered:
		var body_leaved_influence = body.global_position.distance_squared_to(global_position) > dist_planet_influence_exit * dist_planet_influence_exit
		var changed_gravity_area = body_in_other_gravity(body)
		if body_leaved_influence or changed_gravity_area:
			prints("removing body", body, "from planet", name, "influence")
			body_entered.erase(body)
			continue
			
		body.global_position += compute_planet_body_velocity(body)
		


func compute_planet_body_velocity(body: Node3D):
	var center_to_body = body.global_position - global_position
	var angular_vel := basis.y * deg_to_rad(rotation_speed_degrees) * get_physics_process_delta_time()
	return angular_vel.cross(center_to_body)

func _on_gravity_area_body_entered(body: Node3D) -> void:
	# when the body is already part of another gravity area, don't add it
	if body_in_other_gravity(body):
		return
		
	if !body_entered.has(body):
		prints(body, "entered planet", name, "influence")
		body_entered.append(body)

func body_in_other_gravity(body: Node3D) -> bool:
	var active = body.get("active")
	#var owner_gravity = body.owner.get("parent_gravity_area")
	#return owner_gravity and owner_gravity == $PlanetGravity
	return active == false and body.name == "Player"
	#var gravity_parent_area = body.get("parent_gravity_area")
	#if gravity_parent_area:
		#if gravity_parent_area != $PlanetGravity:
			#return true
	#return false
