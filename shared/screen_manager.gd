
extends Node

onready var viewport = get_viewport()
onready var initial_size = viewport.get_rect().size

func _ready():
	viewport.connect("size_changed", self, "window_resize")
	window_resize()

func window_resize():
	var current_size = OS.get_window_size()
	
	var changed = false
	if current_size.x < 100:
		current_size.x = 100
		changed = true
	if current_size.y < 100:
		current_size.y = 100
		changed = true
	
	if changed:
		OS.set_window_size(current_size)
	
	var scale_factor = initial_size.y/current_size.y
	var new_size = Vector2(current_size.x*scale_factor, initial_size.y)
	viewport.set_size_override(true, new_size)
