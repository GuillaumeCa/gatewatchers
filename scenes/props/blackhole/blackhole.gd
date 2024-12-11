@tool
extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mat = $MeshInstance3D.material_override as ShaderMaterial
	var pos = $MeshInstance3D.global_position
	pos = -pos
	mat.set_shader_parameter("pos", pos)
