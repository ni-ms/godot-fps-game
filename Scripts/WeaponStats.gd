extends Resource
class_name WeaponStats

@export var weapon_name: String = "Weapon"
@export var mag_size: int = 30
@export var reserve_ammo: int = 90
@export var damage: float = 20.0

@export_group("Visuals & Feel")
@export var ads_position: Vector3 = Vector3(-0.5, 0.38, 0.4)
@export var ads_fov_multiplier: float = 0.7
@export var recoil_kick: float = 0.2
@export var recoil_rotation: float = 0.1
@export var recoil_return_speed: float = 12.0

@export_group("Animations")
@export var shoot_animation: String = "shoot"
@export var reload_animation: String = "reload"

@export_group("Sway")
@export var sway_amount: float = 0.03
@export var sway_lerp: float = 5.0
