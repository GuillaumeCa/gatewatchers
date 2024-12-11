extends RigidBody3D

enum EnemyState {
	SEARCHING,
	APPROACHING,
	ATTACKING,
	FLEEING,
	DEAD,
}

const EXPLOSITION = preload("res://scenes/vfx/explosition.tscn")

@onready var radar: Area3D = $Radar

# ai process
# 1. scan targets
# 2. go to nearest target
# 3. try to destroy it
# 4. if life gets to below 10%, flee

var health = 100
var speed = 3000

var state = EnemyState.SEARCHING

var current_target: Node3D

signal hit


var enginesParticles: Array[GPUParticles3D] = []

func _ready() -> void:
	for particles in $engines.get_children():
		if particles is GPUParticles3D:
			enginesParticles.append(particles)

func _process(delta: float) -> void:
	$Debug.text = "State: " + EnemyState.keys()[state] + "\nHealth: " + str(health)
	
	
	if state != EnemyState.DEAD:
		if health <= 10:
			state = EnemyState.FLEEING
		else:
			
			if state == EnemyState.SEARCHING:
				current_target = radar.get_closest_target()
			
			if current_target:
				state = EnemyState.APPROACHING
				
				if current_target.global_position.distance_to(global_position) < 200:
					state = EnemyState.ATTACKING
			else:
				state = EnemyState.SEARCHING
			


func _physics_process(delta: float) -> void:
	enable_engine(false)
	match state:
		EnemyState.SEARCHING:
			accelerate_to(30)
			
		EnemyState.APPROACHING:
			var t = global_transform
			t = t.looking_at(current_target.global_position)
			
			
			global_transform.basis = global_transform.basis.slerp(t.basis, 0.01)
			
			accelerate_to(20)
			
		
		EnemyState.ATTACKING:
			var t = global_transform
			t = t.looking_at(current_target.global_position)
			
			
			global_transform.basis = global_transform.basis.slerp(t.basis, 0.2)
			
			fire_guns()
			
		EnemyState.FLEEING: 
			var t = global_transform
			t = t.looking_at(current_target.global_position).inverse()
			
			
			global_transform.basis = global_transform.basis.slerp(t.basis, 0.01)
			accelerate_to(30)

func fire_guns():
	$Weapons/LaserWeapon.fire()


func accelerate_to(maxspeed: float):
	enable_engine(false)
	
	if linear_velocity.length() < maxspeed:
		enable_engine(true)
		var force = Vector3(0, 0, -1) * speed * get_physics_process_delta_time()
		apply_central_force(global_transform.basis * force)
		


func enable_engine(on: bool):
	for particles in enginesParticles:
		particles.emitting = on


func _on_collision_area_entered(area: Area3D) -> void:
	if state == EnemyState.DEAD: return
	if area.is_in_group("projectile"):
		health -= 5
		if health <= 0:
			var explosion_sfx = EXPLOSITION.instantiate()
			explosion_sfx.global_position = global_position
			explosion_sfx.emitting = true
			add_sibling(explosion_sfx)
			
			state = EnemyState.DEAD
			$DeadTimer.start()
		
		hit.emit()


func _on_dead_timer_timeout() -> void:
	queue_free()
