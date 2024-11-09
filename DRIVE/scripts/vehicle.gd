extends VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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
