extends RefCounted
class_name PlacementMode


class SurfacePlacement extends PlacementMode:
	pass
	
class PlanePlacement extends PlacementMode:
	var plane: Plane
	func _init(plane: Plane = Plane.PLANE_XZ):
		self.plane = plane
