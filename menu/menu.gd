
extends Control

export(float) var screen_move_speed = 100

var current_screen = "start"
var old_size = Vector2()

onready var levels = get_node("levels")
onready var options = get_node("options")
onready var credits = get_node("credits")
onready var tween = get_node("tween")

func _ready():
	# Main menu buttons
	for node in get_node("main/buttons").get_children():
		if node extends BaseButton:
			if node.get_name() == "quit":
				node.connect("pressed", self, "quit")
			else:
				node.connect("pressed", self, "go_to_target", [node.get_name()])
	
	# Back buttons
	for node in get_children():
		if node.has_node("back"):
			node.get_node("back").connect("pressed", self, "go_to_target", ["start"])
	
	# Splash fadeout
	if ScenesManager.is_first_load:
		get_node("initial_splash/animation_player").play("SplashFade")
	
	# Prepare to move thing when the aspect ratio changes
	connect("resized", self, "reposition_screens")
	reposition_screens()

func reposition_screens():
	var size = get_size()
	
	if size == old_size:
		return
	
	old_size = size
	
	levels.set_margin(MARGIN_LEFT, size.x)
	levels.set_margin(MARGIN_RIGHT, -size.x)
	
	options.set_margin(MARGIN_LEFT, -size.x)
	options.set_margin(MARGIN_RIGHT, size.x)
	
	credits.set_margin(MARGIN_TOP, size.y)
	credits.set_margin(MARGIN_BOTTOM, -size.y)
	
	var scale = size.x/1024
	if scale > 1:
		get_node("background_layer").set_scale(Vector2(scale,scale))
		get_node("background_layer").set_offset(Vector2(0,-(scale*768-768)))
		get_node("initial_splash").set_scale(Vector2(scale,scale))
		get_node("initial_splash").set_offset(Vector2(0,-(scale*768-768)/2))
	go_to_target(current_screen)

func go_to_target(var screen = "start"):
	current_screen = screen
	
	var target_coordinates = Vector2(0, 0) # By default, use the 0, 0 coordinates
	if has_node(screen):
		target_coordinates = get_node(screen).get_pos() # If possible, use the coordinates of the target
	
	var current_coordinates = get_pos()
	var distance = current_coordinates.distance_to(target_coordinates)
	var time = distance/screen_move_speed
	
	if time > 0:
		tween.interpolate_property(self, "rect/pos", current_coordinates, -target_coordinates, time, Tween.TRANS_EXPO, Tween.EASE_OUT, 0)
		tween.start()

func quit():
	get_tree().quit() # Exit the game
