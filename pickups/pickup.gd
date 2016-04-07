
extends Area2D

const Entity = preload("res://entities/entity.gd")
const Player = preload("res://entities/player.gd")
const PICK_PLAYER = 0
const PICK_ALL = 1

export(String) var goal = ""
export(String) var meta = ""
export(String) var play_sound = ""
export(int, "Player", "All entities") var pickable_by = 0
export(NodePath) var level_holder_path = @"../.."

var picked = false
var pause_frames = 3

onready var level_holder = get_node(level_holder_path)

func _ready():
	if goal != "":
		level_holder.goal_add(goal)
	set_fixed_process(true)

func _fixed_process(delta):
	pause_frames -= 1
	if pause_frames < 0:
		set_fixed_process(false)
		connect("body_enter", self, "_body_enter")

func _body_enter(body):
	if !picked and ((pickable_by == PICK_PLAYER and body extends Player) or (pickable_by == PICK_ALL and body extends Entity)):
		picked = true
		if goal != "":
			level_holder.goal_take(goal)
			goal = ""
		if body.has_method("pickup"):
			body.pickup(self)
		if play_sound != "" and SettingsManager.get_settings().sound:
			get_node("positional_audio").play(play_sound)
		destroy()

func destroy():
	hide()
	var timer = get_node("destroy_timer")
	timer.connect("timeout", self, "queue_free")
	timer.start()
