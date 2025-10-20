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

func set_settings(settings: AssetPlacerSettings):
	var current = get_settings()
	_set_editor_setting(KEY_BINDING_ROTATE, settings.binding_rotate)
	_set_editor_setting(KEY_BINDING_SCALE, settings.binding_scale)
	_set_editor_setting(KEY_BINDING_TRANSLATE, settings.binding_translate)
	_set_editor_setting(KEY_BINDING_GRID_SNAP, settings.binding_grid_snap)
	_set_project_setting(KEY_GENERAL_PREVIEW_MATERIAL, settings.preview_material_resource)
	_set_project_setting(KEY_GENERAL_PLANE_MATERIAL, settings.plane_material_resource)
	settings_changed.emit(get_settings())
	
func get_settings() -> AssetPlacerSettings:
	var settings := AssetPlacerSettings.default()
	settings.binding_scale = _get_editor_setting(KEY_BINDING_SCALE, settings.binding_scale)
	settings.binding_translate = _get_editor_setting(KEY_BINDING_TRANSLATE, settings.binding_translate)
	settings.binding_rotate = _get_editor_setting(KEY_BINDING_ROTATE, settings.binding_rotate)
	settings.binding_grid_snap = _get_editor_setting(KEY_BINDING_GRID_SNAP, settings.binding_grid_snap)
	settings.preview_material_resource = _get_project_setting(KEY_GENERAL_PREVIEW_MATERIAL, settings.preview_material_resource)
	settings.plane_material_resource = _get_project_setting(KEY_GENERAL_PLANE_MATERIAL, settings.plane_material_resource)
	return settings
		

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
