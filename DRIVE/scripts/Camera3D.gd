extends Camera3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var pos = get_node("/root/Node3D/VehicleBody3D").global_position
	pos.y += 1.5
	var distance = pos.distance_to(global_position)
	global_position = global_position - (global_position - pos) / (100.0 / (distance - 3))
	look_at(pos)
