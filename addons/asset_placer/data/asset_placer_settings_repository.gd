extends RefCounted
class_name AssetPlacerSettingsRepository

signal settings_changed(settings: AssetPlacerSettings)

var _editor_settings: EditorSettings
static var  instance: AssetPlacerSettingsRepository

func _init():
	_editor_settings = EditorInterface.get_editor_settings()
	instance = self
	
	
const KEY_BASE = "asset_placer/%s"	
const KEY_BINDING_SCALE: String = "bindings/scale_asset"
const KEY_TRANSFORM_STEP: String = "general/transform_step_normal"
const KEY_ROTATION_STEP: String = "general/rotation_step_normal"
const KEY_BINDING_ROTATE: String = "bindings/rotate_asset"	
const KEY_BINDING_TRANSLATE: String = "bindings/translate_asset"
const KEY_BINDING_GRID_SNAP: String = "bindings/grid_snapping"
const KEY_GENERAL_PREVIEW_MATERIAL: String = "general/preview_material"
const KEY_GENERAL_PLANE_MATERIAL: String = "general/plane_material"
const KEY_BINDING_IN_PLACE_TRANSFORM: String = "bindings/in_place_transform"
const KEY_BINDING_TRANSFORM_POSITIVE: String = "bindings/positive_transform"
const KEY_BINDING_TRANSFORM_NEGATIVE: String = "bindings/negative_transform"
const KEY_BINDING_TOGGLE_AXIS_X: String = "bindings/toggle_axis_x"
const KEY_BINDING_TOGGLE_AXIS_Y: String = "bindings/toggle_axis_y"
const KEY_BINDING_TOGGLE_AXIS_Z: String = "bindings/toggle_axis_z"
const KEY_BINDING_TOGGLE_PLANE_MODE: String = "bindings/toggle_plane_mode"
const KEY_UI_SCALE: String = "general/ui_scale"
const KEY_ASSET_LIBRARY_PATH: String = "general/asset_library_path"
const KEY_UPDATE_CHANNEL: String = "general/update_channel"

func _get_binding_storage_key(binding: AssetPlacerSettings.Bindings) -> String:
	match binding:
		AssetPlacerSettings.Bindings.Rotate:
			return KEY_BINDING_ROTATE
		AssetPlacerSettings.Bindings.Scale:
			return KEY_BINDING_SCALE
		AssetPlacerSettings.Bindings.Translate:
			return KEY_BINDING_TRANSLATE
		AssetPlacerSettings.Bindings.GridSnapping:
			return KEY_BINDING_GRID_SNAP
		AssetPlacerSettings.Bindings.InPlaceTransform:
			return KEY_BINDING_IN_PLACE_TRANSFORM
		AssetPlacerSettings.Bindings.TransformPositive:
			return KEY_BINDING_TRANSFORM_POSITIVE
		AssetPlacerSettings.Bindings.TransformNegative:
			return KEY_BINDING_TRANSFORM_NEGATIVE
		AssetPlacerSettings.Bindings.ToggleAxisX:
			return KEY_BINDING_TOGGLE_AXIS_X
		AssetPlacerSettings.Bindings.ToggleAxisY:
			return KEY_BINDING_TOGGLE_AXIS_Y
		AssetPlacerSettings.Bindings.ToggleAxisZ:
			return KEY_BINDING_TOGGLE_AXIS_Z
		AssetPlacerSettings.Bindings.TogglePlaneMode:
			return KEY_BINDING_TOGGLE_PLANE_MODE
		_:
			push_error("Unknown binding type: " + str(binding))
			return ""




func set_settings(settings: AssetPlacerSettings):
	var current = get_settings()
	
	# Validate and resolve keybind conflicts
	_validate_and_resolve_conflicts(settings, current)
	
	# Save all bindings using the mapping function
	for binding in settings.bindings.keys():
		var storage_key = _get_binding_storage_key(binding)
		if not storage_key.is_empty():
			_set_editor_setting(storage_key, settings.bindings[binding].serialize())
	
	_set_project_setting(KEY_GENERAL_PREVIEW_MATERIAL, settings.preview_material_resource)
	_set_project_setting(KEY_GENERAL_PLANE_MATERIAL, settings.plane_material_resource)
	_set_editor_setting(KEY_TRANSFORM_STEP, settings.transform_step)
	_set_editor_setting(KEY_ROTATION_STEP, settings.rotation_step)
	_set_editor_setting(KEY_UI_SCALE, settings.ui_scale)
	_set_editor_setting(KEY_UPDATE_CHANNEL, settings.update_channel)
	_set_project_setting(KEY_ASSET_LIBRARY_PATH, settings.asset_library_path)
	settings_changed.emit(get_settings())
	
func get_settings() -> AssetPlacerSettings:
	var settings := AssetPlacerSettings.default()
	
	# Load all bindings using the mapping function
	for binding in settings.bindings.keys():
		var storage_key = _get_binding_storage_key(binding)
		if not storage_key.is_empty():
			settings.bindings[binding] = _get_binding_settings(storage_key, settings.bindings[binding])
	
	settings.preview_material_resource = _get_project_setting(KEY_GENERAL_PREVIEW_MATERIAL, settings.preview_material_resource)
	settings.plane_material_resource = _get_project_setting(KEY_GENERAL_PLANE_MATERIAL, settings.plane_material_resource)
	settings.transform_step = _get_editor_setting(KEY_TRANSFORM_STEP, settings.transform_step)
	settings.rotation_step = _get_editor_setting(KEY_ROTATION_STEP, settings.rotation_step)
	settings.ui_scale = _get_editor_setting(KEY_UI_SCALE, settings.ui_scale)
	settings.update_channel = _get_editor_setting(KEY_UPDATE_CHANNEL, settings.update_channel)
	settings.asset_library_path = _get_project_setting(KEY_ASSET_LIBRARY_PATH, settings.asset_library_path)
	return settings

func _get_binding_settings(key: String, default: APInputOption) -> APInputOption:
	var raw = _get_editor_setting(key, default.serialize())
	return APInputOption.desirialize(raw)

func _set_project_setting(key: String, value: Variant):
	ProjectSettings.set_setting(KEY_BASE % key, value)
	
func _get_project_setting(key: String, default: Variant):
	return ProjectSettings.get_setting(KEY_BASE % key, default)

func _set_editor_setting(key: String, value):
	_editor_settings.set(KEY_BASE % key, value)

func _get_editor_setting(key: String, default: Variant) -> Variant:
	if _editor_settings.has_setting(KEY_BASE % key):
		return _editor_settings.get(KEY_BASE % key)
	else:
		return default

func _validate_and_resolve_conflicts(new_settings: AssetPlacerSettings, old_settings: AssetPlacerSettings):
	for binding in AssetPlacerSettings.Bindings.values():
		var new : APInputOption = new_settings.bindings[binding]
		
		if new == null:
			continue
			
		if new.equals(APInputOption.none()):
			continue
		
		
		for old_binding in AssetPlacerSettings.Bindings.values():
			if binding == old_binding:
				continue
				
			var old = old_settings.bindings[old_binding]
			if new.equals(old):
				new_settings.bindings[old_binding] = APInputOption.none()
				
				
