extends Node3D

class LatLong:
	static var relPos = Vector2(38.6305990, -84.6324800)
	var pos
	
	func _init(pos: Vector2) -> void:
		self.pos = pos
		
	# TODO: I have no idea how to actually calculate this lmao
	func toFeet() -> Vector2:
		return (self.pos - relPos) * 10000

class Buildable extends Node:
	var element_name = null
	var tags = []
	var nodes = []
	
	func _init() -> void:
		pass
	
	func add_node(node) -> void:
		nodes.append(node)
	
	func construct() -> void:
		pass

class Way extends Buildable:
	func _init() -> void:
		element_name = "way"
	
	func construct() -> void:
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
			var coordsAndElevation = Vector3(coordsFeet.x, 0-2, coordsFeet.y)
			path.curve.add_point(coordsAndElevation)
		
		
		get_node("./").add_child(path)
		
		# CSG polygon
		var csg = CSGPolygon3D.new()
		csg.mode = CSGPolygon3D.MODE_PATH
		print(path.get_path())
		csg.path_node = path.get_path()
		
		# Add csg to path
		path.add_child(csg)

# Called when the node enters the scene tree for the first time.
func _ready():
	var parser = XMLParser.new()
	var nodes = {}
	var current_element = ""
	var encapsulation_type = null
	parser.open("assets/NYC.osm")
	
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
			
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if encapsulation_type != null and encapsulation_type.element_name == node_name:
				add_child(encapsulation_type)
				encapsulation_type.construct()
				encapsulation_type = null
