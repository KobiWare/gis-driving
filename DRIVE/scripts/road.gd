extends Node
class_name Road

var way
var road_type
var road_width
const type = "Road"

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

func calculate_intersection_polygon(shared_node, other_road):
	# Shared node as lat long
	var shared_node_position = shared_node['latlon'].toMeters()
	
	# Get the directions of both roads at the intersection point
	var our_direction = get_road_direction_at_node(shared_node)
	var other_direction = other_road.get_road_direction_at_node(shared_node)
	
	# Get the widths of both roads
	var our_width = road_width
	var other_width = other_road.road_width
	
	# Calculate the intersection points
	var intersection_points = []
	
	# Calculate corner points of the intersection
	var half_width1 = other_width / 2.0
	var half_width2 = our_width / 2.0
	
	# Calculate perpendicular vectors
	var perp1 = Vector2(our_direction.y, our_direction.x).normalized()
	var perp2 = Vector2(other_direction.y, other_direction.x).normalized()
	
	# Calculate the four corners of the intersection
	var p1 = shared_node_position + (perp1 * half_width1) + (perp2 * half_width2)
	var p2 = shared_node_position + (perp1 * half_width1) - (perp2 * half_width2)
	var p3 = shared_node_position - (perp1 * half_width1) - (perp2 * half_width2)
	var p4 = shared_node_position - (perp1 * half_width1) + (perp2 * half_width2)
	
	return PackedVector2Array([p1, p2, p3, p4])

func get_road_direction_at_node(node):
	# Find the node index
	var node_index = -1
	for i in range(way.nodes.size()):
		if way.nodes[i] == node:
			node_index = i
			break
	
	if node_index == -1:
		return Vector2.ZERO
		
	# Calculate direction based on neighboring nodes
	var direction = Vector2.ZERO
	
	if node_index > 0:
		var prev_node = way.nodes[node_index - 1]
		var directionBackwards = node['latlon'].toMeters() - prev_node['latlon'].toMeters()
		var directionCorrected = Vector2(directionBackwards.y, directionBackwards.x)
		direction += directionCorrected
		"""
		Vector2(
			float(node['lon']) - float(prev_node['lon']),
			float(node['lat']) - float(prev_node['lat'])
		)
		"""
	
	if node_index < way.nodes.size() - 1:
		var next_node = way.nodes[node_index + 1]
		var directionBackwards =  next_node['latlon'].toMeters() - node['latlon'].toMeters()
		var directionCorrected = Vector2(directionBackwards.y, directionBackwards.x)
		direction += directionCorrected
		
		"""
		Vector2(
			float(next_node['lon']) - float(node['lon']),
			float(next_node['lat']) - float(node['lat'])
		)
		"""
	
	return direction.normalized()

func make(way):
	self.way = way

	self.curve = Curve3D.new()
	
	initRoadType()
	
	# Build a path
	
	road_width = getRoadWidthFromClassification(road_type)
	var road_material = getRoadMaterial(road_type)
	
	for i in way.nodes:
		for shared in i['shared']:
			if shared.type == 'Road' and road_width >= 3:
				var intersectionPolygon = calculate_intersection_polygon(i, shared)
				var csg = CSGPolygon3D.new()
				csg.polygon = intersectionPolygon
				csg.depth = 50
				csg.rotation.x = PI / 2
				add_child(csg)
		
		# Construct coordinates
		var coords = Globals.LatLong.new(
			Vector2(
				float(i['lat']),
				float(i['lon'])
			)
		)
		var coordsFeet = coords.toMeters()
		var coordsAndElevation = Vector3(coordsFeet.x, get_parent().get_parent().get_parent().get_elevation_at_xz(coordsFeet), coordsFeet.y)
		self.curve.add_point(coordsAndElevation)
		
		i['shared'].append(self)
	
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
