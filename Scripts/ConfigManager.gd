extends Node

const SAVE_PATH = "user://settings.cfg"

var config = ConfigFile.new()

var settings = {
	"video": {
		"fullscreen": true,
		"glow": true
	},
	"audio": {
		"master_volume": 0.8
	},
	"gameplay": {
		"mouse_sensitivity": 0.002
	},
	"controls": {
		"forward": KEY_W,
		"back": KEY_S,
		"left": KEY_A,
		"right": KEY_D,
		"jump": KEY_SPACE,
		"run": KEY_SHIFT,
		"crouch": KEY_CTRL,
		"reload": KEY_R
	}
}

func _ready():
	load_settings()
	apply_settings()

func save_settings():
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK: return
	
	for section in settings.keys():
		for key in settings[section].keys():
			settings[section][key] = config.get_value(section, key, settings[section][key])

func apply_settings():
	# Video
	if settings.video.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	# Input Map
	for action in settings.controls.keys():
		var keycode = settings.controls[action]
		var event = InputEventKey.new()
		event.physical_keycode = keycode
		
		# Clear existing events for this action
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)
