extends RefCounted
class_name PlacementMode


class SurfacePlacement extends PlacementMode:
	pass
	
class PlanePlacement extends PlacementMode:
	var plane_options: PlaneOptions
	
	func _init(options: PlaneOptions = PlaneOptions.new(Vector3.UP, Vector3.ZERO)):
		self.plane_options = options

class Terrain3DPlacement extends PlacementMode:
	var terrain3dNode: Node3D
	func _init(node: Node3D):
		self.terrain3dNode = node
