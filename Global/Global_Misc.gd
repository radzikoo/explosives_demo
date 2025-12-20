extends Node

enum entity_state { ##0-IDLE  1-RUN_ATTACK   2-WANDER   3-ATTACKING
	IDLE, 
	RUN_ATTACK,
	WANDER,
	ATTACKING
	}

func truncate_v3(vect:Vector3) -> Vector3:
	return Vector3(int(vect.x), int(vect.y), int(vect.z))
