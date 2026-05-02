class_name AssetPlacerSettings
extends RefCounted

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
	TogglePlaneMode,
	PaletteNext,
	PalettePrevious
}

enum UpdateChannel { Stable, Beta, Alpha }

const DEFAULT_PREVIEW_MATERIAL := "res://addons/asset_placer/utils/preview_material.tres"
const DEFAULT_PLANE_MATERIAL := "res://addons/asset_placer/ui/plane_preview/plane_preview_material.tres"
const DEFAULT_ASSET_LIBRARY_PATH := AssetLibraryParser.DEFAULT_SAVE_PATH

var transform_step: float
var rotation_step: float
var bindings: Dictionary
var ui_scale: float
var update_channel: UpdateChannel
var binding_positive_transform: APInputOption:
	get():
		return bindings[Bindings.TransformPositive]
var binding_negative_transform: APInputOption:
	get():
		return bindings[Bindings.TransformNegative]

# Project Settings
var preview_material_resource := DEFAULT_PREVIEW_MATERIAL
var plane_material_resource := DEFAULT_PLANE_MATERIAL
var asset_library_path := DEFAULT_ASSET_LIBRARY_PATH


static func default() -> AssetPlacerSettings:
	var settings = AssetPlacerSettings.new()
	settings.bindings[Bindings.TransformNegative] = APInputOption.mouse_press(
		MouseButton.MOUSE_BUTTON_WHEEL_UP
	)
	settings.bindings[Bindings.TransformPositive] = APInputOption.mouse_press(
		MouseButton.MOUSE_BUTTON_WHEEL_DOWN
	)
	settings.bindings[Bindings.Rotate] = APInputOption.key_press(Key.KEY_E)
	settings.bindings[Bindings.Scale] = APInputOption.key_press(Key.KEY_R)
	settings.bindings[Bindings.Translate] = APInputOption.key_press(Key.KEY_W)
	settings.bindings[Bindings.GridSnapping] = APInputOption.key_press(Key.KEY_S)
	settings.bindings[Bindings.InPlaceTransform] = APInputOption.key_press(
		Key.KEY_E, KeyModifierMask.KEY_MASK_SHIFT
	)
	settings.bindings[Bindings.ToggleAxisX] = APInputOption.key_press(Key.KEY_X)
	settings.bindings[Bindings.ToggleAxisY] = APInputOption.key_press(Key.KEY_Y)
	settings.bindings[Bindings.ToggleAxisZ] = APInputOption.key_press(Key.KEY_Z)
	settings.bindings[Bindings.TogglePlaneMode] = APInputOption.key_press(Key.KEY_Q)
	settings.bindings[Bindings.PaletteNext] = APInputOption.key_press(Key.KEY_BRACKETRIGHT)
	settings.bindings[Bindings.PalettePrevious] = APInputOption.key_press(Key.KEY_BRACKETLEFT)
	settings.transform_step = 0.1
	settings.rotation_step = 5
	settings.ui_scale = 1.0
	settings.update_channel = UpdateChannel.Stable

	return settings
