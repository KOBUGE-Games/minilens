extends Control

var select_pack
var target
var level_btn_scene = preload("res://scenes/level_select_btn.xml")
var level_list
export var level_btn_size = Vector2(100,100)
var level_btn_row_count = 6
var level_selected
var global
func _ready():
	global = get_node("/root/global")
	select_pack = get_node("level_selection/opt_pack")
	level_list = get_node("level_selection/level_list")
	
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
	
	for i in range(level_list.get_child_count()):
		level_list.get_child(i).queue_free()
	var locked_count = global.get_reached_level(select_pack.get_text())
	var diraccess = Directory.new()
	diraccess.open(str("res://levels/", select_pack.get_text()))
	diraccess.list_dir_begin()
	var name = diraccess.get_next()
	var i = 0
	while name:
		if !diraccess.current_is_dir():
			if name.length() > 3:
				var new_instance = level_btn_scene.instance()
				new_instance.set_title(str("Level ",i + 1))
				new_instance.set_metadata(i + 1)
				new_instance.set_locked((i + 1) > locked_count)
				var row_pos = int(i % level_btn_row_count)
				var col_pos = int(i / level_btn_row_count)
				new_instance.set_pos(Vector2(level_btn_size.x * row_pos, level_btn_size.y * col_pos))
				level_list.add_child(new_instance)
				i = i + 1
		name = diraccess.get_next()
	diraccess.list_dir_end()

func level_btn_clicked(var id):
	level_selected = id
	set_fixed_process(true)

func _fixed_process(delta):
	set_fixed_process(false)
	global.load_level(select_pack.get_text(),level_selected)
	
func _process(delta):
	set_pos((get_pos()*4 + target)/5)
	if(abs(get_pos().x - target.x) < 1):
		set_pos(target)
		set_process(false)

func goto_levels():
	target = Vector2(-1024,0)
	set_process(true)


func goto_start():
	target = Vector2(0,0)
	set_process(true)
