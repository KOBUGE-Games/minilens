
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
	
	# Screen size
	var minimum_size = get_minimum_size()
	for child in get_children():
		if child extends Control:
			var child_minimum_size = child.get_minimum_size()
			minimum_size.x = max(minimum_size.x, child_minimum_size.x)
			minimum_size.y = max(minimum_size.y, child_minimum_size.y)
	ScreenManager.set_minimum_size(minimum_size)
	
	# Splash fadeout
	if ScenesManager.is_first_load:
		get_node("animation_player").play("SplashFade")
	
	# Prepare to move thing when the aspect ratio changes
	connect("resized", self, "reposition_screens")
	set_process_input(true)
	reposition_screens()

func _input(event):
	if event.is_action_pressed("exit"):
		if current_screen == "start":
			get_tree().quit()
		else:
			go_to_target("start", true)

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
	
	var initial_size = ScreenManager.get_original_size()
	var scale_vector = size / initial_size
	var scale = max(scale_vector.x, scale_vector.y)
	
	if  scale > 1:
		get_node("background_layer").set_scale(Vector2(scale,scale))
		get_node("initial_splash").set_offset((size - initial_size) * Vector2(0.5, 0))
		if scale_vector.y / scale_vector.x < 1:
			get_node("background_layer").set_offset(Vector2(0, (1 - scale_vector.x / scale_vector.y) * initial_size.y))
		else:
			get_node("background_layer").set_offset(Vector2(0, 0))
	tween.remove_all()
	go_to_target(current_screen, false)

func go_to_target(screen = "start", animate = true):
	current_screen = screen
	
	var target_coordinates = Vector2(0, 0) # By default, use the 0, 0 coordinates
	if has_node(screen):
		target_coordinates = get_node(screen).get_pos() # If possible, use the coordinates of the target
	
	var current_coordinates = get_pos()
	var distance = current_coordinates.distance_to(target_coordinates)
	var time = distance/screen_move_speed
	
	if time > 0:
		tween.remove_all()
		if animate:
			tween.interpolate_property(self, "rect/pos", current_coordinates, -target_coordinates, time, Tween.TRANS_EXPO, Tween.EASE_OUT, 0)
			tween.start()
		else:
			set("rect/pos", -target_coordinates)

func quit():
	get_tree().quit() # Exit the game
