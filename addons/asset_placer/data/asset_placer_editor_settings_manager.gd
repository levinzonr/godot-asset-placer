@tool
class_name APEditorSettingsManager
extends RefCounted

## Singleton class to manage a single active AssetPlacerEditorSettings

const SAVE_PATH := "user://asset_placer_editor_settings.tres"

## Time between settings change and save to disk in seconds.
static var time_to_save: float = 1.0

static var _editor_settings: AssetPlacerEditorSettings
static var _save_timer: SceneTreeTimer

## Last palette AssetPalette.changed connected to editor emit_changed (see _connect_save).
static var _palette_forward_palette: AssetPalette


static func get_editor_settings() -> AssetPlacerEditorSettings:
	assert(
		is_instance_valid(_editor_settings),
		"Cannot get AssetPlacerEditorSettings when none is loaded."
	)
	return _editor_settings


static func load_editor_settings(load_path := SAVE_PATH) -> void:
	if is_instance_valid(_save_timer):
		_save_editor_settings()

	var new_editor_settings := AssetPlacerEditorSettings.new()
	if ResourceLoader.exists(load_path, &"AssetPlacerEditorSettings"):
		new_editor_settings = load(load_path)

	var is_first_load := not is_instance_valid(_editor_settings)
	if is_first_load:
		_editor_settings = new_editor_settings
		_editor_settings.get_asset_palette()
		_connect_save()
	else:
		_disconnect_save()
		_move_signal_connections(new_editor_settings)

		_editor_settings = new_editor_settings
		_editor_settings.get_asset_palette()
		_editor_settings._emit_all_changed()

		_connect_save()


static func free_settings():
	if is_instance_valid(_save_timer):
		_save_editor_settings()

	if is_instance_valid(_editor_settings):
		_disconnect_save()
	_move_signal_connections(null)
	_editor_settings = null


static func _save_editor_settings():
	_save_timer.timeout.disconnect(_save_editor_settings)
	_save_timer = null

	assert(
		is_instance_valid(_editor_settings),
		"Cannot save AssetPlacerEditorSettings when none is loaded."
	)
	ResourceSaver.save(_editor_settings, SAVE_PATH)


static func _queue_save():
	if is_instance_valid(_save_timer):
		_save_timer.time_left = time_to_save
		return

	var mainloop := Engine.get_main_loop()
	assert(mainloop is SceneTree)

	_save_timer = (mainloop as SceneTree).create_timer(time_to_save)
	_save_timer.timeout.connect(_save_editor_settings)


static func _move_signal_connections(other: AssetPlacerEditorSettings):
	for _signal in _editor_settings.get_signal_list():
		for connection in _editor_settings.get_signal_connection_list(_signal["name"]):
			_editor_settings.disconnect(_signal["name"], connection["callable"])
			if is_instance_valid(other):
				other.connect(_signal["name"], connection["callable"])


static func _connect_save():
	_editor_settings.changed.connect(_queue_save)
	var pal := _editor_settings.get_asset_palette()
	_palette_forward_palette = pal
	pal.changed.connect(Callable(_editor_settings, &"emit_changed"))


static func _disconnect_save():
	_editor_settings.changed.disconnect(_queue_save)
	if is_instance_valid(_palette_forward_palette):
		var forward := Callable(_editor_settings, &"emit_changed")
		if _palette_forward_palette.changed.is_connected(forward):
			_palette_forward_palette.changed.disconnect(forward)
		_palette_forward_palette = null
