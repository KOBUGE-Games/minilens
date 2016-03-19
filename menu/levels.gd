
extends Control

export(String, FILE) var packs_file_path = "res://levels/packs.txt"
export(String, DIR) var level_packs_dir_path = "res://levels"
export(String) var names_file_name = "names.txt"
export(PackedScene) var level_select_button_scene = preload("level_select_button.tscn")

var level_select_button_size = Vector2()

onready var raw_packs = FileManager.get_file_lines(packs_file_path)
onready var packs = []
onready var packs_option_button = get_node("items/select_pack/option_button")

onready var level_list = get_node("items/levels")

func _ready():
	level_list.connect("resized", self, "recalulate_grid_columns")
	packs_option_button.connect("item_selected", self, "pack_selected")
	
	for raw_pack in raw_packs:
		var line_parts = raw_pack.split(" ")
		if line_parts.size() >= 2:
			var readable_name = snake_case_to_name(line_parts[0])
			packs.push_back({
				name = line_parts[0],
				path = str(level_packs_dir_path, "/", line_parts[0]),
				level_count = int(line_parts[1])
			})
			packs_option_button.add_item(readable_name)
	
	var lsb_state = level_select_button_scene.get_state()
	
	for node_i in range(lsb_state.get_node_count()):
		if lsb_state.get_node_path(node_i) == ".":
			for prop_i in range(lsb_state.get_node_property_count(node_i)):
				if lsb_state.get_node_property_name(node_i, prop_i) == "rect/min_size":
					level_select_button_size = lsb_state.get_node_property_value(node_i, prop_i)
			break # Found it, no need to loop over the other nodes
	
	pack_selected(0)
	recalulate_grid_columns()

func recalulate_grid_columns():
	var width_available = level_list.get_parent().get_size().x
	var individual_width = level_select_button_size.x + level_list.get("custom_constants/hseparation")
	level_list.set_columns(int(width_available / individual_width))

func pack_selected(id):
	var pack = packs[id]
	
	# Get the names of the levels
	var level_names = {}
	for name_line in FileManager.get_file_lines(str(pack.path, "/", names_file_name)):
		var line_parts = name_line.split(":")
		if line_parts[0] != "" && line_parts.size() == 2:
			level_names[int(line_parts[0])] = line_parts[1]
	
	var locked_level_count = SaveManager.get_reached_level(pack.name) # Get the number of locked levels
	
	# Remove old level selection buttons
	for node in level_list.get_children():
		node.queue_free()
	
	# Create the new level selection buttons
	for i in range(pack.level_count):
		var id = i + 1
		var new_button = level_select_button_scene.instance()
		level_list.add_child(new_button) # Add the button to the list
		
		new_button.connect("pressed", self, "start_level", [pack.name, id])
		
		if level_names.has(id):
			new_button.set_text(level_names[id])
		else:
			new_button.set_text(str("Level ", id)) # When we don't have a name for that level, we just write "Level N"
		
		new_button.set_number(id)
		new_button.set_locked(id > locked_level_count)

func snake_case_to_name(var string):
	var split = string.split("_")
	var name = ""
	for i in split:
		name += i.capitalize() + " "
	return name

var target = []
func start_level(var pack, var id):
	target = [pack, id]
	
	ScenesManager.load_level(target[0], target[1])
