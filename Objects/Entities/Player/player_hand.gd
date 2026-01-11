extends Node3D

#Enums
enum itemType {
	MELEE,
	BOW,
	OTHER
}

#Item properties
@export var item_type:itemType = itemType.MELEE
@export var hit_damage:float = 1

#Nodes
@onready var player: Player = $"../../.."
@onready var item_node:Node3D = get_child(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_item"):
		pass
		#if item_type == itemType.MELEE:
#			item_node.use(get_raycast())

func get_raycast():
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	var origin = player.camera.project_ray_origin(mousepos)
	var end = origin + player.camera.project_ray_normal(mousepos) * 3
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	return space_state.intersect_ray(query)
