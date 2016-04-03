
extends Control

var option_config = {
	fullscreen = TYPE_BOOL,
	music = TYPE_BOOL,
	sound = TYPE_BOOL,
	input_mode = {"Touch areas": SettingsManager.INPUT_AREAS, "Touch buttons": SettingsManager.INPUT_BUTTONS}
}

onready var settings = get_node("settings")

func _ready():
	# Populating options
	var current_options = SettingsManager.read_settings()
	
	for i in current_options:
		set_option(i, current_options[i]) # Remeber last values
		
	for option_name in option_config:
		var current_option_config = {}
		var option_control = settings.get_node(option_name)
		
		if typeof(option_config[option_name]) == TYPE_INT:
			if option_config[option_name] == TYPE_BOOL:
				current_option_config = {"Off": false, "On": true}
		else:
			current_option_config = option_config[option_name]
		
		var reached = 0
		for key in current_option_config:
			option_control.add_item(key)
			option_control.set_item_metadata(reached, current_option_config[key])
			
			if current_options.has(option_name) and current_options[option_name] == current_option_config[key]:
				option_control.select(reached)
			
			reached += 1
		
		option_control.connect("item_selected", self, "option_item_selected", [option_name])
	
	# Hide touch input modes on non-touch-based platforms
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		settings.get_node("input_mode_label").hide()
		settings.get_node("input_mode").hide()

func option_item_selected(ID, setting):
	var current_options = SettingsManager.read_settings()
	
	current_options[setting] = settings.get_node(setting).get_selected_metadata()
	set_option(setting, current_options[setting])

	SettingsManager.save_settings(current_options)

func set_option(setting, value):
	if setting == "fullscreen":
		OS.set_window_fullscreen(bool(int(value)))
	elif setting == "music":
		var bool_music = bool(int(value))
		var music_node = get_node("../music")
		if bool_music:
			music_node.play()
		else:
			music_node.stop()
