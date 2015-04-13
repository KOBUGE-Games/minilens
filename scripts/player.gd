
extends KinematicBody2D
var ray_top
var ray_right
var ray_bottom
var ray_left

var ray_check_top
var ray_check_right
var ray_check_bottom
var ray_check_left

var ray_overlap

var collider_top = ""
var collider_right = ""
var collider_bottom = ""
var collider_left = ""

var check_top = ""
var check_right = ""
var check_bottom = ""
var check_left = ""

var check_overlap = ""

var sinking = false

var movement = 0
var move_left = false
var move_right = false
var move_down = false

var tilemap
var current_position
export var TILE_LADDER = 1
export var TILE_ACID = 2
export var acid_animation_time = 1.0
var move_up = 0
var collider_name
var acid_animation_pos = 0.0
var place_bomb_was_pressed = false
var bomb = preload("res://scenes/bomb.xml")
var bombs = 0
var falling = false
var old_anim
var new_anim

func _ready():
	ray_top = get_node("ray_top")
	ray_right = get_node("ray_right")
	ray_bottom = get_node("ray_bottom")
	ray_left = get_node("ray_left")
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	
	ray_overlap = get_node("ray_overlap")
	
	ray_top.add_exception(self)
	ray_right.add_exception(self)
	ray_bottom.add_exception(self)
	ray_left.add_exception(self)
	
	ray_overlap.add_exception(self)
	
	#fix position

func level_load(var level_node):
	get_node("AnimatedSprite").set_frame(0)
	tilemap = level_node.get_node("tilemap")
	var camera = get_node("Camera2D")
	var top_left_pos = level_node.get_node("camera_start").get_pos()
	var bottom_right_pos = level_node.get_node("camera_end").get_pos()
	camera.set_limit(MARGIN_TOP, top_left_pos.y)
	camera.set_limit(MARGIN_LEFT, top_left_pos.x)
	camera.set_limit(MARGIN_BOTTOM, bottom_right_pos.y)
	camera.set_limit(MARGIN_RIGHT, bottom_right_pos.x)
	move(Vector2(0,-4))
	set_fixed_process(true)
	bombs = 0
	movement = 0
	move_up = 0

func destroy():
	get_node("../../level_holder").retry_level()

func play_anim():
	if(old_anim != new_anim):
		if(new_anim == "stop"):
			get_node("AnimatedSprite/AnimationPlayer")
			get_node("AnimatedSprite/AnimationPlayer").stop()
		else:
			get_node("AnimatedSprite/AnimationPlayer").play(new_anim)

func logic():
	current_position = (get_pos())/64
	#allow to move right
	check_right = tilemap.get_cell(current_position.x + 1, current_position.y)
	move_right = (check_right == -1 || check_right == TILE_LADDER)
	if ray_check_right.is_colliding() and ray_check_right.get_collider():
		var collider_name = ray_check_right.get_collider().get_name()
		if collider_name.substr(0,3) == "box":
			move_right = false

	#allow to move left
	check_left = tilemap.get_cell(current_position.x - 1, current_position.y)
	move_left = (check_left == -1 || check_left == TILE_LADDER)
	if ray_check_left.is_colliding() and ray_check_left.get_collider():
		var collider_name = ray_check_left.get_collider().get_name()
		if collider_name.substr(0,3) == "box":
			move_left = false

	#check overlap
	check_overlap = tilemap.get_cell(current_position.x, current_position.y)

	#check down
	check_bottom = tilemap.get_cell(current_position.x, current_position.y + 1)
	move_down = (check_bottom == -1 || check_bottom == TILE_LADDER)
	if ray_check_bottom.is_colliding() and ray_check_bottom.get_collider():
		var collider_name = ray_check_bottom.get_collider().get_name()
		if collider_name.substr(0,3) == "box":
			move_down = false
	move_down = move_down || int(get_pos().y)%64 != 0

	#check up
	check_top = tilemap.get_cell(current_position.x, current_position.y - 1)

	#collect flower
	if ray_overlap.is_colliding() and ray_overlap.get_collider():
		if ray_overlap.get_collider().get_name().substr(0,6) == "flower":
			ray_overlap.get_collider().queue_free()
			get_node("../../level_holder").goal_take()
			get_node("pickup").play()
		elif ray_overlap.get_collider().get_name().substr(0,11) == "bomb_pickup":
			ray_overlap.get_collider().queue_free()
			bombs = bombs + 1
	#sink
	if(check_overlap == TILE_ACID || check_bottom == TILE_ACID):
		new_anim = "fall"
		set_z(-1)
		move(Vector2(0,1))
		if !sinking:
			sinking = true
			get_node("sink").play()
		if(check_bottom == -1):
			destroy()
		return
	
	#fall
	if move_down && check_bottom != TILE_LADDER && check_overlap != TILE_LADDER:
		falling = true
	else:
		falling = false
		
	if movement == 0 and move_up == 0:
			
		if(falling):
			move(Vector2(0,4))
			new_anim = "fall"
			return
		#ask to move right
		if (!move_down || check_overlap == TILE_LADDER || check_bottom == TILE_LADDER) and move_right:
			if Input.is_action_pressed("btn_right"):
				movement = 64
				return

		#ask to move left
		if (!move_down || check_overlap == TILE_LADDER || check_bottom == TILE_LADDER) and move_left:
			if Input.is_action_pressed("btn_left"):
				movement = -64
				return

		#ask to climb
		if check_overlap == TILE_LADDER && (check_top == -1 || check_top == TILE_LADDER):
			if Input.is_action_pressed("btn_up"):
				move_up = 64
				return

		#ask to lower
		if (check_bottom == TILE_LADDER || check_overlap == TILE_LADDER) && move_down:
			if Input.is_action_pressed("btn_down"):
				move_up = -64
				return

			
		if(Input.is_action_pressed("place_bomb")):
			if(!place_bomb_was_pressed && bombs > 0):
				var new_bomb = bomb.instance()
				new_bomb.set_pos(get_pos())
				tilemap.get_parent().add_child(new_bomb)
				bombs = bombs - 1
			place_bomb_was_pressed = true
		else:
			place_bomb_was_pressed = false
	
	if movement > 0:
		movement -= 4
		move(Vector2(4,0))
		get_node("AnimatedSprite").set_flip_h(false)
		new_anim = "walking"
	elif movement < 0:
		movement += 4
		move(Vector2(-4,0))
		get_node("AnimatedSprite").set_flip_h(true)
		new_anim = "walking"
	if move_up > 0:
		move_up -= 4
		move(Vector2(0,-4))
		new_anim = "stop"
	elif move_up < 0:
		move_up += 4
		move(Vector2(0,4))
		new_anim = "stop"

func _fixed_process(delta):
	old_anim = new_anim
	new_anim = "stop"
	acid_animation_pos = acid_animation_pos + delta
	if(acid_animation_pos > acid_animation_time):
		acid_animation_pos = acid_animation_pos - acid_animation_time
	tilemap.get_tileset().tile_set_texture_offset(2, Vector2(-64*acid_animation_pos/acid_animation_time,0))
	logic()
	play_anim()
	
	