extends StaticBody2D
# This script maneges flowers

func _ready():
	get_node("../../../level_holder").goal_add()
	pass

func destroy(var by): # Called whenever the flower is destroyed
	if(by != "bomb"): # When we weren't demolished by a bomb
		get_node("../../../level_holder").goal_take()
		queue_free() # delete the flower from the scene

