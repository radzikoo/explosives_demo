extends Node

@export var chunk_size: Vector3
var chunk_id: Vector2

var chunk_tiles: Dictionary = {}
@export var tile_size: Vector3

var multimesh_inst: MultiMeshInstance3D
var multimesh: MultiMesh

var noise: FastNoiseLite = FastNoiseLite.new()

func _ready():
	_prepare_noise()
	_generate_chunk()

func _prepare_noise():
	noise.seed = 1
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

func _generate_chunk():
	multimesh_inst = MultiMeshInstance3D.new()
	multimesh = MultiMesh.new()
	multimesh_inst.multimesh = multimesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = preload("res://Scripts/WorldManager/mesh.tres")
	call_deferred("add_child", multimesh_inst)

	# generowanie bloków do słownika
	for Tx in range(chunk_size.x):
		for Tz in range(chunk_size.z):
			var raw_height = (noise.get_noise_2dv(Vector2(Tx + (chunk_id.x * chunk_size.x), Tz + (chunk_id.y * chunk_size.z))) + 1.0) / 2.0 * chunk_size.y
			var height = round(raw_height * 2.0) / 2.0

			for Ty in range(int(floor(height / 0.5))):
				var pos = Vector3(Tx, Ty, Tz)
				_add_tile_to_chunk(pos)

	# wyznacz widoczne bloki i stwórz MultiMesh tylko z nich
	var visible_blocks = _get_visible_tiles()
	_generate_multimesh(visible_blocks)
	_generate_collision(multimesh_inst)

func _add_tile_to_chunk(pos: Vector3):
	chunk_tiles[pos] = {"position": pos}

# ==============================================
# WYBIERANIE BLOKÓW, KTÓRE POWINNY BYĆ WIDOCZNE
# ==============================================
func _get_visible_tiles() -> Array:
	var directions = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 1, 0), Vector3(0, -1, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1)
	]

	var visible_blocks: Array = []

	for pos in chunk_tiles.keys():
		# nie renderuj bloków na samym spodzie
		if pos.y <= 0:
			continue

		var visible = false
		for dir in directions:
			var neighbor = pos + dir

			# jeśli sąsiad nie istnieje -> widoczny (czyli np. na krawędzi chunku)
			if not chunk_tiles.has(neighbor):
				visible = true
				break

		# jeśli nie ma nad sobą powietrza, ale jest na krawędzi chunku lub na szczycie
		if visible:
			visible_blocks.append(pos)

	return visible_blocks

# ==============================================
# TWORZENIE MESHU Z WIDOCZNYCH BLOKÓW
# ==============================================
func _generate_multimesh(visible_blocks: Array):
	multimesh.instance_count = visible_blocks.size()

	for i in range(visible_blocks.size()):
		var pos = visible_blocks[i]
		var world_pos: Vector3 = Vector3(
			pos.x * tile_size.x,
			pos.y * tile_size.y,
			pos.z * tile_size.z
		)

		var transform: Transform3D = Transform3D(Basis(), world_pos)
		multimesh.set_instance_transform(i, transform)

# ==============================================
# KOLIZJE DLA MULTIMESH
# ==============================================
func _generate_collision(mmi: MultiMeshInstance3D):
	var mm = mmi.multimesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in mm.instance_count:
		var transform = mm.get_instance_transform(i)
		st.append_from(mm.mesh, 0, transform)

	var combined_mesh = st.commit()
	var shape = ConcavePolygonShape3D.new()
	shape.data = combined_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	shape.backface_collision = true

	var collision_shape = CollisionShape3D.new()
	var static_body = StaticBody3D.new()
	collision_shape.shape = shape
	mmi.add_child(static_body)
	static_body.add_child(collision_shape)
	static_body.add_to_group("Terrain")
