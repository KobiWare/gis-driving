extends Node3D

@export var texts = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func construct(position: Vector3, n1, n2):
	self.position = position
	print(n1.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
