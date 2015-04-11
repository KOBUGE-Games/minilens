
extends Node2D

var level_scene
var current_pack
var current_level
var player
var level_node
var goals_left = 0
var global

func load_level(var pack, var level):
	current_level = level
	current_pack = pack
	var f = File.new()
	var err = f.open(str("res://levels/", pack, "/level_", level, ".xml"), f.READ)
	if(err != 0):
		back_to_menu()
		return
	f.close()
	level_scene = load(str("res://levels/", pack, "/level_", level, ".xml"))
	if(level_node):
		var music = level_node.get_node("music")
		if(music):
			music.stop()
	for i in range(get_child_count()):
		get_child(i).queue_free()
	level_node = level_scene.instance()
	goals_left = 0
	add_child(level_node)
	var music = level_node.get_node("music")
	if(music):
		music.play()
	player.set_pos(level_node.get_node("start").get_pos())
	player.set_z(0)
	player.level_load(level_node)

func retry_level():
	load_level(current_pack, current_level)

func goal_take():
	goals_left = goals_left - 1
	if(goals_left == 0):
		global.increase_reached_level(current_pack)
		load_level(current_pack, int(current_level) + 1)
	
func goal_add():
	goals_left = goals_left + 1

func _input(event):
	if(event.is_action("retry") && event.is_pressed() && !event.is_echo()):
		retry_level()

func _ready():
	global = get_node("/root/global")
	player = get_node("../player_holder/player")
	set_process_input(true)

func back_to_menu():
	global.load_scene("res://scenes/main_menu.xml")
