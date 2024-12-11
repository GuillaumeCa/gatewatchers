extends Area3D

var targets: Array[Node3D] = []

var current_target: Node3D

func get_closest_target(group = "human") -> Node3D:
	var closest
	var closest_dist
	for target in targets:
		if is_instance_valid(target) and target.is_in_group(group):
			var dist = target.global_position.distance_to(global_position)
			if !closest_dist or dist < closest_dist:
				closest = target
				closest_dist = dist
	return closest


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("ship"):
		targets.append(body)

func _on_body_exited(body: Node3D) -> void:
	if targets.find(body):
		targets.erase(body)
