extends Node3D
#class_name Sword

@onready var mesh: Node3D = $Mesh

func use(raycast_result:Dictionary):
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(mesh, "rotation_degrees", Vector3(-32,-15,32), 0.1)
	tween.tween_callback(unswing_sword)
	if len(raycast_result) > 0:
		_create_damage_area(raycast_result["collider"].global_position)
	
func unswing_sword():
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(mesh, "rotation_degrees", Vector3(0,0,0), 0.1)

func _create_damage_area(pos:Vector3):
	var area3d:Area3D = Area3D.new()
	var collision:CollisionShape3D = CollisionShape3D.new()
	area3d.set_collision_mask_value(2, true)
	area3d.set_collision_layer_value(1, false)
	area3d.set_collision_mask_value(1, false)
	var shape = CylinderShape3D.new()
	shape.height = 0.1
	shape.radius = 0.77
	collision.shape = shape
	area3d.position = Vector3(pos.x, pos.y+0.1, pos.z)
	area3d.name = str(randi_range(0,1000))
	area3d.call_deferred("add_child", collision)
	get_tree().get_root().call_deferred("add_child", area3d)
	print(area3d.name)
	await area3d.tree_entered
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for entity in area3d.get_overlapping_bodies():
		if entity.is_in_group("Enemy"):
			var dmg:float = snapped(area3d.global_position.distance_squared_to(entity.global_position), 0.01)
			entity.take_damage(1-dmg)
			entity.apply_vector_force(global_position, 2, 5)
	area3d.call_deferred("queue_free")
