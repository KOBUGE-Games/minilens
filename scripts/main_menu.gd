extends Control

var select_level
var run_once = true

func _ready():
	select_level = get_node("opt_level")
	
	var diraccess = Directory.new()
	diraccess.open("res://levels/tutorial/")

	diraccess.list_dir_begin()
	var name = diraccess.get_next()

	while name:
		if !diraccess.current_is_dir():
			if name.length() > 3:
				select_level.add_item(name)
		name = diraccess.get_next()
	diraccess.list_dir_end()
		
	set_fixed_process(true)
	
func _fixed_process(delta):
	if get_node("btn_play").is_pressed():
		if run_once:
			run_once = false
			var text = select_level.get_text()
			get_node("/root/global").load_level("tutorial",text.substr(text.length()-5,1))
