
extends "entity.gd"

var opposite_directions = {
	overlap = "overlap",
	top = "bottom",
	right = "left",
	bottom = "top",
	left = "right"
}

var carried_object = null
var first_movement_with_object = false
var should_drop = false

export var direction = "left"

func _ready():
	pass

func _process(delta):
	if carried_object != null:
		if first_movement_with_object:
			carried_object.set_pos(get_pos() + movement)
		else:
			carried_object.set_pos(get_pos() - movement_speed * speed_multiplier * delta)

func _fixed_process(delta):
	if carried_object != null and !first_movement_with_object:
		if carried_object.should_drop():
			should_drop = true
	

func next_move():
	if should_drop and pause_frames <= 1:
		should_drop = false
		if carried_object.has_method("enable"):
			carried_object.enable()
		carried_object.set_pos(get_pos())
		carried_object = null
		set_process(false)
	
	if ray_status[direction] != null and ray_status[direction].has_method("should_drop"):
		if carried_object == null:
			first_movement_with_object = true
			if pause_frames <= 1:
				carried_object = ray_status[direction]
				move_in_direction(direction, false, true)
				
				if carried_object.has_method("disable"):
					carried_object.disable()
				
				set_process(true)
		else:
			move_in_direction(direction, false, true)
	elif can_move_in_direction(direction, false, true):
		move_in_direction(direction, false, true)
		first_movement_with_object = false
	else:
		direction = opposite_directions[direction]
		wait_frames = 5

func destroy():
	pass # Do nothing