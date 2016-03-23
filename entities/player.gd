
extends "entity.gd"

var current_animation = "idle"
var old_animation = ""

var bombs = 0

onready var character = get_node("character")
onready var animation_player = get_node("animation_player")
onready var camera = get_node("camera")

func _ready():
	connect("auto_move_done", self, "animate_auto_move")
	set_process(true)
	set_fixed_process(false)

func _process(delta):
	# Update the animation
	if current_animation != old_animation:
		animation_player.play(current_animation)
		old_animation = current_animation
	
	# Update the orientation
	if movement.x != 0 and sign(movement.x) == sign(character.get_scale().x):
		character.set_scale(character.get_scale() * Vector2(-1,1))

func level_load(level_node):
	current_animation = "idle"
	
	tilemap = level_node.get_node("tilemap") # Get the tilemap
	
	# Set the limis for the camera
	var top_left_pos = level_node.get_node("camera_start").get_pos()
	var bottom_right_pos = level_node.get_node("camera_end").get_pos()
	camera.set_limit(MARGIN_TOP, top_left_pos.y)
	camera.set_limit(MARGIN_LEFT, min(top_left_pos.x,-9999))
	camera.set_limit(MARGIN_BOTTOM, bottom_right_pos.y)
	camera.set_limit(MARGIN_RIGHT, max(bottom_right_pos.x,9999))
	
	# Reset variables
	bombs = 0
	movement = Vector2(0, 0)
	set_fixed_process(true)

func next_move():
	current_animation = "idle"
	
	if tile_types.overlap == TileConfig.TILE_SINK:
		destroy()
	
	if Input.is_action_pressed("btn_right") and can_move_in_direction("right", false, true):
		move_in_direction("right", false, true)
		current_animation = "walk"

	if Input.is_action_pressed("btn_left") and can_move_in_direction("left", false, true):
		move_in_direction("left", false, true)
		current_animation = "walk"

	if Input.is_action_pressed("btn_up") and can_move_in_direction("top", false, true) and tile_types["overlap"] == TileConfig.TILE_CLIMB:
			move_in_direction("top", false, true)
			current_animation = "climb"

	if Input.is_action_pressed("btn_down") and can_move_in_direction("bottom", false, true) and tile_types["overlap"] == TileConfig.TILE_CLIMB:
		move_in_direction("bottom", false, true)
		current_animation = "climb"
	
	if movement != Vector2(0, 0):
		level_holder.turn()

func destroy():
	level_holder.gui.prompt_retry_level()
	set_fixed_process(false) # Stop movement

func animate_auto_move(type):
	if type == "fall" or type == "sink":
		current_animation = "fall"