
extends CanvasLayer

const GOAL_TYPES = ["box", "flower", "artefact"]

var allow_next_level = false

onready var timer = get_node("timer")
onready var popup = get_node("popup")
onready var level_holder = get_node("../level_holder")
onready var player = get_node("../player_holder/player")
onready var JS = get_node("/root/SUTjoystick")

func _ready():
	# Removes the focus from the buttons
	for button in get_node("top_left_buttons").get_children():
		if button extends Control:
			button.set_focus_mode(Control.FOCUS_NONE)
			
			if button extends BaseButton:
				button.connect("pressed", self, "popup_button_pressed", [button.get_name()])
	
	# Removes the focus from the buttons
	for button in get_node("popup/body").get_children():
		if button extends BaseButton:
			button.connect("pressed", self, "popup_button_pressed", [button.get_name()])
	
	# Show some of the touch buttons depending on settings
	var input_mode = SettingsManager.read_settings().input_mode
	get_node("touch_controls/areas").set_hidden(input_mode != SettingsManager.INPUT_AREAS)
	get_node("touch_controls/buttons").set_hidden(input_mode != SettingsManager.INPUT_BUTTONS)
	
	# Turn off mouse emulation in-game
	JS.emulate_mouse(false)
	
	# Subscribe to various notifications
	level_holder.connect("counters_changed", self, "update_counters")
	get_node("/root").connect("size_changed", self, "window_resize")
	set_process_input(true)

func _input(event):
	if JS.get_digital("back") || (event.is_action("retry") && event.is_pressed() && !event.is_echo()):
		popup_button_pressed("retry")
	if JS.get_digital("action_3") || (event.is_action("next_level") && event.is_pressed() && !event.is_echo()):
		popup_button_pressed("next")
	if JS.get_digital("start") || (event.is_action("to_menu") && event.is_pressed() && !event.is_echo()):
		popup_button_pressed("menu")

func update_counters():
	get_node("counters/bomb/label").set_text(str(" x ", player.bombs))
	get_node("counters/resources/turns/label").set_text(str(level_holder.turns))
	
	for goal_type in GOAL_TYPES:
		if level_holder.goals_total.has(goal_type) and level_holder.goals_total[goal_type] > 0:
			get_node("counters/resources").get_node(goal_type).show()
			var label = get_node("counters/resources").get_node(goal_type).get_node("label")
			label.set_text(str(level_holder.goals_taken[goal_type], " / ", level_holder.goals_total[goal_type]))
		else:
			get_node("counters/resources").get_node(goal_type).hide()

func window_resize():
	var new_size = get_node("/root").get_size_override()
	
	popup.set_pos(Vector2(new_size.x/2-252,210))
	
	if !get_node("touch_controls/areas").is_hidden():
		var areas = get_node("touch_controls/areas")
		var unit = Vector2(new_size.x/6, new_size.y/6)
		var sides_scale = Vector2(unit.x/2,(new_size.y-2*unit.y)/2)
		var updown_scale = Vector2((new_size.x-2*unit.x)/2,unit.y/2)
		
		areas.get_node("left").set_pos(Vector2(0,unit.y))
		areas.get_node("left").set_scale(sides_scale)
		areas.get_node("right").set_pos(Vector2(new_size.x-unit.x,unit.y))
		areas.get_node("right").set_scale(sides_scale)
		areas.get_node("up").set_pos(Vector2(unit.x,0))
		areas.get_node("up").set_scale(updown_scale)
		areas.get_node("down").set_pos(Vector2(unit.x,new_size.y-unit.y))
		areas.get_node("down").set_scale(updown_scale)
		
		var bomb_size = areas.get_node("bomb").get_texture().get_size()*areas.get_node("bomb").get_scale()/2
		areas.get_node("bomb").set_pos(Vector2(new_size.x-0.5*unit.x-bomb_size.x,new_size.y-0.5*unit.y-bomb_size.y))
	
	elif !get_node("touch_controls/buttons").is_hidden():
		get_node("touch_controls/buttons").set_pos(Vector2(new_size.x-200,568))
	
	var scale = new_size.x/1024
	if(scale > 1):
		get_node("../gui/CanvasLayer/popup/popup_bg").set_scale(Vector2(scale,scale))

func prompt_retry_level(wait = 0): # Called when the robot dies
	allow_next_level = false
	show_popup("You died", "Your robot was destroyed!\n Do you want to try again?", wait)

func prompt_impossible_level(wait = 0): # Called when the level is impossible
	allow_next_level = false
	show_popup("Impossible", "It seems that it is impossible to pass this level!\nDo you want to try again?", wait)

func prompt_finsh_level(turns = 1, has_more_levels = true, wait = 0): # Called when the level is passed
	allow_next_level = has_more_levels
	
	var body_text = str("Level passed in ", turns, " turns.")
	if !has_more_levels:
		body_text = str(body_text, "\nThere are no more levels left in this pack. You can go to play some other pack, though.")
	
	show_popup("Good job!", body_text, wait)

func show_popup(title, text, wait): # Show a popup with title and text, after some time
	if wait:
		timer.set_wait_time(wait)
		timer.connect("timeout", self, "_show_popup", [
			title, text
		], CONNECT_ONESHOT)
		timer.start()
	else:
		_show_popup(title, text)

func _show_popup(title, text): # Show a popup with title and text
	JS.emulate_mouse(true)
	
	popup.get_node("header/title").set_text(title)
	popup.get_node("body/text").set_text(text)
	popup.get_node("body/next").set_disabled(!allow_next_level)
	
	popup.show()

func popup_button_pressed(name): # Actions for different popup buttons
	if name == "retry":
		level_holder.retry_level()
	elif name == "next":
		print(allow_next_level)
		if allow_next_level:
			allow_next_level = false
			level_holder.next_level()
		else:
			return
	elif name == "menu":
		get_node("/root/global").load_scene("res://menu/menu.tscn")
	
	JS.emulate_mouse(false)
	hide_popup()

func hide_popup(): # Hide the popup
	popup.hide()
