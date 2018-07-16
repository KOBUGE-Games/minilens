
extends Label

export(String, FILE) var credits_path = "res://CREDITS.txt"

onready var credits = FileManager.get_file_contents(credits_path)

func _ready():
	var translated_credits = ""
	for line in credits.split('\n'):
		translated_credits += tr(line) + '\n'
	set_text(translated_credits)


