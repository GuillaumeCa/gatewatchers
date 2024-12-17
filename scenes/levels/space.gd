extends Node3D

class_name Space

@onready var player = $Nebula


const KYTHRAX = preload("res://scenes/spaceships/drexuls/kythrax.tscn")

static var shifted_origin: Vector3
var last_offset: Vector3

const MAX_DISTANCE = 5000.0

func _ready() -> void:
	SpaceManager.init_systems()
	
	var planet = get_tree().get_nodes_in_group("planet").pick_random()
	var loc = planet.global_position
	
	player.relocate(Vector3(
		randf_range(loc.x - 10000, loc.x + 10000),
		randf_range(loc.y-5000, loc.y + 5000),
		randf_range(loc.z-10000, loc.z + 10000),
	))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouse:
		if event.is_pressed():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	
	$Hud/SettingsPanel.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	
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
	$Hud/Label.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS)) + "\n"
	$Hud/Label.text += "Position:\nx: %.2fm\ny: %.2fm\nz: %.2fm" % [player.global_position.x, player.global_position.y, player.global_position.z]
	$Hud/Label2.text = "Shifted Position:\nx: %.2fm\ny: %.2fm\nz: %.2fm" % [shifted_origin.x, shifted_origin.y, shifted_origin.z]


func _on_enemy_wave_timeout() -> void:
	if player.mode != player.Mode.TRAVEL:
		var spawn_pos = player.global_position + Vector3(randf(), randf(), randf()).normalized() * 500
		
		prints("enemy spawned at", spawn_pos)
		var ship = KYTHRAX.instantiate()
		ship.global_position = spawn_pos
		add_child(ship)
	
