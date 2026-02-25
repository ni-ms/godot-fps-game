extends CharacterBody3D

@export_category("Movement Speeds")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.5
@export var crouch_speed: float = 3.0
@export var slide_speed_boost: float = 6.0
@export var slide_decay: float = 0.98
@export var acceleration: float = 12.0
@export var friction: float = 10.0
@export var air_control: float = 5.0

@export_category("Physics")
@export var gravity_multiplier: float = 2.0 # More snappier gravity
@export var jump_height: float = 1.3
@export var weight: float = 4.0

@export_category("Combat & Stats")
@export var max_health: float = 100.0
var current_health: float = max_health

@onready var hud_health_bar = $HUD/Control/HealthSection/ProgressBar
@onready var hud_ammo_label = $HUD/Control/WeaponSection/AmmoLabel
@onready var hud_weapon_name = $HUD/Control/WeaponSection/WeaponName

var inventory: Array = []
var current_weapon_index: int = 0

func _ready() -> void:
	# Add existing guns to inventory
	inventory.append(gun1)
	inventory.append(gun2)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	camera.fov = base_fov
	default_head_y = head.position.y
	target_head_y = default_head_y
	
	update_hud()

func switch_weapon(index: int):
	if index >= inventory.size() or index < 0: return
	
	# Hide all
	for g in inventory:
		g.visible = false
	
	current_weapon_index = index
	gun1 = inventory[index] # Update the 'gun1' reference to active gun
	gun1.visible = true
	update_hud()

func take_damage(amount: float):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	update_hud()
	if current_health <= 0:
		die()

func update_hud():
	hud_health_bar.value = current_health
	# Simple ammo check for now, will refine with inventory
	if gun1:
		hud_ammo_label.text = str(gun1.current_mag) + " / " + str(gun1.reserve_ammo)
		hud_weapon_name.text = gun1.weapon_name

func die():
	get_tree().reload_current_scene()

@export_category("Coyote & Buffering")
@export var coyote_time: float = 0.15 # Time to jump after falling off ledge
@export var jump_buffer: float = 0.1 # Buffer jump input before hitting ground

@export_category("Camera & Feel")
@export var mouse_sensitivity: float = 0.002
@export var lean_amount: float = 0.05
@export var lean_speed: float = 8.0
@export var base_fov: float = 90.0
@export var sprint_fov: float = 100.0
@export var slide_fov: float = 110.0
@export var crouch_depth: float = -0.7
@export var crouch_lerp_speed: float = 12.0

@onready var head: Node3D = $Head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera: Camera3D = $Head/Eyes/Camera3D
@onready var hand: Node3D = $Head/Eyes/Hand
@onready var gun1: Node3D = $Head/Eyes/Hand/gun1
@onready var gun2: Node3D = $Head/Eyes/Hand/gun2

# --- STATE ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float = walk_speed
var t_bob: float = 0.0
var default_head_y: float = 0.0
var target_head_y: float = 0.0

var is_sliding: bool = false
var slide_velocity: Vector3 = Vector3.ZERO
var time_since_on_floor: float = 0.0
var jump_buffer_timer: float = 0.0

# --- CONFIGURATION (PART 2) ---
@export_category("Mantle & WallBounce")
@export var mantle_speed: float = 8.0
@export var wall_jump_force: float = 6.0
@export var landing_shake_intensity: float = 0.2
@export var landing_shake_duration: float = 0.15

@onready var wall_check: RayCast3D = $WallCheck
@onready var ledge_check: RayCast3D = $LedgeCheck

# --- STATE (PART 2) ---
var is_mantling: bool = false
var mantle_target_pos: Vector3 = Vector3.ZERO
var last_velocity_y: float = 0.0
var camera_shake_offset: Vector3 = Vector3.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		eyes.rotate_x(-event.relative.y * mouse_sensitivity)
		eyes.rotation.x = clamp(eyes.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		# Weapon Sway
		hand.rotation.y = lerp(hand.rotation.y, -event.relative.x * 0.005, 0.1)
		hand.rotation.x = lerp(hand.rotation.x, -event.relative.y * 0.005, 0.1)

func _physics_process(delta: float) -> void:
	# 1. TIMERS & LANDING DETECTION
	if is_on_floor():
		if last_velocity_y < -8.0: # Significant fall
			apply_landing_shake()
		time_since_on_floor = 0.0
	else:
		time_since_on_floor += delta
		last_velocity_y = velocity.y
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer
	else:
		jump_buffer_timer -= delta

	# 2. MANTLE LOGIC
	if is_mantling:
		global_position = global_position.lerp(mantle_target_pos, delta * mantle_speed)
		if global_position.distance_to(mantle_target_pos) < 0.2:
			is_mantling = false
		return # Disable normal movement while mantling

	if not is_on_floor() and velocity.y < 2.0:
		if wall_check.is_colliding() and not ledge_check.is_colliding():
			# Potential ledge detected!
			# We need to find the floor of the ledge
			# This is a simple approximation
			is_mantling = true
			mantle_target_pos = wall_check.get_collision_point() + Vector3(0, 2.5, 0) + (-wall_check.get_collision_normal() * 0.5)

	# 3. SHOOTING & RELOAD
	if Input.is_action_just_pressed("left_click"):
		if gun1.has_method("Shoot"):
			var shot_fired = gun1.Shoot()
			if shot_fired:
				apply_recoil_shake()
				shoot_raycast()
				update_hud()



	if Input.is_action_just_pressed("reload"):
		if gun1.has_method("Reload"):
			gun1.Reload()
			update_hud()

	# 4. WEAPON SWITCHING
	if Input.is_action_just_pressed("weapon1"):
		switch_weapon(0)
	elif Input.is_action_just_pressed("weapon2"):
		switch_weapon(1)

	# 5. MOVEMENT INPUT
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 5. SLIDING LOGIC
	var is_sprinting = Input.is_action_pressed("run")
	var wants_crouch = Input.is_action_pressed("crouch")
	var just_crouched = Input.is_action_just_pressed("crouch")
	
	if just_crouched and is_sprinting and is_on_floor() and not is_sliding:
		is_sliding = true
		slide_velocity = direction * (speed + slide_speed_boost)
		target_head_y = default_head_y + crouch_depth
	elif not wants_crouch or not is_on_floor():
		is_sliding = false
	
	# 6. VELOCITY CALCULATION
	if is_sliding:
		velocity.x = slide_velocity.x
		velocity.z = slide_velocity.z
		slide_velocity *= slide_decay
		if slide_velocity.length() < walk_speed:
			is_sliding = false
	else:
		# Standard movement
		if wants_crouch:
			speed = crouch_speed
			target_head_y = default_head_y + crouch_depth
		elif is_sprinting:
			speed = run_speed
			target_head_y = default_head_y
		else:
			speed = walk_speed
			target_head_y = default_head_y

		if is_on_floor():
			if direction:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, friction * delta)
				velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		else:
			# Air control
			if direction:
				velocity.x = lerp(velocity.x, direction.x * speed, air_control * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, air_control * delta)

	# 7. GRAVITY & JUMPING
	if not is_on_floor():
		velocity.y -= gravity * weight * delta
	
	# Jump / Wall Bounce
	if jump_buffer_timer > 0.0:
		if time_since_on_floor < coyote_time:
			velocity.y = sqrt(jump_height * 2.0 * gravity * gravity_multiplier)
			jump_buffer_timer = 0.0
			if is_sliding:
				velocity += direction * 2.0
				is_sliding = false
		elif wall_check.is_colliding():
			# Wall Bounce!
			var wall_normal = wall_check.get_collision_normal()
			velocity = (wall_normal + Vector3.UP).normalized() * wall_jump_force * 1.5
			jump_buffer_timer = 0.0

	# 7. CAMERA EFFECTS (FOV, Tilt, Bob, Shake)
	var target_fov = base_fov
	if Input.is_action_pressed("right_click"):
		target_fov = base_fov * 0.7 # ADS Zoom
	elif is_sliding: target_fov = slide_fov
	elif is_sprinting: target_fov = sprint_fov
	camera.fov = lerp(camera.fov, target_fov, delta * 12.0)
	
	var target_tilt = -input_dir.x * lean_amount
	if is_sliding: target_tilt += lean_amount * 2.0
	camera.rotation.z = lerp(camera.rotation.z, target_tilt, delta * lean_speed)
	
	head.position.y = lerp(head.position.y, target_head_y, delta * crouch_lerp_speed)

	# 9. BOB & SHAKE & BREATHE
	var breathe = sin(Time.get_ticks_msec() * 0.001) * 0.005
	if velocity.length() > 1.0 and is_on_floor() and not is_sliding:
		t_bob += delta * velocity.length()
		var pos = Vector3.ZERO
		pos.y = sin(t_bob * 2.4) * 0.05
		pos.x = cos(t_bob * 2.4 / 2) * 0.05
		camera.transform.origin = camera.transform.origin.lerp(pos + camera_shake_offset, delta * 15.0)
	else:
		camera.transform.origin = camera.transform.origin.lerp(Vector3(0, breathe, 0) + camera_shake_offset, delta * 10.0)

	camera_shake_offset = camera_shake_offset.lerp(Vector3.ZERO, delta * 10.0)
	
	hand.rotation = hand.rotation.lerp(Vector3.ZERO, 8.0 * delta)
	move_and_slide()

func apply_landing_shake():
	camera_shake_offset = Vector3(0, -landing_shake_intensity, 0)

func apply_recoil_shake():
	camera_shake_offset.y += 0.05
	eyes.rotation.x += 0.02 # Camera up kick

func shoot_raycast():
	var space_state = get_world_3d().direct_space_state
	var center = get_viewport().get_size() / 2
	
	var from = camera.project_ray_origin(center)
	var to = from + camera.project_ray_normal(center) * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2 # Hit Layer 2 (Characters/Targets)
	
	var result = space_state.intersect_ray(query)
	if result:
		var target = result.collider
		if target.has_method("take_damage"):
			target.take_damage(20) # Hardcoded damage for now
