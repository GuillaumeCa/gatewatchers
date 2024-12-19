extends Node3D

enum Mode {
	GALAXY,
	SYSTEM
}

var mode = Mode.GALAXY

@export var system_mesh: Mesh

func _ready() -> void:
	generate_map.call_deferred()

func generate_map():
	print("gen ui")
	
	var links = ImmediateMesh.new()
	
	var lines = {}
	
	for key in SpaceManager.systems:
		var system = SpaceManager.systems[key]
		var system_pos: Vector3 = system["pos"] / 100
		var gates = system["gates"].keys()
		var meshinst = MeshInstance3D.new()
		meshinst.mesh = system_mesh
		meshinst.position = system_pos
		add_child(meshinst)
		
		var label = Label3D.new()
		label.position = Vector3.UP * 0.03
		label.text = system["name"]
		label.pixel_size = 0.0012
		meshinst.add_child(label)
		
		for gate in gates:
			if not Vector2i(gate,key) in lines:
				links.surface_begin(Mesh.PRIMITIVE_LINES)
				links.surface_add_vertex(system_pos)
				var target_pos = SpaceManager.systems[gate]["pos"] / 100
				links.surface_add_vertex(target_pos)
				links.surface_end()
				lines[Vector2i(key, gate)] = null
			

	var links_mesh = MeshInstance3D.new()
	links_mesh.mesh = links
	add_child(links_mesh)
func _process(delta: float) -> void:
	pass
