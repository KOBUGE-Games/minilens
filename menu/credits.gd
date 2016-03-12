
extends Label

export(String, FILE) var credits_path = "res://CREDITS.txt"

onready var credits = FileManager.get_file_contents(credits_path)

func _ready():
	set_text(credits)


