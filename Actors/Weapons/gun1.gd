extends Node3D

@onready var AnimPlayer = $AnimationPlayer
@onready var GunSound = $shot


func _ready():
	pass
	
func Shoot():
	if AnimPlayer.is_playing():
		pass
	else:
		AnimPlayer.play("gun")
		GunSound.set_pitch_scale(randf_range(.7,.9))
