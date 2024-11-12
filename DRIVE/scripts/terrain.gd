extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func generate_terrain():
	var terrain = ArrayMesh.new()
	var points = []
	var lat_start = get_parent().lat1
	var lat_end = get_parent().lat2
	var lon_start = get_parent().lon1
	var lon_end = get_parent().lon2
	print("generating")
	
	for i in range(lat_start, lat_end, 0.001):
		pass
