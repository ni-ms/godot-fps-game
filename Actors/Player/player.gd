extends CharacterBody3D

# --- CONFIGURATION ---

@export_category("Movement Speeds")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var crouch_speed: float = 3.0
@export var acceleration: float = 10.0
@export var friction: float = 12.0
@export var air_control: float = 3.0

@export_category("Physics")
@export var gravity_multiplier: float = 1.5
@export var jump_height: float = 1.5
@export var weight: float = 3.0

@export_category("Camera & Feel")
@export var mouse_sensitivity: float = 0.002
@export var bob_freq: float = 2.4
@export var bob_amp: float = 0.08
@export var base_fov: float = 75.0
@export var run_fov: float = 85.0
@export var crouch_depth: float = -0.5
@export var crouch_lerp_speed: float = 10.0

@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera: Camera3D = $Head/Eyes/Camera3D
@onready var hand: Node3D = $Hand
@onready var gun1: Node3D = $Hand/gun1

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float = walk_speed
var t_bob: float = 0.0
var default_head_y: float = 0.0
var target_head_y: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	default_head_y = head.position.y
	target_head_y = default_head_y

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		eyes.rotate_x(-event.relative.y * mouse_sensitivity)
		eyes.rotation.x = clamp(eyes.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		# Weapon Sway
		hand.rotation.y = lerp(hand.rotation.y, -event.relative.x * 0.005, 0.1)
		hand.rotation.x = lerp(hand.rotation.x, -event.relative.y * 0.005, 0.1)

func _physics_process(delta: float) -> void:
	# 1. SHOOTING
	if Input.is_action_just_pressed("left_click"):
		if gun1.has_method("Shoot"):
			gun1.Shoot()
			eyes.rotation.x += 0.005

	# 2. MOVEMENT STATE
	var is_crouching = Input.is_action_pressed("crouch")
	var is_sprinting = Input.is_action_pressed("run")
	var current_fov = base_fov

	if is_crouching:
		speed = crouch_speed
		target_head_y = default_head_y + crouch_depth
	elif is_sprinting and is_on_floor():
		speed = run_speed
		target_head_y = default_head_y
		current_fov = run_fov
	else:
		speed = walk_speed
		target_head_y = default_head_y
	
	camera.fov = lerp(camera.fov, current_fov, delta * 8.0)
	head.position.y = lerp(head.position.y, target_head_y, delta * crouch_lerp_speed)

	# 3. GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * weight * delta

	# 4. JUMP
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = sqrt(jump_height * 2.0 * gravity * gravity_multiplier)

	# 5. MOVEMENT CALCULATION
	# REVERTED TO STANDARD: Left, Right, Forward, Back
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			# Using lerp for smooth start (fixes the jerkiness)
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			# Using move_toward for friction (prevents slippery sliding when stopping)
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	else:
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, air_control * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, air_control * delta)

	# 6. HEAD BOB
	if velocity.length() > 0.1 and is_on_floor():
		t_bob += delta * velocity.length()
		var pos = Vector3.ZERO
		pos.y = sin(t_bob * bob_freq) * bob_amp
		pos.x = cos(t_bob * bob_freq / 2) * bob_amp
		
		# Smooth bob transition
		camera.transform.origin = camera.transform.origin.lerp(pos, delta * 15.0)
	else:
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 10.0)

	hand.rotation = hand.rotation.lerp(Vector3.ZERO, 8.0 * delta)
	move_and_slide()
