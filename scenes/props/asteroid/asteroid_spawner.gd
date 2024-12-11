@tool
extends Node3D


@export var gen_seed = 1:
	set(new_seed):
		gen_seed = new_seed
		seed(new_seed)
		if is_inside_tree():
			generate()

@export var asteroid_scene: PackedScene

@export var count = 400:
	set(new_count):
		count = new_count
		if is_inside_tree():
			generate()

@export var range = 1000:
	set(new_val):
		range = new_val
		if is_inside_tree():
			generate()

@export var inner_range = 0:
	set(new_val):
		inner_range = new_val
		if is_inside_tree():
			generate()



var asteroids = []

func _ready() -> void:
	generate()

func relocate(pos: Vector3):
	var positions = {}
	for a in asteroids:
		positions[a] = a.global_position
		a.freeze = true
		
	global_position = pos
	
	for a in asteroids:
		a.global_position = positions[a]
		a.freeze = false
	
func generate():
	cleanup()

	for i in range(count):
		var asteroid = asteroid_scene.instantiate() as RigidBody3D
		
		var asteroid_scale = randf_range(2.0, 20.0)
		#asteroid.global_position = global_position
		
		var mesh_inst = asteroid.get_node("asteroid").get_child(0)
		mesh_inst.scale *= asteroid_scale
		
		
		#if shifted:
			#asteroid.global_position = Space.shifted_origin + global_position # - Space.shifted_origin
		
		var shape = mesh_inst.mesh.create_trimesh_shape() as ConcavePolygonShape3D
		asteroid.get_node("CollisionShape3D").shape = shape
		
		asteroid.translate(Vector3(
			randf_range(range, -range),
			randf_range(200, -200),
			randf_range(range, -range),
		))
		
		if asteroid.position.length() > range:
			continue
		
		if asteroid.position.length() < inner_range:
			continue
		
		asteroid.rotate_x(randf_range(-PI, PI))
		asteroid.rotate_y(randf_range(-PI, PI))
		asteroid.rotate_z(randf_range(-PI, PI))
		
		asteroid.angular_velocity = Vector3(randf_range(0.3, 5), 0, 0)
		
		#asteroid.add_to_group("space_objects")
		
		add_child(asteroid)
		#prints("spawn", asteroid, "at", asteroid.position)
		asteroids.append(asteroid)

	

func cleanup():
	for asteroid in asteroids:
		asteroid.queue_free()
	
	asteroids = []

func _physics_process(delta: float) -> void:
	rotation_degrees.y += 2 * delta

func _on_proximity_detect_body_entered(body: Node3D) -> void:
	if body.is_in_group("human"):
		#generate(true)
		print("spawn asteroids")


func _on_proximity_detect_body_exited(body: Node3D) -> void:
	if body.is_in_group("human"):
		#cleanup()
		print("DESPAWN asteroids")
