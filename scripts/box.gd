extends KinematicBody2D

var ray_top
var ray_right
var ray_bottom
var ray_left

var ray_check_top
var ray_check_right
var ray_check_bottom
var ray_check_left

var collider_top = ""
var collider_right = ""
var collider_bottom = ""
var collider_left = ""

var check_top = ""
var check_right = ""
var check_bottom = ""
var check_left = ""

var tilemap
var movement = 0
var move_right = false
var move_left = false

func _ready():
	set_fixed_process(true)
	tilemap = get_node("../tilemap")
	ray_top = get_node("ray_top")
	ray_right = get_node("ray_right")
	ray_bottom = get_node("ray_bottom")
	ray_left = get_node("ray_left")
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	
	ray_top.add_exception(self)
	ray_right.add_exception(self)
	ray_bottom.add_exception(self)
	ray_left.add_exception(self)
	
	#fix position
	move(Vector2(0,-4))

func _fixed_process(delta):
	if movement == 0:
		var current_position = get_pos()/64
		#fall
		if !ray_bottom.is_colliding() && tilemap.get_cell(current_position.x, current_position.y + 1) == -1:
			move(Vector2(0,4))
			collider_bottom = ""
		else:
			#sink
			if(ray_bottom.is_colliding()):
				collider_bottom = ray_bottom.get_collider().get_name()
				if collider_bottom.substr(0,4) == "acid":
					move(Vector2(0,1))
			#move left
			if ray_check_left.is_colliding() and move_right:
				collider_left = ray_check_left.get_collider().get_name()
				if collider_left == "player":
					if Input.is_action_pressed("btn_right"):
						movement = 64
						ray_check_left.get_collider().movement = ray_check_left.get_collider().movement + 64
			else:
				collider_left = ""
				
			#move right
			if ray_check_right.is_colliding() and move_left:
				collider_right = ray_check_right.get_collider().get_name()
				if collider_right == "player":
					if Input.is_action_pressed("btn_left"):
						movement = -64
						ray_check_right.get_collider().movement = ray_check_right.get_collider().movement - 64
			else:
				collider_right = ""
				
			#check left
			if ray_check_left.is_colliding():
				check_left = ray_check_left.get_collider().get_name()
				if tilemap.get_cell(current_position.x - 1, current_position.y) == 0 or check_left.substr(0,3) == "box":#!!!
					move_left = false
				else:
					move_left = true
			else:
				check_left == ""
				move_left = true
				
			#check right
			if ray_check_right.is_colliding():
				check_right = ray_check_right.get_collider().get_name()
				if tilemap.get_cell(current_position.x + 1, current_position.y) == 0 or check_right.substr(0,3) == "box":
					move_right = false
				else:
					move_right = true
			else:
				check_right == ""
				move_right = true
				
			#check bottom
		
	else:
		if movement > 0:
			movement -= 4
			move(Vector2(4,0))
		elif movement < 0:
			movement += 4
			move(Vector2(-4,0))








