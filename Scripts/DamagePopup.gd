extends Node3D

@onready var label = $Label3D

var value: int = 0
var velocity: Vector3 = Vector3(0, 2, 0)
var gravity: float = 4.0
var lifetime: float = 1.0

func _ready():
	label.text = str(value)
	# Randomize horizontal velocity slightly
	velocity.x = randf_range(-1, 1)
	velocity.z = randf_range(-1, 1)

func _process(delta):
	position += velocity * delta
	velocity.y -= gravity * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	scale = lerp(scale, Vector3.ZERO, delta * 2.0)
