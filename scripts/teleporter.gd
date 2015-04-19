
extends KinematicBody2D

var ray_overlap # the ray with which we are checking for overlap
export var to_teleport_path = "../teleporter"
var to
var lock
var locked = false
var was_locked = false
export var locked_timeout = 1
var lock_left = 0

func _ready():
	# Find nodes
	ray_overlap = get_node("ray_overlap")
	lock = get_node("sprite/error")
	ray_overlap.add_exception(self)
	
	set_fixed_process(true)

func _fixed_process(delta):
	lock_left = lock_left - delta
	if(!to):
		to = get_node(to_teleport_path)
	if(ray_overlap.is_colliding() && ray_overlap.get_collider()): # We have to teleport something
		if(!locked && !to.locked): # No locked teleports
			var collider = ray_overlap.get_collider()
			if(collider.has_method("set_pos")):
				collider.set_pos(to.get_pos())
				locked = true # Lock everything
				to.locked = true
				lock_left = locked_timeout
				to.lock_left = to.locked_timeout
				if(collider.has_method("stop_move")):
					collider.stop_move()
	elif(lock_left < 0):
		locked = false # Unlock
	if((locked || to.locked) && !was_locked):
		lock.show() # Show that we are locked
	elif(!(locked || to.locked) && was_locked):
		lock.hide() # Hide it
	was_locked = (locked || to.locked)
		