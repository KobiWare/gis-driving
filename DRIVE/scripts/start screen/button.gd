extends Button

func _on_button_down() -> void:
	var lat_long = get_node("/root/StartScreen/TextEdit").text
	
	# Split string and then make the API URL call based on that
	var lat_long_coords = lat_long.split(" ")
	if lat_long_coords.size() != 2:
		print("Invalid input, please provide coordinates in 'lat lon' format.")
		return
	
	var lat = float(lat_long_coords[1])
	var lon = float(lat_long_coords[0])
	
	# Ensure bbox is in the correct format: min_lon,min_lat,max_lon,max_lat
	var bbox = str(lon - 0.05) + "," + str(lat - 0.05) + "," + str(lon + 0.05) + "," + str(lat + 0.05)
	
	# Use Overpass API for fetching data based on bounding box
	var overpass_url = "https://overpass-api.de/api/interpreter?data=[out:xml];(node(" + bbox + ");way(" + bbox + ");relation(" + bbox + "););out;"
	print("Generated Overpass API URL: ", overpass_url)
	
	# Make the API call
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_request_completed)
	http_request.request(overpass_url)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var path = "user://user_map.xml"
		var xml_file = FileAccess.open(path, FileAccess.WRITE)
		xml_file.store_string(body.get_string_from_utf8())
		xml_file.close()
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		print("Request failed with response code: ", response_code)
