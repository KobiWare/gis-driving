extends Node3D

var camera
var minDist = 30
var maxDist = 175
var npc = preload("res://assets/car/npc_vehicle.tscn")
var npcs = []
var maxNPCs = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_node("/root/Node3D/Camera3D") as Camera3D
	

func new_npc(targetDistance) -> void:
	var osm = get_node("/root/Node3D/OSM")
	var targetAngledPoint = randf_range(0, PI)
	var targetPoint = Vector3(cos(targetAngledPoint) * targetDistance, 0, sin(targetAngledPoint) * targetDistance) + camera.global_position
	
	var closestPoint = null
	var closestPath = null
	
	for child in osm.get_children():
		if child.get_child_count() > 0:
			var childschild = child.get_child(0)
			var spawnableRoadTypes = ['residential', "secondary"]
			if childschild != null and childschild.is_class("Path3D"):
				if childschild.road_type in spawnableRoadTypes:
					var closest = childschild.curve.get_closest_point(targetPoint)
					if closestPoint == null or targetPoint.distance_to(closest) < targetPoint.distance_to(closestPoint):
						closestPoint = closest
						closestPath = childschild
		
	var new_npc = npc.instantiate()
	var path_mover = PathFollow3D.new()
	
	path_mover.add_child(new_npc)
	
	path_mover.progress = closestPath.curve.get_closest_offset(closestPoint)
	#new_npc.global_position = closestPoint + Vector3(0,1.5,0)
	npcs.append(path_mover)
	closestPath.add_child(path_mover)
	print("Children")

func new_npcs(count):
	for i in range(count):
		new_npc(minDist + len(npcs) * ((maxDist - minDist) / count))

func despawn_npcs():
	var i = 0
	while i < len(npcs):
		var distanceToCamera = get_node("/root/Node3D/Camera3D").global_position.distance_to(npcs[i].global_position)
		if distanceToCamera > maxDist:
			npcs[i].queue_free()
			npcs.remove_at(i)
			i-=1
		i+=1

func _process(delta: float) -> void:
	if len(npcs) < maxNPCs:
		new_npcs(maxNPCs - len(npcs))
	despawn_npcs()
