
extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"
var metadata

func set_title(var title):
	get_node("Label").set_text(title)

func set_metadata(var data):
	metadata = data


func _on_Clickable_input_event( viewport, event, shape_idx ):
	if(event.type == InputEvent.MOUSE_BUTTON && !event.is_echo() && event.is_pressed()):
		get_node("../../../").level_btn_clicked(metadata)
		pass # replace with function body
