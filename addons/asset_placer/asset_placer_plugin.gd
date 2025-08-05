@tool
extends EditorPlugin

var _folder_repository: FolderRepository
var _presenter: AssetPlacerPresenter
var  _asset_placer: AssetPlacer = AssetPlacer.new()

var _asset_placer_window: AssetLibraryPanel


var plugin_path: String:
	get(): return get_script().resource_path.get_base_dir()


func _enable_plugin():
	pass
	
func _disable_plugin():
	pass
	
func _enter_tree():
	_folder_repository = FolderRepository.new()
	_asset_placer = AssetPlacer.new()
	_presenter = AssetPlacerPresenter.new()
	_presenter.asset_selected.connect(start_placement)
	_presenter.asset_deselcted.connect(_asset_placer.stop_placement)
	_asset_placer_window = load("res://addons/asset_placer/ui/asset_library_panel.tscn").instantiate()
	add_control_to_bottom_panel(_asset_placer_window, "Asset Placer")
	
	
	EditorInterface.get_selection().selection_changed.connect(func():
		var nodes = EditorInterface.get_selection().get_selected_nodes()
		if not nodes.any(func(node): return node is Node3D):
			AssetPlacerPresenter._instance.clear_selection()
	)
	
func _exit_tree():
	_presenter.asset_selected.disconnect(start_placement)
	_presenter.asset_deselcted.disconnect(_asset_placer.stop_placement)
	_asset_placer.stop_placement()
	remove_control_from_bottom_panel(_asset_placer_window)
	_asset_placer_window.queue_free()

func _handles(object):
	return true

func start_placement(asset: AssetResource):
	EditorInterface.set_main_screen_editor("3D")
	AssetPlacerContextUtil.select_context()
	_asset_placer.start_placement(get_tree().root, asset)

func _forward_3d_gui_input(viewport_camera, event):
	return _asset_placer.handle_3d_input(viewport_camera, event)
