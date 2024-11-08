extends Camera3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var pos = get_node("/root/Node3D/VehicleBody3D/MeshInstance3D").global_position
	var distance = pos.distance_to(global_position)
	global_position = global_position - (global_position - pos) / (200.0 / (distance - 3))
	look_at(pos)
