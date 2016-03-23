
extends Reference

var id_n = 0
var tiles_taken = {}

func get_id():
	id_n += 1
	return id_n

func take_tile(id, position): # Call when moving into a tile, since nobody should move there as well
	position = position.snapped(Vector2(1, 1))
	if tiles_taken.has(position):
		return false
	else:
		tiles_taken[position] = id
		return true

func tile_taken(position): # Call when checking aviability of a tile
	position = position.snapped(Vector2(1, 1))
	if tiles_taken.has(position):
		return true
	else:
		return false

func semi_release_tile(id, position): # Call when moving out of a tile, but still not completely out of it
	position = position.snapped(Vector2(1, 1))
	if tiles_taken.has(position) and tiles_taken[position] == id:
		tiles_taken[position] = id
		return true
	else:
		return false

func release_tile(id, position): # Call when you are no longer inside a tile
	position = position.snapped(Vector2(1, 1))
	if tiles_taken.has(position) and tiles_taken[position] == id:
		tiles_taken.erase(position)
		return true
	else:
		return false

