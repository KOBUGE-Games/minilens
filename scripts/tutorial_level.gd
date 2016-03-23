
extends Node2D

var areas = [] # An array with the different area nodes
var areas_fade_dir = {} # A dictionary in which we will store all ongoing and stopped animations
var fade_time = 1 # Time (in sec) for the area to fade in
var player_class = preload("res://entities/player.gd") # The class of the player (so we can check if the player is the body tat we are touching)
var pos_reached = 0 # How many help messages have we shown?

func _ready():
	var area_node = get_node("areas") # Get the node containing the areas
	if(area_node): # Make sure that this node exists
		area_node.set_z(10) # Make hints above everything else
		for i in range(area_node.get_child_count()): # For each area
			var current_area = area_node.get_child(i)
			current_area.connect("body_enter",self,"tutorial_area_enter",[i])
			current_area.connect("body_exit",self,"tutorial_area_exit",[i])
			areas_fade_dir[areas.size()] = 0 # Don't change opacity at all
			current_area.set_opacity(0) # Hide it
			areas.append(current_area)
	set_process( true )

func tutorial_area_enter(var body, var idx = 0):
	var diff = idx - pos_reached
	if(body extends player_class && (diff == 1 || diff == 0)):
		pos_reached = idx
		areas_fade_dir[idx] = 1 # Fade in
	
func tutorial_area_exit(var body, var idx = 0):
	if(body extends player_class):
		areas_fade_dir[idx] = -1 # Fade out
	
func _process(delta):
	for i in areas_fade_dir:
	
		if(areas_fade_dir[i] == 1): # Fading in
			var c_opacity = areas[i].get_opacity()
			areas[i].set_opacity(c_opacity + delta/fade_time)
			if(c_opacity >= 1):
				areas_fade_dir[i] = 0
	
		elif(areas_fade_dir[i] == -1): # Fading out
			var c_opacity = areas[i].get_opacity()
			areas[i].set_opacity(c_opacity - delta/fade_time)
			if(c_opacity <= 0):
				areas_fade_dir[i] = 0
