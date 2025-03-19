extends CharacterBody3D


const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const SENSITIVITY_MOUSE := 0.005

var xr_interface: XRInterface

@export var active = false:
	set(new_val):
		active = new_val
		if new_val and is_inside_tree():
			switch_cam()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var xr_camera_3d: XRCamera3D = $XROrigin/XRCamera3D
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay
@onready var detector: Area3D = $Detector


var in_space = true


var camera_shake := 0.0
var camera_offset: Vector3

# Get the gravity from the project settings to be synced with RigidBody nodes.

var last_pos = Vector3.ZERO

func switch_cam():
	#if xr_interface.is_initialized():
		#xr_camera_3d.current = true
	#else:
	camera_3d.current = true


func _ready() -> void:
	Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$debug.hide()
	camera_offset = camera_pivot.position
	interact_ray.add_exception(self)
	
	#xr_interface = XRServer.find_interface("OpenXR")
	#if xr_interface and xr_interface.is_initialized():
		#print("OpenXR instantiated successfully.")
		#var vp : Viewport = get_viewport()
#
		## Enable XR on our viewport
		#vp.use_xr = true
#
		## Make sure v-sync is off, v-sync is handled by OpenXR
		#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#
		#
		## Enable VRS
		##if RenderingServer.get_rendering_device():
			##vp.vrs_mode = Viewport.VRS_XR
		##elif int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
			##push_warning("OpenXR: Recommend setting Foveation level to High in Project Settings")
#
		## Connect the OpenXR events
		##xr_interface.session_begun.connect(_on_openxr_session_begun)
		##xr_interface.session_visible.connect(_on_openxr_visible_state)
		##xr_interface.session_focussed.connect(_on_openxr_focused_state)
		##xr_interface.session_stopping.connect(_on_openxr_stopping)
		##xr_interface.pose_recentered.connect(_on_openxr_pose_recentered)
	#else:
		## We couldn't start OpenXR.
		#print("OpenXR not instantiated!")
		#get_tree().quit()


func _input(event: InputEvent) -> void:
	if not active:
		return
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouse:
		if event.is_pressed():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.global_rotate(global_basis.x, -event.screen_relative.y * SENSITIVITY_MOUSE)
		global_rotate(global_basis.y, -event.screen_relative.x * SENSITIVITY_MOUSE)

func _process(delta: float) -> void:
	var time = Time.get_ticks_msec()
	var offset = Vector3.ZERO
	offset.x += camera_shake * sin(time * 0.341 + cos(0.112 + time * 0.014)) * 0.01
	offset.y += camera_shake * sin(time * 0.141 + cos(0.412 + time * 0.214)) * 0.01
	camera_shake *= 0.95
	
	camera_pivot.position = camera_offset + offset
	
	$SpaceParticles.emitting = active and in_space
	

func _physics_process(delta: float) -> void:
	$CollisionShape3D.disabled = !active
	
	if not active:
		return
	
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Spaceship and Input.is_action_just_pressed("switch"):
			var spaceship = collider as Spaceship
			camera_pivot.rotation.x = 0
			spaceship.take_control(self)

	
	in_space = true
	up_direction = Vector3.UP
	for area in detector.get_overlapping_areas():
		if area.is_in_group("gravity"):
			in_space = false
			up_direction = area.global_basis.y
	

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	var direction = Vector3.ZERO
	
	
	if in_space:
		direction = (camera_3d.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		velocity += direction * SPEED * delta
		
		velocity.x = clamp(velocity.x, -10, 10)
		velocity.y = clamp(velocity.y, -10, 10)
		velocity.z = clamp(velocity.z, -10, 10)
		
		velocity *= 0.99
	else:
		direction = (global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		# smoothly align to gravity normal
		var target_xform := global_transform.looking_at(global_position - global_basis.z, up_direction)
		global_transform = global_transform.interpolate_with(target_xform, 0.2)
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		
		velocity -= up_direction * 2
		
		if !input_dir:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	
		if input_dir:
			velocity.x = lerpf(velocity.x, direction.x * SPEED, 0.2)
			velocity.y = lerpf(velocity.y, direction.y * SPEED, 0.2)
			velocity.z = lerpf(velocity.z, direction.z * SPEED, 0.2)
	
	var parent = get_parent()
	
#		if is_on_floor():
		
#		else:
			
#			if parent is RigidBody3D:
#				velocity = lerp(velocity, parent.linear_velocity, 0.2)

	

	move_and_slide()


func _on_detector_area_entered(area: Area3D) -> void:
	if area.is_in_group("gravity"):
		in_space = false
		up_direction = area.global_basis.y


func _on_detector_area_exited(area: Area3D) -> void:
	if area.is_in_group("gravity"):
		in_space = true
		up_direction = Vector3.UP
