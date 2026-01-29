class_name AssetPlacementStrategy
extends RefCounted


class CollisionHit:
	var position: Vector3
	var normal: Vector3

	func _init(position: Vector3, normal: Vector3):
		self.position = position
		self.normal = normal

	static func zero() -> CollisionHit:
		return CollisionHit.new(Vector3.ZERO, Vector3.UP)


func get_placement_point(_camera: Camera3D, _mouse_position: Vector2) -> CollisionHit:
	return CollisionHit.zero()
