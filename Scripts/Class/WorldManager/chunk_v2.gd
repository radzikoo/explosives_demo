extends Node3D

@export var chunk_size := 16
@export var block_size := 2.0

@onready var walls := $Walls as MultiMeshInstance3D
@onready var ramps := $Ramps as MultiMeshInstance3D

var wall_transforms: Array[Transform3D] = []
var ramp_transforms: Array[Transform3D] = []

func _ready():
	_generate_chunk()
	_build_meshes()


func _generate_chunk():
	wall_transforms.clear()
	ramp_transforms.clear()

	for x in chunk_size:
		for z in chunk_size:
			var height := randi_range(0, 3)
			var world_pos := Vector3(
				x * block_size,
				height * block_size,
				z * block_size
			)

			_add_walls(world_pos)
			_check_ramps(x, z, height)


func _add_walls(pos: Vector3):
	var half := block_size * 0.5

	_add_wall(pos + Vector3(0, half, -half), 0)
	_add_wall(pos + Vector3(half, half, 0), PI * 0.5)
	_add_wall(pos + Vector3(0, half, half), PI)
	_add_wall(pos + Vector3(-half, half, 0), PI * 1.5)


func _add_wall(pos: Vector3, rot_y: float):
	var t := Transform3D()
	t.origin = pos
	t.basis = Basis(Vector3.UP, rot_y)
	wall_transforms.append(t)


func _check_ramps(x: int, z: int, h: int):
	if x < chunk_size - 1:
		var h2 := randi_range(0, 3)
		if h2 == h + 1:
			_add_ramp(
				Vector3(
					(x + 0.5) * block_size,
					h * block_size,
					z * block_size
				),
				0
			)

	if z < chunk_size - 1:
		var h2 := randi_range(0, 3)
		if h2 == h + 1:
			_add_ramp(
				Vector3(
					x * block_size,
					h * block_size,
					(z + 0.5) * block_size
				),
				PI * 0.5
			)


func _add_ramp(pos: Vector3, rot_y: float):
	var t := Transform3D()
	t.origin = pos

	var slope := Basis(Vector3.RIGHT, deg_to_rad(-45))
	var rot := Basis(Vector3.UP, rot_y)

	t.basis = rot * slope
	ramp_transforms.append(t)


func _build_meshes():
	walls.multimesh.instance_count = wall_transforms.size()
	for i in wall_transforms.size():
		walls.multimesh.set_instance_transform(i, wall_transforms[i])

	ramps.multimesh.instance_count = ramp_transforms.size()
	for i in ramp_transforms.size():
		ramps.multimesh.set_instance_transform(i, ramp_transforms[i])
