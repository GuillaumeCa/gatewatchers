extends Node3D

const LASER = preload("res://scenes/spaceships/weapons/laser.tscn")

@export var fire_rate = 0.1 # Adjust this value to set the fire rate in seconds
@export var spread = 0.0
@export var laser_speed = 3000.0
@export var laser_material: BaseMaterial3D

var time_since_last_shot = 0.0

func fire():
	if time_since_last_shot >= fire_rate:
		var l = LASER.instantiate()
		l.material = laser_material
		l.top_level = true
		l.speed = laser_speed
		add_child(l)
		l.global_transform = global_transform
		l.rotate_y(randf_range(deg_to_rad(-spread), deg_to_rad(spread)))
		l.rotate_x(randf_range(deg_to_rad(-spread), deg_to_rad(spread)))
		time_since_last_shot = 0.0
		$Laser.pitch_scale = randf_range(0.95, 1.05)
		$Laser.play()


## Calculates the predicted impact point based on the target velocity and the projectile speed
func predicted_impact(target_pos: Vector3, target_velocity: Vector3):
	var direction_to_target = target_pos - global_position
	
	# Quadratic coefficients
	var a = target_velocity.length_squared() - laser_speed * laser_speed
	var b = 2.0 * direction_to_target.dot(target_velocity)
	var c = direction_to_target.length_squared()
	
	# Solve the quadratic equation
	var discriminant = b * b - 4.0 * a * c
	if discriminant < 0:
		# No valid solution (projectile cannot reach target)
		return null
	
	# Calculate the smallest positive time to impact
	var t1 = (-b - sqrt(discriminant)) / (2.0 * a)
	var t2 = (-b + sqrt(discriminant)) / (2.0 * a)
	var impact_time = t1 if t1 > 0 else t2
	if impact_time < 0:
		# No valid impact time
		return null
	
	var future_target = target_pos + (target_velocity * impact_time)
	
	return future_target



func _process(delta: float) -> void:
	time_since_last_shot += delta
