extends StaticBody2D

# member variables here, example:
# var a=2
# var b="textvar"

var player_class = preload("res://scripts/player.gd")
var passed = false
var ray_check_top

func _ready():
	ray_check_top = get_node("ray_check_top")
	ray_check_top.add_exception(self)
	set_fixed_process(true)

func _fixed_process(delta):
	if(ray_check_top.is_colliding() && ray_check_top.get_collider()): # We have to break
		if(ray_check_top.get_collider() extends player_class): 
			passed = true
	elif(passed == true):
		queue_free()

