extends HTTPRequest

@export var lat1 := -84.46604  as float
@export var lon1 := 38.99312 as float
@export var lat2 := -84.43377 as float
@export var lon2 := 39.01026 as float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure bbox is in the correct format: min_lon,min_lat,max_lon,max_lat
	var bbox = str(lon1) + "," + str(lat1) + "," + str(lon2) + "," + str(lat2)
	
	# Use Overpass API for fetching data based on bounding box
	var overpass_url = "https://overpass-api.de/api/interpreter?data=[out:xml];(node(" + bbox + ");way(" + bbox + ");relation(" + bbox + "););out;"
	print("Generated Overpass API URL: ", overpass_url)
	
	connect("request_completed", get_parent()._on_request_completed)
	request(overpass_url)
