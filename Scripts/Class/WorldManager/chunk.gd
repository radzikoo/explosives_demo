extends Node

var chunk_size:Vector3
var chunk_id:Vector2
var tile_size:Vector3

var chunk_tiles:Dictionary

var multimesh_inst:MultiMeshInstance3D
var multimesh:MultiMesh

var noise:FastNoiseLite = FastNoiseLite.new()

@onready var chunkmanager = get_parent()

func _ready():
	_prepare_noise()
	_generate_chunk()
	
func _prepare_noise():
	noise.seed = 1
	noise.frequency = 0.01
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.1
	noise.fractal_lacunarity = 1.0
	
func _generate_chunk():
	multimesh_inst = MultiMeshInstance3D.new()
	multimesh = MultiMesh.new()
	multimesh_inst.multimesh = multimesh
	multimesh_inst.visibility_range_end = chunk_size.x*24
	multimesh_inst.visibility_range_end_margin = 1
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = preload("res://Scripts/Class/WorldManager/mesh.tres")
	call_deferred("add_child", multimesh_inst)
	for Tx in range(chunk_size.x):
		for Tz in range(chunk_size.z):
			var raw_height = (noise.get_noise_2dv(Vector2(Tx+(chunk_id.x*chunk_size.x), Tz+(chunk_id.y*chunk_size.z))) + 1.0) / 2.0 * chunk_size.y
			var height = round(raw_height * 2.0) / 2.0
			for Ty in range(int(floor(height / 0.5))):
				_add_tile_to_chunk(Vector3(Tx, Ty, Tz))
	var visible_tiles = _check_tiles_visibility()
	_generate_multimesh(visible_tiles)

func _add_tile_to_chunk(pos:Vector3):
	chunk_tiles[pos] = {
		"position": pos
	}

func _generate_multimesh(visible_tiles:Array):
	if multimesh.instance_count > 0:
		multimesh.instance_count = 0
	multimesh.instance_count = visible_tiles.size()
	var index = 0
	for i in range(visible_tiles.size()):
		var pos:Vector3 = Vector3(
		(visible_tiles[i].x*tile_size.x)+1, 
		(visible_tiles[i].y*tile_size.y)+1, 
		(visible_tiles[i].z*tile_size.z)+1)
		var transform:Transform3D = Transform3D(Basis(Vector3.UP, 0), pos)
		multimesh.set_instance_transform(index, transform)
		index += 1
	_generate_collision(multimesh_inst)
		
func _generate_collision(mmi: MultiMeshInstance3D):
	for chA in get_children():
		if chA is MultiMeshInstance3D:
			for chB in chA.get_children():
				if chB is StaticBody3D:
					chB.call_deferred("queue_free")
					
	var mm = mmi.multimesh
	if mm == null or mm.instance_count == 0:
		return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(mm.instance_count):
		var transform = mm.get_instance_transform(i)
		st.append_from(mm.mesh, 0, transform)

	var combined_mesh = st.commit()
	if combined_mesh == null:
		return

	var arrays = combined_mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	
	if indices.size() == 0:
		for i in range(0, verts.size(), 3):
			if i + 2 < verts.size():
				indices.append(i)
				indices.append(i + 1)
				indices.append(i + 2)

	var shape_verts = PackedVector3Array()
	for i in range(indices.size()):
		var v = verts[indices[i]]
		shape_verts.append(Vector3(
			round(v.x * 1000.0) / 1000.0,
			round(v.y * 1000.0) / 1000.0,
			round(v.z * 1000.0) / 1000.0
		))

	var shape = ConcavePolygonShape3D.new()
	shape.data = shape_verts
	#shape.backface_collision = true

	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	static_body.call_deferred("add_child", collision_shape)
	mmi.call_deferred("add_child", static_body)
	static_body.add_to_group("Terrain")


var visible_tiles:Array = []

func _check_tiles_visibility() -> Array:
	var directions = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1)
	]

	visible_tiles = []

	for pos in chunk_tiles.keys():
		var visible = false
		
		for dir in directions:
			var neighbor = pos + dir
			
			if (neighbor.x < 0 or neighbor.x >= chunk_size.x or
			   #neighbor.y < 0 or neighbor.y >= chunk_size.y or
			   neighbor.z < 0 or neighbor.z >= chunk_size.z):
				continue
			
			if not chunk_tiles.has(neighbor):
				if dir == Vector3(0, -1, 0) and pos.y == 0:
					continue
				visible = true
				break
		if visible:
			visible_tiles.append(pos)

	return visible_tiles

func switch_tile_visibility(show:bool, tpos:Vector3):
	if show:
		if chunk_tiles.has(tpos):
			visible_tiles.append(tpos)
			_generate_multimesh(visible_tiles)
	if !show:
		pass #do whatever hides a tile

func remove_tile(tpos:Vector3):
	if chunk_tiles.has(tpos):
		chunk_tiles.erase(tpos)
		_generate_multimesh(_check_tiles_visibility())
	
func add_tile(tpos:Vector3):
	if not chunk_tiles.has(tpos):
		_add_tile_to_chunk(tpos)
		_generate_multimesh(_check_tiles_visibility())
	
