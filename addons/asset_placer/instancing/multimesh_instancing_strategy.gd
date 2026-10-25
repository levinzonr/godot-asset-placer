class_name MultiMeshInstancingStrategy
extends InstancingStrategy


class MeshPart:
	var mesh_instance: MeshInstance3D
	var mesh_path: NodePath
	var transform: Transform3D

	func _init(node: MeshInstance3D, path: NodePath, relative_transform: Transform3D):
		mesh_instance = node
		mesh_path = path
		transform = relative_transform


func place_instances(
	asset: AssetResource,
	world_transforms: Array[Transform3D],
	parent: Node3D,
	select_after_placement: bool
) -> void:
	if world_transforms.is_empty():
		return
	var source := _instantiate_source(asset)
	if source == null:
		return

	var parts: Array[MeshPart] = []
	_collect_mesh_parts(source, source, Transform3D.IDENTITY, parts)
	var last_batch: AssetPlacerMultiMeshBatch
	if parts.is_empty():
		push_warning(
			"Asset Placer: '%s' has no supported visible MeshInstance3D nodes." % asset.name
		)
	else:
		var scene_owner := EditorInterface.get_edited_scene_root()
		for part in parts:
			last_batch = _place_mesh_part(asset, part, world_transforms, parent, scene_owner)
	source.free()

	if select_after_placement and last_batch != null:
		_undo_redo.add_do_method(self, "_focus_batch", last_batch)
		_focus_batch(last_batch)


func _instantiate_source(asset: AssetResource) -> Node3D:
	var resource := asset.get_resource()
	if resource is PackedScene:
		var instance: Node = resource.instantiate()
		if instance is Node3D:
			return instance
		instance.free()
	elif resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = resource
		return mesh_instance
	push_warning("Asset Placer: MultiMesh instancing requires a 3D scene or mesh: %s" % asset.name)
	return null


func _collect_mesh_parts(
	root: Node3D, node: Node, relative_transform: Transform3D, parts: Array[MeshPart]
) -> void:
	if not node is Node3D:
		if not node.find_children("*", "MeshInstance3D", true, false).is_empty():
			push_warning(
				(
					"Asset Placer: skipping transform-disconnected mesh subtree: %s"
					% root.get_path_to(node)
				)
			)
		return
	if not node.visible:
		return
	if node != root:
		if node.is_set_as_top_level():
			push_warning(
				"Asset Placer: skipping top-level mesh subtree: %s" % root.get_path_to(node)
			)
			return
		relative_transform *= node.transform

	if node is MeshInstance3D and node.mesh != null:
		if _has_deformation(node):
			push_warning(
				"Asset Placer: skipping skinned or blend-shape mesh: %s" % root.get_path_to(node)
			)
		else:
			parts.append(MeshPart.new(node, root.get_path_to(node), relative_transform))
	for child in node.get_children():
		_collect_mesh_parts(root, child, relative_transform, parts)


func _has_deformation(node: MeshInstance3D) -> bool:
	if node.skin != null or node.get_blend_shape_count() > 0:
		return true
	if node.mesh is ArrayMesh:
		for i in range(node.mesh.get_surface_count()):
			if node.mesh.surface_get_format(i) & Mesh.ARRAY_FORMAT_BONES:
				return true
	return false


func _place_mesh_part(
	asset: AssetResource,
	part: MeshPart,
	world_transforms: Array[Transform3D],
	parent: Node3D,
	scene_owner: Node
) -> AssetPlacerMultiMeshBatch:
	var batch := _find_batch(parent, asset.id, part)
	var is_new := batch == null
	if is_new:
		batch = AssetPlacerMultiMeshBatch.new()
		batch.name = (
			(asset.name + "_" + str(part.mesh_instance.name) + "_MultiMesh").validate_node_name()
		)
		batch.configure(asset.id, part.mesh_path, part.mesh_instance)

	var transforms := batch.get_instance_transforms()
	var previous_count := transforms.size()
	var batch_world := parent.global_transform if is_new else batch.global_transform
	var inverse := batch_world.affine_inverse()
	for transform in world_transforms:
		transforms.append(inverse * transform * part.transform)

	if is_new:
		_undo_redo.add_do_reference(batch)
	_undo_redo.add_do_method(self, "_do_placement", batch, parent, scene_owner, transforms)
	_undo_redo.add_undo_method(self, "_undo_placement", batch, parent, previous_count, is_new)
	_do_placement(batch, parent, scene_owner, transforms)
	return batch


func _find_batch(parent: Node3D, asset_id: String, part: MeshPart) -> AssetPlacerMultiMeshBatch:
	for child in parent.get_children():
		if child is AssetPlacerMultiMeshBatch:
			if child.matches_source(asset_id, part.mesh_path, part.mesh_instance):
				return child
	return null


func _do_placement(
	batch: AssetPlacerMultiMeshBatch,
	parent: Node3D,
	scene_owner: Node,
	transforms: Array[Transform3D]
) -> void:
	if batch.get_parent() == null:
		parent.add_child(batch, true)
		batch.owner = scene_owner
	batch.set_instance_transforms(transforms)


func _focus_batch(batch: AssetPlacerMultiMeshBatch) -> void:
	focus_requested.emit(batch)


func _undo_placement(
	batch: AssetPlacerMultiMeshBatch, parent: Node3D, previous_count: int, is_new: bool
) -> void:
	if is_new:
		parent.remove_child(batch)
	else:
		batch.truncate_instances(previous_count)
