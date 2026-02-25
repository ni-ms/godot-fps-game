extends Node3D

@onready var AnimPlayer = $AnimationPlayer
@onready var GunSound = $shot

# --- CONFIGURATION ---
@export var weapon_name: String = "PISTOL"
@export var mag_size: int = 15
@export var reserve_ammo: int = 45
var current_mag: int = mag_size

@export var ads_position: Vector3 = Vector3(-0.5, 0.45, 0.45) 
@export var ads_fov_multiplier: float = 0.8

@export_category("Procedural Recoil")
@export var recoil_kick: float = 0.1
@export var recoil_rotation: float = 0.2
@export var recoil_return_speed: float = 20.0

@export_category("Sway")
@export var sway_amount: float = 0.02
@export var sway_lerp: float = 8.0

# --- STATE ---
var default_position: Vector3
var default_rotation: Vector3
var ads_lerp: float = 0.0
var weapon_recoil_pos: Vector3 = Vector3.ZERO
var weapon_recoil_rot: float = 0.0
var current_sway: Vector2 = Vector2.ZERO

func _ready():
	default_position = position
	default_rotation = rotation

func _physics_process(delta: float) -> void:
	var target_ads = 1.0 if Input.is_action_pressed("right_click") else 0.0
	ads_lerp = lerp(ads_lerp, target_ads, delta * 15.0)
	var mouse_input = Input.get_last_mouse_velocity() * 0.001
	current_sway = current_sway.lerp(Vector2(mouse_input.x, mouse_input.y), delta * sway_lerp)
	var target_pos = default_position.lerp(ads_position, ads_lerp)
	position = target_pos + weapon_recoil_pos
	rotation.x = lerp_angle(rotation.x, default_rotation.x + weapon_recoil_rot + (current_sway.y * sway_amount), delta * 10.0)
	rotation.y = lerp_angle(rotation.y, default_rotation.y + (-current_sway.x * sway_amount), delta * 10.0)
	weapon_recoil_pos = weapon_recoil_pos.lerp(Vector3.ZERO, delta * recoil_return_speed)
	weapon_recoil_rot = lerp(weapon_recoil_rot, 0.0, delta * recoil_return_speed)

func Shoot() -> bool:
	if current_mag <= 0: return false
	current_mag -= 1
	weapon_recoil_pos.z += recoil_kick
	weapon_recoil_rot -= recoil_rotation
	GunSound.set_pitch_scale(randf_range(1.1, 1.3)) # Higher pitch for pistol
	GunSound.play()
	if not AnimPlayer.is_playing():
		AnimPlayer.play("gun")
	return true

func Reload():
	if current_mag == mag_size or reserve_ammo <= 0: return
	var refill = min(mag_size - current_mag, reserve_ammo)
	current_mag += refill
	reserve_ammo -= refill
