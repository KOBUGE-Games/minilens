
extends Area2D

const Entity = preload("res://entities/entity.gd")
const Player = preload("res://entities/player.gd")
const PICK_PLAYER = 0
const PICK_ALL = 1

export(String) var goal = ""
export(String) var meta = ""
export(int, "Player", "All entities") var pickable_by = 0
export(NodePath) var level_holder_path = @"../.."

onready var level_holder = get_node(level_holder_path)

func _ready():
	if goal != "":
		level_holder.goal_add(goal)
	connect("body_enter", self, "_body_enter")

func _body_enter(body):
	if (pickable_by == PICK_PLAYER and body extends Player) or (pickable_by == PICK_ALL and body extends Entity):
		if goal != "":
			level_holder.goal_take(goal)
			goal = ""
		if body.has_method("pickup"):
			body.pickup(self)
		destroy()

func destroy():
	queue_free()
