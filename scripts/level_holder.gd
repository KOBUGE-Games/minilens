
extends Node2D

var level_scene
var current_pack
var current_level
var player
var level_node

func load_level(var pack, var level):
	level_scene = load(str("res://levels/", pack, "/level_", level, ".xml"))
	for i in range(get_child_count()):
		get_child(i).queue_free()
	level_node = level_scene.instance()
	add_child(level_node)
	player.set_pos(level_node.get_node("start").get_pos() + Vector2(32,32))
	player.level_load(level_node)

func _ready():
	player = get_node("../player_holder/player")
	load_level("tutorial", 1)


