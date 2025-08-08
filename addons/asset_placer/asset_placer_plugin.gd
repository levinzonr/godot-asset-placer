@tool
extends EditorPlugin

var _folder_repository: FolderRepository
var _presenter: AssetPlacerPresenter
var  _asset_placer: AssetPlacer
var _assets_repository: AssetsRepository
var files_watchdog: FileSystemWatchDog
var synchronizer: Synchronize

var _asset_placer_window: AssetLibraryPanel


var plugin_path: String:
	get(): return get_script().resource_path.get_base_dir()


func _enable_plugin():
	pass
	
func _disable_plugin():
	pass
	
func _enter_tree():
	_asset_placer = AssetPlacer.new()
	_folder_repository = FolderRepository.new()
	_assets_repository = AssetsRepository.new()
	synchronizer = Synchronize.new(_folder_repository, _assets_repository)
	files_watchdog = FileSystemWatchDog.new(_folder_repository)
	
	_asset_placer = AssetPlacer.new()
	_presenter = AssetPlacerPresenter.new()
	_presenter.asset_selected.connect(start_placement)
	_presenter.asset_deselcted.connect(_asset_placer.stop_placement)
	_asset_placer_window = load("res://addons/asset_placer/ui/asset_library_panel.tscn").instantiate()
	add_control_to_bottom_panel(_asset_placer_window, "Asset Placer")
	
	synchronizer.sync_complete.connect(func(added, removed, scanned):
		var toaster = EditorInterface.get_editor_toaster()
		var message = "Asset Placer Sync complete\nAdded: %d Removed: %d Scanned total: %d" % [added, removed, scanned]
		toaster.push_toast(message, EditorToaster.SEVERITY_INFO, "Asset Placer")
	)
	
	EditorInterface.get_selection().selection_changed.connect(func():
		var nodes = EditorInterface.get_selection().get_selected_nodes()
		if not nodes.any(func(node): return node is Node3D):
			AssetPlacerPresenter._instance.clear_selection()
	)
	
	synchronizer.sync_all()
	
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
