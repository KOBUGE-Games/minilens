extends Node
# Notes:
# - It might be vulnerable to project resolution changes
# - Supports adding custom Objects, not tested tho
# - Terrain tab is loaded from Level/tilemap:TileSet
#   - So as their names and textures
#   - No flipping, etc. supported... yet
# - Currently always saves in "levels/map_editor_pack/level_1.xml"
#   - Custom packs and level IDs are already supported, just need to add some kind of dialog window
# - COULD SOMEONE MAKE/GET SOME GRAPHICS FOR THIS?
# - It's recommended to modify _on_quit_pressed() function
# - Probably forgot to note something


var anim_player
var selected_item = null
var occupied_pos = {}
var ghost_tile = Sprite.new()
var current_sel_menu = "Terrain"
var res_obj_texture = { "Spawn":preload("res://gfx/player.png"), "Radioactive":preload("res://gfx/radioactive.png"), 
	"Flower":preload("res://gfx/flower32.png"), "Bomb":preload("res://gfx/pickup_bomb.png") }
var res_obj_scenes = { "Spawn":preload("res://scenes/player.xml"), "Radioactive":preload("res://scenes/box.scn"), 
	"Flower":preload("res://scenes/flower.xml"), "Bomb":preload("res://scenes/bomb_pickup.xml") }
var res_tile_texture = {}

func _ready():
	# signal connections, I just prefer to keep them inside a script
	get_node("Menu/Hide").connect("pressed",self,"_toggle_panel",["Menu"])
	get_node("Menu/Panel/Save").connect("pressed",self,"_on_save_pressed")
	get_node("Menu/Panel/Quit").connect("pressed",self,"_on_quit_pressed")
	get_node("Menu/Panel/Load").connect("pressed",self,"_on_load_pressed")
	get_node("Menu/Panel/Settings").connect("pressed",self,"_on_settings_pressed")
	get_node("Menu/Panel/Environment").connect("pressed",self,"_on_environment_pressed")
	get_node("Selection/sTerrain").connect("pressed",self,"_toggle_selection",["Terrain"])
	get_node("Selection/sObjects").connect("pressed",self,"_toggle_selection",["Objects"])
	get_node("Selection/Hide").connect("pressed",self,"_toggle_panel",["Selection"])
	get_node("Selection/Next").connect("pressed",self,"_change_tab",[1])
	get_node("Selection/Previous").connect("pressed",self,"_change_tab",[-1])
	
	for tab in get_node("Selection/Objects").get_children():
		if tab.is_type("Control"):
			tab.add_to_group("objects/tabs")
			for object in tab.get_children():
				if object extends Button:
					object.connect("pressed",self,"_item_select",["Objects",object.get_name()])
	# ---
	# Selection tabs
	get_node("Selection").set_meta("hidden",false)
	# basically using metadata as variable
	get_node("Selection/Objects").set_meta("current_tab",1)
	get_node("Selection/Terrain").set_meta("current_tab",1)
	
	get_node("Menu").set_meta("hidden",true)
	anim_player = get_node("Animations")
	
	# Half-transparent sprite, useful thingy
	ghost_tile.set_self_opacity(0.5)
	ghost_tile.set_centered(false)
	ghost_tile.set_pos(Vector2(-128,-128))
	add_child(ghost_tile)
	
	_toggle_selection(current_sel_menu)
	load_terrain_menu()
	
	set_process_unhandled_input(true)
#	add_item("Objects","Name",res_obj_texture["Flower"],res_obj_scenes["Flower"])
	

func _unhandled_input(ev):
	if ev.type == InputEvent.KEY and ev.is_pressed():
		if ev.scancode == KEY_TAB: # toggle panels
			if get_node("Menu").is_visible():
				get_node("Menu").hide()
				get_node("Selection").hide()
			else:
				get_node("Menu").show()
				get_node("Selection").show()
	elif ev.type == InputEvent.MOUSE_BUTTON and ev.is_pressed():
		var t = get_node("Level/tilemap")
		var pos = t.map_to_world(t.world_to_map(ev.pos))
		if pos.y >= OS.get_video_mode_size().y - t.get_cell_size().y:
			# don't allow to modify water at the bottom
			return
		if selected_item == null:
			return
		if ev.button_index == 2: # delete object
			if selected_item[0] == "Objects":
				if occupied_pos.has(pos):
					if selected_item[1] != "Spawn": # spawn can't be deleted
						occupied_pos[pos].queue_free()
						occupied_pos.erase(pos)
			elif selected_item[0] == "Terrain":
				pos = t.world_to_map(pos)
				t.set_cell(pos.x,pos.y,-1)
		elif ev.button_index == 1: # spawn new object (if possible)
			if occupied_pos.has(pos):
				return
			if selected_item[0] == "Objects":
				var i_name = selected_item[1]
				if i_name == "Spawn":
					var s_pos = get_node("Spawn").get_pos()
					if s_pos != pos:
						if occupied_pos.has( s_pos ):
							occupied_pos.erase(s_pos)
						get_node("Spawn").set_pos(pos)
						occupied_pos[pos] = get_node("Spawn")
				elif i_name == "Text":
					# TO DO
					pass
				else:
					var new_obj = Sprite.new()
					get_node("Objects").add_child(new_obj)
					new_obj.set_pos(pos)
					new_obj.set_centered(false)
#					new_obj.set_name(i_name)
					new_obj.set_meta("obj_name",i_name)
					new_obj.set_texture(res_obj_texture[i_name])
					occupied_pos[pos] = new_obj
				#print("Spawning "+i_name)
			elif selected_item[0] == "Terrain":
				var tset = t.get_tileset()
				var id = tset.find_tile_by_name(selected_item[1])
				pos = t.world_to_map(pos)
				t.set_cell(pos.x, pos.y, id)
	elif ev.type == InputEvent.MOUSE_MOTION:
		if selected_item != null:
			var t = get_node("Level/tilemap")
			var pos = t.map_to_world(t.world_to_map(ev.pos))
			ghost_tile.set_pos(pos)

func _toggle_selection( type ):
	if type == "Terrain":
		get_node("Selection/Objects").hide()
		get_node("Selection/Terrain").show()
	elif type == "Objects":
		get_node("Selection/Terrain").hide()
		get_node("Selection/Objects").show()
	else:
		return
	current_sel_menu = type
	_change_tab(0)

func _change_tab( val ):
	var sel_menu = get_node("Selection/"+current_sel_menu)
	if sel_menu.get_child_count() > 0:
		var current_tab = sel_menu.get_meta("current_tab")
		var new_tab = current_tab + val
		if new_tab >= 1 and new_tab <= sel_menu.get_child_count():
			for tab in sel_menu.get_children():
				if tab.get_name() != "Tab"+str(new_tab):
					tab.hide()
				else:
					tab.show()
			sel_menu.set_meta("current_tab",new_tab)
			get_node("Selection/TabLabel").set_text( "Tab "+str(new_tab)+"/"+str(sel_menu.get_child_count()) )
	else:
		get_node("Selection/TabLabel").set_text( "Tab 0/0" )

func add_item( type, i_name, tex, vars = null ):
	var err_string = str(" [ ERROR:add_item(",type,",",i_name,",",tex,",",vars,") ]")
# DEBUG/
	i_name = str(i_name)
	if typeof(tex) == TYPE_OBJECT:
		if tex extends ImageTexture:
			pass
		elif tex extends Sprite:
			tex = tex.get_texture()
		else:
			print(err_string," Unknown texture type.")
			return 1
	elif typeof(tex) == TYPE_STRING:
		tex = load(tex)
	elif typeof(tex) == TYPE_IMAGE:
		pass
	else:
		print(err_string," Unknown texture type.")
		return 1
	if tex == null:
		print(err_string," Failed to load texture.")
		return 2
# /DEBUG
	
	if type in ["Objects","Terrain"]:
		var tab_id = get_node("Selection/"+type).get_child_count()
		var tab
		if get_node("Selection/"+type+"/Tab"+str(tab_id)).get_child_count() == 5:
			tab_id += 1
			tab = Control.new()
			get_node("Selection/"+type).add_child(tab)
			tab.set_name("Tab"+str(tab_id))
			_change_tab(0)
		else:
			tab = get_node("Selection/"+type).get_child(tab_id-1)
			
		if type == "Objects":
			if vars == null:
				print(err_string," No scene specified.")
				return 3
			var obj_scene = null
			if typeof(vars) == TYPE_OBJECT:
				obj_scene = vars
			elif typeof(vars) == TYPE_STRING:
				obj_scene = load(vars)
			if obj_scene == null:
				print(err_string," Failed to load scene.")
				return 4
			res_obj_scenes[i_name] = obj_scene
			res_obj_texture[i_name] = tex
			
		
		var new_but = get_node("Selection/EmptyButton").duplicate()
		new_but.set_name(i_name)
		new_but.get_node("Sprite").set_texture(tex)
		new_but.get_node("Label").set_text(i_name)
		var pos = Vector2(64,0) + Vector2(128,0) * tab.get_child_count()
		new_but.set_pos(pos)
		new_but.show()
		new_but.connect("pressed",self,"_item_select",[type,i_name])
		tab.add_child(new_but)
	else:
		print(err_string," Unknown type.")
		return 5
	
	return 0

func load_terrain_menu( tset = null ):
# maybe later will add loading tileset from path(string)
	var tmap = get_node("Level/tilemap")
	if typeof(tset) == TYPE_OBJECT:
		print("OBJ")
		if tset extends TileSet:
			pass
		else:
			return 1
	elif typeof(tset) == TYPE_NIL:
		tset = tmap.get_tileset()
	else:
		return 2
	if tmap.get_tileset() != tset:
		tmap.set_tileset(tset)
	
	var tiles_count = tset.get_last_unused_tile_id() 
#	print(tiles_count)
	for i in range(tiles_count):
		var tex = tset.tile_get_texture(i)
		res_tile_texture[tset.tile_get_name(i)] = tex
		add_item("Terrain",tset.tile_get_name(i),tex)
	return 0

func _item_select( i_type, i_name ):
	print("Selected "+i_type+"/"+i_name)
	selected_item = [i_type, i_name]
	if i_type == "Objects":
		ghost_tile.set_texture( res_obj_texture[i_name] )
	elif i_type == "Terrain":
		ghost_tile.set_texture( res_tile_texture[i_name] )

func _toggle_panel( panel_name ):
	if get_node(panel_name).get_meta("hidden") == false:
		anim_player.play("Hide"+panel_name)
		get_node(panel_name).set_meta("hidden",true)
	else:
		anim_player.play("Hide"+panel_name, -1, -1, true)
		get_node(panel_name).set_meta("hidden",false)

func _on_save_pressed():
	save( "map_editor_pack" )
	pass

func save( pack, idx = 0 ):
	var level = get_packed_level()
	if idx <= 0:
		idx = get_new_level_idx( pack )
	var path = "levels/"+pack+"/level_"+str(idx)+".xml"
	# check if there's a pack folder
	var dir = Directory.new()
	if dir.open("res://levels/"+pack) != 0:
		dir.open("res://levels")
		dir.make_dir(pack)
	
	path = "levels/"+pack+"/level_1.xml" # ERASE (will increment _nr automatically)
	
	print(" Saving level \"",path,"\"")
	ResourceSaver.save("res://"+path, level)

func get_packed_level():
	var blank_level = preload("res://map_editor/level_blank.xml")
	var level = blank_level.instance()
	level.set_name("level")
	for obj in get_node("Objects").get_children():
		if obj.has_meta("obj_name"):
#			print("   Trying to add ",obj.get_meta("obj_name"))
			var obj_instance = res_obj_scenes[obj.get_meta("obj_name")].instance()
			obj_instance.set_pos(obj.get_pos())
			level.add_child(obj_instance)
			obj_instance.set_owner(level)
	var tm_f = get_node("Level/tilemap")
	var tm_t = level.get_node("tilemap")
	var rect = tm_f.get_item_rect()
	var start = tm_f.world_to_map(rect.pos)
	var end = tm_f.world_to_map(rect.pos + rect.size)
#	print(start)
#	print(end)
#	print(tm_f.world_to_map(start + rect.size))
	for x in range(start.x,end.x):
		for y in range(start.y,end.y):
			var cell = tm_f.get_cell(x,y)
			if cell != -1:
				tm_t.set_cell(x,y,cell)
	level.get_node("start").set_pos(get_node("Spawn").get_pos())
	var scene = PackedScene.new()
	scene.pack( level )
#	level.queue_free()
	return scene

func get_new_level_idx( pack ):
	var dir = Directory.new()
	var err = dir.open("res://levels/"+pack)
	if err != 0:
		return 1
	var idx = 1
	dir.list_dir_begin()
	var next = dir.get_next()
	while next != "":
		if next.begins_with("level_"):
			if int(next) >= idx:
				idx = int(next)+1
		next = dir.get_next()
	return idx

func _on_quit_pressed():
# You should modify this function code
	get_tree().quit()
