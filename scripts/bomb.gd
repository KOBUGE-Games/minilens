extends KinematicBody2D


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

export var seconds_left_to_explode = 3.0

func _ready():
	set_fixed_process(true)
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	
	#fix position
	move(Vector2(0,-4))

func _fixed_process(delta):
	seconds_left_to_explode = seconds_left_to_explode - delta
	if seconds_left_to_explode <= 0:
		#check left
		if ray_check_left.is_colliding():
			check_left = ray_check_left.get_collider().get_name()
			if check_left.substr(0,3) == "box" or check_left == "player":
				ray_check_left.get_collider().destroy()
		#check right
		if ray_check_right.is_colliding():
			check_right = ray_check_right.get_collider().get_name()
			if check_right.substr(0,3) == "box" or check_right == "player":
				ray_check_right.get_collider().destroy()
		#check top
		if ray_check_top.is_colliding():
			check_top = ray_check_top.get_collider().get_name()
			if check_top.substr(0,3) == "box" or check_top == "player":
				ray_check_top.get_collider().destroy()
		#check bottom
		if ray_check_bottom.is_colliding():
			check_bottom = ray_check_bottom.get_collider().get_name()
			if check_bottom.substr(0,3) == "box" or check_bottom == "player":
				ray_check_bottom.get_collider().destroy()
		queue_free()
		








