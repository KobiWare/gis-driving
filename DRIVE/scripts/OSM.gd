extends Node3D

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

const roadScript = preload("res://scripts/road.gd")

const dataRequester = preload("res://scenes/osm_data_requester.tscn")

@export var lat1 := -84.46604  as float
@export var lon1 := 38.99312 as float
@export var lat2 := -84.43377 as float
@export var lon2 := 39.01026 as float

@export var is_first = false
var is_loaded = false

class Buildable extends Node:
	var element_name = null
	var element_type = null
	var tags = []
	var nodes = []
	
	func _init() -> void:
		pass
	
	func add_node(node) -> void:
		node.merge({'latlon': 
				Globals.LatLong.new(
					Vector2(float(node['lat']), float(node['lon']))
				)
			}
		)
		nodes.append(node)
	
	func add_tag(tag) -> void:
		var recondized_tags = ['highway', 'building']
		if tag['k'] in recondized_tags:
			element_type = tag['k']
		tags.append(tag)
	
	func construct() -> void:
		pass

class Way extends Buildable:
	func _init() -> void:
		element_name = "way"
	
	# TODO: water
	func construct() -> void:
		for tag in tags:
			if tag['k'] == 'highway':
				constructRoad()
				break
			if tag['k'] == 'building':
				constructBuilding(tag['v'])
	
	# TODO: Intersections, street-lamps, car npcs, bridges
	
	func constructRoad() -> void:
		var path = Path3D.new()
		add_child(path)
		path.script = roadScript
		path.make(self)
	
	func constructBuilding(type, levels=-1) -> void:
		
		if levels == -1:
			if type == 'office':
				levels = int(8.0 / randf_range(0.2,1))
			elif type == 'yes':
				levels =  int(3.0 / randf_range(0.5,1))
			else:
				levels = 2
		
		var csg = CSGPolygon3D.new()
		var polygon = PackedVector2Array()
		csg.set_use_collision(true)
		
		# Build csg
		for i in nodes:
			# Construct coordinates
			var coords = i['latlon']
			var coordsFeet = coords.toMeters()
			polygon.append(coordsFeet)
		
		csg.polygon = polygon
		csg.rotation.x = PI / 2
		csg.depth = 5 * randi_range(1,min(2, int(levels) / 2))
		
		csg.material = skyscraperBaseMaterial.duplicate()
		csg.material.albedo_texture = skyscraperBaseTextures[randi_range(0, len(skyscraperBaseTextures)-1)]
		
		# TODO: Citymotor like approach of bevelling building logic? (Sorry for plug)
		var topCsg = csg.duplicate()
		topCsg.depth = (levels * 5) - csg.depth
		topCsg.global_position.z -= csg.depth
		topCsg.material = skyscraperMainMaterial
		
		csg.add_child(topCsg)
		
		get_node("./").add_child(csg)

func parse():
	var parser = XMLParser.new()
	var nodes = {}
	var current_element = ""
	var encapsulation_type = null
	var depth = 0
	
	parser.open("user://tmp.xml")
	
	while parser.read() != ERR_FILE_EOF:
		var node_type = parser.get_node_type()
		
		if node_type == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			current_element = node_name
			
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			attributes_dict.merge({'shared': []})
			nodes.merge({attributes_dict.get('id'): attributes_dict})
		elif node_type == XMLParser.NODE_TEXT:
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			
			if current_element == 'way':
				encapsulation_type = Way.new()
				
			elif current_element == 'nd':
				if encapsulation_type != null:
					if(nodes.has(attributes_dict['ref'])):
						encapsulation_type.add_node(nodes[attributes_dict['ref']])
				
			elif current_element == 'node':
				if encapsulation_type != null:
					encapsulation_type.add_node(attributes_dict)
					
			elif current_element == 'tag':
				var recognizedTags = ["building", "building:levels", "highway", "lanes"]
				if encapsulation_type != null and attributes_dict['k'] in recognizedTags:
					encapsulation_type.add_tag(attributes_dict)
					
				
		elif node_type == XMLParser.NODE_ELEMENT_END:
			var node_name = parser.get_node_name()
			if encapsulation_type != null and encapsulation_type.element_name == node_name:
				add_child(encapsulation_type)
				encapsulation_type.construct()
				encapsulation_type = null

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var path = "user://tmp.xml"
		var xml_file = FileAccess.open(path, FileAccess.WRITE)
		xml_file.store_string(body.get_string_from_utf8())
		xml_file.close()
		print("Request complete")
		parse()
		is_loaded = true
	else:
		print("Request failed with response code: ", response_code)

func request_data_parse():
	var requester_instance = dataRequester.instantiate()
	
	if is_first:
		var tile_size = get_parent().tile_size
		var rel_pos = Globals.LatLong.relPos
		requester_instance.lat1 = rel_pos.y - tile_size
		requester_instance.lat2 = rel_pos.y + tile_size
		requester_instance.lon1 = rel_pos.x - tile_size
		requester_instance.lon2 = rel_pos.x + tile_size
	else:
		requester_instance.lat1 = lat1
		requester_instance.lat2 = lat2
		requester_instance.lon1 = lon1
		requester_instance.lon2 = lon2
	
	add_child(requester_instance)
	
	

# Called when the node enters the scene tree for the first time.
func _ready():
	request_data_parse()
