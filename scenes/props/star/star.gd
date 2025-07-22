extends MeshInstance3D


func set_color(star_color: Color):
	material_override.set_shader_parameter("sun_color", star_color)
	position = Vector3.ZERO
	var m: ShaderMaterial = $StarSurface.material_override
	m.set_shader_parameter("color", star_color)

func _process(delta: float) -> void:
	var dist = get_viewport().get_camera_3d().global_position.distance_to(global_position)
	var m: ShaderMaterial = $StarSurface.material_override
	m.set_shader_parameter("intensity", remap(dist, 5000.0, 50000.0, 10.0, 100.0))
