extends RefCounted
class_name AssetPlacerSettings

var transform_step: float 
var preview_material_resource: String
var plane_material_resource: String
var bindings: Dictionary

enum Bindings {
	Rotate, Scale, Translate, GridSnapping, InPlaceTransform
}



static func default() -> AssetPlacerSettings:
	var settings = AssetPlacerSettings.new()
	settings.bindings[Bindings.Rotate] = APInputOption.key_press(Key.KEY_E)
	settings.bindings[Bindings.Scale] = APInputOption.key_press(Key.KEY_R)
	settings.bindings[Bindings.Translate] = APInputOption.key_press(Key.KEY_W)
	settings.bindings[Bindings.GridSnapping] = APInputOption.key_press(Key.KEY_S)
	settings.bindings[Bindings.InPlaceTransform] = APInputOption.key_press(Key.KEY_E, KeyModifierMask.KEY_MASK_SHIFT)
	settings.preview_material_resource = "res://addons/asset_placer/utils/preview_material.tres"
	settings.plane_material_resource = "res://addons/asset_placer/ui/plane_preview/plane_preview_material.tres"
	settings.transform_step = 0.1
	return settings
