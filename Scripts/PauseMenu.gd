extends CanvasLayer

@onready var resume_button = $Control/CenterContainer/VBoxContainer/Buttons/ResumeButton
@onready var main_menu_button = $Control/CenterContainer/VBoxContainer/Buttons/MainMenuButton
@onready var quit_button = $Control/CenterContainer/VBoxContainer/Buttons/QuitButton
@onready var control = $Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	control.hide()
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	
	if new_pause_state:
		control.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		control.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	toggle_pause()

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/TitleScreen.tscn")

func _on_quit_pressed():
	get_tree().quit()
