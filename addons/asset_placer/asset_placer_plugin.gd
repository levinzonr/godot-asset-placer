@tool
extends EditorPlugin

var _folder_repository: FolderRepository
var _presenter: AssetPlacerPresenter
var  _asset_placer: AssetPlacer
var _assets_repository: AssetsRepository
var _collection_repository: AssetCollectionRepository
var synchronizer: Synchronize
var _updater: PluginUpdater
var _async: AssetPlacerAsync

var _asset_placer_window: AssetLibraryPanel
var _file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()
var _viewport_overlay_res = preload("res://addons/asset_placer/ui/viewport_overlay/viewport_overlay.tscn")
var _plane_preview: Node3D
var _asset_placer_button: Button
var overlay: Control
var plane_placer: PlanePlacer

var _migration_collection_id = load("res://addons/asset_placer/data/migrations/collection_id_migration.gd")

var settings_repository: AssetPlacerSettingsRepository
var current_settings: AssetPlacerSettings
var _data_source: AssetLibraryDataSource

var plugin_path: String:
	get(): return get_script().resource_path.get_base_dir()
	
	
const ADDON_PATH = "res://addons/asset_placer"	


func _enable_plugin():
	pass
	
func _disable_plugin():
	pass
	
func _enter_tree():
	_run_migrations()
	_initialize_data_layer()
	_async = AssetPlacerAsync.new()
	_presenter = AssetPlacerPresenter.new()
	AssetPlacerDockPresenter.new()
	_updater = PluginUpdater.new(ADDON_PATH +  "/plugin.cfg", "")
	_plane_preview = load("res://addons/asset_placer/ui/plane_preview/plan_preview.tscn").instantiate()
	get_tree().root.add_child(_plane_preview)
	plane_placer = PlanePlacer.new(_presenter, _plane_preview)
	
	_asset_placer = AssetPlacer.new(get_undo_redo(), plane_placer)
	synchronizer = Synchronize.new(_folder_repository, _assets_repository)
	scene_changed.connect(_handle_scene_changed)
	_init_parent_scene.call_deferred()
	_presenter.asset_selected.connect(start_placement)
	_presenter.asset_deselected.connect(_asset_placer.stop_placement)
	_asset_placer_window = load("res://addons/asset_placer/ui/asset_library_panel.tscn").instantiate()
	_asset_placer_button = add_control_to_bottom_panel(_asset_placer_window, "Asset Placer")
	_asset_placer_window.visibility_changed.connect(_on_dock_visibility_changed)
	
	_presenter.placement_mode_changed.connect(_asset_placer.set_placement_mode)

	synchronizer.sync_complete.connect(func(added, removed, scanned):
		var message = "Asset Placer Sync complete\nAdded: %d Removed: %d Scanned total: %d" % [added, removed, scanned]
		EditorToasterCompat.toast(message)
	)
	
	self.overlay =  _viewport_overlay_res.instantiate()
	get_editor_interface().get_editor_viewport_3d().add_child(overlay)
	
	_file_system.resources_reimported.connect(_react_to_reimorted_files)
	if !_file_system.is_scanning():
		synchronizer.sync_all()
		
	_updater.updater_update_available.connect(_show_update_available)
	_updater.updater_up_to_date.connect(_show_plugin_up_to_date)
	_updater.update_ready.connect(_show_update_available)

func _exit_tree():
	_updater.updater_up_to_date.disconnect(_show_plugin_up_to_date)
	_updater.updater_update_available.disconnect(_show_update_available)
	_updater.update_ready.disconnect(_show_update_available)
	overlay.queue_free()
	_plane_preview.queue_free()
	settings_repository.settings_changed.disconnect(_react_to_settings_change)
	_file_system.resources_reimported.disconnect(_react_to_reimorted_files)
	_presenter.asset_selected.disconnect(start_placement)
	_presenter.asset_deselected.disconnect(_asset_placer.stop_placement)
	_asset_placer_window.visibility_changed.disconnect(_on_dock_visibility_changed)
	_asset_placer.stop_placement()
	scene_changed.disconnect(_handle_scene_changed)
	remove_control_from_bottom_panel(_asset_placer_window)
	_asset_placer_window.queue_free()
	_async.await_completion()

func _init_parent_scene():
	var current_scene = get_tree().edited_scene_root
	if current_scene and current_scene is Node3D:
		_handle_scene_changed(current_scene)

func _handles(object):
	return object is Node3D

func _handle_scene_changed(scene: Node):
	if scene is Node3D:
		_presenter.select_parent(scene.get_path())
	else:
		_presenter.clear_parent()

func _run_migrations():
	_migration_collection_id.new().run()	
	
func _initialize_data_layer():
	settings_repository = AssetPlacerSettingsRepository.new()
	current_settings = settings_repository.get_settings()
	settings_repository.settings_changed.connect(_react_to_settings_change)
	_data_source = AssetLibraryDataSource.new(current_settings.asset_library_path)
	_folder_repository = FolderRepository.new(_data_source)
	_assets_repository = AssetsRepository.new(_data_source)
	_collection_repository = AssetCollectionRepository.new(_data_source)

func _react_to_settings_change(settings: AssetPlacerSettings):
	self.current_settings = settings
	_asset_placer.set_plugin_settings(settings)

func _react_to_reimorted_files(files: PackedStringArray):
	synchronizer.sync_all()

func _on_dock_visibility_changed():
	if not _asset_placer_window.visible:
		_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.None)
		_presenter.clear_selection()
	

func start_placement(asset: AssetResource):
	EditorInterface.set_main_screen_editor("3D")
	AssetPlacerContextUtil.select_context()
	_asset_placer.start_placement(get_tree().root, asset, _presenter.placement_mode)

func _on_node_transform_mode_ended():
	# Node transform mode ended, no special action needed
	pass

func _handle_in_place_transform():
	if _presenter.is_node_transform_mode():
		_presenter.end_node_transform_mode()
		_asset_placer.stop_placement()
	# Check if a Node3D is selected and we're not already in asset placement mode
	elif AssetPlacerContextUtil.is_current_selection_node3d() and not _presenter.plugin_is_active():
		var selection = EditorInterface.get_selection()
		var selected_nodes = selection.get_selected_nodes()
		if selected_nodes.size() == 1 and selected_nodes[0] is Node3D:
			_presenter.start_node_transform_mode(selected_nodes[0])
			_asset_placer.start_node_transform(selected_nodes[0], _presenter.placement_mode)
	# If we're in asset placement mode, Tab should also exit it
	elif _presenter.plugin_is_active() and not _presenter.is_node_transform_mode():
		_presenter.clear_selection()
		_asset_placer.stop_placement()

func _forward_3d_gui_input(viewport_camera, event):
	
	if current_settings.bindings[AssetPlacerSettings.Bindings.InPlaceTransform].is_pressed(event):
		_handle_in_place_transform()
		return _handled()
	
	# Only process other inputs when plugin is active
	if not _presenter.plugin_is_active():
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return false

	if current_settings.bindings[AssetPlacerSettings.Bindings.Rotate].is_pressed(event):
		_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.Rotate)
		return _handled()
		
	if current_settings.bindings[AssetPlacerSettings.Bindings.Scale].is_pressed(event):
		_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.Scale)
		return _handled()
	if current_settings.bindings[AssetPlacerSettings.Bindings.Translate].is_pressed(event):
		_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.Move)
		return _handled()	
	if current_settings.bindings[AssetPlacerSettings.Bindings.GridSnapping].is_pressed(event):
		_presenter.toggle_grid_snapping()
		return _handled()
		
	
	if current_settings.binding_positive_transform.is_pressed(event):
		var axis := _presenter.preview_transform_axis
		if _asset_placer.transform_preview(_presenter.transform_mode, axis, 1):
			return _handled()
			
	elif current_settings.binding_negative_transform.is_pressed(event):	
		var axis := _presenter.preview_transform_axis
		if _asset_placer.transform_preview(_presenter.transform_mode, axis, -1):
			return _handled()

	if current_settings.bindings[AssetPlacerSettings.Bindings.ToggleAxisX].is_pressed(event):
		_presenter.toggle_axis(Vector3.RIGHT)
		return _handled()
	if current_settings.bindings[AssetPlacerSettings.Bindings.ToggleAxisY].is_pressed(event):
		_presenter.toggle_axis(Vector3.UP)
		return _handled()
	if current_settings.bindings[AssetPlacerSettings.Bindings.ToggleAxisZ].is_pressed(event):
		_presenter.toggle_axis(Vector3.BACK)
		return _handled()
		
	if current_settings.bindings[AssetPlacerSettings.Bindings.TogglePlaneMode].is_pressed(event):
		_presenter.cycle_placement_mode()
		return _handled()	
	
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			_presenter.cancel()
			return _handled()

	if event is InputEventMouseMotion:
		if event.button_mask == 0:
			if _asset_placer.move_preview(event.position, viewport_camera):
				return _handled()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Don't handle RMB, let it pass through
			pass
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var handled = _asset_placer.place_asset(Input.is_key_pressed(KEY_SHIFT))
			if handled:
				return _handled()
		
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _show_plugin_up_to_date():
	_asset_placer_button.icon = null

func _show_update_available(update: PluginUpdate):
	_asset_placer_button.icon = EditorIconTexture2D.new("MoveUp")
	_asset_placer_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _handled():
	get_viewport().set_input_as_handled()
	return EditorPlugin.AFTER_GUI_INPUT_STOP
