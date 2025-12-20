
extends Node3D

#Nodes
#@onready var raycast: RayCast3D = $RayCast3D
@onready var agent: NavigationAgent3D = $NavigationAgent3D
var animplayer: AnimationPlayer
#@onready var player := %Player

#Entity properties
@export var entity_active:bool = false
@export var entity_speed:float
@onready var entity_target #= %Player
var entity_state:Misc.entity_state = Misc.entity_state.WANDER

#Navigation realted things
@onready var navmap := agent.get_navigation_map()
@onready var space_state = get_world_3d().direct_space_state
var random_pos:Vector3
var can_get_rand_pos:bool
var navupdate_time_passed:float
var look_time_passed:float
var wander_time_passed:float
var next_pos:Vector3

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
		#_handle_state()
		_handle_target()
		_handle_movement(delta)

func _init_entity():
	for child in get_children():
		if child is AnimationPlayer:
			animplayer = child
	await NavigationServer3D.map_changed
	agent.set_navigation_map(agent.get_navigation_map())
	_get_random_pos()


func _get_random_pos():
	var posx = randi_range(-5,5)
	var posz = randi_range(-5,5)
	var fpos = Vector3(global_position.x + posx, global_position.y, global_position.z + posz)
	random_pos = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), fpos)
	can_get_rand_pos = false
	#print(random_pos)

func _update_rotation():
	if next_pos:
		if self.global_position.distance_to(next_pos) >= 0.05:
			look_at(
			Vector3(next_pos.x,
			global_position.y,
			next_pos.z), Vector3.UP, true)
	#else:
		#look_at(
		#Vector3(random_pos.x,
		#global_position.y,
		#random_pos.z), Vector3.UP, true)

func _handle_target():
	if entity_target:
		target_pos = Vector3(entity_target.global_position.x, entity_target.global_position.y + raycast_height, entity_target.global_position.z)
		my_pos = Vector3(self.global_position.x, self.global_position.y + raycast_height, self.global_position.z)
		query = PhysicsRayQueryParameters3D.create(my_pos, target_pos)
		query.exclude = [self]
		result = space_state.intersect_ray(query)
		if result.has("collider") and result["collider"] == entity_target:
			if self.global_position.distance_to(entity_target.global_position) <= 1.5:
				if entity_state != Misc.entity_state.ATTACKING:
					entity_state = Misc.entity_state.ATTACKING
			else:
				if entity_state != Misc.entity_state.RUN_ATTACK:
					entity_state = Misc.entity_state.RUN_ATTACK
	else:
		if entity_state != Misc.entity_state.WANDER:
			entity_state = Misc.entity_state.WANDER
	
func _handle_movement(delta: float):
	#_update_rotation()
	if random_pos == Vector3.ZERO:
		can_get_rand_pos = true
		_get_random_pos()
	
	#if (next_pos - global_position).length() > 0:
		#agent.set_target_position(random_pos)
		if agent.is_target_reachable():
			next_pos = agent.get_next_path_position()
			var target_dir = (next_pos - global_position).normalized()
			var new_dir = global_transform.basis.z.slerp(target_dir, 5.0 * delta).normalized()
			look_at(global_position + new_dir, Vector3.UP)
			global_position += global_transform.basis.z * 1 * delta
			
			#global_position += velocity * delta
			#agent.set_velocity(velocity)
		else:
			pass
			#can_get_rand_pos = true
			#_get_random_pos()
			#agent.set_target_position(random_pos)
			#_update_rotation()
	else:
		can_get_rand_pos = true
		_get_random_pos()
