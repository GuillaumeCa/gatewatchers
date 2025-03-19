extends Node3D

enum Mode {
	GALAXY,
	SYSTEM
}

var mode = Mode.GALAXY

var mouse_pressed = false

@export var current_system: String
@export var systems: Dictionary

@export var system_mesh: Mesh

func _ready() -> void:
	hide()
	generate_map.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_relative = event.screen_relative
		if mouse_pressed:
			var speed = Vector2(mouse_relative.y, mouse_relative.x) * 0.001
			basis = basis.rotated(Vector3.UP, speed.y).rotated(Vector3.RIGHT, speed.x)
	
	if event is InputEventMouseButton:
		mouse_pressed = event.is_pressed()
	
	


func generate_map():
	print("gen ui")
	
	var links = ImmediateMesh.new()
	
	var lines = {}
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color.v = 0.6
	mat.no_depth_test = true
	
	var highlight_mat = mat.duplicate()
	highlight_mat.albedo_color = Color.ROYAL_BLUE
	
	var links_mesh = MeshInstance3D.new()
	add_child(links_mesh)
	
	for key in SpaceManager.systems:
		var system = SpaceManager.systems[key]
		var current_system = SpaceManager.current_system.system_seed == key
		
		var system_pos: Vector3 = system["pos"] / 100
		var gates = system["gates"].keys()
		var meshinst = MeshInstance3D.new()
		meshinst.mesh = system_mesh
		meshinst.position = system_pos
		meshinst.material_override = highlight_mat if current_system else mat
		
		
		add_child(meshinst)
		
		var area = Area3D.new()
		var collider = CollisionShape3D.new()
		var sphere_col = SphereShape3D.new()
		sphere_col.radius = 0.01
		collider.shape = sphere_col
		area.input_ray_pickable = true
		area.add_child(collider)
		area.set_meta("system", key)
		meshinst.add_child(area)
		
		var label = Label3D.new()
		label.position = Vector3.UP * 0.03
		label.text = system["name"]
		label.pixel_size = 0.0012
		label.no_depth_test = true
		
		label.outline_size = 20
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		meshinst.add_child(label)
		
		for gate in gates:
			if not Vector2i(gate,key) in lines:
				links.surface_begin(Mesh.PRIMITIVE_LINES, mat)
				links.surface_add_vertex(system_pos)
				var target_pos = SpaceManager.systems[gate]["pos"] / 100
				links.surface_add_vertex(target_pos)
				links.surface_end()
				lines[Vector2i(key, gate)] = null
				
	links_mesh.mesh = links
