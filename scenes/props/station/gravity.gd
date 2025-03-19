extends Area3D


var to_move = []

var old_pos: Vector3

func _physics_process(delta: float) -> void:
	pass
	#var vel = global_position - old_pos
	#for body: Node3D in to_move:
		#body.global_position += vel
#
	#old_pos = global_position


func _on_body_entered(body: Node3D) -> void:
	to_move.append(body)


func _on_body_exited(body: Node3D) -> void:
	to_move.erase(body)
