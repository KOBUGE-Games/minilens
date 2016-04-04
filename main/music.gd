
extends Node

func play_random_music():
	stop_music()
	if SettingsManager.get_settings().music:
		var stream_player = get_child(randi() % get_child_count())
		stream_player.play()

func stop_music():
	for child in get_children():
		child.stop()
