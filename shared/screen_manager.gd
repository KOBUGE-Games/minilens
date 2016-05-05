
extends Node

onready var viewport = get_viewport()
onready var initial_size = viewport.get_rect().size

var minimum_size = Vector2(0, 0)

func _ready():
	if Globals.has("display/width"):
		initial_size.x = Globals.get("display/width")
	if Globals.has("display/height"):
		initial_size.y = Globals.get("display/height")
	
	viewport.connect("size_changed", self, "window_resize")
	window_resize()

func set_minimum_size(s):
	if minimum_size != s:
		minimum_size = s
		window_resize()

func get_original_size():
	return initial_size

func window_resize():
	var current_size = OS.get_window_size()
	
	var scale_factor = initial_size.y/current_size.y
	var new_size = Vector2(current_size.x*scale_factor, initial_size.y)
	
	if new_size.y < minimum_size.y:
		scale_factor = minimum_size.y/new_size.y
		new_size = Vector2(new_size.x*scale_factor, minimum_size.y)
	if new_size.x < minimum_size.x:
		scale_factor = minimum_size.x/new_size.x
		new_size = Vector2(minimum_size.x, new_size.y*scale_factor)
	
	viewport.set_size_override(true, new_size)
