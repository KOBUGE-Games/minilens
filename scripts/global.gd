extends Node
# This script is used by others to:
#  1. Change the current scene
#  2. Set/Get the amount of locked levels in a pack
#  3. Keep the aspect ratio

var root
var current_scene
var orig_size
var viewport
var input_mode
var is_first_load = true
var version = 1.2

func _ready():
	randomize()
	root = get_tree().get_root()
	viewport = get_viewport()
	current_scene = root.get_child(root.get_child_count()-1)
	orig_size = Vector2(1024,768)
	viewport.connect("size_changed",self,"window_resize")
	window_resize()
	OS.set_window_title(str("Minilens - Version ", version))

func window_resize():
	var window_size = OS.get_window_size()
	var changed = false
	if(window_size.x < 100):
		window_size.x = 100
		changed = true
	if(window_size.y < 100):
		window_size.y = 100
		changed = true
	if(changed):
		OS.set_window_size(window_size)
	var scale_factor = orig_size.y/window_size.y
	var new_size = Vector2(window_size.x*scale_factor, orig_size.y)
	viewport.set_size_override(true, new_size)

func load_scene(var path):
	is_first_load = false # Disable showing splashes
	current_scene.queue_free() # Destroy the current scene
	current_scene = load(path).instance()
	root.add_child(current_scene) # And add the requested one
	
func load_level(var pack, var level):
	load_scene("res://main/main.tscn")
	print(current_scene.get_name())
	current_scene.get_node("level_holder").load_level(pack, level)
	
# The format of saves is like:
#<packname> <level reached>
#<other_packname> <level reached>
#...
func get_reached_level(var pack):
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://savedata.bin",File.READ,str("minilens",OS.get_unique_ID()))
	if(!err):
		var next_line = f.get_line()
		while(!f.eof_reached()): # We read line by line until we find the needed one
			var parse = next_line.split(" ")
			if(parse[0] == pack):
				f.close() # Allways close files (just in case the engine doesn't do it after the error)
				return int(parse[1])
			next_line = f.get_line()
	
	f.close() # Close the file after we are finished
	return 1 # If we either haven't found the pack, or we failed to open the savedata, we just return one (e.g. first level)
	
func set_reached_level(var pack, var value):
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://savedata.bin",File.READ,str("minilens",OS.get_unique_ID()))
	if(err): # If the file doesn't exist, we try to write to it first
		f.close()
		f.open_encrypted_with_pass("user://savedata.bin",File.WRITE,str("minilens",OS.get_unique_ID()))
		f.store_line("_ 1")
		f.close()
		err = f.open_encrypted_with_pass("user://savedata.bin",File.READ,str("minilens",OS.get_unique_ID()))
	if(!err):
		var data = []
		var found = false
		var next_line = f.get_line()
		while(!f.eof_reached()): # First we read line by line
			var parse = next_line.split(" ")
			data.append([parse[0],int(parse[1])])
			if(parse[0] == pack):
				found = true
				data[data.size() - 1][1] = max(data[data.size() - 1][1], value) # If we reach the needed pack, we just set the amount we've read to value
			next_line = f.get_line()
		if(!found):
			data.append([pack,value])
		f.close()
		var err = f.open_encrypted_with_pass("user://savedata.bin",File.WRITE,str("minilens",OS.get_unique_ID()))
		if(!err): # Then we rewrite everything
			for line in data:
				f.store_line(str(line[0]," ",line[1]))
	f.close()
