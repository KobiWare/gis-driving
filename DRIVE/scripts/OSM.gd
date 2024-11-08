extends Node3D

class LatLong:
	var pos
	
	func _init(pos: Vector2) -> void:
		self.pos = pos
	

var latLong = Vector2(38.6305990, -84.6324800)

class Buildable:
	var element_name = null
	var tags = []
	var verts = []
	
	func _init():
		pass
	
	func addVert(node) -> void:
		print(node)
	
	func construct() -> void:
		pass

class Way extends Buildable:
	func _init():
		element_name = "Way"
	
	func construct() -> void:
		# Build a path
		for i in verts:
			pass

# Called when the node enters the scene tree for the first time.
func _ready():
	var parser = XMLParser.new()
	var nodes = {}
	var current_element = ""
	var encapsulation_type = null
	parser.open("assets/map.osm")
	
	while parser.read() != ERR_FILE_EOF:
		var node_type = parser.get_node_type()
		var node_name = parser.get_node_name()
		
		if node_type == XMLParser.NODE_ELEMENT:
			current_element = node_name
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			nodes.merge({attributes_dict.get("id"): attributes_dict})
		elif node_type == XMLParser.NODE_TEXT:
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			if current_element == 'way':
				encapsulation_type = Way.new()
			
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if encapsulation_type != null and encapsulation_type.element_name == node_name:
				encapsulation_type.construct()
				encapsulation_type = null
