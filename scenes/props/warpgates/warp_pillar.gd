extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation_degrees.x += randf() * 50 * delta
	rotation_degrees.y += randf() * 50 * delta
	rotation_degrees.z += randf() * 50 * delta
