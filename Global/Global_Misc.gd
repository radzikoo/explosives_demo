extends Node

enum entity_state {IDLE,RUN_ATTACK,WANDER,ATTACKING}

func truncate_v3(vect:Vector3) -> Vector3:
	return Vector3(int(vect.x), int(vect.y), int(vect.z))
