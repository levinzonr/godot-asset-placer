extends RefCounted
class_name AssetPlacerPresenter

static var _instance: AssetPlacerPresenter
var _selected_asset: AssetResource
var options: AssetPlacerOptions
var _parent: NodePath = NodePath("")
signal asset_selected(asset: AssetResource)
signal asset_deselcted

signal parent_changed(parent: NodePath)
signal options_changed(options: AssetPlacerOptions)

func _init():
	options = AssetPlacerOptions.new()
	self._selected_asset = null
	self._instance = self

func ready():
	options_changed.emit(options)
	

func select_parent(node: NodePath):
	self._parent = node
	parent_changed.emit(node)

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
