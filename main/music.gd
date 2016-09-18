
extends Node

func play_random_music():
	stop_music()
	if SettingsManager.get_settings().music:
		var stream_player = get_child(randi() % get_child_count())
		stream_player.play()
		stream_player.connect("finished", self, "play_random_music")

func stop_music():
	for child in get_children():
		child.stop()
		if child.is_connected("finished", self, "play_random_music"):
			child.disconnect("finished", self, "play_random_music")
