
extends StaticBody2D

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	get_node("../../../level_holder").goal_add()
	pass


