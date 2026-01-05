extends Node3D

@export var size_x := 100
@export var size_z := 100
@export var tile_size := 1.0

@export var desert_height := 2.0
@export var grass_height := 10.0

var height_noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()

var height_map := {}

@onready var mesh_instance := $MeshInstance3D

func _ready():
	setup_noise()
	build_height_map()
	generate()

func setup_noise():
	height_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	height_noise.frequency = 0.05
	height_noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM
	height_noise.fractal_octaves = 4

	biome_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	biome_noise.frequency = 0.004

func build_height_map():
	for x in range(size_x + 1):
		for z in range(size_z + 1):
			var wx = x * tile_size
			var wz = z * tile_size

			var biome_val = biome_noise.get_noise_2d(wx, wz) * 0.5 + 0.5
			var base = height_noise.get_noise_2d(wx, wz)

			var amp = desert_height
			if biome_val > 0.5:
				amp = grass_height

			height_map[Vector2i(x, z)] = base * amp

func generate():
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(size_x):
		for z in range(size_z):
			add_quad(st, x, z)

	var mesh := st.commit()
	mesh_instance.mesh = mesh

func add_quad(st: SurfaceTool, x: int, z: int):
	var h00 = height_map[Vector2i(x, z)]
	var h10 = height_map[Vector2i(x + 1, z)]
	var h01 = height_map[Vector2i(x, z + 1)]
	var h11 = height_map[Vector2i(x + 1, z + 1)]

	var wx = x * tile_size
	var wz = z * tile_size

	var v00 = Vector3(wx, h00, wz)
	var v10 = Vector3(wx + tile_size, h10, wz)
	var v01 = Vector3(wx, h01, wz + tile_size)
	var v11 = Vector3(wx + tile_size, h11, wz + tile_size)

	var uv00 = Vector2(0, 0)
	var uv10 = Vector2(1, 0)
	var uv01 = Vector2(0, 1)
	var uv11 = Vector2(1, 1)

	# biom z środka quada
	var biome_id := 0.0
	if biome_noise.get_noise_2d(wx + tile_size * 0.5, wz + tile_size * 0.5) > 0.0:
		biome_id = 1.0

	var col = Color(biome_id, 1, 1)

	push(st, v00, uv00, col)
	push(st, v10, uv10, col)
	push(st, v01, uv01, col)

	push(st, v10, uv10, col)
	push(st, v11, uv11, col)
	push(st, v01, uv01, col)

func push(st: SurfaceTool, pos, uv, col):
	st.set_color(col)
	st.set_uv(uv)
	st.add_vertex(pos)
