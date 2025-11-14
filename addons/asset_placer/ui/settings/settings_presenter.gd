extends RefCounted
class_name SettingsPresenter

var _repository: AssetPlacerSettingsRepository

signal show_settings(settings: AssetPlacerSettings)

func _init():
	_repository = AssetPlacerSettingsRepository.instance
	
func ready():
	show_settings.emit(_repository.get_settings())
	_repository.settings_changed.connect(show_settings.emit)

func reset_to_defaults():
	var default = AssetPlacerSettings.default()
	# keep path
	default.asset_library_path = _repository.get_settings().asset_library_path
	_repository.set_settings(AssetPlacerSettings.default())

func set_default_transform_step(value: float):
	var settings = _repository.get_settings()
	settings.transform_step = value
	_repository.set_settings(settings)
	
func set_ui_scale(value: float):	
	var settings = _repository.get_settings()
	settings.ui_scale = value
	_repository.set_settings(settings)

func set_rotation_step(value: float):
	var settings = _repository.get_settings()
	settings.rotation_step = value
	_repository.set_settings(settings)

func set_update_channel(value: AssetPlacerSettings.UpdateChannel):
	var settings = _repository.get_settings()
	settings.update_channel = value
	_repository.set_settings(settings)

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

func set_binding(key: AssetPlacerSettings.Bindings, input: APInputOption):
	var current_settings = _repository.get_settings()
	current_settings.bindings[key] = input
	_repository.set_settings(current_settings)
	
func set_translate_binding(key: APInputOption):
	var current = _repository.get_settings()
	current.binding_translate = key
	_repository.set_settings(current)	
