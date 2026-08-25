class_name PlacementStrategyResolver
extends RefCounted


static func resolve_placement_strategy(root_node: Node) -> GapPlacementMode:
	if not root_node:
		return GapPlacementMode.PlanePlacement.new()

	var terrain_node = _find_terrain_3d(root_node)
	if terrain_node != null:
		return GapPlacementMode.Terrain3DPlacement.new(root_node.get_path_to(terrain_node))

	if _has_physics_objects(root_node):
		return GapPlacementMode.SurfacePlacement.new()

	return GapPlacementMode.PlanePlacement.new()


static func _find_terrain_3d(node: Node) -> Node:
	if node.get_class() == "Terrain3D":
		return node

	for child in node.get_children():
		var found = _find_terrain_3d(child)
		if found:
			return found

	return null


static func _has_physics_objects(node: Node) -> bool:
	if node is PhysicsBody3D:
		return true

	for child in node.get_children():
		if _has_physics_objects(child):
			return true

	return false
