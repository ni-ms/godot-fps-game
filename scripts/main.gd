extends Node3D

var score: int = 0

func _ready() -> void:
	print("main is ready")
	update_score()
	for coin in $Coins.get_children(): 
		coin.main = self


func add_point() -> void:
	score += 1
	update_score()

func update_score() -> void:
	$hud.set_score(score)
