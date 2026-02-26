class_name GapPlacementMode
extends RefCounted


class SurfacePlacement:
	extends GapPlacementMode


class PlanePlacement:
	extends GapPlacementMode
	var plane_options: PlaneOptions

	func _init(options: PlaneOptions = PlaneOptions.new(Vector3.UP, Vector3.ZERO)):
		self.plane_options = options


class Terrain3DPlacement:
	extends GapPlacementMode
	var _terrain_3d_node: Node3D

	func _init(node: Node3D):
		self._terrain_3d_node = node

	func get_terrain_3d_node() -> Node3D:
		return _terrain_3d_node
