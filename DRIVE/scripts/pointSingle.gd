extends Node3D

@export var point_direction = 0.0
@export var text = "Test"

func fresh(point_direction, text):
	self.point_direction = point_direction
	self.text = text

# Called when the node enters the scene tree for the first time.
func _tree_entered() -> void:
	rotate_y(point_direction)
	get_child(0).get_child(0).text = text
