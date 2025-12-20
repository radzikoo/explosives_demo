@icon("res://Scripts/EntitySpawner/class.png")
extends CollisionShape3D
##3D area whose boundaries define where entity can be spawned.
class_name EntitySpawner

@export var autostart:bool = false
@export var entity_scene:PackedScene
@export var entity_amount:int
@export var endless:bool = false
@export var time_delay:float
@export var spawn_y:float

var time:float

func _ready() -> void:
	#if endless:
		#entity_amount = 100000
	if entity_scene == null:
		print_debug("No entity scene path is provided!")
	else:
		if autostart and !time_delay:
			summon_entities(0)
			
func _physics_process(delta: float) -> void:
	if time_delay:
		summon_entities(delta)
		
func summon_entities(delta):
		time += delta
		for n in entity_amount:
			if time >= time_delay:
				var inst = entity_scene.instantiate()
				get_parent().call_deferred("add_child", inst)
				inst.global_position = Vector3(
					randi_range(global_position.x-(shape.size.x/2),global_position.x+(shape.size.x/2)),
					spawn_y,
					randi_range(global_position.z-(shape.size.z/2),global_position.z+(shape.size.z/2)),
				)
				time = 0
				if endless:
					n = n-1
