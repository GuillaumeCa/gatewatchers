extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	%ScalingSlider.value = get_viewport().scaling_3d_scale
	%ScalingSlider.drag_ended.connect(func(changed: bool):
		get_viewport().scaling_3d_scale = %ScalingSlider.value
	)

	%VSync.button_pressed = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
	%VSync.pressed.connect(func():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if %VSync.button_pressed else DisplayServer.VSYNC_DISABLED) 
	)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$M/VB/Scaling.text = "Render Scale %.1fx" % [%ScalingSlider.value]
