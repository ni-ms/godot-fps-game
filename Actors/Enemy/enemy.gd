extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@export var speed: float = 6.0
@export var health: int = 30

# We will set the target (the player) via the main level script
var player = null

func _physics_process(delta):
	if player:
		nav_agent.target_position = player.global_position
		
	if nav_agent.is_navigation_finished():
		return

	var current_agent_position = global_position
	var next_path_position = nav_agent.get_next_path_position()
	
	# Calculate velocity
	var new_velocity = (next_path_position - current_agent_position).normalized() * speed
	velocity = new_velocity
	move_and_slide()
	
	# Look at player (simple billboard effect)
	if player:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))

func take_damage(amount: int):
	health -= amount
	# Add a "hit" flash effect here if you have time
	if health <= 0:
		die()

func die():
	queue_free()
	# Add score to a global singleton here
