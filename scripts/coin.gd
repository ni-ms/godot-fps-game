extends Area3D

var main: Node3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and main:
		print("Player touched the coin!")
		main.add_point()
		queue_free()
