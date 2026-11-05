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
	PalettePrevious,
	TogglePluginActive,
	BrushSizeIncrease,
	BrushSizeDecrease,
	BrushDensityIncrease,
	BrushDensityDecrease,
	ToggleInstancingMode,
}

enum UpdateChannel { Stable, Beta, Alpha }

const DEFAULT_PREVIEW_MATERIAL := "res://addons/asset_placer/utils/preview_material.tres"
const DEFAULT_PLANE_MATERIAL := "res://addons/asset_placer/ui/plane_preview/plane_preview_material.tres"
const DEFAULT_ASSET_LIBRARY_PATH := AssetLibraryParser.DEFAULT_SAVE_PATH
const MIN_BRUSH_SIZE = 5

var transform_step: float
var rotation_step: float
var max_brush_size: float = 20.0:
	set(value):
		max_brush_size = maxf(value, MIN_BRUSH_SIZE)
var bindings: Dictionary
var ui_scale: float
var palette_item_scale: float
var show_toolbar_button: bool = true
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
	settings.bindings[Bindings.TransformNegative] = APInputOption.mouse_wheel_up()
	settings.bindings[Bindings.TransformPositive] = APInputOption.mouse_wheel_down()
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
	settings.bindings[Bindings.ToggleInstancingMode] = APInputOption.key_press(Key.KEY_V)
	settings.bindings[Bindings.PaletteNext] = APInputOption.key_press(Key.KEY_TAB)
	settings.bindings[Bindings.PalettePrevious] = APInputOption.key_press(
		Key.KEY_TAB, KeyModifierMask.KEY_MASK_SHIFT
	)
	settings.bindings[Bindings.TogglePluginActive] = APInputOption.none()
	settings.bindings[Bindings.BrushSizeIncrease] = APInputOption.mouse_wheel_up(
		KeyModifierMask.KEY_MASK_ALT
	)
	settings.bindings[Bindings.BrushSizeDecrease] = APInputOption.mouse_wheel_down(
		KeyModifierMask.KEY_MASK_ALT
	)
	settings.bindings[Bindings.BrushDensityIncrease] = APInputOption.mouse_wheel_up(
		KeyModifierMask.KEY_MASK_ALT | KeyModifierMask.KEY_MASK_SHIFT
	)
	settings.bindings[Bindings.BrushDensityDecrease] = APInputOption.mouse_wheel_down(
		KeyModifierMask.KEY_MASK_ALT | KeyModifierMask.KEY_MASK_SHIFT
	)

	settings.transform_step = 0.1
	settings.rotation_step = 5
	settings.ui_scale = 1.0
	settings.palette_item_scale = 1.0
	settings.update_channel = UpdateChannel.Stable

	return settings
