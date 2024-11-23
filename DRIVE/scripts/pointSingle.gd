extends Node3D


func fresh(point_direction, text):
	rotate_y(point_direction)
	var ch = get_child(get_child_count()-1)
	ch.get_child(0).text = text
