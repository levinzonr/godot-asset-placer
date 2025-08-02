extends RefCounted
class_name AssetPlacerPresenter

static var _instance: AssetPlacerPresenter
var _selected_asset: AssetResource

signal asset_selected(asset: AssetResource)
signal asset_deselcted

func _init():
	print("Init")
	self._selected_asset = null
	self._instance = self
	

func select_asset(asset: AssetResource):
	print("Select")
	if asset == _selected_asset:
		_selected_asset = null
		asset_deselcted.emit()
	else:
		_selected_asset = asset
		asset_selected.emit(asset)
