extends Panel


enum ScalingOptions {
	DISABLED = 0,
	QUALITY = 1,
	BALANCED = 2,
	PERFORMANCE = 3
}

const scaling_options = {
	ScalingOptions.DISABLED: 1,
	ScalingOptions.QUALITY: 0.9,
	ScalingOptions.BALANCED: 0.7,
	ScalingOptions.PERFORMANCE: 0.5,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	%ScalingOptions.item_selected.connect(func(selected: int):
		get_viewport().scaling_3d_scale = scaling_options[selected]
	)

	%VSync.button_pressed = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
	%VSync.pressed.connect(func():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if %VSync.button_pressed else DisplayServer.VSYNC_DISABLED) 
	)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#$M/VB/Scaling.text = "Render Scale %.1fx" % [%ScalingSlider.value]
