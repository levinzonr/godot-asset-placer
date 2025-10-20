extends RefCounted
class_name AssetPlacerSettings

var preview_material_resource: String
var plane_material_resource: String


var binding_in_place_transform: APInputOption
var binding_rotate: APInputOption
var binding_scale: APInputOption
var binding_translate: APInputOption
var binding_grid_snap: APInputOption



enum SettingsKey {
	Rotate, Scale, Translate, GridSnapping, None
}


static func default() -> AssetPlacerSettings:
	var settings = AssetPlacerSettings.new()
	settings.binding_rotate = APInputOption.key_press(Key.KEY_E)
	settings.binding_scale = APInputOption.key_press(Key.KEY_R)
	settings.binding_translate =APInputOption.key_press(Key.KEY_W)
	settings.binding_grid_snap =APInputOption.key_press(Key.KEY_S)
	settings.binding_in_place_transform = APInputOption.mouse_press(MouseButton.MOUSE_BUTTON_RIGHT)
	settings.preview_material_resource = "res://addons/asset_placer/utils/preview_material.tres"
	settings.plane_material_resource = "res://addons/asset_placer/ui/plane_preview/plane_preview_material.tres"
	return settings
