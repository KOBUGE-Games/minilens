
extends Node

const INPUT_AREAS = 0
const INPUT_BUTTONS = 1

const default_settings = {
	fullscreen = false,
	music = true, 
	sound = true,
	input_mode = INPUT_AREAS
}
const DATA_DELIMITER = ":"

var options_path = "user://options.txt"
var cache = default_settings

func read_settings():
	# Read the file
	var settings_lines = FileManager.get_file_lines(options_path)
	
	if settings_lines.size() == 0: # Either no data was stored, or the file wasn't there, save first
		save_settings(default_settings)
		settings_lines = FileManager.get_file_lines(options_path)
	
	var data = default_settings
	
	
	for line in settings_lines:
		var line_parts = line.split(DATA_DELIMITER)
		if line_parts.size() >= 2 and default_settings.has(line_parts[0]):
			var data_type = typeof(default_settings[line_parts[0]])
			if data_type == TYPE_BOOL:
				data[line_parts[0]] = (line_parts[1] == str(true))
			else:
				data[line_parts[0]] = convert(line_parts[1], data_type)
	
	cache = data
	return data

func get_settings():
	return cache

func save_settings(data):
	var lines = []
	for setting in default_settings:
		var data_line = default_settings[setting]
		if data.has(setting):
			data_line = convert(data[setting], typeof(default_settings[setting]))
		lines.push_back(str(setting, DATA_DELIMITER, data_line))
	
	FileManager.set_file_lines(options_path, lines)
	read_settings() # Updating cache
