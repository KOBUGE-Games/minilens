extends Control

var select_level
var select_pack

func _ready():
	select_level = get_node("opt_level")
	select_pack = get_node("opt_pack")
	
	var diraccess = Directory.new()
	diraccess.open("res://levels/")

	diraccess.list_dir_begin()
	var name = diraccess.get_next()
	var i = 1
	while name:
		if diraccess.current_is_dir():
			if name.length() > 3:
				select_pack.add_item(name)
		name = diraccess.get_next()
	diraccess.list_dir_end()
	_on_opt_pack_item_selected( 0 )

func _on_opt_pack_item_selected( ID ):
	select_level.clear()
	var diraccess = Directory.new()
	diraccess.open(str("res://levels/", select_pack.get_text()))

	diraccess.list_dir_begin()
	var name = diraccess.get_next()
	var i = 1
	while name:
		if !diraccess.current_is_dir():
			if name.length() > 3:
				select_level.add_item(str(i))
				i = i + 1
		name = diraccess.get_next()
	diraccess.list_dir_end()

func _on_btn_play_pressed():
	set_fixed_process(true)

func _fixed_process(delta):
	set_fixed_process(false)
	get_node("/root/global").load_level("tutorial",select_level.get_text())
	

