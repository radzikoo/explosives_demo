extends CharacterBody3D
class_name Crab

#Nodes
@onready var agent:NavigationAgent3D = $NavigationAgent3D
var anim_player:AnimationPlayer
var health_status:Label3D
var audio_player:AudioStreamPlayer3D

#Entity properties
@export var entity_active:bool = true
@export var entity_speed:float = 0.7
@onready var entity_target:Object
var entity_state:Misc.entityState = Misc.entityState.WANDER
@export var entity_health:float = 99
@export var show_health_status:bool = false

#Navigation realted things
@onready var space_state:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
var random_pos:Vector3
var can_get_rand_pos:bool
var next_pos:Vector3
var _velocity:Vector3
var target_reached:bool

#Physics
@onready var gravity:float =  ProjectSettings.get_setting("physics/3d/default_gravity")

#Timers
var navupdate_time_passed:float
var look_time_passed:float
var ray_time_passed:float
var attack_time:float

#Player-Entity raycast detection
@export var raycast_height:float = 0.1
var result:Dictionary
var query:PhysicsRayQueryParameters3D
var target_pos:Vector3
var my_pos:Vector3

func _ready() -> void:
	_init_entity()

func _physics_process(delta: float) -> void:
	health_status.text = str(velocity)
	if entity_active:
		_handle_target(delta)
		_handle_movement(delta)
		if anim_player:
			_handle_animation()

func _init_entity():
	for child in get_children():
		if child is AnimationPlayer:
			anim_player = child
			anim_player.set_process_callback(AnimationPlayer.ANIMATION_PROCESS_PHYSICS)
		if child is AudioStreamPlayer3D:
			audio_player = child
		if child is Label3D:
			if show_health_status:
				health_status = child
			else:
				child.call_deferred("queue_free")
			
	#if show_health_status and health_status: health_status.text = str(entity_health)
	await NavigationServer3D.map_changed
	agent.set_navigation_map(agent.get_navigation_map())
	_get_random_pos()

func _get_random_pos():
	can_get_rand_pos = true
	var posx = randi_range(-5,5)
	var posz = randi_range(-5,5)
	var fpos = Vector3(global_position.x + posx, global_position.y, global_position.z + posz)
	random_pos = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), fpos)
	agent.set_target_position(random_pos)
	can_get_rand_pos = false

func _update_rotation(delta:float, pos:Vector3, calc_dir:bool = false):
	look_time_passed += delta
	if look_time_passed >= 0.05:
		look_time_passed = 0
		if !self.global_position.distance_squared_to(pos) >= 0.1 * 0.1: #Zabezpieczenie aby nie patrzyl sie w pozycje na ktorej stoi (gdy dotrze do przeciwnika)
			return
	if calc_dir:
		pos = (pos - global_position).normalized()
	rotation.y = lerp_angle(rotation.y, atan2(pos.x, pos.z), delta * 15)

func _handle_target(delta:float):
	if entity_target:
		ray_time_passed += delta
		if ray_time_passed >= 0.2:
			target_pos = Vector3(entity_target.global_position.x, entity_target.global_position.y + raycast_height, entity_target.global_position.z)
			my_pos = Vector3(self.global_position.x, self.global_position.y + raycast_height, self.global_position.z)
			query = PhysicsRayQueryParameters3D.create(my_pos, target_pos)
			query.exclude = [self]
			result = space_state.intersect_ray(query)
			if self.global_position.distance_squared_to(entity_target.global_position) <= 1.5 * 1.5:
				if entity_state != Misc.entityState.ATTACKING:
					entity_state = Misc.entityState.ATTACKING
			else:
				if result.has("collider") and result["collider"] == entity_target: #Atakuje tylko gdy raycast sie laczy
					if entity_state != Misc.entityState.RUN_ATTACK:
						entity_state = Misc.entityState.RUN_ATTACK
			ray_time_passed = 0
	else:
		if entity_state != Misc.entityState.WANDER:
			entity_state = Misc.entityState.WANDER
			_get_random_pos()

func _handle_movement(delta: float):
	if !velocity.is_zero_approx():
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			if velocity.y < 0:
				velocity.y = 0
				
		velocity.x = lerp(velocity.x, 0.0, gravity * delta)
		velocity.z = lerp(velocity.z, 0.0, gravity * delta)
			
		#print("Physics update on ", name)
		move_and_slide()
	else:
		match entity_state:
			Misc.entityState.IDLE:
				pass

			Misc.entityState.RUN_ATTACK:
				navupdate_time_passed += delta
				if navupdate_time_passed >= 0.5:
					navupdate_time_passed = 0.0
					agent.set_target_position(entity_target.global_transform.origin)
					
				if agent.is_target_reachable():
					next_pos = agent.get_next_path_position()
					var dir = (next_pos - global_position).normalized()
					_velocity = dir * entity_speed
					_update_rotation(delta, dir) #W zaleznosci co ma trackowac przeciwnik, target, czy pozycje do ktorej idzie podczas targetowania targetu.
					if attack_time != 0.5:
						attack_time = 0.5
				else:
					entity_target = null #Skoro state=RUN_ATTACK, musi miec target, a jezeli target nie jest
										#reachable (w zasiegu nawigacji) ustaw target na null
									
				global_position += _velocity * delta

			Misc.entityState.WANDER:
				if random_pos == Vector3.ZERO:
					_get_random_pos()
					
				if !target_reached:
					if agent.is_target_reachable():
						next_pos = agent.get_next_path_position()
						var dir = (next_pos - global_position).normalized()
						_velocity = dir * entity_speed
						_update_rotation(delta, dir)
						
						global_position += _velocity * delta
					else:
						_get_random_pos()
						agent.set_target_position(random_pos)
				else:
					_get_random_pos()
					agent.set_target_position(random_pos)
					target_reached = false

			Misc.entityState.ATTACKING:
				_update_rotation(delta, entity_target.global_position, true)
				attack_time += delta
				if attack_time >= 0.7:
					entity_target.take_damage(1.3)
					attack_time = 0

func _handle_animation():
	match entity_state:
		Misc.entityState.IDLE:
			return
			
		Misc.entityState.RUN_ATTACK:
			if anim_player.current_animation == "animation_Crab_scuttle":
				return
			anim_player.play("animation_Crab_scuttle", -1, entity_speed)
			
		Misc.entityState.WANDER:
			if anim_player.current_animation == "animation_Crab_scuttle":
				return
			anim_player.play("animation_Crab_scuttle", -1, entity_speed)
		
		Misc.entityState.ATTACKING:
			if anim_player.is_playing():
				anim_player.stop(false)
			return

func _on_navigation_agent_3d_target_reached() -> void:
	target_reached = true

func take_damage(amount:float, knockback:float = 0):
	audio_player.play()
	turn_red()
	if amount < 0 or entity_health-amount <= 0:
		if audio_player.playing:
			$Hitbox.disabled = true
			self.hide()
			await audio_player.finished
			call_deferred("queue_free")
		else:
			call_deferred("queue_free")
	else:
		entity_health -= amount
	if show_health_status and health_status:
		pass
		#health_status.text = str(entity_health)

func turn_red():
	var meshes = find_children("*", "MeshInstance3D", true)
	for m in meshes:
		m.material_overlay = Misc.DAMAGE_FLASH
	await get_tree().create_timer(0.15).timeout
	for m in meshes:
		m.material_overlay = null

func apply_vector_force(from:Vector3, vertical_force:float = 4, horizontal_force:float = 16):
	var dir:Vector3 = (global_position - from).normalized()
	if abs(velocity.y) < 1:
		velocity.y =+ vertical_force
	velocity.x =+ dir.x * horizontal_force
	velocity.z =+ dir.z * horizontal_force
