extends RefCounted
class_name SettingsPresenter

var _repository: AssetPlacerSettingsRepository

signal show_settings(settings: AssetPlacerSettings)
signal show_conflict_dialog(conflicting_key: Key, action: AssetPlacerSettings.SettingsKey)

func _init():
	_repository = AssetPlacerSettingsRepository.instance
	
func ready():
	show_settings.emit(_repository.get_settings())
	_repository.settings_changed.connect(show_settings.emit)

func reset_to_defaults():
	_repository.set_settings(AssetPlacerSettings.default())
	

func set_preview_material(material: String):
	if material.is_empty():
		return
	var current = _repository.get_settings()
	current.preview_material_resource = material
	_repository.set_settings(current)	

func set_plane_material(material: String):
	if not material.is_empty():
		var current = _repository.get_settings()
		current.plane_material_resource = material
		_repository.set_settings(current)
		

func clear_preivew_material():
	var current = _repository.get_settings()
	current.preview_material_resource = ""
	_repository.set_settings(current)	

func set_rotate_binding(key: APInputOption):
	var current = _repository.get_settings()
	current.binding_rotate = key
	_repository.set_settings(current)
	
func set_grid_snap_binding(key: APInputOption):
	var current = _repository.get_settings()
	current.binding_grid_snap = key
	_repository.set_settings(current)	
	
func set_scale_binding(key: APInputOption):
	var current = _repository.get_settings()
	current.binding_scale = key
	_repository.set_settings(current)
	
func set_binding_in_place_transform(key: APInputOption):	
	var current = _repository.get_settings()
	current.binding_in_place_transform = key
	_repository.set_settings(current)
	
func set_translate_binding(key: APInputOption):
	var current = _repository.get_settings()
	current.binding_translate = key
	_repository.set_settings(current)	
