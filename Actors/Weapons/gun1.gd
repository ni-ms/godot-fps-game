extends Node3D

@export var stats: WeaponStats

@onready var AnimPlayer = $AnimationPlayer
@onready var GunSound = $shot

# --- STATE ---
var current_mag: int
var reserve_ammo: int
var default_position: Vector3
var default_rotation: Vector3
var ads_lerp: float = 0.0
var weapon_recoil_pos: Vector3 = Vector3.ZERO
var weapon_recoil_rot: float = 0.0
var current_sway: Vector2 = Vector2.ZERO

func _ready():
	if stats:
		current_mag = stats.mag_size
		reserve_ammo = stats.reserve_ammo
	default_position = position
	default_rotation = rotation

func _physics_process(delta: float) -> void:
	if not stats: return
	
	# 1. ADS LERP
	var target_ads = 1.0 if Input.is_action_pressed("right_click") else 0.0
	ads_lerp = lerp(ads_lerp, target_ads, delta * 15.0)
	
	# 2. SWAY CALCULATION
	var mouse_input = Input.get_last_mouse_velocity() * 0.001
	current_sway = current_sway.lerp(Vector2(mouse_input.x, mouse_input.y), delta * stats.sway_lerp)
	
	# 3. APPLY PROCEDURAL POSITION
	var target_pos = default_position.lerp(stats.ads_position, ads_lerp)
	position = target_pos + weapon_recoil_pos
	
	# Rotate for recoil and sway
	rotation.x = lerp_angle(rotation.x, default_rotation.x + weapon_recoil_rot + (current_sway.y * stats.sway_amount), delta * 10.0)
	rotation.y = lerp_angle(rotation.y, default_rotation.y + (-current_sway.x * stats.sway_amount), delta * 10.0)
	rotation.z = default_rotation.z
	
	# 4. RECOIL RECOVERY
	weapon_recoil_pos = weapon_recoil_pos.lerp(Vector3.ZERO, delta * stats.recoil_return_speed)
	weapon_recoil_rot = lerp(weapon_recoil_rot, 0.0, delta * stats.recoil_return_speed)

func Shoot() -> bool:
	if not stats or current_mag <= 0:
		return false
		
	current_mag -= 1
	
	# Procedural Kick
	weapon_recoil_pos.z += stats.recoil_kick
	weapon_recoil_rot -= stats.recoil_rotation
	
	GunSound.set_pitch_scale(randf_range(.7,.9))
	GunSound.play()
	if not AnimPlayer.is_playing():
		AnimPlayer.play("gun")
		
	return true

func Reload():
	if not stats or current_mag == stats.mag_size or reserve_ammo <= 0: return
	
	var amount_needed = stats.mag_size - current_mag
	var refill = min(amount_needed, reserve_ammo)
	
	current_mag += refill
	reserve_ammo -= refill
	
	if AnimPlayer.has_animation("reload"):
		AnimPlayer.play("reload")
