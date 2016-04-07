
extends KinematicBody2D

const TileConfig = preload("./tile_config.gd")
const TILE_SIZE = Vector2(64, 64)
const AUTOMOVE_SOUNDS = {
	push = "box_hit",
	sink = "sink"
}

signal auto_move_done(type)

export(bool) var fall = true
export(bool) var fall_though_ladders = true
export(bool) var destroy_after_acid = true
export(bool) var pushable = true
export(String) var goal = ""
export(bool) var score_goal_on_destroy = true
export(bool) var automatic_sounds = true
export(Vector2) var movement_speed = Vector2(200, 200)
export(NodePath) var tilemap_path = @"../tilemap"
export(NodePath) var level_holder_path = @"../.."

var tile_directions = {
	overlap = Vector2(0, 0),
	top = Vector2(0, -1),
	right = Vector2(1, 0),
	bottom = Vector2(0, 1),
	left = Vector2(-1, 0)
}

var tile_types = {}
var ray_status = {}

var is_moving = false
var movement = Vector2(0, 0)
var movement_original = Vector2(0, 0)
var movement_check_collision = ""
var speed_multiplier = 1
var pause_frames = 0
var wait_frames = 3
var push_direction = ""

onready var tilemap = get_node(tilemap_path)
onready var level_holder = get_node(level_holder_path)
onready var positional_audio = get_node("positional_audio")
onready var ray_nodes = {
	top = get_node("ray_top"),
	right = get_node("ray_right"),
	bottom = get_node("ray_bottom"),
	left = get_node("ray_left"),
	check_top = get_node("ray_check_top"),
	check_right = get_node("ray_check_right"),
	check_bottom = get_node("ray_check_bottom"),
	check_left = get_node("ray_check_left")
}

func _ready():
	for ray in ray_nodes:
		ray_nodes[ray].add_exception(self)
		ray_status[ray] = null
	
	for direction in tile_directions:
		tile_types[direction] = TileConfig.TILE_EMPTY
	
	if goal != "":
		level_holder.goal_add(goal)
	
	connect("auto_move_done", self, "play_auto_move_sound")
	set_fixed_process(true)

func _fixed_process(delta):
	if wait_frames > 0:
		wait_frames -= 1
		return
	
	if is_moving and pause_frames <= 0:
		#printt(get_name(), movement_check_collision, movement)
		if movement_check_collision != "":
			update_ray_status()
			if !can_move_in_direction(movement_check_collision, false, false, true):
				# It seems like we can't move there, so we just restore the position
				move(movement - movement_original)
				movement = Vector2(0, 0)
				movement_original = Vector2(0, 0)
				movement_check_collision = ""
				is_moving = false
		
		var speed = movement_speed * delta * speed_multiplier
		if movement.length_squared() > speed.length_squared():
			speed = speed * movement.normalized()
			movement -= speed
			move(speed)
		else:
			move(movement)
			movement = Vector2(0, 0)
			is_moving = false
			pause_frames = 3 # This way we would do the logic twice, in case the order of execution is important
	else:
		set_pos(get_pos().snapped(TILE_SIZE))
		update_status()
		movement_check_collision = ""
		movement = Vector2(0, 0)
		if !auto_move():
			next_move()
		movement_original = movement
		is_moving = movement.length_squared() > 0.001
	pause_frames -= 1

func update_status():
	update_tile_status()
	update_ray_status()

func update_tile_status():
	var current_position = tilemap.world_to_map(get_global_pos()).snapped(Vector2(1, 1))
	for direction in tile_directions:
		var cell = tilemap.get_cellv(current_position + tile_directions[direction])
		tile_types[direction] = TileConfig.get_tile_type(cell)

func update_ray_status():
	for ray in ray_nodes:
		if ray_nodes[ray].is_colliding() and ray_nodes[ray].get_collider() != null:
			ray_status[ray] = ray_nodes[ray].get_collider()
		else:
			ray_status[ray] = null

func auto_move():
	speed_multiplier = 1
	var old_push_direction = ""
	if tile_types.bottom == TileConfig.TILE_SINK or tile_types.overlap == TileConfig.TILE_SINK:
		set_z(-1)
	else:
		set_z(0)
	if pause_frames <= 1:
		old_push_direction = push_direction
	push_direction = ""
	if fall and destroy_after_acid and tile_types.top == TileConfig.TILE_SINK:
		emit_signal("auto_move_done", "sink_end")
		destroy()
	elif fall and destroy_after_acid and (!can_move_in_direction("bottom", !fall_though_ladders) and tile_types.overlap == TileConfig.TILE_SINK):
		emit_signal("auto_move_done", "sink_end")
		destroy_without_free()
	elif fall and can_move_in_direction("bottom", !fall_though_ladders) and (fall_though_ladders or tile_types.overlap != TileConfig.TILE_CLIMB):
		movement = TILE_SIZE * tile_directions.bottom
		if tile_types.bottom == TileConfig.TILE_SINK or tile_types.overlap == TileConfig.TILE_SINK:
			speed_multiplier = 0.2
			emit_signal("auto_move_done", "sink")
		else:
			emit_signal("auto_move_done", "fall")
	elif old_push_direction != "":
		movement = tile_directions[old_push_direction] * TILE_SIZE
		movement_check_collision = old_push_direction
		emit_signal("auto_move_done", "push")
	else:
		return false
	return true

func play_auto_move_sound(type):
	if pause_frames <= 1:
		if automatic_sounds and AUTOMOVE_SOUNDS.has(type):
			play_sound(AUTOMOVE_SOUNDS[type])

func play_sound(name):
	if SettingsManager.get_settings().sound:
		positional_audio.play(name)

func next_move(): # Virtual
	pass

func destroy_without_free(): # Virtual
	if score_goal_on_destroy and goal != "":
		level_holder.goal_take(goal)
		goal = ""
func destroy(): # Virtual
	destroy_without_free()
	queue_free()

func is_moving():
	return pause_frames <= 0 and is_moving

func stop_movement():
	movement = Vector2(0, 0)
	is_moving = false
	pause_frames = 3

func can_move_in_direction(direction, collide_with_climb = false, attempt_push = false, hard_check = false):
	if tile_types[direction] == TileConfig.TILE_SOLID:
		return false
	if collide_with_climb and tile_types[direction] == TileConfig.TILE_CLIMB:
		return false
	var ray_object = ray_status[direction]
	if hard_check:
		ray_object = ray_status[str("check_", direction)]
	if ray_object != null:
		# We can't use extends here, since get_script returns the finnal script of the object, not the current script.
		if ray_object.get("movement") != null:
			var dot = ray_object.movement.normalized().dot(tile_directions[direction])
			if !ray_object.is_moving():
				if attempt_push:
					return ray_object.can_be_pushed_in_direction(direction)
				else:
					return false
			elif ray_object.is_moving() and dot < 0.4:
				return false # We don't even attempt to push moving objects
			#else:
			#	printt(direction, ray_status[direction].movement, (tile_directions[direction]), ray_status[direction].movement.dot(tile_directions[direction]))
		else:
			return false
	
	return true

func can_be_pushed_in_direction(direction):
	update_status()
	if !pushable or is_moving:
		return false
	if !can_move_in_direction(direction, !fall_though_ladders, false):
		return false
	return true

func move_in_direction(direction, collide_with_climb = false, attempt_push = false, continious_collision = true):
	if !can_move_in_direction(direction, collide_with_climb, attempt_push):
		return false
	movement = tile_directions[direction] * TILE_SIZE
	
	if continious_collision and can_move_in_direction(direction, collide_with_climb, false, true):
		movement_check_collision = direction
	else:
		movement_check_collision = ""
	
	if attempt_push and ray_status[direction] != null and ray_status[direction].get("movement") != null:
		ray_status[direction].push_in_direction(direction)
	return true

func push_in_direction(direction):
	if !can_be_pushed_in_direction(direction):
		return false
	push_direction = direction
	return true
