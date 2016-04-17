
extends CanvasLayer

const GOAL_TYPES = ["box", "flower", "artefact"]

var allow_next_level = false
var popup_running = false

onready var timer = get_node("timer")
onready var popup = get_node("popup")
onready var level_holder = get_node("../level_holder")
onready var player = get_node("../player_holder/player")
onready var JS = get_node("/root/SUTjoystick")

func _ready():
	var nodes_left = get_node("popup/popup_node/body/container").get_children()
	
	# Removes the focus from the buttons
	for button in get_node("top_left_buttons").get_children():
		if button extends Control:
			button.set_focus_mode(Control.FOCUS_NONE)
			
			if button extends BaseButton:
				nodes_left.push_back(button)
	
	# Removes the focus from the buttons
	while nodes_left.size() > 0:
		var button = nodes_left[nodes_left.size() - 1]
		nodes_left.pop_back()
		if button extends BaseButton:
			button.connect("pressed", self, "popup_button_pressed", [button.get_name()])
		else:
			for i in button.get_children():
				nodes_left.push_back(i)
	
	# Show some of the touch buttons depending on settings
	var input_mode = SettingsManager.read_settings().input_mode
	get_node("touch_controls").set_hidden(!OS.has_touchscreen_ui_hint())
	get_node("touch_controls/areas").set_hidden(input_mode != SettingsManager.INPUT_AREAS)
	get_node("touch_controls/areas").set_ignore_mouse(input_mode != SettingsManager.INPUT_AREAS)
	get_node("touch_controls/buttons").set_hidden(input_mode != SettingsManager.INPUT_BUTTONS)
	get_node("touch_controls/buttons").set_ignore_mouse(input_mode != SettingsManager.INPUT_BUTTONS)
	
	# Turn off mouse emulation in-game
	JS.emulate_mouse(false)
	
	# Subscribe to various notifications
	level_holder.connect("counters_changed", self, "update_counters")
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

func prompt_retry_level(wait = 0): # Called when the robot dies
	if not popup_running or allow_next_level:
		allow_next_level = false
		show_popup("You died", "Your robot was destroyed!\n Do you want to try again?", wait)

func prompt_impossible_level(wait = 0): # Called when the level is impossible
	if not popup_running or allow_next_level:
		allow_next_level = false
		show_popup("Impossible", "It seems that it is impossible to pass this level!\nDo you want to try again?", wait)

func prompt_finsh_level(turns = 1, has_more_levels = true, wait = 0): # Called when the level is passed
	if not popup_running:
		allow_next_level = has_more_levels
		
		var body_text = str("Level passed in ", turns, " turns.")
		if !has_more_levels:
			body_text = str(body_text, "\nYou completed all the levels of this pack. Select another pack to play in the level selection menu.")
		
		show_popup("Good job!", body_text, wait)

func show_popup(title, text, wait): # Show a popup with title and text, after some time
	popup_running = true
	timer.disconnect("timeout", self, "_show_popup")
	if wait > 0:
		timer.set_wait_time(wait)
		timer.connect("timeout", self, "_show_popup", [
			title, text
		], CONNECT_ONESHOT)
		timer.start()
	else:
		_show_popup(title, text)

func _show_popup(title, text): # Show a popup with title and text
	JS.emulate_mouse(true)
	get_tree().set_pause(true)
	
	popup.get_node("popup_node/header/title").set_text(title)
	popup.get_node("popup_node/body/container/text").set_text(text)
	popup.get_node("popup_node/body/container/level_buttons/next").set_hidden(!allow_next_level)
	
	popup.show()

func popup_button_pressed(name): # Actions for different popup buttons
	if name == "retry":
		level_holder.retry_level()
	elif name == "next":
		if allow_next_level:
			allow_next_level = false
			level_holder.next_level()
		else:
			return
	elif name == "menu":
		ScenesManager.load_scene("res://menu/menu.tscn")
	
	JS.emulate_mouse(false)
	hide_popup()

func hide_popup(): # Hide the popup
	popup_running = false
	get_tree().set_pause(false)
	popup.hide()
