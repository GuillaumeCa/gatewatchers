extends Area3D


var speed = 3000

func _physics_process(delta: float) -> void:
	global_position += basis * Vector3(0, 0, -1) * speed * delta


func _on_body_entered(body: Node3D) -> void:
	queue_free()


func _on_timer_timeout() -> void:
	queue_free()
