extends Control

@onready var player: Player = $".."


func _process(delta: float) -> void:
	$Metrics.text = ("Frames per second: " + str(Engine.get_frames_per_second()) + " (capped to: " + str(Engine.max_fps) + ")" + "
	XYZ: " + str(player.global_position) + "
	Standing at chunk: " + str(player.standing_at_chunk_id) + "
	Looking at chunk: " + str(player.target_chunk_id))


func _on_teleport_pressed() -> void:
	$"..".global_position = Vector3(float($Teleporter/HBoxContainer/XC.text),
	float($Teleporter/HBoxContainer/YC.text),
	float($Teleporter/HBoxContainer/ZC.text))
