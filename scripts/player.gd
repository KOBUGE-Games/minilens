extends KinematicBody2D
# This (long) script moves the player

var ray_check_top # rays to check for objects in each direction
var ray_check_right
var ray_check_bottom
var ray_check_left
var ray_overlap

var collider_top = "" # Variables in which we store the colliders we find
var collider_right = ""
var collider_bottom = ""
var collider_left = ""
var collider_name # The name of the collider we are checking

var check_top = "" # Variables in which we store the tiles in each direction
var check_right = ""
var check_bottom = ""
var check_left = ""
var check_overlap = ""

var sinking = false # Are we sinking?
var falling = false # Are we falling?

var movement = 0 # How much do we have to move? (+ for right)
var move_left = false # Can we move left/right/up
var move_right = false
var move_up = 0
var move_down = false # How much do we have to move vertically? (+ for down)

var place_bomb_was_pressed = false # Did we press space the last frame?
var bomb = preload("res://scenes/bomb.xml") # The bomb scene
var bombs = 0 # How much bombs do we have left

var tilemap # the Tilemap
var current_position # our current position in the tilemap
export var TILE_LADDER = 1
export var TILE_ACID = 2

var old_anim # the new and the old animation
var new_anim

var bomb_counter # The node counting the bombs

func _ready():
	# Find nodes
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	ray_overlap = get_node("ray_overlap")
	
	ray_overlap.add_exception(self)
	
	bomb_counter = get_node("../../gui/CanvasLayer/bombs")

func level_load(var level_node):
	get_node("SpriteGroup/AnimationPlayer").play("idle") # Play the idle animation when we enter the level
	tilemap = level_node.get_node("tilemap") # Get the tilemap
	# Set the limis for the camera
	var camera = get_node("Camera2D") 
	var top_left_pos = level_node.get_node("camera_start").get_pos()
	var bottom_right_pos = level_node.get_node("camera_end").get_pos()
	camera.set_limit(MARGIN_TOP, top_left_pos.y)
	camera.set_limit(MARGIN_LEFT, top_left_pos.x)
	camera.set_limit(MARGIN_BOTTOM, bottom_right_pos.y)
	camera.set_limit(MARGIN_RIGHT, bottom_right_pos.x)
	#Reset variables
	bombs = 0
	movement = 0
	move_up = 0
	falling = true
	set_fixed_process(true) # Lights on

func destroy(var by): # Destroy the player
	get_node("../../level_holder").prompt_retry_level()
	set_fixed_process(false) # Stop movement

func play_anim():
	if(old_anim != new_anim):# When we want to change the animation
		get_node("SpriteGroup/AnimationPlayer").play(new_anim)

func check_orientation():# Check if the current orientation matches the movement
	if sign(movement) == sign(get_node("SpriteGroup").get_scale().x):
		get_node("SpriteGroup").set_scale(get_node("SpriteGroup").get_scale() * Vector2(-1,1))

func logic():
	# Get the current position in the tilemap, and round it
	current_position = (get_pos())/64
	current_position = Vector2(round(current_position.x), round(current_position.y))
	
	#Can we move right?
	check_right = tilemap.get_cell(current_position.x + 1, current_position.y)
	move_right = (check_right == -1 || check_right == TILE_LADDER) # We can move through air and ladders
	if ray_check_right.is_colliding() and ray_check_right.get_collider():
		var collider_name = ray_check_right.get_collider().get_name()
		if collider_name.substr(0,3) == "box":
			move_right = false # But we can't move through boxes

	#Can we move left?
	check_left = tilemap.get_cell(current_position.x - 1, current_position.y)
	move_left = (check_left == -1 || check_left == TILE_LADDER) # We can move through air and ladders
	if ray_check_left.is_colliding() and ray_check_left.get_collider():
		var collider_name = ray_check_left.get_collider().get_name()
		if collider_name.substr(0,3) == "box":
			move_left = false # But we can't move through boxes

	#Get the tile we overlap
	check_overlap = tilemap.get_cell(current_position.x, current_position.y)

	#Can we move down?
	check_bottom = tilemap.get_cell(current_position.x, current_position.y + 1)
	move_down = (check_bottom == -1 || check_bottom == TILE_LADDER) # We can move through air and ladders
	if ray_check_bottom.is_colliding() and ray_check_bottom.get_collider():
		var collider_name = ray_check_bottom.get_collider().get_name()
		if collider_name.substr(0,3) == "box":
			move_down = false # But we can't move through boxes
	move_down = move_down || int(get_pos().y)%64 != 0

	#Get the tile above
	check_top = tilemap.get_cell(current_position.x, current_position.y - 1)

	#collect flowers or bombs
	if ray_overlap.is_colliding() and ray_overlap.get_collider():
		if ray_overlap.get_collider().get_name().substr(0,6) == "flower":
			ray_overlap.get_collider().destroy("player")
			get_node("pickup").play()
		elif ray_overlap.get_collider().get_name().substr(0,11) == "bomb_pickup":
			ray_overlap.get_collider().queue_free()
			bombs = bombs + 1
			get_node("pickup").play()
			bomb_counter.get_node("Label").set_text(str(" x ", bombs))
			bomb_counter.show()
	#sink in acid
	if(check_overlap == TILE_ACID || check_bottom == TILE_ACID):
		new_anim = "fall"
		set_z(-1)
		move(Vector2(0,1))
		if !sinking:
			sinking = true
			get_node("sink").play()
		if(check_bottom == -1): # We passed through the acid
			destroy("acid")
		return
	
	#Check if we have to fall
	if move_down && check_bottom != TILE_LADDER && check_overlap != TILE_LADDER:
		falling = true
	else:
		falling = false
		
	if movement == 0 and move_up == 0: # We aren't moving
			
		if(falling): # We have to fall
			move(Vector2(0,4))
			new_anim = "fall"
			return # Stop the other actions (you can't fall and move right, after all)
		
		#Should we move right?
		if (!move_down || check_overlap == TILE_LADDER || check_bottom == TILE_LADDER) and move_right:
			if Input.is_action_pressed("btn_right"):
				movement = 64
				return

		#Should we move left?
		if (!move_down || check_overlap == TILE_LADDER || check_bottom == TILE_LADDER) and move_left:
			if Input.is_action_pressed("btn_left"):
				movement = -64
				return

		#Should we climb up?
		if check_overlap == TILE_LADDER && (check_top == -1 || check_top == TILE_LADDER):
			if Input.is_action_pressed("btn_up"):
				move_up = 64
				return

		#Should we climb down?
		if (check_bottom == TILE_LADDER || check_overlap == TILE_LADDER) && move_down:
			if Input.is_action_pressed("btn_down"):
				move_up = -64
				return

		# Should we place a bomb
		if(Input.is_action_pressed("place_bomb")):
			if(!place_bomb_was_pressed && bombs > 0): # Check if we have placed a bomb in the last frame.. if we had it will be better to not place one again
				var new_bomb = bomb.instance()
				new_bomb.set_pos(get_pos())
				tilemap.get_parent().add_child(new_bomb)
				bombs = bombs - 1
				bomb_counter.get_node("Label").set_text(str(" x ", bombs))
				if(bombs == 0):
					bomb_counter.hide()# Hide counter when no bombs are available
			place_bomb_was_pressed = true
		else:
			place_bomb_was_pressed = false
	#Commit moves
	if movement > 0:
		movement -= 4
		move(Vector2(4,0))
		check_orientation()
		new_anim = "walk"
	elif movement < 0:
		movement += 4
		move(Vector2(-4,0))
		check_orientation()
		new_anim = "walk"
	if move_up > 0:
		move_up -= 4
		move(Vector2(0,-4))
		new_anim = "climb"
	elif move_up < 0:
		move_up += 4
		move(Vector2(0,4))
		new_anim = "climb"
	elif (movement == 0) and !falling:# Not moving and not falling
		new_anim = "idle"

func _fixed_process(delta):
	old_anim = new_anim # Save the old anim
	logic() # do the logic
	play_anim() # Play the new anim if needed
	
	