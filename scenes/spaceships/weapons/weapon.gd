extends Node3D

const LASER = preload("res://scenes/spaceships/weapons/laser.tscn")

@export var fire_rate = 0.1 # Adjust this value to set the fire rate in seconds
@export var spread = 1
var time_since_last_shot = 0.0

func fire():
	if time_since_last_shot >= fire_rate:
		var l = LASER.instantiate()
		l.top_level = true
		add_child(l)
		l.global_transform = global_transform
		l.rotate_y(randf_range(deg_to_rad(-spread), deg_to_rad(spread)))
		l.rotate_x(randf_range(deg_to_rad(-spread), deg_to_rad(spread)))
		time_since_last_shot = 0.0
		$Laser.pitch_scale = randf_range(0.95, 1.05)
		$Laser.play()
		


func _process(delta: float) -> void:
	time_since_last_shot += delta
