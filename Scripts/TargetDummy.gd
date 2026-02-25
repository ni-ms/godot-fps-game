extends CharacterBody3D

@export var health: float = 100.0
@export var damage_popup_scene: PackedScene = preload("res://Scene/DamagePopup.tscn")

func take_damage(amount: int):
	health -= amount
	spawn_popup(amount)
	
	# Visual feedback (flash red)
	var tween = create_tween()
	tween.tween_property($CSGMesh3D, "material_override:albedo_color", Color.RED, 0.1)
	tween.tween_property($CSGMesh3D, "material_override:albedo_color", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func spawn_popup(amount: int):
	var popup = damage_popup_scene.instantiate()
	popup.value = amount
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector3(0, 1.5, 0)

func die():
	queue_free()
