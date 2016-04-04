
extends Reference

const TILESET = preload("res://shared/tileset.tres")

const TILE_EMPTY = 0
const TILE_SOLID = 1
const TILE_CLIMB = 2
const TILE_SINK = 3

const DEFAULT_TILE = TILE_SOLID
const DEFAULT_CLEAR_TILE = TILE_EMPTY
const TILES = {
	Ladder = TILE_CLIMB,
	Acid = TILE_SINK,
	Chest = TILE_SINK
}

static func get_tile_type(tile):
	if tile != -1:
		var tile_name = TILESET.tile_get_name(tile)
		
		if TILES.has(tile_name):
			return TILES[tile_name]
		else:
			return DEFAULT_TILE
	else:
		return DEFAULT_CLEAR_TILE