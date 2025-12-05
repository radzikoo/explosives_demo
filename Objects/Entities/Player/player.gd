extends CharacterBody3D
class_name Player

var cursor_hidden: bool = true

var health:float = 100

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	$UI/HealthBar.value = health
	_player_movement(delta)
	_check_chunk_collisions()
	get_raycast()
	get_target()
	
@export var auto_jump:bool = true
@export var speed:float
@export var walk_speed = 3.2
@export var sprint_speed = 4.5
@export var jump_velocity:float = 5
@export var sensitivity = 0.0016
@export var bob_freq = 5.4
@export var bob_amp = 0.02
@export var t_bob = 0.0
@export var base_fov = 75.0
@export var fov_change = 0.5
@export var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head:Node3D = $Head
@onready var camera:Camera3D = $Head/Camera3D

@onready var ajd1: RayCast3D = $AutoJumpDetector/RayCast3D
@onready var ajd2: RayCast3D = $AutoJumpDetector/RayCast3D2

var standing_at_chunk_id:Vector2
var target_chunk_id:Vector2
@onready var chunk_manager: Node3D = $"../ChunkManager"

func _player_movement(delta: float) -> void:
	
	standing_at_chunk_id = Vector2(floor(global_position.x/chunk_manager.chunk_size.x), 
							floor(global_position.z/chunk_manager.chunk_size.z))
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle Sprint.
	if Input.is_action_pressed("run"):
		speed = sprint_speed
	else:
		speed = walk_speed

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, sprint_speed * 2)
	var target_fov = base_fov + fov_change * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("mouseMode"):
		cursor_hidden = !cursor_hidden
	
		if cursor_hidden:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
	if Input.is_action_just_pressed("explode"):
		PFX.sphere_explosion(self.global_transform, 10, 1)
			
	
	if auto_jump:
		if direction:
			ajd1.target_position = direction/1.5
			ajd2.target_position = direction/1.5
		
		if direction != Vector3.ZERO:
			if ajd1.is_colliding() and not ajd2.is_colliding():
				if ajd1.get_collider().is_in_group("Terrain"):
					if !ajd1.is_colliding():
						pass
					else: 
						if velocity.y == 0:
							velocity.y += jump_velocity
							#print("Autojumped")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if cursor_hidden:
			head.rotate_y(-event.relative.x * sensitivity)
			camera.rotate_x(-event.relative.y * sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

const RAY_LENGTH:float = 4
var raycast_result:Dictionary

func get_raycast():
	#Intersects a ray in a given space. 
#Ray position and other parameters are defined through PhysicsRayQueryParameters3D. The returned object is a dictionary with the following fields:
#collider: The colliding object.
#collider_id: The colliding object's ID.
#normal: The object's surface normal at the intersection point, or Vector3(0, 0, 0) if the ray starts inside the shape and PhysicsRayQueryParameters3D.hit_from_inside is true.
#position: The intersection point.
#face_index: The face index at the intersection point.
#Note: Returns a valid number only if the intersected shape is a ConcavePolygonShape3D. Otherwise, -1 is returned.
#rid: The intersecting object's RID.
#shape: The shape index of the colliding shape.
#If the ray did not intersect anything, then an empty dictionary is returned instead.
	
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = camera.project_ray_origin(mousepos)
	var end = origin + camera.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self.get_rid(), $DamageArea.get_rid()]
	raycast_result = space_state.intersect_ray(query)
	 
var snapped_targetpos:Vector3
var chunk_adjusted_target_pos:Vector3
	
func get_target():
	if len(raycast_result) > 0:
		var target_pos:Vector3 = raycast_result["position"]
		var target_face:Vector3 = raycast_result["normal"]
		#var snapped_targetpos:Vector3 #= Vector3(
			#snapped(floor(target_pos.x), 1),
			#(snapped(floor(target_pos.y), 1))-1,
			#snapped(floor(target_pos.z), 1)
			#snapped(target_pos.x-target_face.x, 1-0),
			#snapped(target_pos.y-target_face.y, 1-1),
			#snapped(target_pos.z-target_face.z, 1-1)
		#)
		
		# -- X --
		if target_face == Vector3(1,0,0):
			snapped_targetpos.x = (snapped(floor(target_pos.x), 1))-1
		else:
			pass
			snapped_targetpos.x = (snapped(floor(target_pos.x), 1))
		
		# -- Y --
		if target_face == Vector3(0,1,0):
			snapped_targetpos.y = (snapped(floor(target_pos.y), 1))-1
		else:
			pass
			snapped_targetpos.y = (snapped(floor(target_pos.y), 1))
		
		# -- Z --
		if target_face == Vector3(0,0,1):
			snapped_targetpos.z = (snapped(floor(target_pos.z), 1))-1
		else:
			pass
			snapped_targetpos.z = (snapped(floor(target_pos.z), 1))
			
		
		target_chunk_id = Vector2(floor(snapped_targetpos.x/chunk_manager.chunk_size.x), 
			floor(snapped_targetpos.z/chunk_manager.chunk_size.z))
		
		if Input.is_action_just_pressed("destroy"):
			chunk_manager.destroy_tile(snapped_targetpos, target_chunk_id)
			#print("=======")
			#print("FACE: ", target_face)
			#print("CHUNK: ", target_chunk_id)
			#print("TARGET POS: ", target_pos)
			#print("SNAPP TARG POS: ", snapped_targetpos)
		if Input.is_action_just_pressed("place"):
			chunk_manager.place_tile(snapped_targetpos, target_chunk_id)

func _on_damage_area_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		print("player impact ", body.name)
		#if ((body.linear_velocity.length()) * body.mass) > 10:
			#print("HIT ", ((body.linear_velocity.length()) * body.mass))

func take_damage(damage:float):
	health -= damage

func _check_chunk_collisions():
	pass
#	for tile in chunk.chunk_tiles:
		#print(Misc.truncate_v3(chunk.chunk_tiles[tile]["position"]))
	#	if Misc.truncate_v3(chunk.chunk_tiles[tile]["position"]) == Misc.truncate_v3(self.global_position):
		#	print("d")
