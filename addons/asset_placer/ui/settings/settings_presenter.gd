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
	_repository.set_settings(AssetPlacerSettings.default())

func set_rotate_binding(key: Key):
	var current = _repository.get_settings()
	current.binding_rotate = key
	_repository.set_settings(current)
	
func set_grid_snap_binding(key: Key):
	var current = _repository.get_settings()
	current.binding_grid_snap = key
	_repository.set_settings(current)	
	
func set_scale_binding(key: Key):
	var current = _repository.get_settings()
	current.binding_scale = key
	_repository.set_settings(current)
	
func set_translate_binding(key: Key):
	var current = _repository.get_settings()
	current.binding_translate = key
	_repository.set_settings(current)	
