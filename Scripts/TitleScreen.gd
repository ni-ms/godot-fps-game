extends Control

@onready var start_button = $CenterContainer/VBoxContainer/MenuButtons/StartButton
@onready var quit_button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Ensure mouse is visible menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scene/Map.tscn")

func _on_quit_pressed():
	get_tree().quit()
