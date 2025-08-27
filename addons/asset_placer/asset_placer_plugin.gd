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
var _viewport_overlay_res = preload("res://addons/asset_placer/ui/viewport_overlay/viewport_overlay.tscn")
var _plane_preview: MeshInstance3D
var overlay: Control

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
	_presenter.asset_deselected.connect(_asset_placer.stop_placement)
	_asset_placer_window = load("res://addons/asset_placer/ui/asset_library_panel.tscn").instantiate()
	add_control_to_bottom_panel(_asset_placer_window, "Asset Placer")
	
	_presenter.placement_mode_changed.connect(func(p: PlacementMode):
		_asset_placer.set_placement_mode(p)
		if p is PlacementMode.PlanePlacement:
			if _plane_preview:
				_plane_preview.queue_free()
				
			_plane_preview = MeshInstance3D.new()
			var plane_mesh = PlaneMesh.new()
			var normal = p.plane.normal.normalized()  # The normal you want
			var forward = normal.cross(Vector3.UP).normalized() if (abs(normal.dot(Vector3.UP)) < 0.99) else normal.cross(Vector3.FORWARD).normalized()
			var right = forward.cross(normal).normalized()
			var basis = Basis(right, normal, forward)
			plane_mesh.material = load("res://addons/asset_placer/utils/preview_material.tres")
			plane_mesh.size = Vector2(1000, 1000)
			_plane_preview.mesh = plane_mesh
			_plane_preview.transform.basis = basis.orthonormalized()
			get_tree().root.add_child(_plane_preview)
		else:
			if _plane_preview:
				_plane_preview.queue_free()
				_plane_preview = null
	)
	
	synchronizer.sync_complete.connect(func(added, removed, scanned):
		var message = "Asset Placer Sync complete\nAdded: %d Removed: %d Scanned total: %d" % [added, removed, scanned]
		EditorToasterCompat.toast(message)
	)
	
	self.overlay =  _viewport_overlay_res.instantiate()
	get_editor_interface().get_editor_viewport_3d().add_child(overlay)
	
	_file_system.resources_reimported.connect(_react_to_reimorted_files)
	if !_file_system.is_scanning():
		synchronizer.sync_all()
		
	
func _exit_tree():
	overlay.queue_free()
	if _plane_preview:
		_plane_preview.queue_free()
	_file_system.resources_reimported.disconnect(_react_to_reimorted_files)
	_presenter.asset_selected.disconnect(start_placement)
	_presenter.asset_deselected.disconnect(_asset_placer.stop_placement)
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
	_asset_placer.start_placement(get_tree().root, asset, _presenter.placement_mode)

func _forward_3d_gui_input(viewport_camera, event):	
	if event is InputEventMouseMotion:
		if event.button_mask == 0:
			return _asset_placer.move_preview(event.position, viewport_camera)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			return _asset_placer.place_asset(Input.is_key_pressed(KEY_SHIFT))
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var direction := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			var axis := _presenter.preview_transform_axis
			return _asset_placer.transform_preview(_presenter.transform_mode, axis, direction)
	
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_E:
			_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.Rotate)
			return true
		if event.keycode == KEY_R:
			_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.Scale)
			return true
		if event.keycode == KEY_W:
			_presenter.toggle_transformation_mode(AssetPlacerPresenter.TransformMode.Move)
			return true
		if event.keycode == KEY_ESCAPE:
			_presenter.cancel()
			return true
		if event.keycode == KEY_Y:
			_presenter.toggle_axis(Vector3.UP)	
			return true
			
		if event.keycode == KEY_Z:
			_presenter.toggle_axis(Vector3.BACK)
			return true
		if event.keycode == KEY_X:
			_presenter.toggle_axis(Vector3.RIGHT)
			return true
			
	return false
