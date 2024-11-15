extends Node

const pointer = preload("res://assets/world/point.blend")

class LatLong:
	# NOTE: Backwards
	#static var relPos = Vector2(38.6334750, -84.6633720)
	static var relPos = Vector2(40.73575, -74.06416)
	var pos

	func _init(pos: Vector2) -> void:
		self.pos = pos
		
	# TODO: I have no idea how to actually calculate this lmao
	func toMeters() -> Vector2:
		return (self.pos - relPos) * 100000

class LatLongHeight extends LatLong:
	var height
	
	func _init(pos: Vector2, height: float) -> void:
		self.pos = pos
		self.height = height
	
	# TODO: I have no idea how to actually calculate this lmao
	func toMeters3D() -> Vector3:
		var latlon = super.toMeters()
		return Vector3(latlon.x, self.height, latlon.y)
