extends StaticBody2D

var player_class = preload("res://entities/player.gd")
var passed = false
var destroyed = false
var delay = -1
onready var ray_check_top = get_node("ray_check_top")
onready var animation_player = get_node("animation_player")

func _ready():
	ray_check_top.add_exception(self)
	
	animation_player.connect("finished", self, "animation_finished")
	
	get_node("sprite").set_opacity(1)
	get_node("sprite").set_pos(Vector2(0,-8))
	
	set_fixed_process(true)

func _fixed_process(delta):
	if(ray_check_top.is_colliding() && ray_check_top.get_collider()): # We have to break
		if(ray_check_top.get_collider() extends player_class): 
			passed = true
			
	elif(passed == true && !destroyed):
		animation_player.play("destroy")
		destroyed = true
		set_layer_mask(4)

func animation_finished():
	if(destroyed):
		queue_free()

