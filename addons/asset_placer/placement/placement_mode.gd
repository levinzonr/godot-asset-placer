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
	var _terrain_3d_node_path: NodePath

	func _init(path: NodePath):
		self._terrain_3d_node_path = path

	func get_terrain_3d_node() -> Node3D:
		var root = EditorInterface.get_edited_scene_root()
		if root and not _terrain_3d_node_path.is_empty():
			return root.get_node_or_null(_terrain_3d_node_path) as Node3D
		return null
