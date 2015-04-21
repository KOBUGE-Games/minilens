extends "box.gd"

var fallen_in_force = false

func _ready():
	goal_type = "artefact"
	print(goal_type)

func destroy(var by): # Called whenever the box is destroyed
	if(moveable && is_goal):
		if(by == "collect"):
			get_node("../../../level_holder").goal_take(goal_type)
			is_goal = 0
		else:
			get_node("../../../level_holder").level_impossible(0.1)

func _fixed_process(delta):
	if movement == 0: # We aren't moveing right now
		var current_position = get_pos()/64
		if ray_bottom.is_colliding() and ray_bottom.get_collider():
			var collider_name = ray_bottom.get_collider().get_name()
			if collider_name.substr(0,5) == "force": # When we fall into a force
				fallen_in_force = true
				if !sinking:
					sinking = true
				if(int(get_pos().y) % 64 <= 1):
					destroy("collect")
		elif(fallen_in_force):
			get_node("../../../level_holder").goal_return(goal_type)
			fallen_in_force = false
			is_goal = true

