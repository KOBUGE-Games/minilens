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
	
	
