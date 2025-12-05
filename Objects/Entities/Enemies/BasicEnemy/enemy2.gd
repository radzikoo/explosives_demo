extends CharacterBody3D

var state: Misc.entity_state = Misc.entity_state.RUN_ATTACK

var navagent: RID = NavigationServer3D.agent_create()
var navmap: RID

var path: PackedVector3Array = []
var path_index: int = 0
var speed: float = 3.0

var wander_timer: float = 0.0
var wander_interval: float = 2.0 # co ile sekund losować nowy cel

@onready var navreg: NavigationRegion3D = $"../NavigationRegion3D"

func _ready() -> void:
	navmap = navreg.get_navigation_map()
	
	NavigationServer3D.agent_set_map(navagent, navmap)
	NavigationServer3D.agent_set_avoidance_enabled(navagent, true)
	NavigationServer3D.agent_set_height(navagent, 2)
	NavigationServer3D.agent_set_radius(navagent, 0.5)


func _physics_process(delta: float) -> void:
	NavigationServer3D.agent_set_position(navagent, global_position)
	handle_state(delta)

func get_rand_pos() -> Vector3:
	var xpos = randi_range(-10, 10)
	var zpos = randi_range(-10, 10)
	var complete_pos = Vector3(global_position.x + xpos, global_position.y, global_position.z + zpos)
	var closest = NavigationServer3D.map_get_closest_point(navmap, complete_pos)
	#print("Random target: ", closest)
	return closest


func handle_state(delta: float):
	match state:
		Misc.entity_state.IDLE:
			idle(delta)
		
		Misc.entity_state.RUN_ATTACK:
			run_attack(delta)
		
		Misc.entity_state.WANDER:
			wander()
			
		Misc.entity_state.ATTACKING:
			attacking(delta)


# === STATES ===
func idle(delta: float):
	velocity = Vector3.ZERO
	move_and_slide()


func run_attack(delta: float):
	# Jeśli brak ścieżki lub czas na nowy cel
	if path.is_empty() or wander_timer <= 0.0:
		var target = get_rand_pos()
		path = NavigationServer3D.map_get_path(navmap, global_position, target, true)
		#print("Generated path: ", path) # DEBUG
		path_index = 0
		wander_timer = wander_interval
	
	# Jeśli mamy ścieżkę, poruszamy się po niej
	if path.size() > 0 and path_index < path.size():
		var target_pos = path[path_index]
		var dir = (target_pos - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		
		# Rotacja przeciwnika
		if (target_pos - global_position).length() > 0.01:
			pass
			look_at(target_pos, Vector3.UP)
		
		# Sprawdzenie, czy osiągnięto punkt
		if global_position.distance_to(target_pos) < 0.3:
			path_index += 1
	else:
		velocity = Vector3.ZERO
		move_and_slide()


func wander():
	pass

func attacking(delta: float):
	pass
