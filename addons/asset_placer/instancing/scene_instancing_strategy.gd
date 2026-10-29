class_name SceneInstancingStrategy
extends InstancingStrategy

const META_ASSET_ID = &"asset_placer_res_id"


func place_instances(
	asset: AssetResource, world_transforms: Array[Transform3D], parent: Node3D
) -> void:
	for transform in world_transforms:
		var new_node: Node3D = _instantiate_asset_resource(asset)
		new_node.global_transform = transform
		new_node.transform = parent.global_transform.affine_inverse() * transform
		new_node.name = _pick_name(new_node, parent, asset)
		new_node.set_meta(META_ASSET_ID, asset.id)

		_undo_redo.add_do_reference(new_node)
		_undo_redo.add_do_method(self, "_do_placement", new_node, parent)
		_undo_redo.add_undo_method(self, "_undo_placement", new_node, parent)

		_do_placement(new_node, parent)


func _do_placement(new_node: Node3D, parent: Node3D):
	var temp_name := new_node.name
	parent.add_child(new_node)
	new_node.name = temp_name
	new_node.owner = EditorInterface.get_edited_scene_root()


func _undo_placement(new_node: Node3D, parent: Node3D):
	parent.remove_child(new_node)


func _instantiate_asset_resource(asset: AssetResource) -> Node3D:
	var new_node: Node3D
	var resource := asset.get_resource()
	if resource is PackedScene:
		new_node = (resource.instantiate() as Node3D)
	elif resource is Mesh:
		new_node = MeshInstance3D.new()
		new_node.name = asset.name
		new_node.mesh = resource.duplicate()
	else:
		push_error("Not supported resource type %s" % str(resource))

	return new_node


func _pick_name(node: Node3D, parent: Node3D, asset: AssetResource) -> String:
	var number_of_same_scenes := 0
	for child in parent.get_children():
		if child.has_meta(META_ASSET_ID) && child.get_meta(META_ASSET_ID) == asset.id:
			number_of_same_scenes += 1
	return node.name if number_of_same_scenes == 0 else node.name + " (%s)" % number_of_same_scenes
