extends CharacterBody3D

@export var speed:float
@export var jump_velocity:float

#IDLE,RUN_ATTACK,WANDER,ATTACKING
var state:Misc.entity_state = Misc.entity_state.WANDER

@export var entity_active:bool = false

var rand_pos:Vector3
var can_get_rand_pos:bool
@onready var navagent: NavigationAgent3D = $NavigationAgent3D

@onready var healthbar: Label3D = $Health
var health:float = 100
var target: Object
var check_raycast:bool = false

@onready var player: CharacterBody3D = %Player

var space_state

func _ready() -> void:
	space_state = get_world_3d().direct_space_state
	get_rand_pos()

func _physics_process(delta: float) -> void:
	if entity_active:
		_handle_target()
		if int(healthbar.text) != health:
			healthbar.text = str(health)
		if health <= 0:
			self.queue_free()
		if speed > 0:
			_handle_movement(delta)
		_handle_impact()

func get_rand_pos():
	var posx = randi_range(-5,5)
	var posz = randi_range(-5,5)
	#NavigationServer3D.map_get_closest_point(navagent.get_navigation_map(), Vector3(global_position.x + posx, global_position.y, global_position.z + posz))
	rand_pos = NavigationServer3D.map_get_closest_point(navagent.get_navigation_map(), 
	Vector3(global_position.x + posx, global_position.y, global_position.z + posz))
	#print("d")
	can_get_rand_pos = false

func _handle_movement(delta):
	if arrows <= 0:
		if self.global_position.distance_to(player.global_position) < 7:
			if target != player:
				target = player
		else:
			if target != null:
				target = null
	
	match state:
		Misc.entity_state.IDLE:
			print("idle")
			if a_time != a_wait_time:
				a_time = a_wait_time
			
		Misc.entity_state.WANDER:
			if global_position.distance_to(rand_pos) > 2:
				#print(global_position.distance_to(rand_pos))
				#print("asd")
				navagent.set_target_position(rand_pos)
				var next_nav_point: Vector3 = navagent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * speed
				var new_lookat_pos = Vector3(navagent.get_next_path_position().x, global_position.y, navagent.get_next_path_position().z)
				if global_position != new_lookat_pos: 
					look_at(new_lookat_pos, Vector3.UP, true)
				move_and_slide()
			else:
				can_get_rand_pos = true
				get_rand_pos()
			if a_time != a_wait_time:
				a_time = a_wait_time
			
		Misc.entity_state.RUN_ATTACK:
			navagent.set_target_position(player.global_transform.origin)
			var next_nav_point: Vector3 = navagent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * speed
			look_at(Vector3(navagent.get_next_path_position().x, global_position.y, navagent.get_next_path_position().z), Vector3.UP, true)
			move_and_slide()
			#if a_time != a_wait_time:
				#a_time = a_wait_time
			
		Misc.entity_state.ATTACKING:
			if target:
				a_time += delta
				if a_time >= a_wait_time:
					target.take_damage(10)
					a_time = 0
					
var a_time:float = a_wait_time
var a_wait_time:float = 2
var result:Dictionary

func _handle_target():
	if target:
		var player_pos = Vector3(player.global_position.x, player.global_position.y + 1.5, player.global_position.z)
		var enemy_pos = Vector3(self.global_position.x, self.global_position.y + 1.5, self.global_position.z)
		var query = PhysicsRayQueryParameters3D.create(enemy_pos, player_pos)
		query.exclude = [self]
		result = space_state.intersect_ray(query)
		if result.has("collider"):
			#print(result["collider"].name)
			if result["collider"] == player:
				if self.global_position.distance_to(player.global_position) > 1.5:
					if state != Misc.entity_state.RUN_ATTACK:
						state = Misc.entity_state.RUN_ATTACK
				else:
					if state != Misc.entity_state.ATTACKING:
						state = Misc.entity_state.ATTACKING
			else:
				if state == Misc.entity_state.RUN_ATTACK or state == Misc.entity_state.ATTACKING:
					if state != Misc.entity_state.WANDER:
						state = Misc.entity_state.WANDER
	elif state != Misc.entity_state.WANDER:
		state = Misc.entity_state.WANDER

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			PFX.sphere_explosion(self.global_transform, 10, 1)

var arrows:int

func take_damage(damage:float, from:Object):
	health -= damage
	if from:
		_attack_from_far(from)

func _attack_from_far(from:Object):
	arrows += 1
	target = from
	state = Misc.entity_state.RUN_ATTACK
	await get_tree().create_timer(6).timeout
	arrows -= 1

func _on_damage_area_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		print("enemy impact ", body.name)
		take_damage(snapped(body.linear_velocity.length() * body.mass, 0), null)

func _handle_impact():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() is RigidBody3D:
			var collider = collision.get_collider()
			print("enemy impact ", collider.name)
			take_damage(snapped(collider.linear_velocity.length() * collider.mass, 0), null)
		
