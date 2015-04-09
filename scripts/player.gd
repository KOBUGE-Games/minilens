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

var movement = 0
var move_left = false
var move_right = false

var move_up = 0

func _ready():
	set_fixed_process(true)
	
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
	move(Vector2(0,-4))
	
func _fixed_process(delta):
	
	if movement == 0 and move_up == 0:
		#allow to move right
		if ray_check_right.is_colliding():
			check_right = ray_check_right.get_collider().get_name()
			if check_right.substr(0,6) == "ground" or check_right.substr(0,3) == "box":
				move_right = false
			else:
				move_right = true
		else:
			check_right =  ""
			move_right = true
		
		#allow to move left
		if ray_check_left.is_colliding():
			check_left = ray_check_left.get_collider().get_name()
			if check_left.substr(0,6) == "ground" or check_left.substr(0,3) == "box":
				move_left = false
			else:
				move_left = true
		else:
			check_left =  ""
			move_left = true
			
				#check overlap
		if ray_overlap.is_colliding():
			check_overlap = ray_overlap.get_collider().get_name()
		else:
			check_overlap = ""
			
		#check down
		if ray_check_bottom.is_colliding():
			check_bottom = ray_check_bottom.get_collider().get_name()
		else:
			check_bottom = ""
	
		#ask to move right
		if ray_bottom.is_colliding() and move_right:
			if Input.is_action_pressed("btn_right"):
				get_node("Sprite").set_flip_h(false)
				movement = 64
				
		#ask to move left
		if ray_bottom.is_colliding() and move_left:
			if Input.is_action_pressed("btn_left"):
				get_node("Sprite").set_flip_h(true)
				movement = -64
				
		#ask to climb
		if check_overlap.substr(0,6) == "ladder":
			if Input.is_action_pressed("btn_up"):
				move_up = 64
				
		#ask to lower
		if check_bottom.substr(0,6) == "ladder":
			if Input.is_action_pressed("btn_down"):
				move_up = -64

		#fall
		if !ray_bottom.is_colliding():
			move(Vector2(0,4))
	
	else:
		if movement > 0:
			movement -= 4
			move(Vector2(4,0))
		elif movement < 0:
			movement += 4
			move(Vector2(-4,0))
		if move_up > 0:
			move_up -= 4
			move(Vector2(0,-4))
		elif move_up < 0:
			move_up += 4
			move(Vector2(0,4))