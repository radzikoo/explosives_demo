extends Node3D

@export var world_size:Vector2
@export var chunk_size:Vector3
@export var tile_size:Vector3

const CHUNK = preload("uid://cc1qdbduh3apw")

var world_chunks:Dictionary

func _ready():
	_generate_chunk()
	_generate_chunk_borders()

func _generate_chunk():
	for sx in range(world_size.x):
		for sy in range(world_size.y):
			var new_chunk_inst = CHUNK.instantiate()
			new_chunk_inst.chunk_size = chunk_size
			new_chunk_inst.tile_size = tile_size
			new_chunk_inst.chunk_id = Vector2(sx, sy)
			call_deferred("add_child", new_chunk_inst)
			new_chunk_inst.transform.origin = Vector3(chunk_size.x*sx, 0 , chunk_size.z*sy)
			new_chunk_inst.name = str(sx) + ";" + str(sy)
			world_chunks[Vector2(sx, sy)] = {
				"node": new_chunk_inst
				}

func _generate_chunk_borders():
	$ChunkBorder.visible = $TileController/CheckButton.button_pressed
	var chunk_border:MultiMeshInstance3D = $ChunkBorder
	var multimesh:MultiMesh = MultiMesh.new()
	chunk_border.multimesh = multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 40
	var border_mesh := preload("uid://db40pa6ftoee1")
	border_mesh.size = Vector3(world_size.x*chunk_size.x, 50, 0)
	multimesh.mesh = border_mesh
	var mmi_count = 512
	multimesh.instance_count = mmi_count
	
	var index_x:int = 0
	var index_z:int = 0
	
	for cx in range(world_size.x+1):
		var pos := Vector3(
			cx*chunk_size.x,
			5, (world_size.x*chunk_size.x)/2
		)
		var transform:Transform3D = Transform3D(Basis(Vector3.UP, deg_to_rad(-90)), pos)
		multimesh.set_instance_transform(index_x, transform)
		index_x += 1

	for cz in range(world_size.y+1):
		var pos := Vector3(
			(world_size.y*chunk_size.z)/2,
			5, cz*chunk_size.z
		)
		var transform:Transform3D = Transform3D(Basis(Vector3.UP, deg_to_rad(-180)), pos)
		multimesh.set_instance_transform(index_z+index_x, transform)
		index_z += 1
	
@onready var xc: LineEdit = $TileController/HBoxContainer/XC
@onready var yc: LineEdit = $TileController/HBoxContainer/YC
@onready var zc: LineEdit = $TileController/HBoxContainer/ZC
@onready var chunk_x: LineEdit = $TileController/HBoxContainer/ChunkX
@onready var chunk_y: LineEdit = $TileController/HBoxContainer/ChunkY

func _on_place_tile_pressed() -> void:
	var given_id:Vector2 = Vector2(int(chunk_x.text), int(chunk_y.text))
	var given_xyz:Vector3
	if xc.text and yc.text and zc.text:
		given_xyz = Vector3(int(xc.text), int(yc.text), int(zc.text))
	if world_chunks.has(given_id):
		var target_chunk = world_chunks[given_id]["node"]
		if given_xyz:
			target_chunk.add_tile(given_xyz)

func _on_dest_tile_pressed() -> void:
	var given_id:Vector2 = Vector2(int(chunk_x.text), int(chunk_y.text))
	var given_xyz:Vector3
	if xc.text and yc.text and zc.text:
		given_xyz = Vector3(int(xc.text), int(yc.text), int(zc.text))
	if world_chunks.has(given_id):
		var target_chunk = world_chunks[given_id]["node"]
		if given_xyz:
			target_chunk.remove_tile(given_xyz)

func _on_gennewchunk_pressed() -> void:
	var given_id:Vector2 = Vector2(int(chunk_x.text), int(chunk_y.text))
	if given_id:
		var new_chunk_inst = CHUNK.instantiate()
		new_chunk_inst.chunk_size = chunk_size
		new_chunk_inst.tile_size = tile_size
		new_chunk_inst.chunk_id = Vector2(given_id.x, given_id.y)
		call_deferred("add_child", new_chunk_inst)
		new_chunk_inst.transform.origin = Vector3(chunk_size.x*given_id.x, 0 , chunk_size.z*given_id.y)
		new_chunk_inst.name = str(given_id.x) + ";" + str(given_id.y)
		world_chunks[Vector2(given_id.x, given_id.y)] = {
			"node": new_chunk_inst
			}

func _on_check_button_pressed() -> void:
	$ChunkBorder.visible = $TileController/CheckButton.button_pressed

func place_tile(xyz:Vector3, chunk_id:Vector2):
	if world_chunks.has(chunk_id):
		var target_chunk = world_chunks[chunk_id]["node"]
		if xyz:
			var chunk_adjusted_xyz = Vector3(
				xyz.x - (chunk_size.x-chunk_id.x),
				xyz.y,
				xyz.z - (chunk_size.z-chunk_id.y)
			)
			target_chunk.add_tile(chunk_adjusted_xyz)
			
func destroy_tile(xyz:Vector3, chunk_id:Vector2):
	var look_for_neighbouring_chunk:bool = false
	if world_chunks.has(chunk_id):
		var target_chunk = world_chunks[chunk_id]["node"]
		if xyz:
			var chunk_adjusted_xyz = Vector3(
				xyz.x - (chunk_size.x*chunk_id.x),
				xyz.y,
				xyz.z - (chunk_size.z*chunk_id.y)
			)
			target_chunk.remove_tile(chunk_adjusted_xyz)
			
			var neighbouring_chunk_id:Vector2
			
			#print("MY CLICKPOS: ", chunk_adjusted_xyz)
			
			#print("CURRENT CHUNK: ", chunk_id)
			
			var x_shift:int #= 1
			var z_shift:int #= 1

			if chunk_adjusted_xyz.x == 0 and chunk_adjusted_xyz.z == 0:
				print("rog 0,0")
			elif chunk_adjusted_xyz.x == chunk_size.x-1 and chunk_adjusted_xyz.z == 0:
				print("rog MAX,0")
			elif chunk_adjusted_xyz.x == 0 and chunk_adjusted_xyz.z == chunk_size.z-1:
				print("rog 0,MAX")
			elif chunk_adjusted_xyz.x == chunk_size.x-1 and chunk_adjusted_xyz.z == chunk_size.z-1:
				print("rog MAX,MAX")
			
			elif chunk_adjusted_xyz.x == 0:
				x_shift = chunk_size.x - 1
				neighbouring_chunk_id.x = chunk_id.x-1
				look_for_neighbouring_chunk = true
				print("X krawędz 0")
				#print("x: ", chunk_id.x-1)
			elif chunk_adjusted_xyz.x == chunk_size.x-1:
				x_shift = chunk_size.x - 1
				neighbouring_chunk_id.x = chunk_id.x+1
				look_for_neighbouring_chunk = true
				print("X krawedz KONCOWA")
				#print(x_shift)
				#print("x: ", chunk_id.x+1)
			#elif chunk_adjusted_xyz.x != 0 and chunk_adjusted_xyz.x != chunk_size.x-1:
			#	print("dupa Y")
				#pass
				#x_bias = 0
				#neighbouring_chunk_id.x = chunk_id.x
				
			elif chunk_adjusted_xyz.z == 0:
				z_shift = abs(chunk_size.z-chunk_adjusted_xyz.z)-1
				neighbouring_chunk_id.y = chunk_id.y-1
				look_for_neighbouring_chunk = true
				#print("y: ", chunk_id.y-1)
				print("Z krawedz 0")
			elif chunk_adjusted_xyz.z == chunk_size.z-1:
				z_shift = chunk_adjusted_xyz.z
				neighbouring_chunk_id.y = chunk_id.y+1
				look_for_neighbouring_chunk = true
				print("Z krawedz KONCOWA")
				#print("y: ", chunk_id.y+1)
			elif (chunk_adjusted_xyz.z != 0 and chunk_adjusted_xyz.z != chunk_size.z-1
			and chunk_adjusted_xyz.x != 0 and chunk_adjusted_xyz.x != chunk_size.x-1):
				print("dupa XZ")
				pass
				#z_bias = 0
				neighbouring_chunk_id = chunk_id
				
			
			if look_for_neighbouring_chunk:
				#print("NB CHUNK: ", neighbouring_chunk_id)
				if world_chunks.has(neighbouring_chunk_id):
					var neighbouring_target_chunk = world_chunks[neighbouring_chunk_id]["node"]
					var nb_tg_chunk_xyz = Vector3(
						abs((chunk_adjusted_xyz.x - x_shift)),
						chunk_adjusted_xyz.y,
						abs((chunk_adjusted_xyz.z - z_shift))
					)
					
					print("NB POS: ", nb_tg_chunk_xyz)
					
					neighbouring_target_chunk.remove_tile(nb_tg_chunk_xyz)
