extends KinematicBody2D
#This script is used for movable and static boxes/a
var ray_check_top # rays to check for objects in each direction
var ray_check_right
var ray_check_bottom
var ray_bottom
var ray_check_left

var collider_top = "" # Variables in which we store the colliders we find
var collider_right = ""
var collider_bottom = ""
var collider_left = ""

var check_top = "" # Variables in which we store the tiles in each direction
var check_right = ""
var check_bottom = ""
var check_left = ""

var sinking = false # Are we sinking?

var tilemap # the Tilemap
var movement = 0 # How much do we have to move? (+ for right)
var move_right = false # can we move left/right
var move_left = false
export var moveable = true # Can we move, or is this box a static one
export var TILE_COLLECT = 2 
export var TILE_SINK = 2 
export var TILE_LADDER = 1
var is_goal = true # Do we have to remove the box from the list of goals?
var is_registered_as_goal = false # Did we add the box to the list of goals?
var can_move_in = 5 # We freese the box for the first few frames
#some classes (e.g. other scripts)
var box_class = get_script()
var player_class = preload("res://scripts/player.gd")
var sample_player # The node that plays samples
var JS # joystick support module
var goal_type = "box" # The type of the goal

func _ready():
	if(moveable):
		set_fixed_process(true)
	# Getting nodes
	tilemap = get_node("../tilemap")
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_bottom = get_node("ray_bottom")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	ray_bottom.add_exception(self)
	JS = get_node("/root/SUTjoystick")
	sample_player = get_node("../../../sample")

func destroy(var by): # Called whenever the box is destroyed
	if(moveable && is_goal):
		if(by == "bomb"): # When we were demolished by a bomb
			get_node("../../../level_holder").goal_take(goal_type,1)
		elif(by == "collect"):
			get_node("../../../level_holder").goal_take(goal_type)
		is_goal = 0
	if(by != "acid" && by != "collect"): # When we weren't coroding
		queue_free() # delete the box from the scene

func stop_move():
	movement = 0
	can_move_in = 5

func _fixed_process(delta):
	if(can_move_in > 0):
		can_move_in = can_move_in - 1
		if(can_move_in <= 0 && moveable && !is_registered_as_goal):
			get_node("../../../level_holder").goal_add(goal_type) # When we can move, we add a goal to the level
			is_registered_as_goal = true # Prevent double-registering
		return
	if movement == 0: # We aren't moveing right now
		var current_position = get_pos()/64
		current_position = Vector2(round(current_position.x), floor(current_position.y))
		#fall
		var check_bottom = tilemap.get_cell(current_position.x, current_position.y + 1)
		var check_overlap = tilemap.get_cell(current_position.x, current_position.y)
		var check_top = tilemap.get_cell(current_position.x, current_position.y - 1)
		var move_down # can we move down
		if ray_bottom.is_colliding() and ray_bottom.get_collider():
			var collider_name = ray_bottom.get_collider().get_name()
			if(collider_name.substr(0,6) == "flower"): # When we fall into a flower
				move_down = true
				ray_bottom.get_collider().destroy("flower")
			elif collider_name.substr(0,11) == "bomb_pickup": # When we fall into a bomb
				if ray_check_bottom.is_colliding() and ray_check_bottom.get_collider():
					if(ray_bottom.get_collider() extends box_class):
						move_down = true
					else:
						move_down = false
				else:
					move_down = true
			else:
				move_down = false
		else:
			move_down = true
		if(check_top == TILE_SINK):#When we have fallen through the acid
			queue_free() # delete the box from the scene
			if(is_goal): # No way to pass the level if we are still a goal..
				get_node("../../../level_holder").level_impossible(0.1)
		
		#sinking
		if(check_bottom == TILE_SINK):
			if !sinking:
				sinking = true
				sample_player.play("sink", false)
		elif(check_bottom == TILE_COLLECT):
			if !sinking:
				sinking = true
		
		if move_down && (check_bottom == -1 || check_bottom == TILE_LADDER) && check_overlap != TILE_SINK && check_overlap != TILE_COLLECT: # we are able to fall
			move(Vector2(0,4))
		else:
			#sink
			if(((check_overlap == TILE_SINK || check_overlap == TILE_COLLECT) && move_down && (check_bottom == -1 || check_bottom == TILE_LADDER)) || (check_bottom == TILE_SINK || check_bottom == TILE_COLLECT) && move_down):# if we can sink
				set_z(-1)
				move(Vector2(0,1))
			if(check_overlap == TILE_COLLECT):
				destroy("collect")
			
			#check if we can move left
			var tm_left = tilemap.get_cell(current_position.x - 1, current_position.y)
			if(tm_left != -1 && tm_left != TILE_LADDER && tm_left != TILE_SINK):
				move_left = false
			elif ray_check_left.is_colliding() and ray_check_left.get_collider():
				check_left = ray_check_left.get_collider()
				if check_left extends box_class: # We can't move through boxes
					move_left = false
				else:
					move_left = true
			else:
				check_left = ""
				move_left = true
				
			#check if we can move right
			var tm_right = tilemap.get_cell(current_position.x + 1, current_position.y)
			if(tm_right != -1 && tm_right != TILE_LADDER && tm_right != TILE_SINK):
				move_right = false
			elif ray_check_right.is_colliding() and ray_check_right.get_collider():
				check_right = ray_check_right.get_collider()
				if check_right extends box_class: # We can't move through boxes
					move_right = false
				else:
					move_right = true
			else:
				check_right = ""
				move_right = true
			
			#Is the player pushing right?
			if ray_check_left.is_colliding() and move_right:
				collider_left = ray_check_left.get_collider()
				if collider_left and collider_left extends player_class && !collider_left.falling:
					if (Input.is_action_pressed("btn_right") || JS.get_digital("leftstick_right") || JS.get_digital("dpad_right")) && collider_left.movement == 0:# the player doesn't move, and is pressing right, and doesn't fall
						movement = 64 # Both we and the player move 64 px left
						collider_left.movement = 64
						get_node("../../../level_holder").turn()
						sample_player.play("box_hit", false)
			else:
				collider_left = ""
				
			#Is the player pushing left?
			if ray_check_right.is_colliding() and move_left:
				collider_right = ray_check_right.get_collider()
				if collider_right and collider_right extends player_class && !collider_right.falling:
					if (Input.is_action_pressed("btn_left") || JS.get_digital("leftstick_left") || JS.get_digital("dpad_left")) && collider_right.movement == 0:# the player doesn't move, and is pressing left, and doesn't fall
						movement = -64
						collider_right.movement = -64
						get_node("../../../level_holder").turn()
						sample_player.play("box_hit", false)
			else:
				collider_right = ""
				
	else:# When we are moving
		if movement > 0:
			movement -= 4
			move(Vector2(4,0))#Commit the move
		elif movement < 0:
			movement += 4
			move(Vector2(-4,0))#Commit the move

