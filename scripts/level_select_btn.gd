extends Node2D
# This script wraps the level btn, so that instead of using level_button.get_node(...), one might just call those functions

var metadata
var lock

func set_title(var title): # Set the title
	get_node("Label").set_text(title)
	
func set_locked(var locked): # Set if the level is locked
	lock = locked
	if(locked):
		get_node("Label").hide()
		get_node("lock").show()
	else:
		get_node("Label").show()
		get_node("lock").hide()

func set_metadata(var data): # Set the metadata
	metadata = data
	get_node("Label/bg_num").set_text(str(data))

func _on_Clickable_input_event( viewport, event, shape_idx ): # On click
	# It's a click, it isn't an echo of a previous click, it is pressed, and the level isn't locked
	if(event.type == InputEvent.MOUSE_BUTTON && !event.is_echo() && event.is_pressed() && !lock):
		get_node("../../../").level_btn_clicked(metadata) # We call the level_btn_clicked function, with the metadata
