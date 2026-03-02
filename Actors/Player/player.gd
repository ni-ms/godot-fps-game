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

@export_category("Advanced Movement")
@export var coyote_time: float = 0.15
@export var jump_buffer: float = 0.1
@export var wall_jump_force: float = 8.0
@export var crouch_depth: float = -0.5
@export var crouch_lerp_speed: float = 10.0

@export_category("Visuals")
@export var base_fov: float = 75.0
@export var slide_fov: float = 85.0
@export var sprint_fov: float = 80.0
@export var lean_amount: float = 0.05
@export var lean_speed: float = 5.0
@export var landing_shake_intensity: float = 0.1

@export_category("Physics")
@export var gravity_multiplier: float = 2.0 # More snappier gravity
@export var jump_height: float = 1.3
@export var weight: float = 4.0

@export_category("Combat & Stats")
@export var max_health: float = 100.0
var current_health: float = max_health

@onready var head = $Head
@onready var eyes = $Head/Eyes
@onready var camera = $Head/Eyes/Camera3D
@onready var hand = $Head/Eyes/Hand
@onready var gun1 = $Head/Eyes/Hand/gun1
@onready var gun2 = $Head/Eyes/Hand/gun2

@onready var wall_check = $WallCheck
@onready var ledge_check = $LedgeCheck
@onready var head_check = $HeadCheck
@onready var right_wall_check = $RightWallCheck
@onready var left_wall_check = $LeftWallCheck

@onready var hud_health_bar = $HUD/Control/HealthSection/ProgressBar
@onready var hud_ammo_label = $HUD/Control/WeaponSection/AmmoLabel
@onready var hud_weapon_name = $HUD/Control/WeaponSection/WeaponName

# State Variables
var speed: float = 5.0
var last_velocity_y: float = 0.0
var time_since_on_floor: float = 0.0
var wallrun_side: float = 1.0
var slide_velocity: Vector3 = Vector3.ZERO
var is_wallrunning: bool = false
var is_mantling: bool = false
var is_sliding: bool = false
var jump_buffer_timer: float = 0.0
var default_head_y: float = 0.0
var target_head_y: float = 0.0
var camera_shake_offset: Vector3 = Vector3.ZERO
var t_bob: float = 0.0
var inventory: Array = []
var current_weapon_index: int = 0

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Add existing guns to inventory
	inventory.append(gun1)
	inventory.append(gun2)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	camera.fov = base_fov
	default_head_y = head.position.y
	
	# Physics Configuration
	wall_min_slide_angle = 0.0
	floor_constant_speed = true
	
	target_head_y = default_head_y
	update_hud()

func switch_weapon(index: int):
	if index >= inventory.size() or index < 0: return
	for g in inventory: g.visible = false
	current_weapon_index = index
	gun1 = inventory[index]
	gun1.visible = true
	update_hud()

func take_damage(amount: float):
	current_health = clamp(current_health - amount, 0, max_health)
	update_hud()
	if current_health <= 0: die()

func update_hud():
	hud_health_bar.value = current_health
	if gun1 and gun1.stats:
		hud_ammo_label.text = str(gun1.current_mag) + " / " + str(gun1.reserve_ammo)
		hud_weapon_name.text = gun1.stats.weapon_name
	else:
		hud_ammo_label.text = "- / -"
		hud_weapon_name.text = "NONE"

func die():
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var sensitivity = ConfigManager.settings.gameplay.mouse_sensitivity
		rotate_y(-event.relative.x * sensitivity)
		eyes.rotate_x(-event.relative.y * sensitivity)
		eyes.rotation.x = clamp(eyes.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
		# Weapon Sway
		hand.rotation.y = lerp(hand.rotation.y, -event.relative.x * 0.005, 0.1)
		hand.rotation.x = lerp(hand.rotation.x, -event.relative.y * 0.005, 0.1)

func _physics_process(delta: float) -> void:
	# 1. TIMERS
	if is_on_floor():
		if last_velocity_y < -8.0: apply_landing_shake()
		time_since_on_floor = 0.0
		is_wallrunning = false
	else:
		time_since_on_floor += delta
		last_velocity_y = velocity.y
		
	if Input.is_action_just_pressed("jump"): jump_buffer_timer = jump_buffer
	else: jump_buffer_timer -= delta

	# 2. VAULT / WALLRUN LOGIC
	if is_mantling: return

	if not is_on_floor() and velocity.y < 3.0:
		handle_wallrun(delta)
		if wall_check.is_colliding() and not ledge_check.is_colliding() and not head_check.is_colliding():
			start_vault()

	# 3. COMBAT & INPUT
	handle_combat()
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Wall Sliding Fix
	if is_on_wall() and direction:
		var wall_normal = get_wall_normal()
		var dot = direction.dot(wall_normal)
		if dot < 0: direction = (direction - wall_normal * dot).normalized()
	
	handle_movement_logic(delta, direction, input_dir)
	handle_jumping()
	handle_effects(delta, input_dir)

	move_and_slide()

func handle_wallrun(delta: float):
	if not Input.is_action_pressed("run"):
		is_wallrunning = false
		return

	if right_wall_check.is_colliding():
		is_wallrunning = true
		wallrun_side = 1.0
	elif left_wall_check.is_colliding():
		is_wallrunning = true
		wallrun_side = -1.0
	else:
		is_wallrunning = false

	if is_wallrunning:
		velocity.y = lerp(velocity.y, 0.0, delta * 5.0)
		var wall_normal = right_wall_check.get_collision_normal() if wallrun_side == 1.0 else left_wall_check.get_collision_normal()
		var wall_forward = wall_normal.cross(Vector3.UP) * wallrun_side
		velocity = velocity.lerp(wall_forward * run_speed, delta * 5.0)

func handle_jumping():
	if jump_buffer_timer > 0.0:
		if time_since_on_floor < coyote_time:
			velocity.y = sqrt(jump_height * 2.0 * gravity * gravity_multiplier)
			jump_buffer_timer = 0.0
		elif is_wallrunning:
			var wall_normal = right_wall_check.get_collision_normal() if wallrun_side == 1.0 else left_wall_check.get_collision_normal()
			velocity = (wall_normal + Vector3.UP + (transform.basis * Vector3.FORWARD)).normalized() * wall_jump_force * 1.5
			is_wallrunning = false
			jump_buffer_timer = 0.0
		elif wall_check.is_colliding():
			var wall_normal = wall_check.get_collision_normal()
			velocity = (wall_normal + Vector3.UP).normalized() * wall_jump_force
			jump_buffer_timer = 0.0

func start_vault():
	is_mantling = true
	var hit_normal = wall_check.get_collision_normal()
	var target_up = global_position + Vector3(0, 2.5, 0)
	var target_forward = target_up + (-hit_normal * 1.5)
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_up, 0.15)
	tween.tween_property(self, "global_position", target_forward, 0.15)
	tween.finished.connect(func(): is_mantling = false)

func handle_movement_logic(delta: float, direction: Vector3, input_dir: Vector2):
	var is_sprinting = Input.is_action_pressed("run")
	var wants_crouch = Input.is_action_pressed("crouch")
	
	handle_sliding(delta, direction, is_sprinting, wants_crouch)
	
	if not is_sliding:
		if wants_crouch:
			speed = crouch_speed
			target_head_y = default_head_y + crouch_depth
		elif is_sprinting or is_wallrunning:
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
			if direction:
				velocity.x = lerp(velocity.x, direction.x * speed, air_control * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, air_control * delta)

	if not is_on_floor() and not is_wallrunning:
		velocity.y -= gravity * weight * delta

func handle_sliding(delta: float, direction: Vector3, is_sprinting: bool, wants_crouch: bool):
	if Input.is_action_just_pressed("crouch") and is_sprinting and is_on_floor() and not is_sliding:
		is_sliding = true
		slide_velocity = direction * (speed + slide_speed_boost)
		target_head_y = default_head_y + crouch_depth
	elif not wants_crouch or not is_on_floor():
		is_sliding = false
	
	if is_sliding:
		velocity.x = slide_velocity.x
		velocity.z = slide_velocity.z
		slide_velocity *= slide_decay
		if slide_velocity.length() < walk_speed: is_sliding = false

func handle_effects(delta, input_dir):
	var target_fov = base_fov
	if Input.is_action_pressed("right_click"): target_fov = base_fov * 0.7
	elif is_sliding: target_fov = slide_fov
	elif Input.is_action_pressed("run") or is_wallrunning: target_fov = sprint_fov
	camera.fov = lerp(camera.fov, target_fov, delta * 12.0)
	
	var target_tilt = -input_dir.x * lean_amount
	if is_sliding: target_tilt += lean_amount * 2.0
	if is_wallrunning: target_tilt += deg_to_rad(15.0 * wallrun_side)
	camera.rotation.z = lerp(camera.rotation.z, target_tilt, delta * lean_speed)
	
	head.position.y = lerp(head.position.y, target_head_y, delta * crouch_lerp_speed)
	handle_camera_bob(delta)
	camera_shake_offset = camera_shake_offset.lerp(Vector3.ZERO, delta * 10.0)
	hand.rotation = hand.rotation.lerp(Vector3.ZERO, 8.0 * delta)

func handle_camera_bob(delta):
	var breathe = sin(Time.get_ticks_msec() * 0.001) * 0.005
	if velocity.length() > 1.0 and is_on_floor() and not is_sliding:
		t_bob += delta * velocity.length()
		var pos = Vector3(cos(t_bob * 1.2) * 0.05, sin(t_bob * 2.4) * 0.05, 0)
		camera.transform.origin = camera.transform.origin.lerp(pos + camera_shake_offset, delta * 15.0)
	else:
		camera.transform.origin = camera.transform.origin.lerp(Vector3(0, breathe, 0) + camera_shake_offset, delta * 10.0)

func handle_combat():
	if Input.is_action_just_pressed("left_click") and gun1.has_method("Shoot"):
		if gun1.Shoot():
			apply_recoil_shake()
			shoot_raycast()
			update_hud()
	if Input.is_action_just_pressed("reload") and gun1.has_method("Reload"):
		gun1.Reload()
		update_hud()
	if Input.is_action_just_pressed("weapon1"): switch_weapon(0)
	elif Input.is_action_just_pressed("weapon2"): switch_weapon(1)

func apply_landing_shake(): camera_shake_offset = Vector3(0, -landing_shake_intensity, 0)
func apply_recoil_shake():
	camera_shake_offset.y += 0.05
	eyes.rotation.x += 0.02

func shoot_raycast():
	var space_state = get_world_3d().direct_space_state
	var center = get_viewport().get_size() / 2
	var from = camera.project_ray_origin(center)
	var to = from + camera.project_ray_normal(center) * 100.0
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	var result = space_state.intersect_ray(query)
	if result:
		var target = result.collider
		if target.has_method("take_damage"): target.take_damage(20)
