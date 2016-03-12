
extends TextureButton

onready var label = get_node("label") # The label with the name of the level
onready var number = get_node("number") # The label with the number of the level
onready var lock = get_node("lock") # The lock image

func set_text(text):
	label.set_text(text)

func set_number(n):
	number.set_text(str(n))

func set_locked(locked):
	set_disabled(locked)
	
	label.set_hidden(locked)
	number.set_hidden(locked)
	
	lock.set_hidden(!locked)