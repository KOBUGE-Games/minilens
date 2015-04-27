extends Control
# this is the script that drives the main menu
var select_pack    # the OptionButton for selecting packs
var target         # When moveing the view, where do we want to go?
var level_btn_scene = preload("res://scenes/level_select_btn.xml") # the Level selecion button in a scene
var level_list     # the node that contains all level buttons
export var level_btn_size = Vector2(100,100) # the size+margin of every level selecion button
export var level_btn_margin_x = 212.0 # the size+margin of every level selecion button
var level_btn_row_count = 6 # How many level buttons can we arrange in a row?
var level_selected # The level we have selected
var global # the global node (serves like a library, see global.gd)
var packs_included = ["tutorial"] # name of packs loaded from "res://levels" (levels existing when exporting project), generated in _ready
var options # the node containing all options
var pack_folders = [] # the folders of the packs
var viewport # The viewport
var my_pos = Vector2(0,0) # The current position of the start screen
var current_target = "start" # The screen we are currently on
var JS # SUTjoystick module
var pack_levels = [] # how many levels does each pack have

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
	f.close() # Close splashes.txt
	# Packs
	f.open("res://levels/packs.txt", File.READ)
	while(!f.eof_reached()):
		var line = f.get_line().split(" ")
		if(line.size() >= 2):
			select_pack.add_item(snake_case_to_Name(line[0]))
			pack_folders.append(line[0])
			pack_levels.append(int(line[1]))
	
	# Using the Diectory class to list all folders, so we can add the packs to the menu
	#var diraccess = Directory.new()
	# check 2 paths - 1. bundled levels, 2. created later using map editor
	#var dir_paths = ["res://levels/"] # res://levels (bundled)
	#dir_paths.append(Globals.globalize_path(dir_paths[0])) # C:/.../levels (disk)
	#select_pack.add_item("Tutorial")
	#pack_folders.append("tutorial")
	#var i = 0 # the id of the number
	#for path in dir_paths:
	#	print(diraccess.open(path))
	#	diraccess.list_dir_begin()
	#	var name = diraccess.get_next()
	#	while name:
	#		if diraccess.current_is_dir():
	#			if name != "." and name != ".." and name != "tutorial":
	#				pack_folders.append(name)
	#				print("res://levels/",name)
	#				if path.begins_with("res://"): # bundled
	#					select_pack.add_item(snake_case_to_Name(name))
	#					packs_included.append(name)
	#				#else: # made with map editor
	#				#	if !name in packs_included:
	#				#		select_pack.add_item(snake_case_to_Name(name))
	#		name = diraccess.get_next()
	#	diraccess.list_dir_end()
	_on_opt_pack_item_selected(0)#Update level list
	#populating options
	var current_options = global.read_options()
	for i in current_options:
		set_option(i,current_options[i]) # remeber last values
	var bool_opts = ["fullscreen", "music"]
	for cur_opt_name in bool_opts:
		var cur_opt = options.get_node(str(cur_opt_name, "/opt"))
		cur_opt.add_item("Off")
		cur_opt.add_item("On")
		if(current_options.has(cur_opt_name)):
			cur_opt.select(current_options[cur_opt_name])
	JS.emulate_mouse(true) # enable gamepad mouse emulation for menus
	#prepare to move thing when the aspect ratio changes
	viewport.connect("size_changed",self,"window_resize")
	window_resize()

func window_resize():
	var new_size = viewport.get_size_override()
	var old_row_count = level_btn_row_count
	level_btn_row_count = int((new_size.x - level_btn_margin_x*2) / level_btn_size.x) + 1
	if(old_row_count != level_btn_row_count): #So we have a reason to relayout
		_on_opt_pack_item_selected(0) # Recalculate btn positions
	my_pos = Vector2((new_size.x-1024)/2,0)
	#set_pos(my_pos)
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
	goto_target(current_target)

func _on_opt_pack_item_selected( ID ):
	#remove old level selection buttons
	for i in range(level_list.get_child_count()):
		level_list.get_child(i).queue_free()
	#Get the pack
	var pack = pack_folders[select_pack.get_selected()]
	#Get the number of locked levels
	var locked_count = global.get_reached_level(pack)
	#Get the names of the levels
	var level_names = {}
	var f = File.new()
	var err = f.open(str("res://levels/", pack, "/names.txt"),File.READ)
	if(!err):#if we can open that file
		while(!f.eof_reached()):
			var line = f.get_line().split(":")      #Read every line
			if(line[0] != ""):
				level_names[int(line[0])] = line[1] #and record the result
	f.close()
	#Using the Directory class to list all files
	#var diraccess = Directory.new()
	#diraccess.open(str("res://levels/", pack))
	#if diraccess.open(str("res://levels/", pack)) != 0: # pack is not bundled
	#	diraccess.open(Globals.globalize_path(str("res://levels/", pack))) # load from disk
	#diraccess.list_dir_begin()
	#var name = diraccess.get_next()
	#var i = 0 #The number of the current level
	#while name:
	#	print("res://levels/",pack,name)
	#	if !diraccess.current_is_dir():
	#		if name.substr(0,5) == "level":# the file starts with "level"
	for i in range(0,pack_levels[select_pack.get_selected()]):
				var new_instance = level_btn_scene.instance() # an instance of the level button
				if(level_names.has(i+1)):
					new_instance.set_title(level_names[i+1]) # When we have a name for that level, we use it
				else:
					new_instance.set_title(str("Level ",i + 1)) # Otherwise we write simply "Level N"
				new_instance.set_metadata(i + 1) # We set some metadata for later, so we won't forget which level this button is bound to
				new_instance.set_locked((i + 1) > locked_count) # When the level is locked we show it as one
				var row_pos = int(i % level_btn_row_count) # The position on X
				var col_pos = int(i / level_btn_row_count) # and on Y
				new_instance.set_pos(Vector2(level_btn_size.x * row_pos + level_btn_margin_x, level_btn_size.y * col_pos)) # then both of them used to make the final pos
				level_list.add_child(new_instance) # At last we add it to the list
				i = i + 1
	#	name = diraccess.get_next()
	#diraccess.list_dir_end()

func level_btn_clicked(var id): # When any level button is clicked
	level_selected = id
	set_fixed_process(true) # We use _fixed_process to change scenes, so no crashes happen

func _fixed_process(delta):
	#Get the pack
	var pack = pack_folders[select_pack.get_selected()]
	set_fixed_process(false)
	global.load_level(pack,level_selected) # We use _fixed_process to change scenes, so no crashes happen
	
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
		target = -get_node("level_selection").get_pos() #Select the target coordinates
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
