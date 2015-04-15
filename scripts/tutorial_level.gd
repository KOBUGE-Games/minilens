
extends Node2D

var areas = [] # an array with the different area nodes
var areas_fade_dir = {} # a dictionary in which we will store all ongoing and stopped animations
var fade_time = 1 # time (in sec) for the area to fade in
var player_class = preload("res://scripts/player.gd") # the class of the player (so we can check if the player is the body tat we are touching)
var pos_reached = 0 # how many tut messages have we shown?

func _ready():
	var area_node = get_node("areas") # get the node containing the areas
	if(area_node): # make sure that this node exists
		area_node.set_z(10) # make hints above everything else
		for i in range(area_node.get_child_count()): # for each area
			var current_area = area_node.get_child(i)
			current_area.connect("body_enter",self,"tutorial_area_enter",[i])
			current_area.connect("body_exit",self,"tutorial_area_exit",[i])
			areas_fade_dir[areas.size()] = 0 # don't change opacity
			current_area.set_opacity(0) # hide it
			areas.append(current_area)
	set_process( true )

func tutorial_area_enter(var body, var idx = 0):
	var diff = idx - pos_reached
	if(body extends player_class && (diff == 1 || diff == 0)):
		pos_reached = idx
		areas_fade_dir[idx] = 1 # fade in
	
func tutorial_area_exit(var body, var idx = 0):
	if(body extends player_class):
		areas_fade_dir[idx] = -1 # fade out
	
func _process(delta):
	for i in areas_fade_dir:
		if(areas_fade_dir[i] == 1):
			var c_opacity = areas[i].get_opacity()
			areas[i].set_opacity(c_opacity + delta/fade_time)
			if(c_opacity >= 1):
				areas_fade_dir[i] = 0
		elif(areas_fade_dir[i] == -1):
			var c_opacity = areas[i].get_opacity()
			areas[i].set_opacity(c_opacity - delta/fade_time)
			if(c_opacity <= 0):
				areas_fade_dir[i] = 0
