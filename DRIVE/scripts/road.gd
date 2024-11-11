extends Node

var way
var road_type

const roadTextures = [
	preload("res://assets/materials/roads/primary.tres"),
	preload("res://assets/materials/roads/secondary.tres")
]

func getRoadWidthFromClassification(val):
	match val:
		"motorway":
			return 0#15
		"trunk":
			return 3#10
		"primary":
			return 3#10
		"secondary":
			return 7
		"tertiary":
			return 7
		"unclassified":
			return 7
		"residential":
			return 7
		"motorway_link":
			return 0
		"trunk_link":
			return 3
		"primary_link":
			return 3
		"secondary_link":
			return 5
		"tertiary_link":
			return 5
		"living_street":
			return 5
		"service":
			return 3
		"pedestrian":
			return 5
		"track":
			return 3.5
		"footway":
			return 2
		"path":
			return 2
		"sidewalk":
			return 2
	return 0

func getRoadMaterial(val):
	match val:
		"motorway":
			return roadTextures[1]
		"trunk":
			return roadTextures[1]
		"primary":
			return roadTextures[1]
		"secondary":
			return roadTextures[1]
		"tertiary":
			return roadTextures[1]
		"residential":
			return roadTextures[0]
		"motorway_link":
			return roadTextures[1]
		"trunk_link":
			return roadTextures[1]
		"primary_link":
			return roadTextures[1]
		"secondary_link":
			return roadTextures[0]
		"tertiary_link":
			return roadTextures[0]

func initRoadType():
	for tag in way.tags:
		if tag['k'] == 'highway':
			road_type = tag['v']
			return

func make(way):
	self.way = way

	self.curve = Curve3D.new()
	
	initRoadType()
	
	# Build a path
	
	var road_width = getRoadWidthFromClassification(road_type)
	var road_material = getRoadMaterial(road_type)
	
	for i in way.nodes:
		# Construct coordinates
		var coords = Globals.LatLong.new(
			Vector2(
				float(i['lat']),
				float(i['lon'])
			)
		)
		var coordsFeet = coords.toMeters()
		var coordsAndElevation = Vector3(coordsFeet.x, -1, coordsFeet.y)
		self.curve.add_point(coordsAndElevation)
	
	# CSG polygon
	var csg = CSGPolygon3D.new()
	csg.mode = CSGPolygon3D.MODE_PATH
	
	var resizedPolygon = PackedVector2Array()
	for i in csg.polygon:
		i.x -= 0.5
		if(i.y == 0):
			resizedPolygon.append(Vector2(i.x*road_width*1.1, i.y+0.9))
		else:
			resizedPolygon.append(Vector2(i.x*road_width, i.y + road_width/300.0 + randf_range(0.0, 0.001)))
	csg.polygon = resizedPolygon
	
	csg.set_use_collision(true)
	csg.path_node = self.get_path()
	csg.material = road_material
	
	# Add csg to path
	self.add_child(csg)
