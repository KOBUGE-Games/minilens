extends StaticBody2D

var player_class = preload("res://entities/player.gd")
var passed = false
var destroyed = false
var delay = -1
var ray_check_top

func _ready():
	get_node("Sprite").set_opacity(1)
	get_node("Sprite").set_pos(Vector2(0,-8))
	ray_check_top = get_node("ray_check_top")
	ray_check_top.add_exception(self)
	set_fixed_process(true)

func _fixed_process(delta):
	if(ray_check_top.is_colliding() && ray_check_top.get_collider()): # We have to break
		if(ray_check_top.get_collider() extends player_class): 
			passed = true
	elif(passed == true && !destroyed):
		get_node("Sprite/AnimationPlayer").play("destroy")
		destroyed = true
		set_layer_mask(4)

func _on_AnimationPlayer_finished():
	if(destroyed):
		queue_free()

