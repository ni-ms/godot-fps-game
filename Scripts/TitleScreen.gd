extends Control

@onready var test_range_button = $CenterContainer/VBoxContainer/MenuButtons/TestRangeButton
@onready var map_button = $CenterContainer/VBoxContainer/MenuButtons/MapButton
@onready var settings_button = $CenterContainer/VBoxContainer/MenuButtons/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton

func _ready():
	test_range_button.pressed.connect(_on_test_range_pressed)
	map_button.pressed.connect(_on_map_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Ensure mouse is visible menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_test_range_pressed():
	get_tree().change_scene_to_file("res://Scene/TestRange.tscn")

func _on_map_pressed():
	get_tree().change_scene_to_file("res://Scene/Map.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scene/SettingsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
