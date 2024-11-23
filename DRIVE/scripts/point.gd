extends Node3D

@export var texts = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# TODO: Calculate pointy direction
func construct(position: Vector3, n1, direction):
	self.position = position
	self.get_child(0).fresh(direction, n1.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
