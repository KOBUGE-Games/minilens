
extends Control

onready var settings = get_node("settings")

func _ready():
	# Populating options
	var current_options = SettingsManager.read_settings()
	
	for i in current_options:
		set_option(i, current_options[i]) # Remeber last values
	
	var bool_options = ["fullscreen", "music", "sound", "input_mode"]
	
	for bool_option_name in bool_options:
		var option_control = settings.get_node(bool_option_name)
		
		if bool_option_name == "input_mode":
			option_control.add_item("Touch areas", SettingsManager.INPUT_AREAS)
			option_control.add_item("Touch buttons", SettingsManager.INPUT_BUTTONS)
		else:
			option_control.add_item("Off")
			option_control.add_item("On")
		
		if current_options.has(bool_option_name):
			option_control.select(int(current_options[bool_option_name]))
		
		option_control.connect("item_selected", self, "option_item_selected", [bool_option_name])
	
	# Hide touch input modes on non-touch-based platforms
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		settings.get_node("input_mode_label").hide()
		settings.get_node("input_mode").hide()

func option_item_selected(var ID, var setting):
	var current_options = SettingsManager.read_settings()
	
	current_options[setting] = settings.get_node(setting).get_selected()
	set_option(setting, current_options[setting])

	SettingsManager.save_settings(current_options)

func set_option(var setting, var value):
	if setting == "fullscreen":
		OS.set_window_fullscreen(bool(int(value)))
	elif setting == "music":
		var bool_music = bool(int(value))
		var music_node = get_node("../music")
		if bool_music:
			music_node.play()
		else:
			music_node.stop()
