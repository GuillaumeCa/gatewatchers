extends CharacterBody3D

const SPEED := 5.0
const ACCELERATION := 30.0
const GRAVITY := 10.0
const JUMP_VELOCITY := 12.0
const SENSITIVITY_MOUSE := 0.005

var xr_interface: XRInterface

@export var active = false:
	set(new_val):
		active = new_val
		if new_val and is_inside_tree():
			SpaceManager.player = self
			switch_cam()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var xr_camera_3d: XRCamera3D = $XROrigin/XRCamera3D
@onready var interact_ray: RayCast3D = $CameraPivot/Camera3D/InteractRay
@onready var detector: Area3D = $Detector


var parent_gravity_area: Area3D

var camera_shake := 0.0
var camera_offset: Vector3


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
	
	$SpaceParticles.emitting = active and !parent_gravity_area
	

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

	
	up_direction = Vector3.UP
	var areas = detector.get_overlapping_areas()
	for area in areas:
		if area.is_in_group("gravity"):
			parent_gravity_area = area

	if parent_gravity_area:
		if parent_gravity_area.gravity_point:
			up_direction = parent_gravity_area.global_position.direction_to(global_position)
		else:
			up_direction = parent_gravity_area.global_basis.y
	

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	var direction = Vector3.ZERO
	
	
	if !parent_gravity_area:
		# movement in space
		direction = (camera_3d.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		#velocity += direction * SPEED * delta
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
		
		velocity.x = clamp(velocity.x, -SPEED, SPEED)
		velocity.y = clamp(velocity.y, -SPEED, SPEED)
		velocity.z = clamp(velocity.z, -SPEED, SPEED)
		
		
		velocity *= 0.99
	else:
		# movement in gravity area
		direction = (global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# smoothly align player to gravity normal
		var target_xform := global_transform.looking_at(global_position - global_basis.z, up_direction)
		global_transform = global_transform.interpolate_with(target_xform, 0.3)
		
		# switch to grounded mode
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

		# apply gravity
		if not is_on_floor():
			velocity -= up_direction * GRAVITY * delta
		
		if input_dir:
			velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
			#velocity.x = lerpf(velocity.x, direction.x * SPEED, 0.2)
			#velocity.y = lerpf(velocity.y, direction.y * SPEED, 0.2)
			#velocity.z = lerpf(velocity.z, direction.z * SPEED, 0.2)
		
		if !input_dir and is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, ACCELERATION * delta)
		
		
		
		if Input.is_action_just_pressed("up") and is_on_floor():
			velocity += up_direction * JUMP_VELOCITY
		
	

	move_and_slide()


func _on_detector_area_entered(area: Area3D) -> void:
	#var area_owner = area.owner
	#if area_owner:
		#var parent_gravity = area_owner.get("parent_gravity_area")
		#if parent_gravity_area != null and parent_gravity != parent_gravity_area:
			#return
	
	if area.is_in_group("gravity"):
		parent_gravity_area = area
		prints("player entered gravity area", area)


func _on_detector_area_exited(area: Area3D) -> void:
	if area.is_in_group("gravity"):
		if parent_gravity_area and parent_gravity_area == area:
			prints("player left gravity area", area)
			parent_gravity_area = null
