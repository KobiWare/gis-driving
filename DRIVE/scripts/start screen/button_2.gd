extends Button

func _on_button_down() -> void:
	var location = get_node("/root/StartScreen/TextEdit").text
	var latlon = location.split(" ")
	Globals.LatLong.relPos = Vector2(float(latlon[0]), float(latlon[1]))
	get_tree().change_scene_to_file("res://scenes/game.tscn")
