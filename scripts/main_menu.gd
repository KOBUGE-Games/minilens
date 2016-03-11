extends Control
# This script drives the main menu
var select_pack    # The OptionButton for selecting packs
var target         # When moveing the view, where do we want to go?
var level_btn_scene = preload("res://scenes/level_select_btn.tscn") # The level selection button in a scene
var level_list     # The node that contains all level buttons
export var level_btn_size = Vector2(100,100) # The size+margin of every level selecion button
export var level_btn_margin_x = 212.0 # The size+margin of every level selecion button
var level_btn_row_count = 6 # How many level buttons can we arrange in a row?
var level_selected # The level we have selected
var global # The global node (serves like a library, see global.gd)
var packs_included = ["tutorial"] # Name of packs loaded from "res://levels" (levels existing when exporting project), generated in _ready
var options # The node containing all options
var pack_folders = [] # The folders for the packs
var viewport # The viewport
var my_pos = Vector2(0,0) # The current position of the start screen
var current_target = "start" # The screen we are currently on
var JS # SUTjoystick module
var pack_levels = [] # How many levels does each pack have?

func snake_case_to_Name(var string):
	var split = string.split("_")
	var name = ""
	for i in split:
		name += i.capitalize() + " "
	return name

func _ready():
	# Finding nodes
	global = get_node("/root/global")
	JS = get_node("/root/SUTjoystick")
	select_pack = get_node("level_selection/opt_pack")
	level_list = get_node("level_selection/level_list")
	options = get_node("options")
	var splash = get_node("splash/Label")
	viewport = get_viewport()
	
	# Filling the credits label
	var credits = get_node("credits/Label")
	var f = File.new()
	f.open("res://CREDITS.txt", f.READ)
	var credit = ""
	while(!f.eof_reached()):
		credit = str(credit, "\n", f.get_line())
	credits.set_text(credit)
	
	# Filling the splash label
	var f = File.new()
	f.open("res://splashes.txt", f.READ)
	var splashes = []
	while(!f.eof_reached()):
		splashes.append(f.get_line())
	var random = int(abs(rand_seed(OS.get_unix_time())[1])) % splashes.size()
	splash.set_text(splashes[random])
	f.close()
	
	# Packs
	f.open("res://levels/packs.txt", File.READ)
	while(!f.eof_reached()):
		var line = f.get_line().split(" ")
		if(line.size() >= 2):
			select_pack.add_item(snake_case_to_Name(line[0]))
			pack_folders.append(line[0])
			pack_levels.append(int(line[1]))
	
	_on_opt_pack_item_selected(0) # Update level list
	
	# Populating options
	var current_options = global.read_options()
	for i in current_options:
		set_option(i,current_options[i]) # Remeber last values
	var bool_opts = ["fullscreen", "music", "sound", "input_mode"]
	for cur_opt_name in bool_opts:
		var cur_opt = options.get_node(str(cur_opt_name, "/opt"))
		if(cur_opt_name == "input_mode"):
			cur_opt.add_item("Touch areas", global.INPUT_AREAS)
			cur_opt.add_item("Touch buttons", global.INPUT_BUTTONS)
		else:
			cur_opt.add_item("Off")
			cur_opt.add_item("On")
		if(current_options.has(cur_opt_name)):
			cur_opt.select(int(current_options[cur_opt_name]))
	# Hide touch input modes on non-touch-based platforms
	if(OS.get_name() != "Android" and OS.get_name() != "iOS"):
		options.get_node("input_mode").hide()
	JS.emulate_mouse(true) # Enable gamepad mouse emulation for menus
	
	# Splash
	if(global.is_first_load):
		get_node("Splash/AnimationPlayer").play("SplashFade")
	
	# Prepare to move thing when the aspect ratio changes
	viewport.connect("size_changed",self,"window_resize")
	window_resize()

func window_resize():
	var new_size = viewport.get_size_override()
	var old_row_count = level_btn_row_count
	level_btn_row_count = int((new_size.x - level_btn_margin_x*2) / level_btn_size.x) + 1
	
	if(old_row_count != level_btn_row_count): # If we need to make the buttons again
		_on_opt_pack_item_selected(0) # Recalculate btn positions
		
	my_pos = Vector2((new_size.x-1024)/2,0)
	get_node("level_selection").set_pos(my_pos + Vector2(1024,0))
	get_node("options").set_pos(Vector2(-new_size.x-1024,0))
	get_node("options").set_size(new_size)
	get_node("options/back").set_pos(Vector2(new_size.x-96,8))
	get_node("credits").set_pos(Vector2(-my_pos.x,768))
	get_node("credits").set_size(new_size)
	var scale = new_size.x/1024
	if(scale > 1):
		get_node("CanvasLayer").set_scale(Vector2(scale,scale))
		get_node("CanvasLayer").set_offset(Vector2(0,-(scale*768-768)))
		get_node("Splash").set_scale(Vector2(scale,scale))
		get_node("Splash").set_offset(Vector2(0,-(scale*768-768)/2))
	goto_target(current_target)

func _on_opt_pack_item_selected( ID ):
	# Remove old level selection buttons
	for i in range(level_list.get_child_count()):
		level_list.get_child(i).queue_free()
	
	# Get the pack
	var pack = pack_folders[select_pack.get_selected()]
	var locked_count = global.get_reached_level(pack) # Get the number of locked levels
	
	# Get the names of the levels
	var level_names = {}
	var f = File.new()
	var err = f.open(str("res://levels/", pack, "/names.txt"),File.READ)
	if(!err): # If we can open the file
		while(!f.eof_reached()):
			var line = f.get_line().split(":")      # Read every line
			if(line[0] != ""):
				level_names[int(line[0])] = line[1] # And record the result
	f.close()
	
	# Make the buttons
	for i in range(0,pack_levels[select_pack.get_selected()]):
				var new_instance = level_btn_scene.instance() # An instance of the level button
				if(level_names.has(i+1)):
					new_instance.set_title(level_names[i+1]) # When we have a name for that level, we use it
				else:
					new_instance.set_title(str("Level ",i + 1)) # Otherwise we write simply "Level N"
				new_instance.set_metadata(i + 1) # We set some metadata for later, so we don't forget which level this button is bound to
				new_instance.set_locked((i + 1) > locked_count) # When the level is locked we show the lock
				
				var row_pos = int(i % level_btn_row_count) # The position on X
				var col_pos = int(i / level_btn_row_count) # And on Y
				
				new_instance.set_pos(Vector2(level_btn_size.x * row_pos + level_btn_margin_x, level_btn_size.y * col_pos)) # Then use both of them to make the final position
				level_list.add_child(new_instance) # At last we add it to the list
				
				i = i + 1

func level_btn_clicked(var id): # When any level button is clicked
	level_selected = id
	set_fixed_process(true) # We use _fixed_process to change scenes, so no crashes happen

func _fixed_process(delta): # We use _fixed_process to change scenes, so no crashes happen 
	# Get the pack
	var pack = pack_folders[select_pack.get_selected()]
	set_fixed_process(false)
	global.load_level(pack,level_selected) 
	
func _process(delta):
	# We use _process to move the screen
	set_pos((get_pos()*4 + target)/5)
	if(abs(get_pos().x - target.x) < 1 && abs(get_pos().y - target.y) < 1):
		set_pos(target)
		set_process(false)

func goto_target(var target_place = "start"):
	current_target = target_place
	if(target_place == "start"):
		target = my_pos
	elif(target_place == "levels"):
		target = -get_node("level_selection").get_pos() # Select the target coordinates
	elif(target_place == "options"):
		target = -get_node("options").get_pos()
	elif(target_place == "credits"):
		target = -get_node("credits").get_pos()
	set_process(true) # We use _process to move the screen

func goto_levels():
	goto_target("levels")

func goto_start():
	goto_target("start")
	
func goto_options():
	goto_target("options")
	
func goto_credits():
	goto_target("credits")

func quit():
	get_tree().quit() # Exit the game

func _on_options_change(var ID, var setting):
	var current_options = global.read_options()
	current_options[setting] = get_node(str("options/", setting, "/opt")).get_selected()
	set_option(setting,current_options[setting])

	global.save_options(current_options)

func set_option(var setting, var value):
	if(setting == "fullscreen"):
		OS.set_window_fullscreen(bool(int(value)))
	elif(setting == "music"):
		var bool_music = bool(int(value))
		var music_node = get_node("music")
		if(bool_music):
			music_node.play()
		else:
			music_node.stop()
	elif(setting == "input_mode"):
		global.input_mode = bool(int(value))
