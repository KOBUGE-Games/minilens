
extends Node2D

var level_scene
var current_pack
var current_level
var player
var level_node
var goals_left = 0
var global
var btn2_action = 0
var time_until_popup = 0

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

func goal_take(var wait = 0):
	time_until_popup = wait
	goals_left = goals_left - 1
	if(goals_left == 0):
		global.set_reached_level(current_pack,current_level + 1)
		btn2_action = 1
		show_popup("Good job!","Level passed")

func prompt_retry_level():
	btn2_action = 0
	show_popup("You died","Your robot was destroyed!\n Do you want to try again?")

func next_level():
	load_level(current_pack, int(current_level) + 1)

func goal_add():
	goals_left = goals_left + 1

func _input(event):
	if(event.is_action("retry") && event.is_pressed() && !event.is_echo()):
		retry_level()

func _ready():
	global = get_node("/root/global")
	player = get_node("../player_holder/player")
	get_node("../gui/CanvasLayer/retry").set_focus_mode(Control.FOCUS_NONE)
	get_node("../gui/CanvasLayer/popup/body/btn1").connect("pressed", self, "popup_btn1_pressed")
	get_node("../gui/CanvasLayer/popup/body/btn2").connect("pressed", self, "popup_btn2_pressed")
	get_node("../gui/CanvasLayer/popup/body/btn3").connect("pressed", self, "popup_btn3_pressed")
	set_process_input(true)

func back_to_menu():
	global.load_scene("res://scenes/main_menu.xml")

func show_popup(var title, var text):
	var popup = get_node("../gui/CanvasLayer/popup")
	popup.get_node("header/title").set_text(title)
	popup.get_node("body/text").set_text(text)
	if(btn2_action == 1):
		popup.get_node("body/btn2").set_disabled(false)
	else:
		popup.get_node("body/btn2").set_disabled(true)
	set_process(true)
func _process(delta):
	time_until_popup = time_until_popup - delta
	if(time_until_popup <= 0):
		var popup = get_node("../gui/CanvasLayer/popup")
		player.set_fixed_process(false)
		popup.show()
		set_process(false)

func hide_popup():
	var popup = get_node("../gui/CanvasLayer/popup")
	popup.hide()
	

func popup_btn1_pressed():
	retry_level()
	hide_popup()
func popup_btn2_pressed():
	if(btn2_action == 1):
		btn2_action = 0
		next_level()
		hide_popup()
func popup_btn3_pressed():
	back_to_menu()
	hide_popup()
