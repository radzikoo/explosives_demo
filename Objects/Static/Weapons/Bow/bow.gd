extends Node3D

#Resources
const BULLET:PackedScene = preload("uid://dira71b32v7yy")

#Timers
var bow_charge_time:float = 0.0

#Nodes
@onready var player: Player = get_tree().get_first_node_in_group("Players")
@onready var charge_bar:ProgressBar = player.weapon_charge_bar

#Properties
@export var bullet_speed:float = 22
@export var bullet_rotate_speed:float = 16

#Bullets array
var active_bullets:Array[Object]

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("place"):
		bow_charge_time += 0.05
	if Input.is_action_just_released("place"):
		if bow_charge_time > 0:
			_shoot()
	
	if active_bullets.size() > 0:
		for bullet in active_bullets:
			if bullet:
				if bullet.linear_velocity.length() > 0.1 and !is_equal_approx(abs(bullet.global_transform.basis.z.dot(Vector3.UP)), 1):#abs(bullet.global_transform.basis.z.dot(Vector3.UP)) < 0.99:
					var direction:Vector3 = bullet.linear_velocity.normalized()
					var current_forward = bullet.global_transform.basis.z * -1
					var target_rotation = current_forward.slerp(direction, bullet_rotate_speed * delta)
					bullet.look_at(bullet.global_transform.origin + target_rotation, Vector3.UP)
				
				var from = bullet.global_transform.origin
				var forward = -bullet.global_transform.basis.z.normalized()
				var to = from + forward * 0.5
				var space := get_world_3d().direct_space_state
				var query := PhysicsRayQueryParameters3D.create(from, to)
				query.exclude = [player.damage_area.get_rid()]
				query.collide_with_areas = true
				query.collide_with_bodies = true
				var result := space.intersect_ray(query)
				if result:
					_on_hit(bullet, result.get("collider"))

func _on_hit(bullet:Node3D, collider:Node3D):
	print("[RIFLE] I've hit: ", collider.name)
	var new_bullet:Node3D
	if collider is not Player:
		bullet.freeze = true
		bullet.sleeping = true
		var new_transform:Transform3D = bullet.global_transform
		new_bullet = Node3D.new()
		collider.add_child(new_bullet)
		new_bullet.global_transform = new_transform
		for child in bullet.get_children():
			if child is MeshInstance3D:
				child.reparent(new_bullet)
	if collider is Player:
		new_bullet = bullet
	active_bullets.erase(bullet)
	bullet.call_deferred("queue_free")
	if collider.is_in_group("Enemy") or collider is Player:
		collider.take_damage(2.3)
		collider.apply_vector_force(new_bullet.global_position, 2, 5)

func _shoot():
	var bullet_scene:Object = BULLET.instantiate()
	bullet_scene.global_transform = player.camera.global_transform
	print(bow_charge_time)
	bullet_scene.linear_velocity = -player.camera.global_transform.basis.z * (bullet_speed * clampf(bow_charge_time,0.15,2))
	bow_charge_time = 0
	get_tree().get_root().call_deferred("add_child", bullet_scene)
	await bullet_scene.tree_entered
	await get_tree().physics_frame
	await get_tree().physics_frame
	active_bullets.append(bullet_scene)
