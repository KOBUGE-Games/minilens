
extends Label

export(String, FILE) var splashes_path = "res://splashes.txt"

onready var splashes = FileManager.get_file_lines(splashes_path)

func _ready():
	var random = randi() % splashes.size()
	set_text(splashes[random])


