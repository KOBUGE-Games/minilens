extends Node
#This script is used by others to:
# 1. change the current scene
# 2. Set/Get the amount of locked levels in a pack
var root
var current_scene

func _ready():
	root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count()-1)

func load_scene(var path):
	current_scene.queue_free() # Destroy the current scene
	current_scene = load(path).instance()
	root.add_child(current_scene) # And add the requested one
	
func load_level(var pack, var level):
	load_scene("res://scenes/main.xml")
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
		while(!f.eof_reached()): #We read line by line until we find the needed one
			var parse = next_line.split(" ")
			if(parse[0] == pack):
				f.close() # allways close files (just in case the engine doesn't)
				return int(parse[1])
			next_line = f.get_line()
	f.close() # allways close files (just in case the engine doesn't)
	return 1 # If we either haven't found our pack, or we failed to open the savedata, we just return one(e.g. first level)
	
func increase_reached_level(var pack):
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
				data[data.size() - 1][1] = data[data.size() - 1][1] + 1 # if we reach the needed pack, we just increase the amount we've read by one
			next_line = f.get_line()
		if(!found):
			data.append([pack,2])
		f.close()
		var err = f.open_encrypted_with_pass("user://savedata.bin",File.WRITE,str("minilens",OS.get_unique_ID()))
		if(!err):# then we rewrite everything
			for line in data:
				f.store_line(str(line[0]," ",line[1]))
	f.close()
