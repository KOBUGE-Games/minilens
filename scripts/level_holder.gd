extends Node2D
# This script serves to hold the levels, and to manage them
var level_scene # The scene containing the level
var current_pack # The current pack/level
var current_level
var player # The player ofc
var level_node # The Node with the level
var goals_left = 0 # The amount of goals left to be taken
var goals_amount_by_type = {} # A Dictionary containing the STARTING amounts of different goals left to be taken
var goals_taken_by_type = {} # A Dictionary containing the TAKEN amounts of different goals
var global # The global node (serves like a library, see global.gd)
var JS # The SUTjoystick module
var btn2_action = 0 # Can we move left, when we press the secound button
var time_until_popup = 0 # How much time should we wait 
export var acid_animation_time = 1.0 # The speed of the acid animation
var acid_animation_pos = 0.0 # The current pos of the animation (0-1)
var tileset = TileSet.new() # The Tileset
var viewport # The Viewport
var tile_map_acid_y # When we extend the tilemap, we need to know on which Y we should place the acid
var tile_map_acid_x_start # When we extend the tilemap, we need to know on which Y we should place the acid
var tile_map_acid_x_end # When we extend the tilemap, we need to know on which Y we should place the acid
var musics = ["music_1.ogg","music_2.ogg"] # The possible background music files
var turns = 0 # How many turns passed from the start
var has_music = true

func load_level(var pack, var level): # Load level N from pack P
	current_level = level
	current_pack = pack
	level_scene = load(str("res://levels/", pack, "/level_", level, ".xml"))
	# Remove every currently loaded level
	for i in range(get_child_count()):
		get_child(i).queue_free()
	level_node = level_scene.instance() # Instance the new level
	# Reset the counters
	goals_left = 0 
	goals_taken_by_type = {}
	for type in goals_amount_by_type:
		var goals_node = get_node("../gui/CanvasLayer/").get_node(type)# Get node like ../gui/CanvasLayer/<type>
		goals_node.hide()
	goals_amount_by_type = {}
	add_child(level_node) # Add that node to the scene
	player.set_pos(level_node.get_node("start").get_pos()) # Teleport the player to his new location
	player.set_z(0)
	turns = -1 # reset the number of turns
	turn() # This will increase the number of turns by one, so will still have 0 turns...
	player.level_load(level_node) # Have the player prepare to play..
	tileset = level_node.get_node("tilemap").get_tileset()
	var tilemap = level_node.get_node("tilemap")
	tile_map_acid_y = 0
	tile_map_acid_x_start = 2
	tile_map_acid_x_end = 1
	while(tilemap.get_cell(0,tile_map_acid_y) != 2 && tile_map_acid_y < 3000):
		tile_map_acid_y += 1
	while(tilemap.get_cell(tile_map_acid_x_start, tile_map_acid_y) == 2 && tile_map_acid_x_start > -100):
		tile_map_acid_x_start -= 1
	while(tilemap.get_cell(tile_map_acid_x_end, tile_map_acid_y) == 2 && tile_map_acid_x_end < 3000):
		tile_map_acid_x_end += 1
	window_resize()
	var musics_node = get_node("../music")
	for i in range(musics_node.get_child_count()):
		musics_node.get_child(i).stop()
	if(has_music):
		var random = abs(rand_seed(OS.get_unix_time())[1]) % musics_node.get_child_count()
		musics_node.get_child(random).play()

func window_resize():
	var new_size = viewport.get_size_override()
	var new_pos = Vector2((new_size.x-1024)/2,0)
	get_node("../gui/CanvasLayer/popup").set_pos(Vector2(new_size.x/2-252,210))
	get_node("../gui/CanvasLayer/touch_buttons").set_pos(Vector2(new_size.x-200,568))
	var tilemap = level_node.get_node("tilemap")
	for i in range(ceil(new_size.x/2/64)):
		tilemap.set_cell(tile_map_acid_x_start - i, tile_map_acid_y, 2)
		tilemap.set_cell(tile_map_acid_x_end + i, tile_map_acid_y, 2)
	var scale = new_size.x/1024
	if(scale > 1):
		get_node("../gui/CanvasLayer/popup/popup_bg").set_scale(Vector2(scale,scale))
		level_node.get_node("CanvasLayer").set_scale(Vector2(scale,scale))
		level_node.get_node("CanvasLayer").set_offset(Vector2(32*scale,32-(scale - 1)*768/2))
	player.get_node("Camera2D").force_update_scroll()

func turn():
	turns += 1
	get_node("../gui/CanvasLayer/turns/Label").set_text(str(turns))

func retry_level(): # Retry the current level
	load_level(current_pack, current_level)

func goal_take(var type = "",var wait = 0): # Called when a goal is taken
	if(goals_amount_by_type.has(type)):
		goals_taken_by_type[type] += 1
		var goals_node = get_node("../gui/CanvasLayer/").get_node(type)# Get node like ../gui/CanvasLayer/<type>
		if(goals_node):
			goals_node.get_node("Label").set_text(str(goals_taken_by_type[type]," / ",goals_amount_by_type[type]))
	time_until_popup = wait
	goals_left = goals_left - 1
	if(goals_left == 0): # No more goals ;(
		global.set_reached_level(current_pack, current_level + 1)
		# Try to open the next level
		var f = File.new()
		var err = f.open(str("res://levels/", current_pack, "/level_", int(current_level) + 1, ".xml"), f.READ)
		if(err != 0):# If we are unable to open it, we show that no more levels are left in this pack instead of crashing
			btn2_action = 0 # Can't click "Next Level", because there is no level after that one
			show_popup("Good job!",str("Level passed in ",turns," turns.\nThere are no more levels left in this pack. You can go to play some other pack, though."))
		else:
			btn2_action = 1 # Can click "Next Level"
			show_popup("Good job!",str("Level passed in ",turns," turns."))
		f.close()
		
func goal_return(var type = "",var wait = 0): # Called when a goal is returned (e.g. when you push a artefact out of a force)
	if(goals_amount_by_type.has(type)):
		goals_taken_by_type[type] -= 1
		var goals_node = get_node("../gui/CanvasLayer/").get_node(type)# Get node like ../gui/CanvasLayer/<type>
		if(goals_node):
			goals_node.get_node("Label").set_text(str(goals_taken_by_type[type]," / ",goals_amount_by_type[type]))
	goals_left = goals_left + 1

func prompt_retry_level(): # Called when the robot dies
	btn2_action = 0
	show_popup("You died","Your robot was destroyed!\n Do you want to try again?")

func level_impossible(var wait = 0): # Called when the level is impossible
	btn2_action = 0
	time_until_popup = wait
	show_popup("Impossible","It seems that it is impossible to pass that level!\n Do you want to try again?")
func next_level(): # Go to the next level
	load_level(current_pack, int(current_level) + 1)

func goal_add(var type=""): # Add one more goal
	goals_left = goals_left + 1
	if(goals_amount_by_type.has(type)):
		goals_amount_by_type[type] += 1
		var goals_node = get_node("../gui/CanvasLayer/").get_node(type)# get node like ../gui/CanvasLayer/<type>
		if(goals_node):
			goals_node.get_node("Label").set_text(str(goals_taken_by_type[type]," / ",goals_amount_by_type[type]))
	elif(type != ""):
		goals_taken_by_type[type] = 0
		goals_amount_by_type[type] = 1
		var goals_node = get_node("../gui/CanvasLayer/").get_node(type)# get node like ../gui/CanvasLayer/<type>
		if(goals_node):
			goals_node.show()
			goals_node.get_node("Label").set_text(str(goals_taken_by_type[type]," / ",goals_amount_by_type[type]))

func _input(event):
	if JS.get_digital("back") || (event.is_action("retry") && event.is_pressed() && !event.is_echo()):
		popup_btn1_pressed()
	if JS.get_digital("action_3") || (event.is_action("next_level") && event.is_pressed() && !event.is_echo()):
		popup_btn2_pressed()
	if JS.get_digital("start") || (event.is_action("to_menu") && event.is_pressed() && !event.is_echo()):
		popup_btn3_pressed()

func _ready():
	# Find nodes
	global = get_node("/root/global")
	JS = get_node("/root/SUTjoystick")
	player = get_node("../player_holder/player")
	viewport = get_viewport()
	# Removes the focus from the retry button
	get_node("../gui/CanvasLayer/retry").set_focus_mode(Control.FOCUS_NONE)
	# Connect the popup buttons
	get_node("../gui/CanvasLayer/popup/body/btn1").connect("pressed", self, "popup_btn1_pressed")
	get_node("../gui/CanvasLayer/popup/body/btn2").connect("pressed", self, "popup_btn2_pressed")
	get_node("../gui/CanvasLayer/popup/body/btn3").connect("pressed", self, "popup_btn3_pressed")
	set_process_input(true)
	set_process(true)
	viewport.connect("size_changed",self,"window_resize")
	JS.emulate_mouse(false) # Turn off mouse emulation in-game
	if(bool(int(get_node("/root/global").read_options()["music"]))):
		has_music = true
	else:
		has_music = false

func _process(delta): # Move the acid
	acid_animation_pos = acid_animation_pos + delta
	if(acid_animation_pos > acid_animation_time):
		acid_animation_pos = acid_animation_pos - acid_animation_time
	tileset.tile_set_region(2, Rect2(64-64*acid_animation_pos/acid_animation_time,0,64,64))

func back_to_menu(): # Jump back to the main menu
	global.load_scene("res://scenes/main_menu.xml")

func show_popup(var title, var text): # Show a popup with some title, and some text
	var popup = get_node("../gui/CanvasLayer/popup")
	popup.get_node("header/title").set_text(title)
	popup.get_node("body/text").set_text(text)
	if(btn2_action == 1):
		popup.get_node("body/btn2").set_disabled(false)
	else:
		popup.get_node("body/btn2").set_disabled(true)
	set_fixed_process(true)

func _fixed_process(delta): # When we have to wait till the popup is shown
	time_until_popup = time_until_popup - delta
	if(time_until_popup <= 0):
		var popup = get_node("../gui/CanvasLayer/popup")
		player.set_fixed_process(false)
		popup.show()
		set_fixed_process(false)
		JS.emulate_mouse(true) # turn on mouse emulation for popups

func hide_popup(): # Hide the popup
	var popup = get_node("../gui/CanvasLayer/popup")
	popup.hide()
	

func popup_btn1_pressed():# Actions for different popup buttons
	JS.emulate_mouse(false) # turn off mouse emulation again	
	retry_level()
	hide_popup()

func popup_btn2_pressed():
	if(btn2_action == 1):
		btn2_action = 0 # No double clicking pls
		JS.emulate_mouse(false) # turn off mouse emulation again	
		next_level()
		hide_popup()
	
func popup_btn3_pressed():
	back_to_menu()
	hide_popup()
