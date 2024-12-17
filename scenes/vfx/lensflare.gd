extends CanvasLayer


@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	#var pos = camera.unproject_position(sun.global_position)
	#
	#
	#color_rect.material.set_shader_parameter("sun_position", pos)
	#color_rect.material.set_shader_parameter("resolution", get_viewport().size)
