extends RigidBody3D

class_name Spaceship

enum Mode {
	COMBAT,
	NAVIGATION,
	TRAVEL
}

@export var speed = 300
@export var roll_speed = 100
@export var hull_health = 100

@export var enginesParticles: Array[GPUParticles3D] = []

@onready var camera_pivot: Node3D = $CameraPivot
@onready var engine_sfx: AudioStreamPlayer3D = $EngineSfx
@onready var thruster: AudioStreamPlayer3D = $Thruster
@onready var speed_label: Label = $CanvasLayer/HelmetHud/SpeedLabel
@onready var hud_target: Sprite2D = $CanvasLayer/HelmetHud/Target

@onready var warp_effect: MeshInstance3D = $WarpEffect
@onready var spaceship_hud = $HudMesh/HudViewPort/SpaceshipHud
@onready var radar = $Radar

const SENSITIVITY_MOUSE = 0.1

var mode = Mode.COMBAT

var active = true
var engine_sound_lvl = -40.0

var current_target: Node3D

var warping_progress = 0.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	for particles in $engines.get_children():
		if particles is GPUParticles3D:
			enginesParticles.append(particles)
	


func _unhandled_input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("switch"):
		active = !active
		
		$PilotPosition/Player.active = !$PilotPosition/Player.active
		if active:
			# when switching to spaceship, snap back the player in the seat
			$PilotPosition/Player.global_transform = $PilotPosition.global_transform
			#$CameraPivot/Camera3D.current = true
		else:
			$PilotPosition/Player.switch_cam()
	
	if not active:
		return
			
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_torque_impulse(-global_transform.basis.x * event.relative.y * SENSITIVITY_MOUSE)
		apply_torque_impulse(-global_transform.basis.y * event.relative.x * SENSITIVITY_MOUSE)
	
	if Input.is_action_just_pressed("forward"):
		enable_engine(true)
	if Input.is_action_just_released("forward"):
		enable_engine(false)

	
	if Input.is_action_just_pressed("backward") or Input.is_action_just_pressed("left") or \
		Input.is_action_just_pressed("right") or Input.is_action_just_pressed("down") or \
		Input.is_action_just_pressed("up"):
		thruster.play()
		
	if Input.is_action_just_pressed("nav_mode"):
		mode = Mode.NAVIGATION if mode != Mode.NAVIGATION else Mode.COMBAT
		

func get_warp_points():
	return get_tree().get_nodes_in_group("warp")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("change_view"):
		print("swap cam")
		if !$CameraPivot/Camera3D.current:
			$CameraPivot/Camera3D.current = true
		elif !$PilotPosition/Player.camera_3d.current:
			$PilotPosition/Player.switch_cam()
	
	if Input.is_action_just_pressed("map"):
		$MapProjector.visible = !$MapProjector.visible 
	
	var dir = Vector3.ZERO
	
	if mode == Mode.TRAVEL and Input.is_action_just_pressed("travel"):
		mode = Mode.NAVIGATION
		active = true
		var tw = create_tween()
		tw.tween_property(self, "linear_velocity", linear_velocity.normalized() * 0.1, 3).set_trans(Tween.TRANS_CUBIC)
		return
		
	var boost = false
	
	if active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		dir = Vector3(
			Input.get_axis("left", "right"),
			Input.get_axis("down", "up"),
			Input.get_axis("forward", "backward"),
		)
		
		boost = Input.is_action_pressed("boost")
		
		if mode == Mode.COMBAT:
			var target = radar.get_closest_target("drexul", -global_basis.z) as Node3D
			if target != current_target:
				if current_target != null:
					current_target.disconnect("hit", on_target_hit)
				if target != null:
					target.connect("hit", on_target_hit)
				
				current_target = target
			
			if Input.is_action_pressed("fire"):
				$Weapons/LaserWeapon.fire()
		
		if mode == Mode.NAVIGATION:
			var warp_points = get_warp_points()
			current_target = null
			var target_dot = null
			for p: Node3D in warp_points:
				var dir_to_planet = global_position.direction_to(p.global_position)
				if !target_dot:
					target_dot = dir_to_planet.dot(-global_basis.z)
				# check if aligned towards planet
				var align = dir_to_planet.dot(-global_basis.z)
				if align > 0.95 and align >= target_dot:
					current_target = p
					target_dot = align
					if Input.is_action_just_pressed("travel"):
						mode = Mode.TRAVEL
						# align ship towards current_target
						var tw = create_tween()
						tw.tween_property(self, "quaternion", Quaternion(global_transform.looking_at(current_target.global_position).basis), 2).set_trans(Tween.TRANS_CUBIC)
	
	if mode == Mode.TRAVEL:

		if current_target and is_instance_valid(current_target):
			var dist = global_position.distance_to(current_target.global_position)
			# if ship has not yet reached the target + 5000m, continue to go towards it
			if dist > current_target.get_warp_distance():
				var dir_target = global_position.direction_to(current_target.global_position)
				linear_velocity = lerp(linear_velocity, dir_target * clamp(dist * 0.1, 0, 40000), 0.008)
				angular_velocity = Vector3.ZERO
				active = false
				
			else:
				# slow down to 0m/s smoothly
				linear_velocity = lerp(linear_velocity, Vector3.ZERO, 0.1)
				if linear_velocity.length() < 1:
					active = true
					mode = Mode.NAVIGATION
	
	

	
	var speed_multiplier = 20.0 if boost else 1.0
	
	var force = dir.normalized() * speed * speed_multiplier * delta
	
	var fade = 0.03
	if force.z < 0:
		engine_sound_lvl = lerpf(engine_sound_lvl, -5, fade)
		engine_sfx.pitch_scale = lerpf(engine_sfx.pitch_scale, 0.2, fade)

	else:
		engine_sound_lvl = lerpf(engine_sound_lvl, -60, fade)
		engine_sfx.pitch_scale = lerpf(engine_sfx.pitch_scale, 0.02, fade)
	
	
	engine_sfx.volume_db = engine_sound_lvl
	
#	print(global_transform.basis * impulse)
	apply_central_force(global_transform.basis * force);
	
	var roll_force = Vector3(0, 0, -Input.get_axis("roll_left", "roll_right")) * roll_speed * delta
	apply_torque(global_transform.basis * roll_force)
	
	if freeze:
		camera_pivot.global_transform = camera_pivot.global_transform.interpolate_with(global_transform, 0.5)
	else:
		camera_pivot.global_transform = global_transform
		
	var relative_speed = linear_velocity.length()
		
	speed_label.text = "%.1f m/s" % relative_speed
	
	spaceship_hud.speed = relative_speed
	
	spaceship_hud.mode = Mode.keys()[mode]
	
	spaceship_hud.hull_health = hull_health
	
	
	warping_progress = lerp(warping_progress, min(relative_speed * 0.0001 if relative_speed > 500 else 0.0, 1.0), 0.05)
	var warp_mat: ShaderMaterial = warp_effect.material_override
	warp_mat.set_shader_parameter("alpha", warping_progress)

	hud_target.visible = false
	if current_target != null:
		
		var enemy = current_target.is_in_group("drexul")
		
		var target_dir = global_position.direction_to(current_target.global_position)
		var target_dist = global_position.distance_to(current_target.global_position)
		
		var angle = -global_transform.basis.z.dot(target_dir)
		var pos = get_viewport().get_camera_3d().unproject_position(current_target.global_position)
		#if get_viewport().get_camera_3d().is_position_in_frustum(current_target.global_position):
		if angle > 0:
			var offset = 30
			hud_target.modulate = Color.RED if enemy else Color.AQUAMARINE
			hud_target.position = Vector2(clamp(pos.x, offset, get_viewport().size.x - offset), clamp(pos.y, offset, get_viewport().size.y - offset))
			hud_target.visible = true
			var dist = hud_target.get_node("Distance")
			
			var target_name = hud_target.get_node("Name")
			if not enemy:
				target_name.show()
				target_name.text = current_target.name
			else:
				target_name.hide()
				
			var dist_km = round(target_dist / 1000.0)
			dist.text =  str(dist_km) + "KM"
			dist.visible = dist_km > 0
	
	var weapon_dist_target = $Weapons/LaserWeapon.global_position + -$Weapons/LaserWeapon.global_basis.z * 1000
	var weapon_target_pos = get_viewport().get_camera_3d().unproject_position(weapon_dist_target)
	$CanvasLayer/HelmetHud/WeaponReticule.position = weapon_target_pos

# used to recenter the ship for the floating origin
func relocate(pos: Vector3):
	freeze = true
	var vel = linear_velocity
	var ang = angular_velocity
	global_position = pos
	camera_pivot.global_transform = global_transform
	linear_velocity = vel
	angular_velocity = ang
	freeze = false
	


func enable_engine(on: bool):
	for particles in enginesParticles:
		particles.emitting = on

func on_target_hit():
	$CanvasLayer/HelmetHud/Target/Hit.visible = true
	await get_tree().create_timer(0.1).timeout
	$CanvasLayer/HelmetHud/Target/Hit.visible = false


func _on_collision_area_entered(area: Area3D) -> void:
	if area.is_in_group("projectile"):
		hull_health -= 5
		
		if hull_health <= 0:
			hull_health = 0
			print("DEAD")
			get_tree().reload_current_scene()
