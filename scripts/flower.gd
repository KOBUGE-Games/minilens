extends StaticBody2D
# This script maneges flowers

func _ready():
	get_node("../../../level_holder").goal_add("flower")
	pass

func destroy(var by): # Called whenever the flower is destroyed
	if(by != "bomb"): # When we weren't demolished by a bomb
		get_node("../../../level_holder").goal_take("flower")
		queue_free() # delete the flower from the scene

