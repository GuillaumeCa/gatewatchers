extends Control

var speed = 0.0
var mode = ""
var hull_health = 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Dials/Speed.text = "%.1f m/s" % speed
	$Dials/Mode.text = mode
	$Dials/Health.text = str(hull_health)
