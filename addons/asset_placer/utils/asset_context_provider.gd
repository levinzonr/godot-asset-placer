extends RefCounted
class_name AssetPlacerContextUtil


	
static func select_context():
	if !is_current_selection_node3d():
		var selection = EditorInterface.get_edited_scene_root()
		EditorInterface.get_selection().add_node(selection)

	

static func is_current_selection_node3d() -> bool:
	var selection = EditorInterface.get_selection()
	for node in selection.get_selected_nodes():
		if node is Node3D:
			return true
	return false
