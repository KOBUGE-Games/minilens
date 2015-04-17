extends Control
# this is the script that drives the main menu
var select_pack    # the OptionButton for selecting packs
var target         # When moveing the view, where do we want to go?
var level_btn_scene = preload("res://scenes/level_select_btn.xml") # the Level selecion button in a scene
var level_list     # the node that contains all level buttons
export var level_btn_size = Vector2(100,100) # the size+margin of every level selecion button
var level_btn_row_count = 6 #
var level_selected # The level we have selected
var global # the global node (serves like a library, see global.gd)
var packs_included = ["tutorial"] # name of packs loaded from "res://levels" (levels existing when exporting project), generated in _ready
var options # the node containing all options
var pack_folders = [] # the folders of the packs

func snake_case_to_Name(var string):
	var split = string.split("_")
	var name = ""
	for i in split:
		name += i.capitalize() + " "
	return name

func _ready():
	# Finding nodes
	global = get_node("/root/global")
	select_pack = get_node("level_selection/opt_pack")
	level_list = get_node("level_selection/level_list")
	options = get_node("options")
	var splash = get_node("splash/Label")
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
	print()
	var random = int(rand_seed(OS.get_unix_time())[1] % splashes.size())
	print(random)
	splash.set_text(splashes[random])
	# Using the Diectory class to list all folders, so we can add the packs to the menu
	var diraccess = Directory.new()
	# check 2 paths - 1. bundled levels, 2. created later using map editor
	var dir_paths = ["res://levels/"] # res://levels (bundled)
	dir_paths.append(Globals.globalize_path(dir_paths[0])) # C:/.../levels (disk)
	select_pack.add_item("Tutorial")
	pack_folders.append("tutorial")
	var i = 0 # the id of the number
	for path in dir_paths:
		diraccess.open(path)
		diraccess.list_dir_begin()
		var name = diraccess.get_next()
		while name:
			if diraccess.current_is_dir():
				if name != "." and name != ".." and name != "tutorial":
					pack_folders.append(name)
					if path.begins_with("res://"): # bundled
						select_pack.add_item(snake_case_to_Name(name))
						packs_included.append(name)
					else: # made with map editor
						if !name in packs_included:
							select_pack.add_item(snake_case_to_Name(name))
			name = diraccess.get_next()
		diraccess.list_dir_end()
	_on_opt_pack_item_selected(0)#Update level list
	#populating options
	var current_options = global.read_options()
	for i in current_options:
		set_option(i,current_options[i]) # remeber last values
	var fullscreen_opt = options.get_node("fullscreen/opt")
	fullscreen_opt.add_item("Off")
	fullscreen_opt.add_item("On")
	if(current_options.has("fullscreen")):
		fullscreen_opt.select(current_options["fullscreen"])

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
	var diraccess = Directory.new()
	if diraccess.open(str("res://levels/", pack)) != 0: # pack is not bundled
		diraccess.open(Globals.globalize_path(str("res://levels/", pack))) # load from disk
	diraccess.list_dir_begin()
	var name = diraccess.get_next()
	var i = 0 #The number of the current level
	while name:
		if !diraccess.current_is_dir():
			if name.substr(0,5) == "level":# the file starts with "level"
				var new_instance = level_btn_scene.instance() # an instance of the level button
				if(level_names.has(i+1)):
					new_instance.set_title(level_names[i+1]) # When we have a name for that level, we use it
				else:
					new_instance.set_title(str("Level ",i + 1)) # Otherwise we write simply "Level N"
				new_instance.set_metadata(i + 1) # We set some metadata for later, so we won't forget which level this button is bound to
				new_instance.set_locked((i + 1) > locked_count) # When the level is locked we show it as one
				var row_pos = int(i % level_btn_row_count) # The position on X
				var col_pos = int(i / level_btn_row_count) # and on Y
				new_instance.set_pos(Vector2(level_btn_size.x * row_pos, level_btn_size.y * col_pos)) # then both of them used to make the final pos
				level_list.add_child(new_instance) # At last we add it to the list
				i = i + 1
		name = diraccess.get_next()
	diraccess.list_dir_end()

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


func goto_levels():
	target = Vector2(-1024,0) #Select the target coordinates
	set_process(true) # We use _process to move the screen

func goto_start():
	target = Vector2(0,0)
	set_process(true)
	
func goto_options():
	target = Vector2(1024,0)
	set_process(true)
	
func goto_credits():
	target = Vector2(0,-768)
	set_process(true)

func quit():
	get_tree().quit() # Exit the game

func _on_options_change(var ID, var setting):
	var current_options = global.read_options()
	if(setting == "fullscreen"):
		current_options["fullscreen"] = get_node("options/fullscreen/opt").get_selected()
		set_option("fullscreen",current_options["fullscreen"])
	global.save_options(current_options)

func set_option(var setting, var value):
	if(setting == "fullscreen"):
		OS.set_window_fullscreen(bool(int(value)))