extends Node3D

class_name Space

@onready var player = $Nebula

var settings_open = false


const KYTHRAX = preload("res://scenes/spaceships/drexuls/kythrax.tscn")

static var shifted_origin: Vector3
var last_offset: Vector3

const MAX_DISTANCE = 5000.0

func _ready() -> void:
	SpaceManager.init_systems()
	
	var warp_locations = get_tree().get_nodes_in_group("warp")
	warp_locations.shuffle()
	for warp in warp_locations:
		if warp.name.ends_with("StationS11"):
			var loc = warp.global_position
			
			var dist = 300 #warp.get_warp_distance()
			player.relocate(Vector3(
				randf_range(loc.x - dist, loc.x + dist),
				randf_range(loc.y-dist/2.0, loc.y + dist/2.0),
				randf_range(loc.z-dist, loc.z + dist),
			))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			settings_open = true
	if settings_open and event is InputEventMouse:
		if event.is_pressed():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			settings_open = false

# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	$Hud/SettingsPanel.visible = settings_open
	
	var playerGlobalPos = player.global_position
	
	# Calculate the player's position relative to the shifted origin
	#var playerRelativePos = playerGlobalPos - last_offset
	
	update_HUD()
	
	if playerGlobalPos.length() > MAX_DISTANCE:
		shift_origin(playerGlobalPos)




func shift_origin(offset: Vector3):
	prints("shift", offset)
	# Calculate the new shifted origin position
	shifted_origin -= offset
	#last_offset = offset
	
	#print("shift origin")
	
	# Shift all objects and nodes in the game world to maintain relative positions
	for node in get_tree().get_nodes_in_group("space_objects"):
		if node != self:
			if node.has_method("relocate"):
				node.relocate(node.global_position - offset)
			else:
				node.global_position -= offset
	
	# Update the user interface, minimap, or other HUD elements to reflect the new origin


func update_HUD():
	$Hud/Debug.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
	$Hud/Debug.text += "\nPosition:\nx: %.2fm\ny: %.2fm\nz: %.2fm" % [player.global_position.x, player.global_position.y, player.global_position.z]
	$Hud/Debug.text += "\nShifted Position:\nx: %.2fm\ny: %.2fm\nz: %.2fm" % [shifted_origin.x, shifted_origin.y, shifted_origin.z]
	$Hud/Debug.text += "\nProcess time %.2f" % [Performance.get_monitor(Performance.TIME_PROCESS)]
	$Hud/Debug.text += "\nPhysics time %.2f" % [Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)]
	$Hud/Debug.text += "\nDraw calls " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	
	

func _on_enemy_wave_timeout() -> void:
	if player.mode != player.Mode.TRAVEL:
		for i in randi_range(3, 5):
			var spawn_pos = player.global_position + Vector3(randf(), randf(), randf()).normalized() * 500
			
			prints("enemy spawned at", spawn_pos)
			var ship = KYTHRAX.instantiate()
			ship.global_position = spawn_pos
			add_child(ship)


func _on_simulation_tick_timeout() -> void:
	#SimulationManager.debug()
	SimulationManager.simulate_tick()
