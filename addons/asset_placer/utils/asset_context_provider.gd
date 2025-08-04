extends RefCounted
class_name AssetContextProvider


static func resolve_current_context() -> Node3D:
	var selected = EditorInterface.get_selection().get_selected_nodes()
	var contex_id = selected.find_custom(func(node): return node is AssetPlacerContext)
	if contex_id != -1:
		return selected[contex_id]
	else:
		var root = EditorInterface.get_edited_scene_root()
		var first_in_group = root.get_first_node_in_group("asset_placer_context")
		if first_in_group:
			return first_in_group
		else:
			return root
