extends Node2D
# this script serves to hold the levels, and to manage them
var level_scene # The scene containing the level
var current_pack # The current pack/level
var current_level
var player # The player ofc
var level_node # the Node with the level
var goals_left = 0 # the amount of goals left to be taken
var global # the global node (serves like a library, see global.gd)
var btn2_action = 0 # Can we move left, when we press the secound button
var time_until_popup = 0 # How much time should we wait 

func load_level(var pack, var level): # Load level N from pack P
	current_level = level
	current_pack = pack
	# try to open the level
	var f = File.new()
	var err = f.open(str("res://levels/", pack, "/level_", level, ".xml"), f.READ)
	if(err != 0):# if we are unable to open it, we return to the menu instead of crashing
		back_to_menu()
		return
	f.close()
	level_scene = load(str("res://levels/", pack, "/level_", level, ".xml"))
	# Remove every currently loaded level
	for i in range(get_child_count()):
		get_child(i).queue_free()
	level_node = level_scene.instance() # instance the new level
	goals_left = 0 # reset the counter
	add_child(level_node) # add that node to the scene
	player.set_pos(level_node.get_node("start").get_pos()) # Teleport the player to his new location
	player.set_z(0)
	player.level_load(level_node) # Have the player prepare to play..

func retry_level(): # Retry the current level
	load_level(current_pack, current_level)

func goal_take(var wait = 0): # Called when a goal is taken
	time_until_popup = wait
	goals_left = goals_left - 1
	if(goals_left == 0): # no more goals ;(
		global.set_reached_level(current_pack,current_level + 1)
		btn2_action = 1 # can pass
		show_popup("Good job!","Level passed")

func prompt_retry_level(): # Called when the robot dies
	btn2_action = 0
	show_popup("You died","Your robot was destroyed!\n Do you want to try again?")

func next_level(): # go to the next level
	load_level(current_pack, int(current_level) + 1)

func goal_add(): # Add one more goal
	goals_left = goals_left + 1

func _input(event):
	if(event.is_action("retry") && event.is_pressed() && !event.is_echo()):
		retry_level()

func _ready():
	# Find nodes
	global = get_node("/root/global")
	player = get_node("../player_holder/player")
	#Removes the focus from the retry button
	get_node("../gui/CanvasLayer/retry").set_focus_mode(Control.FOCUS_NONE)
	#Connect the popup buttons
	get_node("../gui/CanvasLayer/popup/body/btn1").connect("pressed", self, "popup_btn1_pressed")
	get_node("../gui/CanvasLayer/popup/body/btn2").connect("pressed", self, "popup_btn2_pressed")
	get_node("../gui/CanvasLayer/popup/body/btn3").connect("pressed", self, "popup_btn3_pressed")
	set_process_input(true)

func back_to_menu(): # jump back to the main menu
	global.load_scene("res://scenes/main_menu.xml")

func show_popup(var title, var text): # Show a popup with some title, and some text
	var popup = get_node("../gui/CanvasLayer/popup")
	popup.get_node("header/title").set_text(title)
	popup.get_node("body/text").set_text(text)
	if(btn2_action == 1):
		popup.get_node("body/btn2").set_disabled(false)
	else:
		popup.get_node("body/btn2").set_disabled(true)
	set_process(true)

func _process(delta): # When we have to wait till the popup is shown
	time_until_popup = time_until_popup - delta
	if(time_until_popup <= 0):
		var popup = get_node("../gui/CanvasLayer/popup")
		player.set_fixed_process(false)
		popup.show()
		set_process(false)

func hide_popup(): # Hide the popup
	var popup = get_node("../gui/CanvasLayer/popup")
	popup.hide()
	

func popup_btn1_pressed():# Actions for different popup buttons
	retry_level()
	hide_popup()

func popup_btn2_pressed():
	if(btn2_action == 1):
		btn2_action = 0 # No double clicking pls
		next_level()
		hide_popup()
	
func popup_btn3_pressed():
	back_to_menu()
	hide_popup()
