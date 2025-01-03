extends Node3D

var open = true

var target_system: int

func get_warp_distance():
	return 500.0

func _ready() -> void:
	name = SpaceManager.systems[target_system]["name"] + "Gate"
	var tunnel_material: ShaderMaterial = $warp_tunnel/tunnel.material_override
	tunnel_material.set_shader_parameter("alpha", 1.0 if open else 0.0)
	$GateArea/CollisionShape3D.disabled = not open

func _on_gate_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("human"):
		enter_system(body)

func enter_system(body: Node3D):
	var tw = get_tree().create_tween()
	var gate_area := $GateArea
	
	tw.parallel().tween_property(body, "global_position", gate_area.global_position, 1).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(body, "quaternion", Quaternion(gate_area.global_basis), 2).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(body, "global_position", gate_area.global_position - gate_area.global_basis.z * 50, .5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(switch_system.bind(body))

func switch_system(body: Node3D):
	var current_system = SpaceManager.systems[SpaceManager.current_system.system_seed]
	SpaceManager.load_system(target_system)
	var warp_gate = SpaceManager.current_system.get_node("Objects/" + current_system["name"] + "Gate")
	Space.shifted_origin = Vector3.ZERO
	body.relocate(warp_gate.global_position + Vector3(0, 0, -100))
