extends RefCounted
class_name AssetParentSelector


static func pick_parent(root: Node3D, asset: AssetResource, auto_group: bool) -> Node3D:
	if not auto_group || asset.tags.is_empty():
		return root

	var id = asset.tags[0]
	var repository = AssetCollectionRepository.instance
	var collection = repository.find_by_id(id)
	var expected_name = collection.name.capitalize()
	var existing_chidren = root.find_children(expected_name, "Node3D", true)
	var group_parent: Node3D
	if existing_chidren.is_empty():
		group_parent = Node3D.new()
		print("Not found with name %s" % expected_name)
		group_parent.name = expected_name
		root.add_child(group_parent)
		group_parent.owner = EditorInterface.get_edited_scene_root()

	else:
		group_parent = existing_chidren[0]

	return group_parent
