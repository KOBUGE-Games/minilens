
extends Node

var is_first_load = true # Disable showing splashes after the first time
var game_scene_path = "res://main/main.tscn"

func load_scene(path):
	is_first_load = false
	var scene = load(path).instance()
	get_tree().get_current_scene().queue_free()
	get_tree().get_root().add_child(scene)
	get_tree().set_current_scene(scene)
	
func load_level(pack, level):
	load_scene(game_scene_path)
	_set_level(pack, level)

func _set_level(pack, level):
	var current_scene = get_tree().get_current_scene()
	if current_scene.has_node("level_holder"):
		current_scene.get_node("level_holder").load_level(pack, level)
	else:
		call_deferred("_set_level", pack, level)
	
