extends Node3D

const grass = preload("res://assets/materials/terrain/grass.tres")
var points = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# TODO: Interperlation
func get_elevation_at_xz(position: Vector2):
	var index = Vector2(int(len(points[0])/2), int(len(points)/2))
	var binary_search = len(points) / 4.0
	var point = null
	while binary_search > 0.2:
		point = points[round(index.y)][round(index.x)]
		if point.z < position.x:
			index.x += binary_search
		else:
			index.x -= binary_search
		
		if point.x < position.y:
			index.y += binary_search
		else:
			index.y -= binary_search
		binary_search /= 2.0
	return point.y

func generate_terrain():
	var terrain = ArrayMesh.new()
	var lat_start = get_parent().lat1
	var lat_end = get_parent().lat2
	var lon_start = get_parent().lon1
	var lon_end = get_parent().lon2
	var subdivision = 0.0001
	
	var lon = lon_start
	while lon < lon_end:
		var lat = lat_start
		var lat_points = []
		while lat < lat_end:
			var newPoint = Globals.LatLongHeight.new(
					Vector2(lon, lat), 
					(cos(lon * 5000) * cos(lat * 5000) * 4)
				)
			lat_points.append(
				newPoint.toMeters3D()
			)
			lat+=subdivision
		points.append(lat_points)
		lon+=subdivision
	
	var arr_mesh = ArrayMesh.new()
	var triangles = PackedVector3Array()
	
	for i in range(len(points)-1):
		for j in range(len(points[i])-1):
			var triangle1 = PackedVector3Array(
					[
						points[i][j],
						points[i+1][j],
						points[i][j+1]
					]
				)
			var triangle2 = PackedVector3Array(
					[
						points[i+1][j],
						points[i+1][j+1],
						points[i][j+1]
					]
				)
			triangles.append_array(triangle1)
			triangles.append_array(triangle2)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = triangles
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
				
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = arr_mesh
	print(len(points), " ", len(points[0]))
	add_child(mesh_instance)
