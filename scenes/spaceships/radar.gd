extends Area3D

var targets: Array[Node3D] = []

var current_target: Node3D

func get_closest_target(group = "human", dir = Vector3.ZERO) -> Node3D:
	var closest
	var closest_dist
	var alignment = -1
	for target in targets:
		if is_instance_valid(target) and target.is_in_group(group):
			var target_alignment = dir.dot(global_position.direction_to(target.global_position))
			var dist = target.global_position.distance_to(global_position)
			
			if dir == Vector3.ZERO:
				if !closest_dist or dist < closest_dist:
					closest_dist = dist
					closest = target
			elif target_alignment > alignment:
				alignment = target_alignment
				closest = target
				
	return closest


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("ship"):
		targets.append(body)

func _on_body_exited(body: Node3D) -> void:
	if targets.find(body):
		targets.erase(body)
