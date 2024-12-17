extends Node3D

var open = true

var target_system = 44

func get_warp_distance():
	return 50.0

func _ready() -> void:
	name = SpaceManager.systems[target_system]["name"] + "Gate"

func _on_gate_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("human"):
		var current_system = SpaceManager.systems[SpaceManager.current_system.system_seed]
		SpaceManager.load_system(target_system)
		var warp_gate = SpaceManager.current_system.get_node("Objects/" + current_system["name"] + "Gate")
		Space.shifted_origin = Vector3.ZERO
		body.relocate(warp_gate.global_position + Vector3(0, 0, -100))
