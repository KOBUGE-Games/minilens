
extends "entity.gd"

export var seconds_left_to_explode = 2.5
export var seconds_after_explode = 1.2

var exploded = false

onready var timer = get_node("timer")
onready var animation_player = get_node("animation_player")

func _ready():
	timer.set_wait_time(seconds_left_to_explode)
	timer.set_one_shot(true)
	timer.connect("timeout", self, "destroy")
	timer.start()
	animation_player.connect("finished", self, "check_free")

func destroy():
	if not exploded:
		exploded = true
		animation_player.play("explode")
		play_sound("explode")
		
		level_holder.set_goal_wait(seconds_after_explode)
		
		for direction in ray_status:
			if ray_status[direction] != null and ray_status[direction].has_method("destroy"):
				ray_status[direction].destroy()
		
		set_layer_mask(0)
		set_collision_mask(0)

func check_free():
	if exploded:
		queue_free()
