@tool
extends EditorPlugin

var _folder_repository: FolderRepository
var _presenter: AssetPlacerPresenter
var  _asset_placer: AssetPlacer
var _assets_repository: AssetsRepository
var synchronizer: Synchronize
var _updater: PluginUpdater
var _async: AssetPlacerAsync

var _asset_placer_window: AssetLibraryPanel
var _file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()


var plugin_path: String:
	get(): return get_script().resource_path.get_base_dir()
	
	
const ADDON_PATH = "res://addons/asset_placer"	


func _enable_plugin():
	pass
	
func _disable_plugin():
	pass
	
func _enter_tree():
	_async = AssetPlacerAsync.new()
	_updater = PluginUpdater.new(ADDON_PATH +  "/plugin.cfg", "")
	_asset_placer = AssetPlacer.new(get_undo_redo())
	_folder_repository = FolderRepository.new()
	_assets_repository = AssetsRepository.new()
	synchronizer = Synchronize.new(_folder_repository, _assets_repository)
	_presenter = AssetPlacerPresenter.new()
	scene_changed.connect(_handle_scene_changed)
	_presenter.asset_selected.connect(start_placement)
	_presenter.asset_deselcted.connect(_asset_placer.stop_placement)
	_asset_placer_window = load("res://addons/asset_placer/ui/asset_library_panel.tscn").instantiate()
	add_control_to_bottom_panel(_asset_placer_window, "Asset Placer")
	
	synchronizer.sync_complete.connect(func(added, removed, scanned):
		var message = "Asset Placer Sync complete\nAdded: %d Removed: %d Scanned total: %d" % [added, removed, scanned]
		EditorToasterCompat.toast(message)
	)
	
	
	_file_system.resources_reimported.connect(_react_to_reimorted_files)
	if !_file_system.is_scanning():
		synchronizer.sync_all()
		
	
func _exit_tree():
	_file_system.resources_reimported.disconnect(_react_to_reimorted_files)
	_presenter.asset_selected.disconnect(start_placement)
	_presenter.asset_deselcted.disconnect(_asset_placer.stop_placement)
	_asset_placer.stop_placement()
	scene_changed.disconnect(_handle_scene_changed)
	remove_control_from_bottom_panel(_asset_placer_window)
	_asset_placer_window.queue_free()
	_async.await_completion()


func _handles(object):
	return object is Node3D

func _handle_scene_changed(scene: Node):
	if scene is Node3D:
		_presenter.select_parent(scene.get_path())
	else:
		_presenter.clear_parent()
	

func _react_to_reimorted_files(files: PackedStringArray):
	synchronizer.sync_all()

func start_placement(asset: AssetResource):
	EditorInterface.set_main_screen_editor("3D")
	AssetPlacerContextUtil.select_context()
	_asset_placer.start_placement(get_tree().root, asset)

func _forward_3d_gui_input(viewport_camera, event):
	return _asset_placer.handle_3d_input(viewport_camera, event)
