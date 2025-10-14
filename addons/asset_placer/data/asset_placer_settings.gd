extends RefCounted
class_name AssetPlacerSettings

var binding_rotate: Key
var binding_scale: Key
var binding_translate: Key
var binding_grid_snap: Key



static func default() -> AssetPlacerSettings:
	var settings = AssetPlacerSettings.new()
	settings.binding_rotate = Key.KEY_E
	settings.binding_scale = Key.KEY_R
	settings.binding_translate = Key.KEY_W
	settings.binding_grid_snap = Key.KEY_S
	return settings
