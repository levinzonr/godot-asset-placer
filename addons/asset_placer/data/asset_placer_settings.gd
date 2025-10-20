extends RefCounted
class_name AssetPlacerSettings

var preview_material_resource: String
var plane_material_resource: String
var binding_rotate: Key:
	set(key):
		var conflict = get_conflicting_action_for_key(key, SettingsKey.Rotate)
		if conflict != SettingsKey.None:
			_clear_conflicting_binding(conflict)
		_binding_rotate = key
	get:
		return _binding_rotate
		
var binding_scale: Key:
	set(key):
		var conflict = get_conflicting_action_for_key(key, SettingsKey.Scale)
		if conflict != SettingsKey.None:
			_clear_conflicting_binding(conflict)
		_binding_scale = key
	get:
		return _binding_scale
		
var binding_translate: Key:
	set(key):
		var conflict = get_conflicting_action_for_key(key, SettingsKey.Translate)
		if conflict != SettingsKey.None:
			_clear_conflicting_binding(conflict)
		_binding_translate = key
	get:
		return _binding_translate
		
var binding_grid_snap: Key:
	set(key):
		var conflict = get_conflicting_action_for_key(key, SettingsKey.GridSnapping)
		if conflict != SettingsKey.None:
			_clear_conflicting_binding(conflict)
		_binding_grid_snap = key
	get:
		return _binding_grid_snap

# Private backing fields to avoid setter recursion
var _binding_rotate: Key = KEY_NONE
var _binding_scale: Key = KEY_NONE
var _binding_translate: Key = KEY_NONE
var _binding_grid_snap: Key = KEY_NONE


enum SettingsKey {
	Rotate, Scale, Translate, GridSnapping, None
}

func _clear_conflicting_binding(action: SettingsKey):
	match action:
		SettingsKey.Rotate: _binding_rotate = KEY_NONE
		SettingsKey.Scale: _binding_scale = KEY_NONE
		SettingsKey.Translate: _binding_translate = KEY_NONE
		SettingsKey.GridSnapping: _binding_grid_snap = KEY_NONE
		SettingsKey.None: pass
		

var key_map: Dictionary[SettingsKey, Key]:
	get():
		return {
			SettingsKey.Rotate: _binding_rotate,
			SettingsKey.Scale: _binding_scale,
			SettingsKey.Translate: _binding_translate,
			SettingsKey.GridSnapping: _binding_grid_snap,
			SettingsKey.None: Key.KEY_NONE
		}

func get_conflicting_action_for_key(key_to_check: Key, except: SettingsKey) -> SettingsKey:
	for action in SettingsKey.values():
		if action == except:
			continue
		if key_map[action] == key_to_check:
			return action
	return SettingsKey.None
	
	

static func default() -> AssetPlacerSettings:
	var settings = AssetPlacerSettings.new()
	settings.binding_rotate = Key.KEY_E
	settings.binding_scale = Key.KEY_R
	settings.binding_translate = Key.KEY_W
	settings.binding_grid_snap = Key.KEY_S
	settings.preview_material_resource = "res://addons/asset_placer/utils/preview_material.tres"
	settings.plane_material_resource = "res://addons/asset_placer/ui/plane_preview/plane_preview_material.tres"
	return settings
