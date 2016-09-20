
extends Control

var mouse_down = false
var last_mouse_pos = Vector2()
var preenable_top_margin = 0

onready var player_camera = get_node("../../player_holder/player/camera")
onready var tween = get_node("Tween")
onready var animation_player = get_node("AnimationPlayer")

func _ready():
	hide()
	set_enabled(false)

func set_enabled(enabled):
	player_camera.set_offset(Vector2(0, 0))
	var z = 0.24
	var camera_zoom = player_camera.get_zoom()
	var scale_factor = Vector2(enabled*z + 1, enabled*z + 1)
	
	tween.interpolate_property(player_camera, "zoom", camera_zoom, scale_factor, 0.5, 1, 1)
	tween.start()
	
	if enabled:
		player_camera.get_parent().can_move = false
		animation_player.play("enabled")
		
		preenable_top_margin = player_camera.get_limit(MARGIN_TOP)
		var distance = player_camera.get_limit(MARGIN_BOTTOM) - player_camera.get_limit(MARGIN_TOP)
		var space = get_node("/root/ScreenManager").initial_size.y
		if distance / scale_factor.y < space:
			player_camera.set_limit(MARGIN_TOP, player_camera.get_limit(MARGIN_BOTTOM) - space * scale_factor.y)
			player_camera.force_update_scroll()
		
		player_camera.set_limit(MARGIN_TOP, player_camera.get_limit(MARGIN_TOP) - 60) # Makes things feel less rigid
		show()
	else:
		player_camera.get_parent().can_move = true
		if camera_zoom > Vector2(1, 1):
			animation_player.play("disabled")
			animation_player.connect("finished", self, "set_disabled")

func set_disabled():
	hide()
	if animation_player.is_connected("finished", self, "set_disabled"):
		animation_player.disconnect("finished", self, "set_disabled")
	player_camera.set_limit(MARGIN_TOP, preenable_top_margin)

func _input_event(event):
	
	if event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT:
		mouse_down = event.is_pressed()
		last_mouse_pos = event.global_pos
	
	if mouse_down and event.type == InputEvent.MOUSE_MOTION:
		var delta = last_mouse_pos - event.global_pos
		var old_offset = player_camera.get_offset()
		
		var old_center_offset = player_camera.get_camera_screen_center() - player_camera.get_camera_pos()
		player_camera.set_offset(old_offset + delta)
		
		var new_center_offset =  player_camera.get_camera_screen_center() - player_camera.get_camera_pos()
		player_camera.set_offset(old_offset + new_center_offset - old_center_offset)
		
		last_mouse_pos = event.global_pos

