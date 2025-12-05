extends Node3D

const BULLET = preload("uid://dira71b32v7yy")
var speed:float = 25
var bullet_rotate_speed:float = 16.0
var is_gun_loading:bool = false
var loading_time:float = 0.25

var bullets:Array
var dead_bullets:Array

var player
@onready var weapon_charge: ProgressBar = $"../../../UI/WeaponCharge"

func _ready() -> void:
	if get_parent().get_parent().get_parent():
		player = get_parent().get_parent().get_parent()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		loading_time = 0.25
		is_gun_loading = true
		weapon_charge.show()
	if event.is_action_released("shoot"):
		_fire()

func _fire():
	if is_gun_loading:
		is_gun_loading = false
		weapon_charge.hide()
		
		var bullet_inst = BULLET.instantiate()
		get_tree().get_root().add_child(bullet_inst)
		bullet_inst.global_position = self.global_position
		bullet_inst.global_transform.basis = self.global_transform.basis
		bullet_inst.linear_velocity = -self.global_transform.basis.z * (speed * clampf(loading_time,0.25,1))
		bullets.append(bullet_inst)
		
func _physics_process(delta: float) -> void:
	if is_gun_loading and loading_time <= 1:
		loading_time += delta
		weapon_charge.value = loading_time
	
	if bullets.size() > 0:
		for bullet in bullets:
			if bullet == null:
				bullets.erase(bullet)
			#if bullet:
				#if bullet is RigidBody3D:
					#if bullet.linear_velocity.length() > 0.1 and abs(bullet.global_transform.basis.z.dot(Vector3.UP)) < 0.99:
						#var direction = bullet.linear_velocity.normalized()
						#var current_forward = bullet.global_transform.basis.z * -1
						#var target_rotation = current_forward.slerp(direction, bullet_rotate_speed * delta)
						#bullet.look_at(bullet.global_transform.origin + target_rotation, Vector3.UP)
					
					#if bullet.get_node("RayCast3D").is_colliding():
						#var new_bullet = Node3D.new()
						#var target = bullet.get_node("RayCast3D").get_collider()
						##print(target.get_parent().name)
						#print("[RIFLE] I've hit: ", target.name)
						#target.add_child(new_bullet)
						##new_bullet.position = to_local(bullet.global_position)
						#new_bullet.global_transform.origin = bullet.global_transform.origin
						##PFX.sphere_explosion(new_bullet.global_transform, 10, 1)
						#for child in bullet.get_children():
							#if child is MeshInstance3D or child is Timer:
								#child.reparent(new_bullet)
						#dead_bullets.append(new_bullet)
						#bullets.erase(bullet)
						#if target.is_in_group("Enemy"): #or target.get_parent().is_in_group("Enemy"):
							##print(target.get_parent().name)
							#target.take_damage(20, player)
						#bullet.queue_free() #Usuniecie lecacego bulletu na rzecz statycznego
						
				if bullets.has(bullet):
					if bullet.get_node("Timer").time_left < 0.1:
						pass
						bullets.erase(bullet)
						bullet.queue_free() #Usuwanie LECACYCH bulletow po czasie
	
	if dead_bullets.size() > 0:  
		for d_bullet in dead_bullets:
			if d_bullet == null:
				dead_bullets.erase(d_bullet)
			if d_bullet:
				if d_bullet.get_node("Timer").time_left < 0.1:
					pass
					dead_bullets.erase(d_bullet)
					#d_bullet.queue_free() #Usuwanie DEAD-bulletow po czasie
