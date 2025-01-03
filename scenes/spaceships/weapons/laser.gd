extends Area3D


var speed = 3000
var material: BaseMaterial3D

func _ready() -> void:
	$MeshInstance3D.set_surface_override_material(0, material)

func _physics_process(delta: float) -> void:
	global_position += basis * Vector3.FORWARD * speed * delta

func _on_body_entered(body: Node3D) -> void:
	queue_free()


func _on_timer_timeout() -> void:
	queue_free()
