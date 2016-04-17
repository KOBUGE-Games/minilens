
extends Node2D

signal counters_changed()

export var acid_animation_time = 1.0 # The speed of the acid animation

var level_scene # The scene containing the level
var level_node # The Node with the level
var level_tileset = TileSet.new() # The Tileset
var current_pack # The current pack/level
var current_level

var goals_left = 0 # The amount of goals left to be taken
var goals_total = {} # The starting amounts of different goals left to be taken
var goals_taken = {} # The taken amounts of different goals
var goal_wait = 0

var acid_animation_pos = 0.0 # The current pos of the animation (0-1)
var tile_map_acid_y # The Y coordinate of the acid sea
var tile_map_acid_x_start # The start of the acid sea on X
var tile_map_acid_x_end # The end of the acid sea on X

var turns = 0 # How many turns passed from the start

onready var sample_player = get_node("../sample_player")
onready var music = get_node("../music")
onready var gui = get_node("../gui")
onready var player = get_node("../player_holder/player")

onready var raw_packs = FileManager.get_file_lines("res://levels/packs.txt")

func _ready():
	set_process(true)
	get_node("/root").connect("size_changed",self,"window_resize")

func _process(delta): # Move the acid
	acid_animation_pos = acid_animation_pos + delta
	if(acid_animation_pos > acid_animation_time):
		acid_animation_pos = acid_animation_pos - acid_animation_time
	level_tileset.tile_set_region(2, Rect2(64-64*acid_animation_pos/acid_animation_time,0,64,64))

func load_level(pack, level): # Load level from pack
	current_level = level
	current_pack = pack
	level_scene = load(str("res://levels/", pack, "/level_", level, ".tscn"))
	
	# Remove every currently loaded level
	for node in get_children():
		node.queue_free()
	
	# Reset the counters
	turns = 0
	goals_left = 0
	goals_taken = {}
	goals_total = {}
	
	# Create the new level
	level_node = level_scene.instance()
	add_child(level_node)
	
	# Prepare the player
	player.set_pos(level_node.get_node("start").get_pos())
	player.set_z(0)
	player.level_load(level_node)
	emit_signal("counters_changed")
	
	# Compute useful info about the tiles
	level_tileset = level_node.get_node("tilemap").get_tileset()
	var tilemap = level_node.get_node("tilemap")
	
	tile_map_acid_y = 0
	tile_map_acid_x_start = 2
	tile_map_acid_x_end = 1
	
	while(tilemap.get_cell(0, tile_map_acid_y) != 2 && tile_map_acid_y < 3000):
		tile_map_acid_y += 1
	
	while(tilemap.get_cell(tile_map_acid_x_start, tile_map_acid_y) == 2 && tile_map_acid_x_start > -100):
		tile_map_acid_x_start -= 1
	
	while(tilemap.get_cell(tile_map_acid_x_end, tile_map_acid_y) == 2 && tile_map_acid_x_end < 3000):
		tile_map_acid_x_end += 1
	
	window_resize()
	
	music.play_random_music()

func window_resize():
	var new_size = get_node("/root").get_size_override()
	var tilemap = level_node.get_node("tilemap")
	for i in range(ceil(new_size.x/2/64)):
		tilemap.set_cell(tile_map_acid_x_start - i, tile_map_acid_y, 2)
		tilemap.set_cell(tile_map_acid_x_end + i, tile_map_acid_y, 2)
	var scale = new_size.x/1024
	if(scale > 1):
		level_node.get_node("CanvasLayer").set_scale(Vector2(scale,scale))
		level_node.get_node("CanvasLayer").set_offset(Vector2(32*scale,32-(scale - 1)*768/2))
	player.camera.force_update_scroll()

func goal_add(type = ""): # Add one more goal
	if goals_total.has(type):
		goals_total[type] += 1
	elif type != "":
		goals_taken[type] = 0
		goals_total[type] = 1
	
	goals_left = goals_left + 1
	
	emit_signal("counters_changed")

func goal_take(type = ""): # Called when a goal is taken
	if goals_total.has(type):
		goals_taken[type] += 1
	
	goals_left = goals_left - 1
	
	if goals_left == 0:
		SaveManager.set_reached_level(current_pack, current_level + 1)
		
		# Check if there are more levels
		for raw_pack in raw_packs:
			var line_parts = raw_pack.split(" ")
			if line_parts.size() >= 2:
				if line_parts[0] == current_pack:
					gui.prompt_finsh_level(turns, int(line_parts[1]) >= int(current_level) + 1, goal_wait - OS.get_unix_time())
					break
	
	emit_signal("counters_changed")

func goal_return(type = ""): # Called when a goal is returned (e.g. when you push a artefact out of a force)
	if(goals_total.has(type)):
		goals_taken[type] -= 1
	
	goals_left = goals_left + 1
	
	emit_signal("counters_changed")

func set_goal_wait(time = 0):
	goal_wait  = time + OS.get_unix_time()

func play_sample(name):
	if SettingsManager.read_settings().sound:
		sample_player.play(name)

func turn(): # Increment turns
	turns += 1
	emit_signal("counters_changed")

func retry_level(): # Retry the current level
	load_level(current_pack, current_level)

func next_level(): # Go to the next level
	load_level(current_pack, int(current_level) + 1)
