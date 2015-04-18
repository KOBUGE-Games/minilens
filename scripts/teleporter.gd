
extends KinematicBody2D

var ray_overlap # the ray with which we are checking for overlap

func _ready():
	ray_overlap = get_node("ray_overlap")
	


