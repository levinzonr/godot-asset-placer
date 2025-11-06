extends RefCounted
class_name AssetPlacerSettings

var transform_step: float
var rotation_step: float 
var preview_material_resource: String
var plane_material_resource: String
var bindings: Dictionary
var ui_scale: float
var asset_library_path: String
var update_channel: UpdateChannel

var binding_positive_transform: APInputOption:
	get(): return bindings[Bindings.TransformPositive]
	
var binding_negative_transform: APInputOption:
	get(): return bindings[Bindings.TransformNegative]	
	
	

enum Bindings {
	Rotate,
	Scale,
	Translate,
	GridSnapping, 
	InPlaceTransform, 
	TransformPositive, 
	TransformNegative,
	ToggleAxisX,
	ToggleAxisZ,
	ToggleAxisY,
	TogglePlaneMode
}

enum UpdateChannel {
	Stable,
	Beta,
	Alpha
}



static func default() -> AssetPlacerSettings:
	var settings = AssetPlacerSettings.new()
	settings.bindings[Bindings.TransformNegative] = APInputOption.mouse_press(MouseButton.MOUSE_BUTTON_WHEEL_UP)
	settings.bindings[Bindings.TransformPositive] = APInputOption.mouse_press(MouseButton.MOUSE_BUTTON_WHEEL_DOWN)
	settings.bindings[Bindings.Rotate] = APInputOption.key_press(Key.KEY_E)
	settings.bindings[Bindings.Scale] = APInputOption.key_press(Key.KEY_R)
	settings.bindings[Bindings.Translate] = APInputOption.key_press(Key.KEY_W)
	settings.bindings[Bindings.GridSnapping] = APInputOption.key_press(Key.KEY_S)
	settings.bindings[Bindings.InPlaceTransform] = APInputOption.key_press(Key.KEY_E, KeyModifierMask.KEY_MASK_SHIFT)
	settings.bindings[Bindings.ToggleAxisX] = APInputOption.key_press(Key.KEY_X)
	settings.bindings[Bindings.ToggleAxisY] = APInputOption.key_press(Key.KEY_Y)
	settings.bindings[Bindings.ToggleAxisZ] = APInputOption.key_press(Key.KEY_Z)
	settings.bindings[Bindings.TogglePlaneMode] = APInputOption.key_press(Key.KEY_Q)
	settings.preview_material_resource = "res://addons/asset_placer/utils/preview_material.tres"
	settings.plane_material_resource = "res://addons/asset_placer/ui/plane_preview/plane_preview_material.tres"
	settings.transform_step = 0.1
	settings.rotation_step = 5
	settings.ui_scale = 1.0
	settings.asset_library_path = "user://asset_library.json"
	settings.update_channel = UpdateChannel.Stable
	return settings
