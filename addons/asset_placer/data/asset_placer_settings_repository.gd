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
const KEY_BINDING_ROTATE: String = "bindings/rotate_asset"	
const KEY_BINDING_TRANSLATE: String = "bindings/translate_asset"
const KEY_BINDING_GRID_SNAP: String = "bindings/grid_snapping"
const KEY_GENERAL_PREVIEW_MATERIAL: String = "general/preview_material"
const KEY_GENERAL_PLANE_MATERIAL: String = "general/plane_material"
const KEY_BINDING_IN_PLACE_TRANSFORM: String = "bindings/in_place_transform"

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
		_:
			push_error("Unknown binding type: " + str(binding))
			return ""

func set_settings(settings: AssetPlacerSettings):
	var current = get_settings()
	# Save all bindings using the mapping function
	for binding in settings.bindings.keys():
		var storage_key = _get_binding_storage_key(binding)
		if not storage_key.is_empty():
			_set_editor_setting(storage_key, settings.bindings[binding].serialize())
	
	_set_project_setting(KEY_GENERAL_PREVIEW_MATERIAL, settings.preview_material_resource)
	_set_project_setting(KEY_GENERAL_PLANE_MATERIAL, settings.plane_material_resource)
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
