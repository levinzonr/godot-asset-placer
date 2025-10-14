extends RefCounted
class_name AssetPlacerSettingsRepository

signal settings_changed(settings: AssetPlacerSettings)

var _settings: EditorSettings
static var  instance: AssetPlacerSettingsRepository

func _init():
	_settings = EditorInterface.get_editor_settings()
	instance = self
	
	
const KEY_BINDING_SCALE: String = "bindings/scale_asset"
const KEY_BINDING_ROTATE: String = "bindings/rotate_asset"	
const KEY_BINDING_TRANSLATE: String = "bindings/translate_asset"
const KEY_BINDING_GRID_SNAP: String = "bindings/grid_snapping"

func set_settings(settings: AssetPlacerSettings):
	var current = get_settings()
	_set_editor_setting(KEY_BINDING_ROTATE, settings.binding_rotate)
	_set_editor_setting(KEY_BINDING_SCALE, settings.binding_scale)
	_set_editor_setting(KEY_BINDING_TRANSLATE, settings.binding_translate)
	_set_editor_setting(KEY_BINDING_GRID_SNAP, settings.binding_grid_snap)
	settings_changed.emit(get_settings())
	
func get_settings() -> AssetPlacerSettings:
	var settings := AssetPlacerSettings.default()
	settings.binding_scale = _get_editor_setting(KEY_BINDING_SCALE, settings.binding_scale)
	settings.binding_translate = _get_editor_setting(KEY_BINDING_TRANSLATE, settings.binding_translate)
	settings.binding_rotate = _get_editor_setting(KEY_BINDING_ROTATE, settings.binding_rotate)
	settings.binding_grid_snap = _get_editor_setting(KEY_BINDING_GRID_SNAP, settings.binding_grid_snap)
	return settings
		


func _set_editor_setting(key: String, value):
	_settings.set("asset_placer/%s" % key, value)

func _get_editor_setting(key: String, default: Variant) -> Variant:
	if _settings.has_setting("asset_placer/%s" % key):
		return _settings.get("asset_placer/%s" % key)
	else:
		return default
