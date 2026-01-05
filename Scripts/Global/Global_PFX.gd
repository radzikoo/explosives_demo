extends Node3D

#@export var radius: float = 10.0 
#@export var power: float = 1 
@export var max_results: int = 256 

func sphere_explosion(summon_transform:Transform3D, radius:float, power:float) -> void:
	var space_state = get_world_3d().direct_space_state

	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = sphere_shape
	params.transform = Transform3D(Basis(), summon_transform.origin)
	params.collide_with_bodies = true

	var results = space_state.intersect_shape(params, max_results)

	for res in results:
		var body = res.get("collider", null)
		if body is RigidBody3D:
			body.set_sleeping(false)

			var dir = (body.global_transform.origin - summon_transform.origin)
			var dist = max(dir.length(), 0.0001)
			dir = dir.normalized()
			var attenuation = 1.0 - clamp(dist / radius, 0.0, 1.0)
			var impulse = dir * power * attenuation

			var local_offset = body.to_local(global_transform.origin)
			body.apply_impulse(local_offset, impulse)
		if body is CharacterBody3D and body.is_in_group("Enemy"):
			var dmg:float = snapped(summon_transform.origin.distance_to(body.global_position), 0.01)
			body.take_damage(4-dmg)
			body.apply_vector_force(global_position, 8, 16)
