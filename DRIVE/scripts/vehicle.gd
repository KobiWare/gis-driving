extends VehicleBody3D

var view_distance = 0.125
var environment
# Called when the node enters the scene tree for the first time.
func _ready():
	environment = get_node("/root/Node3D/WorldEnvironment")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ui_up"):
		engine_force = 350
	else:
		engine_force /= 1+delta*5
	
	if Input.is_action_pressed("ui_down"):
		brake = 30
		engine_force = -150
	
	if Input.is_action_pressed("ui_left"):
		steering = min(0.2, steering+delta)
	elif Input.is_action_pressed("ui_right"):
		steering = max(-0.2, steering-delta)
	else:
		steering /= 1+delta*3
		
	if Input.is_action_just_pressed("reset_car"):
		self.rotation = Vector3(0, 46.2, 0)
		
	if Input.is_action_just_pressed("cycle_view_distance"):
		if view_distance < 1:
			view_distance += 0.125
		else:
			view_distance = 0
		environment.environment.fog_density = view_distance
