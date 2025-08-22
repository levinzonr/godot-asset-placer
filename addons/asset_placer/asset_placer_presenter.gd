extends RefCounted
class_name AssetPlacerPresenter

static var _instance: AssetPlacerPresenter
var _selected_asset: AssetResource
var options: AssetPlacerOptions
var _parent: NodePath = NodePath("")
var _mode: Mode = Mode.Place
var preview_transform_axis: Vector3 = Vector3.UP

signal asset_selected(asset: AssetResource)
signal asset_deselected
signal parent_changed(parent: NodePath)
signal options_changed(options: AssetPlacerOptions)
signal mode_changed(mode: Mode)
signal preview_transform_axis_changed(axis: Vector3)
enum Mode {
	Place,
	Rotate,
	Scale,
	Move
}

func _init():
	options = AssetPlacerOptions.new()
	self._selected_asset = null
	self._instance = self

func ready():
	options_changed.emit(options)
	

func select_parent(node: NodePath):
	self._parent = node
	parent_changed.emit(node)

func change_mode(mode: Mode):
	if _mode == mode:
		_mode = Mode.Place
	else:
		_mode = mode
	mode_changed.emit(_mode)
	_select_default_axis(_mode)
	
func clear_parent():
	self._parent = NodePath("")
	parent_changed.emit(_parent)	
	
func set_unform_scaling(value: bool):
	options.uniform_scaling = value
	if value:
		options.min_scale = uniformV3(options.min_scale.x)
		options.max_scale = uniformV3(options.max_scale.x)
	options_changed.emit(options)	

func set_grid_snap_value(value: float):
	options.snapping_grid_step = value
	options_changed.emit(options)

func toggle_axis(axis: Vector3):
	var new = (preview_transform_axis - axis).abs()
	select_axis(new)

func select_axis(axis: Vector3):	
	preview_transform_axis = axis
	preview_transform_axis_changed.emit(preview_transform_axis)

func _select_default_axis(mode: Mode):
	match mode:
		Mode.Rotate:
			select_axis(Vector3.UP)
		Mode.Scale:
			select_axis(Vector3.ONE)
		Mode.Move:
			select_axis(Vector3.FORWARD)
		_: pass

func uniformV3(value: float) -> Vector3:
	return Vector3(value, value, value)
 	
func set_grid_snapping_enabled(value: bool):
	options.snapping_enabled = value
	options_changed.emit(options)
	
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
	if _mode != Mode.Place:
		change_mode(Mode.Place)
	else:
		clear_selection()
	
func clear_selection():
	_selected_asset = null
	asset_deselcted.emit()	

func select_asset(asset: AssetResource):
	if asset == _selected_asset:
		_selected_asset = null
		asset_deselcted.emit()
	else:
		_selected_asset = asset
		asset_selected.emit(asset)
