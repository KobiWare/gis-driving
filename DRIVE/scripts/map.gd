extends Node3D

@export var lat1 := -84.46604  as float
@export var lon1 := 38.99312 as float
@export var lat2 := -84.43377 as float
@export var lon2 := 39.01026 as float

@export var is_first = false

const dataRequester = preload("res://scenes/osm_data_requester.tscn")


func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var path = "user://tmp.xml"
		var xml_file = FileAccess.open(path, FileAccess.WRITE)
		xml_file.store_string(body.get_string_from_utf8())
		xml_file.close()
		print("Request complete")
		get_child(0).parse()
		get_child(0).is_loaded = true
	else:
		print("Request failed with response code: ", response_code)

func request_data_parse():
	var requester_instance = dataRequester.instantiate()

	requester_instance.lat1 = lat1
	requester_instance.lat2 = lat2
	requester_instance.lon1 = lon1
	requester_instance.lon2 = lon2
	
	add_child(requester_instance)

func generate_terrain():
	get_child(1).generate_terrain()

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_first:
		var rel_pos = Globals.LatLong.relPos
		var tile_size = get_parent().tile_size
		lat1 = rel_pos.y - tile_size
		lat2 = rel_pos.y + tile_size
		lon1 = rel_pos.x - tile_size
		lon2 = rel_pos.x + tile_size
	generate_terrain()
	request_data_parse()
