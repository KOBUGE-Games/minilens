extends Node

var root
var current_scene

func _ready():
	root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count()-1)

func load_scene(var path):
	current_scene.queue_free()
	current_scene = load(path).instance()
	root.add_child(current_scene)
	
func load_level(var pack, var level):
	load_scene("res://scenes/main.xml")
	current_scene.get_node("level_holder").load_level(pack, level)
	
func get_reached_level(var pack):
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://savedata.bin",File.READ,str("minilens",OS.get_unique_ID()))
	if(!err):
		var next_line = f.get_line()
		while(!f.eof_reached()):
			var parse = next_line.split(" ")
			if(parse[0] == pack):
				f.close()
				return int(parse[1])
			next_line = f.get_line()
	f.close()
	return 1
	
func increase_reached_level(var pack):
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://savedata.bin",File.READ,str("minilens",OS.get_unique_ID()))
	if(err):
		f.close()
		f.open_encrypted_with_pass("user://savedata.bin",File.WRITE,str("minilens",OS.get_unique_ID()))
		f.store_line("_ 1")
		f.close()
		err = f.open_encrypted_with_pass("user://savedata.bin",File.READ,str("minilens",OS.get_unique_ID()))
	if(!err):
		var data = []
		var found = false
		var next_line = f.get_line()
		while(!f.eof_reached()):
			var parse = next_line.split(" ")
			data.append([parse[0],int(parse[1])])
			if(parse[0] == pack):
				found = true
				data[data.size() - 1][1] = data[data.size() - 1][1] + 1
			next_line = f.get_line()
		if(!found):
			data.append([pack,2])
		f.close()
		var err = f.open_encrypted_with_pass("user://savedata.bin",File.WRITE,str("minilens",OS.get_unique_ID()))
		if(!err):
			for line in data:
				f.store_line(str(line[0]," ",line[1]))
	f.close()
