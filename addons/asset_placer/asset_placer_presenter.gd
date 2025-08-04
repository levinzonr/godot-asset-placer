extends RefCounted
class_name AssetPlacerPresenter

static var _instance: AssetPlacerPresenter
var _selected_asset: AssetResource
var options: AssetPlacerOptions

signal asset_selected(asset: AssetResource)
signal asset_deselcted

signal options_changed(options: AssetPlacerOptions)

func _init():
	print("Init")
	options = AssetPlacerOptions.new()
	self._selected_asset = null
	self._instance = self

func ready():
	options_changed.emit(options)

func set_grid_snap_value(value: float):
	options.snapping_grid_step = value
	options_changed.emit(options)
	
func set_grid_snapping_enabled(value: bool):
	options.snapping_enabled = value
	options_changed.emit(options)
	
func set_transform_rotation(x: bool, y: bool, z: bool):
	options.transform_rotate_x = x;
	options.transform_rotate_y = y;
	options.transform_rotate_z = z	
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
