extends Node

enum entity_state { ##Enum responsible for entity behaviour
	IDLE, ## 0  Waits for instructions/state change
	RUN_ATTACK, ## 1  Runs toward target
	WANDER, ## 2  Wanders around and waits for instructions/state change
	ATTACKING ## 3  When enough close to target and deals damage do it.
	}

func truncate_v3(vect:Vector3) -> Vector3:
	return Vector3(int(vect.x), int(vect.y), int(vect.z))
