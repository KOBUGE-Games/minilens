
extends KinematicBody2D

var ray_overlap # the ray with which we are checking for overlap
export var to_teleport_path = "../teleporter"
var to
var sprite
var locked = true
var was_locked = false
export var locked_timeout = 1
var lock_left = 0.1
var show_locked = true
var c_rot = 0.0
export var rot_speed = 1

func _ready():
	# Find nodes
	ray_overlap = get_node("ray_overlap")
	sprite = get_node("sprite")
	ray_overlap.add_exception(self)
	
	set_fixed_process(true)
	set_process(true)

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
	show_locked = (locked || to.locked)
	if(show_locked && !was_locked):
		#lock
		sprite.set_region_rect(Rect2(64,0,64,64));
	elif(!show_locked && was_locked):
		#unlock
		sprite.set_region_rect(Rect2(0,0,64,64));
	was_locked = show_locked
		
func _process(delta):
	if(!show_locked):
		c_rot -= rot_speed * delta
		if(c_rot < -360):
			c_rot += 360
		if(c_rot > 0):
			c_rot -= 360
		sprite.set_rot(c_rot);
