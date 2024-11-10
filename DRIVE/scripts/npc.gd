extends Node3D

var speed = 1
var danger = 0
var backwards
var road_width

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().get_parent().v_offset = 1.2
	get_parent().get_parent().h_offset = randf_range(-4, 4)
	speed *= randf_range(3, 4.5)
	if randi_range(0,1) == 0:
		backwards = true
		get_parent().get_parent().h_offset+1
	else:
		backwards = false
		get_parent().get_parent().h_offset-1
	road_width = 7
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	get_parent().get_parent().progress -= delta * (speed * cos(rotation.y) / ((danger**2 / 5) + 1))
	get_parent().get_parent().h_offset += delta * (speed * sin(rotation.y) / ((danger**2 / 5) + 1))

func _physics_process(delta):
	var casts = []
	var relativeDirection = -45
	
	while relativeDirection <= 45:
		var forward = Vector3(0,0.5,5)
		if backwards:
			rotation = Vector3(0, deg_to_rad(relativeDirection + 180), 0)
		else:
			rotation = Vector3(0, deg_to_rad(relativeDirection), 0)
		
		var space_rid = get_world_3d().space
		var space_state = PhysicsServer3D.space_get_direct_state(space_rid)
		
		var query = PhysicsRayQueryParameters3D.create(to_global(position), to_global(forward))
		var result = space_state.intersect_ray(query)
		var dangerometer = 0
		var distFromCenter = 0
		if result.has('position'):
			dangerometer = 1.0 / (to_global(position).distance_to(result['position']) + 0.01)
		if backwards:
			distFromCenter = abs((get_parent().get_parent().h_offset - road_width / 4) + -sin(deg_to_rad(relativeDirection)))
		else:
			distFromCenter = abs((get_parent().get_parent().h_offset + road_width / 4) + sin(deg_to_rad(relativeDirection)))
		casts.append({"result": result, "angle": relativeDirection, "dangerometer": dangerometer, "distFromCenter": distFromCenter})
		
		relativeDirection += 15
	
	rotation = Vector3()
	var sumDanger = 0.2
	var angle = 0
	for raycast in casts:
		var danger = raycast['dangerometer'] + raycast['distFromCenter'] / 100.0
		sumDanger += danger
		angle -= deg_to_rad(raycast['angle']) * danger
	if backwards:
		rotation = Vector3(0, angle / sumDanger + deg_to_rad(180), 0)
	else:
		rotation = Vector3(0, angle / sumDanger, 0)
	danger = sumDanger
