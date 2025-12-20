extends Node3D

#Nodes
@onready var agent:NavigationAgent3D = $NavigationAgent3D
var animplayer:AnimationPlayer

#Entity properties
@export var entity_active:bool = false
@export var entity_speed:float
@onready var entity_target:Object
var entity_state:Misc.entity_state = Misc.entity_state.WANDER

#Navigation realted things
@onready var navmap:RID #to mozna wyciac
@onready var space_state:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
var random_pos:Vector3
var can_get_rand_pos:bool
var next_pos:Vector3
var velocity:Vector3

#Time counters
var navupdate_time_passed:float
var look_time_passed:float
var wander_time_passed:float
var ray_time_passed:float

#Player-Entity raycast detection
@export var raycast_height:float
var result:Dictionary
var query:PhysicsRayQueryParameters3D
var target_pos:Vector3
var my_pos:Vector3

func _ready() -> void:
	_init_entity()

func _physics_process(delta: float) -> void: #moze zmienic na zwykly process
	if entity_active:
		_handle_target(delta)
		_handle_movement(delta)

func _init_entity():
	for child in get_children():
		if child is AnimationPlayer:
			animplayer = child
	await NavigationServer3D.map_changed
	agent.set_navigation_map(agent.get_navigation_map())
	_get_random_pos()

func _get_random_pos():
	can_get_rand_pos = true
	var posx = randi_range(-5,5)
	var posz = randi_range(-5,5)
	var fpos = Vector3(global_position.x + posx, global_position.y, global_position.z + posz)
	random_pos = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), fpos)
	can_get_rand_pos = false

func _update_rotation(delta:float, pos:Vector3):
	look_time_passed += delta
	if look_time_passed >= 0.1:
		look_time_passed = 0
		look_at(
		Vector3(pos.x, global_position.y, pos.z),
		Vector3.UP, true
		)
		
func _update_pos_rotation(delta):
	look_time_passed += delta
	if look_time_passed >= 0.1:
		look_time_passed = 0
		look_at(
		Vector3(next_pos.x,
		global_position.y,
		next_pos.z), Vector3.UP, true)
		#print("UPDATE POS ROTATION")

func _update_target_rotation(delta):
	look_time_passed += delta
	if look_time_passed >= 0.1:
		look_time_passed = 0.0
		look_at(
		Vector3(entity_target.global_position.x,
		global_position.y,
		entity_target.global_position.z), Vector3.UP, true)

func _handle_target(delta:float):
	if entity_target:
		ray_time_passed += delta
		if ray_time_passed >= 0.2:
			target_pos = Vector3(entity_target.global_position.x, entity_target.global_position.y + raycast_height, entity_target.global_position.z)
			my_pos = Vector3(self.global_position.x, self.global_position.y + raycast_height, self.global_position.z)
			query = PhysicsRayQueryParameters3D.create(my_pos, target_pos)
			query.exclude = [self]
			result = space_state.intersect_ray(query)
			if self.global_position.distance_to(entity_target.global_position) <= 1.5:
				if entity_state != Misc.entity_state.ATTACKING:
					entity_state = Misc.entity_state.ATTACKING
			else:
				if result.has("collider") and result["collider"] == entity_target: #Atakuje tylko gdy raycast sie laczy
					if entity_state != Misc.entity_state.RUN_ATTACK:
						entity_state = Misc.entity_state.RUN_ATTACK
			ray_time_passed = 0
	else:
		if entity_state != Misc.entity_state.WANDER:
			entity_state = Misc.entity_state.WANDER
	
func _handle_movement(delta: float):
	match entity_state:
		Misc.entity_state.IDLE:
			pass
			print("IDLE on ", name)

		Misc.entity_state.RUN_ATTACK:
			navupdate_time_passed += delta
			if navupdate_time_passed >= 0.5:
				navupdate_time_passed = 0.0
				agent.set_target_position(entity_target.global_transform.origin)
				
			if agent.is_target_reachable():
				next_pos = agent.get_next_path_position()
				var dir = (next_pos - global_position).normalized()
				velocity = dir * entity_speed
				_update_rotation(delta, entity_target.global_position) #W zaleznosci co ma trackowac przeciwnik, target, czy pozycje do ktorej idzie podczas targetowania targetu.
			else:
				entity_target = null #Skoro state=RUN_ATTACK, musi miec target, a jezeli target nie jest
									#reachable (w zasiegu nawigacji) ustaw target na null
								
			global_position += velocity * delta

		Misc.entity_state.WANDER:
			if random_pos == Vector3.ZERO:
				_get_random_pos()
				
			if self.global_position.distance_to(random_pos) >= 0.5:
				wander_time_passed += delta
				if wander_time_passed >= 0.5:
					wander_time_passed = 0.0
					agent.set_target_position(random_pos)
						
				if agent.is_target_reachable():
					next_pos = agent.get_next_path_position()
					var dir = (next_pos - global_position).normalized()
					velocity = dir * entity_speed
					_update_rotation(delta, next_pos)
					
					global_position += velocity * delta
				else:
					_get_random_pos()
					agent.set_target_position(random_pos)
			else:
				_get_random_pos()

		Misc.entity_state.ATTACKING:
			pass
