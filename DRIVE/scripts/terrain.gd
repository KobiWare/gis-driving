extends Node3D

const grass = preload("res://assets/materials/terrain/grass.tres")
var points = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# TODO: Mostly fixed but still weird and too much y offset sometimes
func get_terrain(index: Vector2) -> Vector3:
	index += Vector2(0.00001, 0.00001)
	if index.x > len(points[0])-1:
		index.x -=1
	if index.x < 0:
		index.x +=1
	
	if index.y > len(points)-1:
		index.y -=1
	if index.y < 0:
		index.y +=1
	
	# Bilinear interpolation
	var x1 = floor(index.x)
	var x2 = ceil(index.x)
	var y1 = floor(index.y)
	var y2 = ceil(index.y)
	
	var Q11 = points[y1][x1]
	var Q21 = points[y1][x2]
	var Q12 = points[y2][x1]
	var Q22 = points[y2][x2]
	
	var R1 = ((x2 - index.x) / (x2 - x1)) * Q11 + ((index.x - x1) / (x2 - x1)) * Q21
	var R2 = ((x2 - index.x) / (x2 - x1)) * Q12 + ((index.x - x1) / (x2 - x1)) * Q22
	
	var P = ((y2 - index.y) / (y2 - y1)) * R1 + ((index.y - y1) / (y2 - y1)) * R2
	return P
func get_elevation_at_xz(position: Vector2):
	var index = Vector2(len(points[0])/2.0, len(points)/2.0)
	var binary_search = len(points) / 4.0
	var point = null
	while binary_search > 0.01:
		point = get_terrain(index)
		
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
					(cos(lon * 10000) * cos(lat * 10000) * 40)
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
