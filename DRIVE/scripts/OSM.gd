extends Node3D

const roadTextures = [
	preload("res://assets/materials/roads/primary.tres"),
	preload("res://assets/materials/roads/secondary.tres")
]

const skyscraperBaseTextures = [
	preload("res://assets/materials/buildings/skyscraper/base/1.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/2.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/3.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/4.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/5.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/6.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/7.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/8.jpg"),
	preload("res://assets/materials/buildings/skyscraper/base/9.jpg"),
]

const skyscraperBaseMaterial = preload("res://assets/materials/buildings/skyscraper/base/general.tres")

const skyscraperMainMaterial = preload("res://assets/materials/buildings/skyscraper/other/general.tres")

class LatLong:
	static var relPos = Vector2(40.70562, -74.0176)
	var pos
	
	func _init(pos: Vector2) -> void:
		self.pos = pos
		
	# TODO: I have no idea how to actually calculate this lmao
	func toFeet() -> Vector2:
		return (self.pos - relPos) * 100000

class Buildable extends Node:
	var element_name = null
	var tags = []
	var nodes = []
	
	func _init() -> void:
		pass
	
	func add_node(node) -> void:
		nodes.append(node)
	
	func add_tag(tag) -> void:
		tags.append(tag)
	
	func construct() -> void:
		pass

class Way extends Buildable:
	func _init() -> void:
		element_name = "way"
	
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
				return roadTextures[0]
			"tertiary":
				return roadTextures[0]
			"residential":
				return roadTextures[0]
			"motorway_link":
				return roadTextures[0]
			"trunk_link":
				return roadTextures[0]
			"primary_link":
				return roadTextures[0]
			"secondary_link":
				return roadTextures[0]
			"tertiary_link":
				return roadTextures[0]
	
	# TODO: water
	func construct() -> void:
		for tag in tags:
			if tag['k'] == 'highway':
				constructRoad(getRoadWidthFromClassification(tag['v']), tag['v'])
				break
			if tag['k'] == 'building':
				constructBuilding(tag['v'])
	
	# TODO: Intersections, street-lamps, car npcs, bridges
	
	func constructRoad(width, roadType) -> void:
		var path = Path3D.new()
		path.curve = Curve3D.new()
		# Build a path
		print("Constructing...")
		for i in nodes:
			# Construct coordinates
			var coords = LatLong.new(
				Vector2(
					float(i['lat']),
					float(i['lon'])
				)
			)
			var coordsFeet = coords.toFeet()
			var coordsAndElevation = Vector3(coordsFeet.x, -1, coordsFeet.y)
			path.curve.add_point(coordsAndElevation)
		
		
		get_node("./").add_child(path)
		
		# CSG polygon
		var csg = CSGPolygon3D.new()
		csg.mode = CSGPolygon3D.MODE_PATH
		
		var resizedPolygon = PackedVector2Array()
		for i in csg.polygon:
			i.x -= 0.5
			if(i.y == 0):
				resizedPolygon.append(Vector2(i.x*width*1.1, i.y+0.9))
			else:
				resizedPolygon.append(Vector2(i.x*width, i.y + width/300.0 + randf_range(0.0, 0.001)))
		csg.polygon = resizedPolygon
		
		csg.set_use_collision(true)
		csg.path_node = path.get_path()
		csg.material = getRoadMaterial(roadType)
		
		# Add csg to path
		path.add_child(csg)
	
	func constructBuilding(type, levels=-1) -> void:
		
		if levels == -1:
			if type == 'office':
				levels = int(8.0 / randf_range(0.2,1))
			elif type == 'yes':
				levels = 3
			else:
				levels = 2
		
		var csg = CSGPolygon3D.new()
		var polygon = PackedVector2Array()
		csg.set_use_collision(true)
		# Build a path
		print("Constructing building...")
		for i in nodes:
			# Construct coordinates
			var coords = LatLong.new(
				Vector2(
					float(i['lat']),
					float(i['lon'])
				)
			)
			var coordsFeet = coords.toFeet()
			polygon.append(coordsFeet)
		
		csg.polygon = polygon
		csg.rotation.x = PI / 2
		csg.depth = 5 * randi_range(1,min(2, int(levels / 2)))
		
		csg.material = skyscraperBaseMaterial.duplicate()
		csg.material.albedo_texture = skyscraperBaseTextures[randi_range(0, len(skyscraperBaseTextures)-1)]
		
		# TODO: Citymotor like approach of bevelling building logic? (Sorry for plug)
		var topCsg = csg.duplicate()
		topCsg.depth = (levels * 5) - csg.depth
		topCsg.global_position.z -= csg.depth
		topCsg.material = skyscraperMainMaterial
		
		csg.add_child(topCsg)
		
		get_node("./").add_child(csg)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	var parser = XMLParser.new()
	var nodes = {}
	var current_element = ""
	var encapsulation_type = null
	var depth = 0
	
	parser.open("user://user_map.xml")
	
	while parser.read() != ERR_FILE_EOF:
		var node_type = parser.get_node_type()
		var node_name = parser.get_node_name()
		
		if node_type == XMLParser.NODE_ELEMENT:
			current_element = node_name
			
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			nodes.merge({attributes_dict.get('id'): attributes_dict})
		elif node_type == XMLParser.NODE_TEXT:
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			
			if current_element == 'way':
				encapsulation_type = Way.new()
				
			elif current_element == 'nd':
				if encapsulation_type != null:
					encapsulation_type.add_node(nodes[attributes_dict['ref']])
				
			elif current_element == 'node':
				if encapsulation_type != null:
					encapsulation_type.add_node(attributes_dict)
					
			elif current_element == 'tag':
				var recognizedTags = ["building", "building:levels", "highway", "lanes"]
				if encapsulation_type != null and attributes_dict['k'] in recognizedTags:
					encapsulation_type.add_tag(attributes_dict)
					
				
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if encapsulation_type != null and encapsulation_type.element_name == node_name:
				add_child(encapsulation_type)
				encapsulation_type.construct()
				encapsulation_type = null
