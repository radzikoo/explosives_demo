extends Node3D

@export var chunk_size:Vector3

var chunk_tiles:Dictionary
@export var tile_size:Vector3

func _ready():
	for Tx in range(chunk_size.x):
		for Ty in range(chunk_size.y):
			for Tz in range(chunk_size.z):
				#_add_tile_to_chunk(Vector3(Tx, Ty, Tz))
				_generate_tiles(Vector3(Tx, Ty*tile_size.y, Tz))

func _add_tile_to_chunk(pos:Vector3, obj:Object):
	chunk_tiles[chunk_tiles.size()+1] = {
		"position": pos,
		"node": obj
	}

func _generate_tiles(tile_pos:Vector3):
	#for i in range(chunk_tiles.size()):
	var tile = MeshInstance3D.new()
	var boxshape = BoxMesh.new()
	boxshape.size = tile_size
	tile.mesh = boxshape
	tile.position = tile_pos
	call_deferred("add_child", tile)
	#_add_tile_to_chunk(tile_pos, tile)
