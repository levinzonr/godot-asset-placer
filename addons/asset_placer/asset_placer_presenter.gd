# gdlint: disable=max-public-methods
# Temporary - needs refactoring in the future
class_name AssetPlacerPresenter
extends RefCounted

signal asset_deselected
signal parent_changed(parent: NodePath)
signal options_changed(options: AssetPlacerOptions)
signal transform_mode_changed(mode: TransformMode)
signal placement_mode_changed(mode: GapPlacementMode)
signal preview_transform_axis_changed(axis: Vector3)
signal asset_selected(asset: AssetResource)
signal show_error(message: String)
signal placer_active(value: bool)
signal asset_placed

enum TransformMode { None, Rotate, Scale, Move }

static var _instance: AssetPlacerPresenter
static var transform_step: float = 0.1

var options: AssetPlacerOptions
var transform_mode: TransformMode = TransformMode.None
var current_assets: Array[AssetResource]
var placement_mode: GapPlacementMode = GapPlacementMode.SurfacePlacement.new():
	set(value):
		placement_mode = value
		placement_mode_changed.emit(value)
var preview_transform_axis: Vector3 = Vector3.UP

var _selected_asset: AssetResource
var _parent: NodePath = NodePath("")
var _last_plane_options := PlaneOptions.new(Vector3.UP, Vector3.ZERO)
var _selected_node: Node3D


func _init():
	options = AssetPlacerOptions.new()
	self._selected_asset = null
	self._instance = self


func ready():
	options_changed.emit(options)
	placement_mode_changed.emit(placement_mode)


func plugin_is_active() -> bool:
	if _selected_asset != null or _selected_node != null:
		return true
	else:
		return false


func toggle_plane_placement():
	placement_mode = GapPlacementMode.PlanePlacement.new(_last_plane_options)


func cycle_placement_mode():
	if placement_mode is GapPlacementMode.SurfacePlacement:
		toggle_plane_placement()
	elif placement_mode is GapPlacementMode.PlanePlacement:
		toggle_transformation_mode(TransformMode.None)
		toggle_surface_placement()


func toggle_surface_placement():
	placement_mode = GapPlacementMode.SurfacePlacement.new()


func toggle_terrain_3d_placement(node_path: NodePath):
	if not node_path.is_empty():
		var node = EditorInterface.get_edited_scene_root().get_node(node_path)
		self.placement_mode = GapPlacementMode.Terrain3DPlacement.new(node)
	else:
		placement_mode_changed.emit(placement_mode)


func _select_placement_mode(mode: GapPlacementMode):
	self.placement_mode = mode


func get_assets_parent_path() -> NodePath:
	return _parent


func select_parent(node: NodePath):
	self._parent = node
	options.use_selected_as_parent = false
	parent_changed.emit(node)
	options_changed.emit(options)


func toggle_transformation_mode(mode: TransformMode):
	if transform_mode == mode:
		transform_mode = TransformMode.None
	else:
		transform_mode = mode
	transform_mode_changed.emit(transform_mode)

	if transform_mode == TransformMode.Move:
		_select_placement_mode(GapPlacementMode.PlanePlacement.new(_last_plane_options))

	if transform_mode == TransformMode.Rotate:
		set_random_rotation_enabled(false)

	if transform_mode == TransformMode.Scale:
		set_random_scale_enabled(false)

	_select_default_axis(transform_mode)


func clear_parent():
	self._parent = NodePath("")
	options.use_selected_as_parent = false
	parent_changed.emit(_parent)
	options_changed.emit(options)


func set_use_selected_as_parent(value: bool):
	options.use_selected_as_parent = value
	options_changed.emit(options)
	parent_changed.emit(_parent)


func resolve_placement_parent(edited_root: Node) -> Node3D:
	if options.use_selected_as_parent:
		return _resolve_parent_from_selection()
	if _parent.is_empty():
		push_warning(
			(
				'Asset Placer: enable "Use selection for parent" or choose an Assets Parent node '
				+ "in the options panel."
			)
		)
		return null
	var node = edited_root.get_node_or_null(_parent)
	if node is Node3D:
		return node
	push_warning("Asset Placer: Assets Parent path is invalid for this scene.")
	return null


func _resolve_parent_from_selection() -> Node3D:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() > 1:
		push_warning(
			(
				"Asset Placer: multiple nodes selected; select a single Node3D or disable "
				+ '"Use selection for parent" and set Assets Parent.'
			)
		)
		return null
	if selected.is_empty():
		push_warning(
			(
				"Asset Placer: no node selected; select a Node3D (new assets are placed as siblings) "
				+ 'or disable "Use selection for parent" and set Assets Parent.'
			)
		)
		return null
	var picked: Node = selected[0]
	if picked is not Node3D:
		push_warning("Asset Placer: selected node must be a Node3D.")
		return null
	return picked


func set_unform_scaling(value: bool):
	options.uniform_scaling = value
	if value:
		options.min_scale = _uniform_v3(options.min_scale.x)
		options.max_scale = _uniform_v3(options.max_scale.x)
	options_changed.emit(options)


func set_grid_snap_value(value: float):
	options.snapping_grid_step = value
	options_changed.emit(options)


func set_random_asset_enabled(value: bool):
	options.enable_random_placement = value
	options_changed.emit(options)


func toggle_axis(axis: Vector3):
	var new := (preview_transform_axis - axis).abs()
	_select_axis(new)


func _select_axis(axis: Vector3):
	if axis == Vector3.ZERO:
		show_error.emit("Ignoring Axis selection because it is zero")
		return
	preview_transform_axis = axis
	preview_transform_axis_changed.emit(preview_transform_axis)

	var movement_mode = transform_mode == TransformMode.Move
	var idle_mode = transform_mode == TransformMode.None
	var plane_placement = placement_mode is GapPlacementMode.PlanePlacement
	if plane_placement and (idle_mode || movement_mode):
		_last_plane_options.normal = axis.normalized()
		placement_mode = GapPlacementMode.PlanePlacement.new(_last_plane_options)


func set_random_scale_enabled(value: bool):
	options.scale_on_placement = value
	options_changed.emit(options)

	if value and transform_mode == TransformMode.Scale:
		toggle_transformation_mode(TransformMode.None)


func set_random_rotation_enabled(value: bool):
	options.rotate_on_placement = value
	options_changed.emit(options)

	if value and transform_mode == TransformMode.Rotate:
		toggle_transformation_mode(TransformMode.None)


func set_align_normals(value: bool):
	options.align_normals = value
	options_changed.emit(options)


func set_use_asset_origin(value: bool):
	options.use_asset_origin = value
	options_changed.emit(options)


func _select_default_axis(mode: TransformMode):
	match mode:
		TransformMode.Rotate:
			_select_axis(Vector3.UP)
		TransformMode.Scale:
			_select_axis(Vector3.ONE)
		TransformMode.Move:
			_select_axis(_last_plane_options.normal)
		_:
			pass


func _uniform_v3(value: float) -> Vector3:
	return Vector3(value, value, value)


func set_grid_snapping_enabled(value: bool):
	options.snapping_enabled = value
	options_changed.emit(options)


func toggle_grid_snapping():
	set_grid_snapping_enabled(!options.snapping_enabled)


func set_min_rotation(vector: Vector3):
	options.min_rotation = vector
	options_changed.emit(options)


func set_max_scale(vector: Vector3):
	options.max_scale = vector
	options_changed.emit(options)


func set_min_scale(vector: Vector3):
	options.min_scale = vector
	options_changed.emit(options)


func set_max_rotation(vector: Vector3):
	options.max_rotation = vector
	options_changed.emit(options)


func cancel():
	if transform_mode != TransformMode.None:
		toggle_transformation_mode(TransformMode.None)
	elif _selected_node != null:
		end_node_transform_mode()
	else:
		clear_selection()


func clear_selection():
	_selected_asset = null
	asset_deselected.emit()
	placer_active.emit(false)


func toggle_asset(asset: AssetResource):
	if asset == _selected_asset:
		_selected_asset = null
		asset_deselected.emit()
		placer_active.emit(false)
	else:
		_selected_asset = asset
		asset_selected.emit(asset)
		placer_active.emit(true)


func select_asset(asset: AssetResource):
	_selected_asset = asset
	asset_selected.emit(asset)
	placer_active.emit(true)


func start_node_transform_mode(node: Node3D):
	_selected_node = node
	placer_active.emit(true)


func end_node_transform_mode():
	_selected_node = null
	placer_active.emit(false)


func on_asset_placed():
	var es := APEditorSettingsManager.get_editor_settings()
	if es:
		es.update_asset_time_placed(_selected_asset.id)

	if options.enable_random_placement:
		var random = current_assets.pick_random()
		select_asset(random)


func set_automatic_grouping(value: bool):
	options.group_automatically = value
	options_changed.emit(options)


func is_node_transform_mode() -> bool:
	return _selected_node != null


func get_selected_node() -> Node3D:
	return _selected_node


func move_plane_up(direction: int):
	if placement_mode is GapPlacementMode.PlanePlacement:
		var plane_options = placement_mode.plane_options
		var step = options.snapping_grid_step if options.snapping_enabled else 0.2
		var new_origin = plane_options.origin + plane_options.normal * (direction * step)

		# Apply grid snapping if enabled
		if options.snapping_enabled:
			var normal = plane_options.normal.normalized()
			var distance_along_normal = normal.dot(new_origin)
			var snapped_distance = (
				round(distance_along_normal / options.snapping_grid_step)
				* options.snapping_grid_step
			)
			new_origin = normal * snapped_distance

		plane_options.origin = new_origin
		placement_mode = GapPlacementMode.PlanePlacement.new(plane_options)
