extends CanvasLayer


@export var sun: Node3D

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.hide()
	
func _process(delta: float) -> void:
	if sun:
		var camera = get_viewport().get_camera_3d()

		var visible = not camera.is_position_behind(sun.global_position)
		if visible:
			color_rect.show()
			#var pos = camera.unproject_position(sun.global_position)
			#
			#
			#color_rect.material.set_shader_parameter("sun_position", pos)
			#color_rect.material.set_shader_parameter("resolution", get_viewport().size)
			
