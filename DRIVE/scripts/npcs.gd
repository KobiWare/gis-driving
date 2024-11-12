extends Node3D

var camera
var minDist = 10
var maxDist = 200
var npc = preload("res://assets/car/npc_vehicle.tscn")
var npcs = []
var maxNPCs = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_node("/root/Node3D/Camera3D") as Camera3D
	

func new_npc() -> void:
	var osm = get_parent()
	if osm.is_loaded:
		var child = null
		var childschild = null
		while true:
			child = osm.get_child(randi_range(0, osm.get_child_count()-1))
			childschild  = child.get_child(0)
			
			var spawnableRoadTypes = ['residential', "secondary"]
			if childschild != null and childschild.is_class("Path3D"):
				if childschild.road_type in spawnableRoadTypes and len(childschild.way.nodes) > 1:
					break
		var new_npc = npc.instantiate()
		var path_mover = PathFollow3D.new()
		
		path_mover.progress = randf_range(0, 1) * childschild.curve.get_baked_length()
		path_mover.add_child(new_npc)
		#new_npc.global_position = closestPoint + Vector3(0,1.5,0)
		npcs.append(path_mover)
		childschild.add_child(path_mover)

func new_npcs(count):
	for i in range(count):
		new_npc()

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
		print(len(npcs))
		new_npcs(maxNPCs - len(npcs))
	#despawn_npcs()
