
extends Control

var mouse_down = false
var last_mouse_pos = Vector2()
var preenable_top_margin = 0

var enabled = false

onready var player_camera = get_node("/root/world/player_holder/player/camera")
onready var tween = get_node("Tween")
onready var animation_player = get_node("AnimationPlayer")

func _ready():
	hide()

func set_enabled(active):
	var offset = player_camera.get_offset()
	var z = 0.24
	var camera_zoom = player_camera.get_zoom()
	var scale_factor = Vector2(active*z + 1, active*z + 1)
	
	tween.interpolate_property(player_camera, "zoom", camera_zoom, scale_factor, 0.4, 1, 1)
	tween.start()
	if offset != Vector2(0, 0):
		tween.interpolate_property(player_camera, "offset", offset, Vector2(0, 0), 0.4, 1, 1)
		tween.start()
	
	if active:
		player_camera.get_parent().disable()
		
		preenable_top_margin = player_camera.get_limit(MARGIN_TOP)
		var distance = player_camera.get_limit(MARGIN_BOTTOM) - player_camera.get_limit(MARGIN_TOP)
		var space = get_node("/root/ScreenManager").initial_size.y
		if distance / scale_factor.y < space:
			player_camera.set_limit(MARGIN_TOP, player_camera.get_limit(MARGIN_BOTTOM) - space * scale_factor.y)
			player_camera.force_update_scroll()
		
		player_camera.set_limit(MARGIN_TOP, player_camera.get_limit(MARGIN_TOP) - 60) # Makes things feel less rigid
		animation_player.play("enabled")
		show()
	else:
		player_camera.get_parent().enable()
		if enabled:
			animation_player.play("disabled")
			yield(animation_player, "finished")
			hide()
			player_camera.set_limit(MARGIN_TOP, preenable_top_margin)
			mouse_down = false
	
	if animation_player.is_playing():
		yield(animation_player, "finished")
	
	enabled = active

func _input_event(event):
	if enabled:
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
