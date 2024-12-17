extends GPUParticles3D

func _ready() -> void:
	$Sparkle.emitting = true
	await get_tree().create_timer(.1).timeout
	emitting = true

func _on_finished() -> void:
	queue_free()
