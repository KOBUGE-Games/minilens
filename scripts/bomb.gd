extends KinematicBody2D
# Script that manages bombs

var ray_check_top # rays to check for objects in each direction
var ray_check_right
var ray_check_bottom
var ray_check_left
var ray_overlap

var sample_player # The node that plays samples

var check_top = "" # Variables in which we store the colliders we find
var check_right = ""
var check_bottom = ""
var check_left = ""
var check_overlap = ""

var seconds_left_to_explode = 2.2 # In how many seconds the bomb will explode?
var dangerous = true # Has the bomb exploded already?

func _ready():
	# find nodes
	ray_check_top = get_node("ray_check_top")
	ray_check_right = get_node("ray_check_right")
	ray_check_bottom = get_node("ray_check_bottom")
	ray_check_left = get_node("ray_check_left")
	ray_overlap = get_node("ray_overlap")
	ray_overlap.add_exception(self)
	
	set_fixed_process(true)

func _fixed_process(delta):
	seconds_left_to_explode = seconds_left_to_explode - delta # Decrease the timer
	if seconds_left_to_explode <= 0 && dangerous: # EXPLODE!
		get_node("../../../level_holder").play_sample("explode")
		#check for objects left
		if ray_check_left.is_colliding():
			check_left = ray_check_left.get_collider()
			if check_left.has_method("destroy"):
				ray_check_left.get_collider().destroy("bomb")
		#check for objects right
		if ray_check_right.is_colliding():
			check_right = ray_check_right.get_collider()
			if check_right.has_method("destroy"):
				ray_check_right.get_collider().destroy("bomb")
		#check for objects top
		if ray_check_top.is_colliding():
			check_top = ray_check_top.get_collider()
			if check_top.has_method("destroy"):
				ray_check_top.get_collider().destroy("bomb")
		#check for objects bottom
		if ray_check_bottom.is_colliding():
			check_bottom = ray_check_bottom.get_collider()
			if check_bottom.has_method("destroy"):
				ray_check_bottom.get_collider().destroy("bomb")
		#check for objects that overlap (e.g. the player)
		if ray_overlap.is_colliding():
			check_overlap = ray_overlap.get_collider()
			if check_overlap.has_method("destroy"):
				ray_overlap.get_collider().destroy("bomb")
		get_node("AnimationPlayer").play("Explode")
		set_fixed_process(false)
		set_layer_mask(2) # Move the bomb to second layer so object won't collide with it
		dangerous = false
		

func _on_AnimationPlayer_finished():
	if(!dangerous):
		queue_free() # Remove the bomb
