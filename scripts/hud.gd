extends CanvasLayer

@onready var score_label = $ScoreLabel
func _ready():
	print("HUD is ready:", $ScoreLabel)

func set_score(score: int) -> void:
	score_label.text = "Score: %d" % score
