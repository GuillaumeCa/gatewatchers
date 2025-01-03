extends GPUParticles3D

func _ready() -> void:
	$Sparkle.emitting = true
	$ExplosionSound.play()
	await get_tree().create_timer(.1).timeout
	emitting = true
	await finished
	await $ExplosionSound.finished
	queue_free()
