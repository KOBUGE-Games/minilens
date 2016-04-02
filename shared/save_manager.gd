
extends Node

const DATA_DELIMITER = " "

var save_path = "user://savedata.bin"

func _ready():
	FileManager.set_file_password(save_path, str("minilens", OS.get_unique_ID())) # Set the password

func get_reached_level(pack):
	var save_lines = FileManager.get_file_lines(save_path) # Read the file
	
	for line in save_lines:
		var line_parts = line.split(DATA_DELIMITER)
		if line_parts.size() >= 2:
			if line_parts[0] == pack:
				return int(line_parts[1])
	
	return 1 # If we either haven't found the pack, or we failed to open the savedata, we just return one (e.g. first level)

func set_reached_level(pack, value):
	var current_save_lines = FileManager.get_file_lines(save_path)
	var future_save_lines = []
	var reached_set = false
	
	for line in current_save_lines:
		var line_parts = line.split(DATA_DELIMITER)
		if line_parts.size() >= 2:
			if line_parts[0] == pack:
				reached_set = true
				future_save_lines.push_back(str(pack, DATA_DELIMITER, value))
			else:
				future_save_lines.push_back(line)
	
	if !reached_set:
		future_save_lines.push_back(str(pack, DATA_DELIMITER, value))
	
	FileManager.set_file_lines(save_path, future_save_lines)
