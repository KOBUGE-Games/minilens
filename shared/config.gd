
extends Node

func _ready():
	# Seed the random generator
	randomize()
	
	# Set the version string
	var version_parts = [
		get_config_property("version_major"),
		get_config_property("version_minor"),
		get_config_property("version_patch"),
		get_config_property("version_build")
	]
	
	var version = version_parts[0] + "." + version_parts[1]
	if version_parts[2] != "0" and version_parts[2] != "":
		version += "." + version_parts[2]
	if version_parts[3] != "":
		version += "-" + version_parts[3]
	
	OS.set_window_title(str("Minilens - Version ", version))
	
	# If debug is enabled, load the required level
	if get_config_property("debug_load_level"):
		ScenesManager.call_deferred("load_level", get_config_property("debug_load_level_pack"), get_config_property("debug_load_level_id"))

	# If stepping is enabled, configure
	if get_config_property("debug_enable_step"):
		set_pause_mode(PAUSE_MODE_PROCESS)
		set_process_input(true)

var unpause_frames = 0
var event_repeats = 0
func _input(event):
	if event.is_action("step") and event.is_pressed():
		event_repeats += 1
		if event_repeats > 20:
			event_repeats = 0
			get_tree().set_pause(false)
			set_fixed_process(false)
		elif not event.is_echo():
			event_repeats = 0
			set_fixed_process(true)
			get_tree().set_pause(false)
			unpause_frames = 2
func _fixed_process(delta):
	unpause_frames -= 1
	if unpause_frames <= 0:
		get_tree().set_pause(true)
		set_fixed_process(false)

func get_config_property(name):
	return Globals.get(str("application.config/", name))

