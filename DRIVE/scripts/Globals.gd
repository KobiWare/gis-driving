extends Node
class LatLong:
	static var relPos = Vector2(40.70562, -74.0176)
	var pos

	func _init(pos: Vector2) -> void:
		self.pos = pos
		
	# TODO: I have no idea how to actually calculate this lmao
	func toFeet() -> Vector2:
		return (self.pos - relPos) * 100000
