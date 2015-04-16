#==============================================================================#
# Shine Upon Thee Joysticks Module
#------------------------------------------------------------------------------#
# Written by Dana Olson <dana@shineuponthee.com>
#
# License: MIT (same as Godot Engine)
#
# Target Version: Godot Engine master branch
#
# Handles remapping gamepads automatically based on the device name reported
# by Godot. Also converts analog-digital and digital-analog so all pads support
# both (digital-analog conversions are limited to all-or-nothing values).
# Also supports automatic device registration and deregistration for up to 4 players.
# Also supports automatic device switching, eg: for single-player games.
#
# TO USE: add SUTjoystick.gd and the js_maps/ directory to your project.
# Add SUTjoystick.gd as an autoload.
#
# The functions you will be interested in are:
#   get_digital(name, player) - pass the digital state name you wish to poll and player number (optional). Returns 1/True or 0/False.
#   get_analog(name, player) -  pass the analog state name you wish to poll and player number (optional). Returns float between 0 and 1.
# And to a lesser extent:
#   get_device_name(player) - pass the player number (optional). Returns the name of the device assigned to the player.
#   get_device_number(player) - pass the player number (optional). Returns the system device number assigned to the player.
#   get_device_player(device) - pass the system device number. Returns the player number using the device.
#   deregister_player(player) - pass the player number (optional). Clears the assigned device(s) from the player or all players.
#
# Fully-detailed documentation is available in the README; also online here:
# https://gitlab.com/shine-upon-thee/joystick
#
# TODO:
# Show common_name when a profile is loaded, rather than raw name
# Enable the diagram on the mapper tool after editing a mapping, for testing purposes prior to upload.
# Android / Ouya support - possibly only one map is needed?
# Detailed states and signals for digital inputs?
# Pick up profiles in SUTjoystick GUI appdata dir? (could be problematic if users have old configs, but they could just regenerate them... would give the benefit of a global file for all games using this module)
# Detect max deadzone during junk collection? limit it to 50% or something, as that's pretty high
# Add more axis and buttons to Raw tab
# Somehow add a button to allow opening the map file directly in a text editor?
# Allow tweaking a mapping somehow, before submitting
# If no mapping is supported and fallback is disabled, passthru the raw values? May or may not be useful.
# Maybe just allow access to raw values via raw_*, where analog gets axes and digital gets buttons 
# Remove null key/value pairs from dictionaries before converting to json?
# Profile versioning, to ignore out-of-date files? (should be unnecessary, as I think we're stable now)
# Digital tooltips on diagram (tooltips not possible on sprites, apparently - this is more trouble than it's worth)
#==============================================================================#
extends Node

# Windows is in the list, but not really supported properly yet. Godot for Windows needs work...
const supported_os = [
	"x11",
	"windows"
]

const js_map_template = {
	common_name = "", # product name as sold in stores
	name = "", # name reported by driver to Godot
	md5 = "", # md5 of name reported by Godot
	os = null, # operating system profile applies to
	special = false,
	flight_stick = false,
	guitar = false,
	deadzone = 0.1,
	axis = {
		leftstick_up = null,
		leftstick_down = null,
		leftstick_left = null,
		leftstick_right = null,
		rightstick_up = null,
		rightstick_down = null,
		rightstick_left = null,
		rightstick_right = null,
		dpad_up = null,
		dpad_down = null,
		dpad_left = null,
		dpad_right = null,
		trig_left = null,
		trig_right = null
	},
	button = {
		dpad_up = null,
		dpad_down = null,
		dpad_left = null,
		dpad_right = null,
		trig_left = null,
		trig_right = null,
		action_1 = null, # A / green / cross / 6 o'clock
		action_2 = null, # B / red / circle / 3 o'clock
		action_3 = null, # X / blue / square / 9 o'clock
		action_4 = null, # Y / yellow / triangle / 12 o'clock
		back = null, # back / select
		start = null, # start
		home = null, # labeled analog
		bump_left = null,
		bump_right = null,
		click_left = null,
		click_right = null
	}
}

# mappings will be loaded first from user://, then from res://js_maps/, then from this array.
# mappings are OS-specific, so they're loaded by the load_js_maps function.
var js_maps = []

# set this flag to false to suppress debugging text output
var verbose = true
# this variable is used to disable falling back to the default mapping for unrecognized devices
var disable_fallback_map = false
# this variable will reassign a device to the first empty player slot in the event that an earlier player slot opens up (device is disconnected)
var reassign_active_devices = true
# this variable will hold the device id of whichever joystick is sending input
var player_device = [-1, -1, -1, -1] # 4-player support max (could be extended if need be)
# this variable holds the currently-active joystick mappings for each player
var active_map = [null,null,null,null]
# this is set at every input, allows to get input for any player
var active_player = 1 # from 1 to 4

# these hold the axis and button states in analog and digital formats
var analog_state = [
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,leftstick_hor=0,leftstick_ver=0,rightstick_hor=0,rightstick_ver=0,dpad_hor=0,dpad_ver=0},
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,leftstick_hor=0,leftstick_ver=0,rightstick_hor=0,rightstick_ver=0,dpad_hor=0,dpad_ver=0},
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,leftstick_hor=0,leftstick_ver=0,rightstick_hor=0,rightstick_ver=0,dpad_hor=0,dpad_ver=0},
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,leftstick_hor=0,leftstick_ver=0,rightstick_hor=0,rightstick_ver=0,dpad_hor=0,dpad_ver=0}
]
var digital_state = [
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,action_1=0,action_3=0,action_4=0,action_2=0,back=0,start=0,home=0,click_right=0,click_left=0,bump_left=0,bump_right=0},
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,action_1=0,action_3=0,action_4=0,action_2=0,back=0,start=0,home=0,click_right=0,click_left=0,bump_left=0,bump_right=0},
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,action_1=0,action_3=0,action_4=0,action_2=0,back=0,start=0,home=0,click_right=0,click_left=0,bump_left=0,bump_right=0},
	{leftstick_up=0,leftstick_down=0,leftstick_left=0,leftstick_right=0,rightstick_up=0,rightstick_down=0,rightstick_left=0,rightstick_right=0,dpad_up=0,dpad_down=0,dpad_left=0,dpad_right=0,trig_left=0,trig_right=0,action_1=0,action_3=0,action_4=0,action_2=0,back=0,start=0,home=0,click_right=0,click_left=0,bump_left=0,bump_right=0}
]

func _init():
	if not OS.get_name().to_lower() in supported_os:
		print("[SUTjoystick]: operating system not currently supported")
		return
	load_js_maps()
	Input.connect("joy_connection_changed",self,"_device_connection")
	set_process_input(true)
	print("[SUTjoystick]: module loaded")
	return


func load_js_maps():
# this function loads platform-specific maps and fallbacks into the js_maps array
# it runs once, at init time
# if the fallback hasn't been disabled, the first entry in the array will be used.
# if you don't want the js_maps directory in your project, you can add more json mappings to this array.
	if OS.get_name().to_lower() == 'x11':
		js_maps = [
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":3,"trig_right":6},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":9,"click_right":10,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":7,"trig_left":null,"trig_right":null},"common_name":"Fallback","deadzone":0.2,"flight_stick":false,"guitar":false,"md5":"882277bdf25efaeb8295e842ebcb3d11","name":"Fallback","os":"x11","special":false},
			# add new Linux mappings here
			{"axis":{"dpad_down":7,"dpad_left":-6,"dpad_right":6,"dpad_up":-7,"leftstick_down":3,"leftstick_left":-4,"leftstick_right":4,"leftstick_up":-3,"rightstick_down":2,"rightstick_left":-1,"rightstick_right":1,"rightstick_up":-2,"trig_left":null,"trig_right":null},"button":{"action_1":5,"action_2":6,"action_3":4,"action_4":7,"back":10,"bump_left":1,"bump_right":0,"click_left":3,"click_right":2,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":null,"start":11,"trig_left":9,"trig_right":8},"common_name":"Thrustmaster T-Flight Hotas X Flight Stick","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"028eb3d1145466520cda0304dd6850d5","name":"Thrustmaster T.Flight Hotas X","os":"x11","special":false},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":null,"leftstick_left":null,"leftstick_right":null,"leftstick_up":null,"rightstick_down":null,"rightstick_left":null,"rightstick_right":null,"rightstick_up":null,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":3,"action_4":0,"back":8,"blue":3,"bump_left":null,"bump_right":null,"click_left":null,"click_right":null,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"green":1,"home":12,"orange":4,"red":2,"start":9,"trig_left":null,"trig_right":null,"yellow":0},"common_name":"Guitar Hero 3 PS3 Guitar","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"12d6d31f37826c613975b1a13500c4a1","name":"Licensed by Sony Computer Entertainment Guitar Hero3 for PlayStation (R) 3","os":"x11","special":true},
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":3,"trig_right":6},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":9,"click_right":10,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":7,"trig_left":null,"trig_right":null},"common_name":"Logitech Gamepad F510","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"1494e42f2ef3a43aed70f3eb6bae44cb","name":"Logitech Gamepad F510","os":"x11","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":3,"trig_right":-6},"button":{"action_1":0,"action_2":3,"action_3":1,"action_4":2,"back":16,"bump_left":4,"bump_right":5,"click_left":6,"click_right":7,"dpad_down":9,"dpad_left":10,"dpad_right":11,"dpad_up":8,"home":15,"start":14,"trig_left":12,"trig_right":13},"common_name":"OUYA Wireless Controller","deadzone":0.15,"flight_stick":false,"guitar":false,"md5":"2282b5deb46ec99a8012a79483878334","name":"OUYA Game Controller","os":"x11","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":null,"leftstick_left":null,"leftstick_right":null,"leftstick_up":null,"rightstick_down":null,"rightstick_left":null,"rightstick_right":null,"rightstick_up":null,"trig_left":null,"trig_right":null},"button":{"action_1":null,"action_2":null,"action_3":null,"action_4":null,"back":null,"blue1":4,"blue2":9,"blue3":14,"blue4":19,"bump_left":null,"bump_right":null,"click_left":null,"click_right":null,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"green1":2,"green2":7,"green3":12,"green4":17,"home":null,"orange1":3,"orange2":8,"orange3":13,"orange4":18,"red1":0,"red2":5,"red3":10,"red4":15,"start":null,"trig_left":null,"trig_right":null,"yellow1":1,"yellow2":6,"yellow3":11,"yellow4":16},"common_name":"Buzz PS3 Controllers","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"2abaa9765204c75aec53a81ad6435f65","name":"Namtai Wbuzz","os":"x11","special":true},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":null,"leftstick_left":null,"leftstick_right":null,"leftstick_up":null,"rightstick_down":null,"rightstick_left":null,"rightstick_right":null,"rightstick_up":null,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"blue":0,"bump_left":null,"bump_right":null,"click_left":null,"click_right":null,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"green":1,"home":12,"lead_indicator":6,"orange":4,"red":2,"start":9,"trig_left":null,"trig_right":null,"yellow":3},"common_name":"Rock Band PS3 Guitar","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"4d60d1bda12f2d3e294838aa47d60d81","name":"Licensed by Sony Computer Entertainment America Harmonix Guitar for PlayStation3","os":"x11","special":true},
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":6,"trig_right":5},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":9,"click_right":10,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":7,"trig_left":null,"trig_right":null},"common_name":"Microsoft Xbox 360 Controller (xboxdrv)","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"5d98694fae9bc456936c3141dc2df5d1","name":"Xbox Gamepad (userspace driver)","os":"x11","special":false},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":12,"start":9,"trig_left":6,"trig_right":7},"common_name":"Rock Candy Wireless Gamepad","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"62cb440051003f81e5ebfabcb634d0a5","name":"Performance Designed Products Rock Candy Wireless Gamepad for PS3","os":"x11","special":false},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":null,"rightstick_left":null,"rightstick_right":null,"rightstick_up":null,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":null,"bump_right":null,"click_left":10,"click_right":null,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":12,"start":9,"trig_left":6,"trig_right":7},"common_name":"Rapala Fishing Rod PS3 Controller","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"6d75b4dc963aa0b331fc4a24097ad168","name":"GuitarHero for Playstation (R) 3 GuitarHero for Playstation (R) 3","os":"x11","special":true},
			{"axis":{"dpad_down":7,"dpad_left":-6,"dpad_right":6,"dpad_up":-7,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":null,"trig_right":null},"button":{"action_1":2,"action_2":1,"action_3":3,"action_4":0,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":null,"start":9,"trig_left":6,"trig_right":7},"common_name":"SPEEDLINK Strike Gamepad","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"7405f31b70f8002536e8771479cb1931","name":"DragonRise Inc.   Generic   USB  Joystick  ","os":"x11","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":-2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":2,"rightstick_down":-4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":4,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":0,"action_3":3,"action_4":2,"back":10,"bump_left":6,"bump_right":7,"click_left":null,"click_right":null,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":9,"trig_left":4,"trig_right":5},"common_name":"Nintendo Wii Classic Controller","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"8ea7def47e5e821805253745eb48e773","name":"Nintendo Wii Remote Classic Controller","os":"x11","special":false},
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":3,"trig_right":6},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":9,"click_right":10,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":7,"trig_left":null,"trig_right":null},"common_name":"Logitech Gamepad F310","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"8fd846f25dd3d37bc02dde759023cc27","name":"Logitech Gamepad F310","os":"x11","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":null,"rightstick_left":null,"rightstick_right":null,"rightstick_up":null,"trig_left":null,"trig_right":null},"button":{"action_1":14,"action_2":13,"action_3":null,"action_4":null,"back":null,"bump_left":10,"bump_right":null,"click_left":1,"click_right":null,"dpad_down":6,"dpad_left":7,"dpad_right":5,"dpad_up":4,"home":16,"start":null,"trig_left":8,"trig_right":null},"common_name":"PlayStation Navigation Controller","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"983a7856b9a6b0e406cf347b374357b1","name":"Sony Navigation Controller","os":"x11","special":false},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":null,"trig_right":null},"button":{"action_1":3,"action_2":4,"action_3":0,"action_4":1,"back":10,"bump_left":6,"bump_right":7,"click_left":2,"click_right":5,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":null,"start":11,"trig_left":8,"trig_right":9},"common_name":"InterAct Hammerhead FX Gamepad","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"98a74c9f896e219797038f079bbf3b72","name":"S.T.D. Interact Gaming Device","os":"x11","special":false},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":null,"start":9,"trig_left":6,"trig_right":7},"common_name":"Logitech Cordless RumblePad 2","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"ad549640d1dc4475e99322ab97aad5bc","name":"Logitech Logitech Cordless RumblePad 2","os":"x11","special":false},
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":6,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-6,"trig_left":4,"trig_right":5},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":12,"start":9,"trig_left":6,"trig_right":7},"common_name":"Sony DualShock 4 Controller","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"b3a3fcaa6e4b2ab4ef2652873401bb50","name":"Sony Computer Entertainment Wireless Controller","os":"x11","special":false},
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":3,"trig_right":6},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":9,"click_right":10,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":7,"trig_left":null,"trig_right":null},"common_name":"Microsoft Xbox 360 Controller","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"cfa4a29ff20eda298e1e9aae963a0cfa","name":"Microsoft X-Box 360 pad","os":"x11","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":13,"trig_right":14},"button":{"action_1":14,"action_2":13,"action_3":15,"action_4":12,"back":0,"bump_left":10,"bump_right":11,"click_left":1,"click_right":2,"dpad_down":6,"dpad_left":7,"dpad_right":5,"dpad_up":4,"home":16,"start":3,"trig_left":8,"trig_right":9},"common_name":"Sony DualShock 3 Controller","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"d13b8d6f46331f0e7ce5bac321b9e548","name":"Sony PLAYSTATION(R)3 Controller","os":"x11","special":false},
			{"axis":{"dpad_down":6,"dpad_left":-5,"dpad_right":5,"dpad_up":-6,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":12,"start":9,"trig_left":6,"trig_right":7},"common_name":"Hori Gem Pad 3","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"e348a33709a2ed9b6ffa8e7055ef2e39","name":"HORI CO.,LTD  PAD A","os":"x11","special":false},
			{"axis":{"dpad_down":2,"dpad_left":-1,"dpad_right":1,"dpad_up":-2,"leftstick_down":null,"leftstick_left":null,"leftstick_right":null,"leftstick_up":null,"rightstick_down":null,"rightstick_left":null,"rightstick_right":null,"rightstick_up":null,"trig_left":null,"trig_right":null},"button":{"action_1":0,"action_2":1,"action_3":3,"action_4":4,"back":null,"bump_left":6,"bump_right":7,"click_left":null,"click_right":null,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":null,"start":8,"trig_left":5,"trig_right":2},"common_name":"SLS Sega Saturn USB Control Pad (Cypress)","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"e374509322a147b7564531b1dfe528a0","name":"CYPRESS USB Gamepad","os":"x11","special":false},
			{"axis":{"dpad_down":8,"dpad_left":-7,"dpad_right":7,"dpad_up":-8,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":5,"rightstick_left":-4,"rightstick_right":4,"rightstick_up":-5,"trig_left":3,"trig_right":6},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":9,"click_right":10,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":8,"start":7,"trig_left":null,"trig_right":null},"common_name":"Logitech Wireless Gamepad F710","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"eab2a984c7e3a7d63145da4b85e354f6","name":"Logitech Gamepad F710","os":"x11","special":false},
			{"axis":{"dpad_down":5,"dpad_left":6,"dpad_right":5,"dpad_up":-6,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"home":null,"start":9,"trig_left":6,"trig_right":7},"common_name":"Logitech Dual Action Gamepad","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"fb062fb595f4a8dc6514de3711715cfc","name":"Logitech Logitech Dual Action","os":"x11","special":false},
		]
	elif OS.get_name().to_lower() == 'windows':
		js_maps = [
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-5,"rightstick_right":5,"rightstick_up":-4,"trig_left":3,"trig_right":-3},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":8,"click_right":9,"dpad_down":13,"dpad_left":14,"dpad_right":15,"dpad_up":12,"home":null,"start":7,"trig_left":null,"trig_right":null},"common_name":"Fallback","deadzone":0.2,"flight_stick":false,"guitar":false,"md5":"882277bdf25efaeb8295e842ebcb3d11","name":"Fallback","os":"windows","special":false},
			# add new Windows mappings here
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-3,"rightstick_right":3,"rightstick_up":-4,"trig_left":null,"trig_right":null},"button":{"action_1":1,"action_2":2,"action_3":0,"action_4":3,"back":8,"bump_left":4,"bump_right":5,"click_left":10,"click_right":11,"dpad_down":13,"dpad_left":14,"dpad_right":15,"dpad_up":12,"home":null,"start":9,"trig_left":6,"trig_right":7},"common_name":"Logitech Dual Action Gamepad","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"1cf550ea7d99812211fa396b7a6cd14d","name":"Logitech Dual Action USB","os":"windows","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-5,"rightstick_right":5,"rightstick_up":-4,"trig_left":3,"trig_right":-3},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":8,"click_right":9,"dpad_down":13,"dpad_left":14,"dpad_right":15,"dpad_up":12,"home":null,"start":7,"trig_left":null,"trig_right":null},"common_name":"Logitech Gamepad F510","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"5a56109c103985cd58cb632aba7ab21a","name":"Controller (Gamepad F510)","os":"windows","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-5,"rightstick_right":5,"rightstick_up":-4,"trig_left":3,"trig_right":-3},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":8,"click_right":9,"dpad_down":13,"dpad_left":14,"dpad_right":15,"dpad_up":12,"home":null,"start":7,"trig_left":null,"trig_right":null},"common_name":"Generic Gamepad","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"6600671ba26e978aae43536af123b683","name":"Microsoft PC-joystick driver","os":"windows","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-5,"rightstick_right":5,"rightstick_up":-4,"trig_left":3,"trig_right":-3},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":8,"click_right":9,"dpad_down":13,"dpad_left":14,"dpad_right":15,"dpad_up":12,"home":null,"start":7,"trig_left":null,"trig_right":null},"common_name":"Logitech Wireless Gamepad F710","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"ad7479fc125ad9464261f219b46ce088","name":"Controller (Gamepad F710)","os":"windows","special":false},
			{"axis":{"dpad_down":null,"dpad_left":null,"dpad_right":null,"dpad_up":null,"leftstick_down":2,"leftstick_left":-1,"leftstick_right":1,"leftstick_up":-2,"rightstick_down":4,"rightstick_left":-5,"rightstick_right":5,"rightstick_up":-4,"trig_left":3,"trig_right":-3},"button":{"action_1":0,"action_2":1,"action_3":2,"action_4":3,"back":6,"bump_left":4,"bump_right":5,"click_left":8,"click_right":9,"dpad_down":13,"dpad_left":14,"dpad_right":15,"dpad_up":12,"home":null,"start":7,"trig_left":null,"trig_right":null},"common_name":"Logitech Gamepad F310","deadzone":0.1,"flight_stick":false,"guitar":false,"md5":"dd91fa3cdc97ee58bfe45f2f417a444f","name":"Controller (Gamepad F310)","os":"windows","special":false},
		]
	return


################################################################################
# START OF PUBLIC FUNCTIONS

func get_digital(name, player=0):
# pass the button name and optional player number and get back true or false if it's pressed or not
# player will be 1-4, 0 will be any player
	# aliases for face buttons
	if name.match('action_*'):
		name = name.replace("_a","_1")
		name = name.replace("_south","_1")
		name = name.replace("_s","_1")
		name = name.replace("_down","_1")
		name = name.replace("_green","_1")
		name = name.replace("_cross","_1")
		name = name.replace("_b","_2")
		name = name.replace("_east","_2")
		name = name.replace("_e","_2")
		name = name.replace("_right","_2")
		name = name.replace("_red","_2")
		name = name.replace("_circle","_2")
		name = name.replace("_x","_3")
		name = name.replace("_west","_3")
		name = name.replace("_w","_3")
		name = name.replace("_left","_3")
		name = name.replace("_blue","_3")
		name = name.replace("_square","_3")
		name = name.replace("_y","_4")
		name = name.replace("_north","_4")
		name = name.replace("_n","_4")
		name = name.replace("_up","_4")
		name = name.replace("_yellow","_4")
		name = name.replace("_triangle","_4")
	else:
		# other aliases
		name = name.replace("guide","home")
		name = name.replace("ps","home")
		name = name.replace("playstation","home")
		name = name.replace("system","start")
		name = name.replace("run","start")
		name = name.replace("select","back")
		name = name.replace("option","back")
		name = name.replace("bumper_","bump_")
		name = name.replace("shoulder_","bump_")
		name = name.replace("trigger_","trig_")
		name = name.replace("d-pad_","dpad_")
		name = name.replace("d_pad_","dpad_")
		name = name.replace("direction_","dpad_")
		name = name.replace("directionpad_","dpad_")
		name = name.replace("ls_","leftstick_")
		name = name.replace("left_","leftstick_")
		name = name.replace("lstick_","leftstick_")
		name = name.replace("rs_","rightstick_")
		name = name.replace("right_","rightstick_")
		name = name.replace("rstick_","rightstick_")
	if player == 0:
		player = active_player
	return digital_state[player-1][name]


func get_analog(name, player=0):
# pass an axis name and optional player number and get back the value
# player will be 1-4, 0 will be any player
	# a few aliases
	name = name.replace("_vert","_ver")
	name = name.replace("_vertical","_ver")
	name = name.replace("_horiz","_hor")
	name = name.replace("_horizontal","_hor")
	name = name.replace("trigger_","trig_")
	name = name.replace("d-pad_","dpad_")
	name = name.replace("d_pad_","dpad_")
	name = name.replace("direction_","dpad_")
	name = name.replace("directionpad_","dpad_")
	name = name.replace("ls_","leftstick_")
	name = name.replace("left_","leftstick_")
	name = name.replace("lstick_","leftstick_")
	name = name.replace("rs_","rightstick_")
	name = name.replace("right_","rightstick_")
	name = name.replace("rstick_","rightstick_")
	if not player:
		player = active_player
	return analog_state[player-1][name]


func get_device_number(player=0):
# returns the current device number for the given player
# player will be 1-4
	if player == 0:
		player = active_player
	return player_device[player-1]


func get_device_player(device):
# returns the player number for the given system device number
# player will be 1-4
	for player in range(player_device.size()):
		if player_device[player] == device:
			return player+1
	return 0


func get_device_name(player=0):
# returns the device name for the given player
# returns empty string if no device connected
# player will be 1-4
	if player == 0:
		player = active_player
	if active_map[player-1] != null:
		if active_map[player-1].has("common_name"):
			return active_map[player-1]["common_name"]
		elif active_map[player-1].has("name"):
			return active_map[player-1]["name"]
		else:
			return ""
	else:
		return "No mapping found"


func deregister_player(player=0):
	if player > 0:
		debug_print("device " + str(player_device[player-1]) + " disconnected from player #" + str(player))
		player_device[player-1] = -1
		active_map[player-1] = null
	else:
		player_device= [-1,-1,-1,-1]
		active_map = [null,null,null,null]
		debug_print("deregistering all devices.")

# END OF PUBLIC FUNCTIONS
################################################################################


func get_assign_player_device(evdev):
# pass the event device and a boolean if we should be assigning unclaimed devices to open player slots
# returns the player number (0-3) for the given event device id.
	# loop through the 4 player devices and determine which this event is for
	var slot = -1 # this will be the player number the current device is assigned to, or -1
	for player in range(player_device.size()):
		var playerdev = player_device[player]
		# is evdev already in use by another player?
		var previous_player = get_device_player(evdev)
		if playerdev == evdev:
			# device was already assigned to a player, set slot to player number
			slot = player
			break
		elif (playerdev == -1) and not previous_player:
			# device hasn't been assigned yet, assign it to next player
			player_device[player] = evdev
			debug_print("assigned device #" + str(evdev) + " to player #" + str(player+1))
			slot = player
			update_js_map(slot)
			break
		elif (playerdev == -1) and reassign_active_devices:
			# player slot empty, reassign whatever device this is
			active_map[player] = active_map[previous_player-1]
			player_device[previous_player-1] = -1
			active_map[previous_player-1] = null
			# now reassign the device to the empty player slot
			player_device[player] = evdev
			debug_print("reassigned device #" + str(evdev) + " from player #" + str(previous_player) + " to player #" + str(player+1))
			slot = player
			break
		elif player == player_device.size() - 1:
			# if we have looped through all four slots in the player_device array
			debug_print("four devices assigned, ignoring device " + str(evdev))
	return slot


func _input(ev):
	var player = -1 # which assigned device are we using?
	# buttons
	if ev.type == InputEvent.JOYSTICK_BUTTON:
		player = get_assign_player_device(ev.device)
		if player == -1:
			return
		if active_map[player] == null:
			return
		for btn in active_map[player]["button"]:
			if active_map[player]["button"][btn] == ev.button_index:
				digital_state[player][btn] = ev.pressed
				# handle mapping certain buttons to axes
				if btn == "dpad_up" and active_map[player]["axis"]["dpad_up"] == null:
					analog_state[player]["dpad_up"] = ev.pressed
					analog_state[player]["dpad_ver"] = -ev.pressed
				elif btn == "dpad_down" and active_map[player]["axis"]["dpad_down"] == null:
					analog_state[player]["dpad_down"] = ev.pressed
					analog_state[player]["dpad_ver"] = ev.pressed
				elif btn == "dpad_left" and active_map[player]["axis"]["dpad_left"] == null:
					analog_state[player]["dpad_left"] = ev.pressed
					analog_state[player]["dpad_hor"] = -ev.pressed
				elif btn == "dpad_right" and active_map[player]["axis"]["dpad_right"] == null:
					analog_state[player]["dpad_right"] = ev.pressed
					analog_state[player]["dpad_hor"] = ev.pressed
				elif btn == "trig_left" and active_map[player]["axis"]["trig_left"] == null:
					analog_state[player]["trig_left"] = ev.pressed
				elif btn == "trig_right" and active_map[player]["axis"]["trig_right"] == null:
					analog_state[player]["trig_right"] = ev.pressed
		# update the active player number
		active_player = player + 1
	# axes
	elif ev.type == InputEvent.JOYSTICK_MOTION:
		if ev.axis > 13: # should be a safe number... ignore all events from DualShock 3 motion-sensing
			return
		# if an axis moves greater than 75%, we can assume it's a valid input and do the assign
		if abs(ev.value) > 0.75:
			player = get_assign_player_device(ev.device)
		else:
			player = get_device_player(ev.device) - 1
		if player == -1:
			return
		if active_map[player] == null:
			return
		# variable which will prevent updating the active player variable when a noisy device is sending values under the deadzone
		var skip_active_player_update = false
		# loop through all axis names from the map until we match the one the event is for
		for axis_name in active_map[player]["axis"]:
			# axes start at 1 in the maps due to signage: -0 clashes with +0
			# add 1 to event axis so it matches
			var evaxis = ev.axis + 1
			# if the event value is less than 0, check to match up negative axis in the maps
			if ev.value < 0:
				evaxis = -evaxis
			#NOTE triggers are super finnicky and handled differently by driver/device/platform
			# if I had my choice, the entire world would use a single gamepad, or at least a standard
			# but sadly, this won't happen. so, I have to make a sacrifice. gamepads that use a full
			# axis for each trigger will only register once they pass 0. they lose sensitivity, but this
			# is simply the easiest way to get around a stupid problem.
			# FIXME: what about triggers that share an axis? what happens if you pull both at the
			# same time? ...ARRRRRRGHHHHHHHHH
			# workaround for if left and right triggers do not share an axis
			if active_map[player]["axis"]["trig_left"] and active_map[player]["axis"]["trig_right"]:
				if abs(active_map[player]["axis"]["trig_left"]) != abs(active_map[player]["axis"]["trig_right"]):
					# if absolute event axis matches absolute trigger axis, force the polarity match
					if abs(evaxis) == abs(active_map[player]["axis"]["trig_left"]):
						evaxis = active_map[player]["axis"]["trig_left"]
					elif abs(evaxis) == abs(active_map[player]["axis"]["trig_right"]):
						evaxis = active_map[player]["axis"]["trig_right"]

			# if we get  a match from the map
			if active_map[player]["axis"][axis_name] == evaxis:
				# get the absolute event value
				var val = abs(ev.value)
				var mirror_axis = null # axis to zero, if any
				var composite_axis = null # ver/hor/bal axis to simulate
				var composite_val = 0
				# if it's a trigger, reverse the range to 0-1
				if axis_name == 'trig_left':
					# hacky workaround for stupid triggers...
					# if mapped axis polarity doesn't match event value, it was forced
					if active_map[player]["axis"][axis_name] > 0 and ev.value < 0:
						val = 0
					elif active_map[player]["axis"][axis_name] < 0 and ev.value > 0:
						val = 0
				elif axis_name == 'trig_right':
					# hacky workaround for stupid triggers...
					# if mapped axis polarity doesn't match event value, it was forced
					if active_map[player]["axis"][axis_name] > 0 and ev.value < 0:
						val = 0
					elif active_map[player]["axis"][axis_name] < 0 and ev.value > 0:
						val = 0
				# zero the opposite axis, except for triggers
				elif axis_name.match('*_up'):
					# if up is pressed, down must not be. zero it out.
					mirror_axis = axis_name.replace("_up","_down")
					# handle the vertical composite axis
					composite_axis = axis_name.replace("_up","_ver")
					composite_val = -val
				elif axis_name.match('*_down'):
					# if down is pressed, up must not be. zero it out.
					mirror_axis = axis_name.replace("_down","_up")
					# handle the vertical composite axis
					composite_axis = axis_name.replace("_down","_ver")
					composite_val = val
				elif axis_name.match('*_left'):
					# if left is pressed, right must not be. zero it out.
					mirror_axis = axis_name.replace("_left","_right")
					# handle the horizontal composite axis
					composite_axis = axis_name.replace("_left","_hor")
					composite_val = -val
				elif axis_name.match('*_right'):
					# if right is pressed, left must not be. zero it out.
					mirror_axis = axis_name.replace("_right","_left")
					# handle the horizontal composite axis
					composite_axis = axis_name.replace("_right","_hor")
					composite_val = val
				# set the composite axis state/value
				if composite_axis != null:
					if abs(composite_val) < active_map[player]["deadzone"]:
						composite_val = 0
					elif composite_val > 0.99:
					# it bothers me to never see a 1... maybe add an option to disable this, or maybe it should check against 1-deadzone?
						composite_val = 1
					elif composite_val < -0.99:
					# it bothers me to never see a 1... maybe add an option to disable this, or maybe it should check against 1-deadzone?
						composite_val = -1
					analog_state[player][composite_axis] = composite_val
				# check if our analog value is in the deadzone
				if val < active_map[player]["deadzone"]:
					# if the axis was already zero, let's not change the active player for noisy devices
					if analog_state[player][axis_name] == 0:
						skip_active_player_update = true
					val = 0
				elif val > 0.99:
				# it bothers me to never see a 1... maybe add an option to disable this, or maybe it should check against 1-deadzone?
					val = 1
				# set the analog state/value
				analog_state[player][axis_name] = val
				# convert analog values to digital states
				# mappings include a possible digital state for this axis
				if active_map[player]["button"].has(axis_name):
					# only set the digital state if this particular mapping doesn't have the button
					if active_map[player]["button"][axis_name] == null:
						digital_state[player][axis_name] = val > 0
				# mappings don't include a possible digital state for this axis
				else:
					digital_state[player][axis_name] = val > 0
				# now let's zero the flipped axis if need be
				if mirror_axis != null:
					analog_state[player][mirror_axis] = 0
					if active_map[player]["button"].has(axis_name):
						if active_map[player]["button"][axis_name] == null:
							digital_state[player][mirror_axis] = 0
					else:
						digital_state[player][mirror_axis] = 0
		# now update the active player number
		if not skip_active_player_update:
			active_player = player + 1
	return


func update_js_map(player):
	if player < 0:
		return
	var name = Input.get_joy_name(player_device[player])
	# remove this check later on, after fixing the bug mentioned in _device_connection()
	#if name == "":
	#	return
	var joy_md5 = name.md5_text()
	if active_map[player] != null and active_map[player]["md5"] == joy_md5:
		# no mapping change needed
		return
	# read from file first
	active_map[player] = load_mapping_file(joy_md5)
	if typeof(active_map[player]) == TYPE_DICTIONARY:
		if active_map[player].has("md5"):
			if active_map[player].md5 == joy_md5:
				debug_print("player " + str(player+1) + " is using " + active_map[player]["common_name"])
				return
	# read hard-coded mappings
	for map in js_maps:
		if map["md5"] == joy_md5:
			debug_print("using hard-coded mapping.")
			active_map[player] = map
			debug_print("player " + str(player+1) + " is using " + active_map[player]["common_name"])
			return
	# couldn't find a map, handle fallback behavior
	if disable_fallback_map:
		debug_print("no mapping found, fallback disabled. " + joy_md5)
	else:
		debug_print("no mapping found, using fallback. " + joy_md5)
		var map = js_maps[0]
		map.md5 = joy_md5
		active_map[player] = map
	return


func _device_connection(devnum, connected):
	if connected:
		debug_print("device " + str(devnum) + " connected")
		get_assign_player_device(devnum)
	else:
		# only disconnect if the device is assigned to a slot
		var player = get_device_player(devnum)
		if player:
			deregister_player(player)
	return


func debug_print(message):
	if verbose:
		print("[SUTjoystick]: " + message)
	return


# this function will load a json file into a mapping dictionary
# returns null if no file found
func load_mapping_file(joy_md5):
	var os = OS.get_name().to_lower()
	var f = File.new()
	var mapfile = "user://joystick-" + joy_md5 + "-" + os + ".json"
	if f.file_exists(mapfile):
		debug_print("using mapping from user file.")
	else:
		mapfile = "res://js_maps/joystick-" + joy_md5 + "-" + os + ".json"
		if f.file_exists(mapfile):
			debug_print("using mapping from bundled file.")
	if f.file_exists(mapfile):
		var err = f.open(mapfile,File.READ) #TODO: handle error
		var jsonmap = f.get_as_text()
		f.close()
		if jsonmap == "":
			return
		var map = js_map_template # not sure this does anything at all
		map.parse_json(jsonmap)
		return map
	return


# this function will write a mapping dictionary out to a json file
func save_mapping_file(map):
	debug_print("saving mapping to file...")
	if map["os"] == null:
		map["os"] = OS.get_name().to_lower()
	var mapfile = "user://joystick-" + map["md5"] + "-" + map["os"].to_lower() + ".json"
	var f = File.new()
	var err = f.open(mapfile,File.WRITE) #TODO: handle error
	f.store_string(map.to_json())
	f.close()
	return
