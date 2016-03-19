
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
	var version = "%0.%1.%2-%3"
	for i in range(version_parts.size()):
		version = version.replace(str("%", i), str(version_parts[i]))
	
	OS.set_window_title(str("Minilens - Version ", version))
	
	# If debug is enabled, load the required level
	if get_config_property("debug_load_level"):
		ScenesManager.call_deferred("load_level", get_config_property("debug_load_level_pack"), get_config_property("debug_load_level_id"))
	
func get_config_property(name):
	return Globals.get(str("application.config/", name))

