
extends Node2D

var level_scene
var current_pack
var current_level
var player
var level_node
var goals_left = 0

func load_level(var pack, var level):
	current_level = level
	current_pack = pack
	level_scene = load(str("res://levels/", pack, "/level_", level, ".xml"))
	for i in range(get_child_count()):
		get_child(i).queue_free()
	level_node = level_scene.instance()
	goals_left = 0
	add_child(level_node)
	player.set_pos(level_node.get_node("start").get_pos())
	player.set_z(0)
	player.level_load(level_node)

func retry_level():
	load_level(current_pack, current_level)

func goal_take():
	goals_left = goals_left - 1
	if(goals_left == 0):
		load_level(current_pack, int(current_level) + 1)
	
func goal_add():
	goals_left = goals_left + 1

func _input(event):
	if(event.is_action("retry") && event.is_pressed() && !event.is_echo()):
		retry_level()

func _ready():
	player = get_node("../player_holder/player")
	set_process_input(true)


