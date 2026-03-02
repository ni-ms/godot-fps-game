extends Control

@onready var fullscreen_toggle = $MarginContainer/VBoxContainer/TabContainer/VIDEO/Fullscreen/CheckButton
@onready var sensitivity_slider = $MarginContainer/VBoxContainer/TabContainer/GAMEPLAY/Sensitivity/HSlider
@onready var save_button = $MarginContainer/VBoxContainer/Buttons/SaveButton
@onready var back_button = $MarginContainer/VBoxContainer/Buttons/BackButton

func _ready():
	# Sync UI with current settings
	fullscreen_toggle.button_pressed = ConfigManager.settings.video.fullscreen
	sensitivity_slider.value = ConfigManager.settings.gameplay.mouse_sensitivity
	
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Future: Populate Controls tab dynamically
	_setup_controls_tab()

func _setup_controls_tab():
	var controls_container = $MarginContainer/VBoxContainer/TabContainer/CONTROLS/VBoxContainer
	for action in ConfigManager.settings.controls.keys():
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = action.to_upper()
		label.custom_minimum_size = Vector2(250, 0)
		
		var button = Button.new()
		var keycode = ConfigManager.settings.controls[action]
		button.text = OS.get_keycode_string(keycode)
		button.custom_minimum_size = Vector2(100, 40)
		
		hbox.add_child(label)
		hbox.add_child(button)
		controls_container.add_child(hbox)

func _on_save_pressed():
	ConfigManager.settings.video.fullscreen = fullscreen_toggle.button_pressed
	ConfigManager.settings.gameplay.mouse_sensitivity = sensitivity_slider.value
	
	# Apply and Save
	ConfigManager.apply_settings()
	ConfigManager.save_settings()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scene/TitleScreen.tscn")
