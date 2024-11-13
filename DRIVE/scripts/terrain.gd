extends Node3D

const grass = preload("res://assets/materials/terrain/grass.tres")

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
	var subdivision = 0.0005
	
	var lon = lon_start
	while lon < lon_end:
		var lat = lat_start
		var lat_points = []
		while lat < lat_end:
			var newPoint = Globals.LatLongHeight.new(
					Vector2(lon, lat), 
					10
				)
			lat_points.append(
				newPoint.toMeters3D()
			)
			lat+=subdivision
		points.append(lat_points)
		lon+=subdivision
	
	var arr_mesh = ArrayMesh.new()
	#arrays.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	for i in range(len(points)):
		for j in range(len(points[i])):
			verts.push_back(
				points[i][j+(1 if i%3 == 0 and j!=len(points[i])-1 else 0)]
			)
			if len(verts) == 3:
				
				var arrays = []
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX] = verts
				print(verts)
				arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				
				verts = PackedVector3Array()
				
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = arr_mesh
	print("Push mesh")
	add_child(mesh_instance)
