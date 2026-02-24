@tool
class_name AssetLibraryManager
extends RefCounted

## Singleton class to manage a single active AssetLibrary

## Time between AssetLibrary change and save to disk in seconds.
static var time_to_save: float = 1.0

static var _asset_library: AssetLibrary
static var _timer: SceneTreeTimer


static func get_asset_library() -> AssetLibrary:
	assert(
		is_instance_valid(_asset_library),
		"Cannot get AssetLibrary when none is loaded."
	)
	return _asset_library


static func load_asset_library(load_path: String) -> void:
	if is_instance_valid(_timer):
		_save_asset_library()

	var new_asset_library := AssetLibraryParser.load_library(load_path)

	var is_first_load := not is_instance_valid(_asset_library)
	if is_first_load:
		_asset_library = new_asset_library
		_connect_save()
	else:
		_disconnect_save()
		_move_signal_connections(new_asset_library)

		_asset_library = new_asset_library
		_asset_library._emit_all_changed()

		_connect_save()


static func free_library():
	if is_instance_valid(_timer):
		_save_asset_library()

	_move_signal_connections(null)
	_asset_library = null


static func _save_asset_library():
	_timer.timeout.disconnect(_save_asset_library)
	_timer = null

	assert(
		is_instance_valid(_asset_library),
		"Cannot save AssetLibrary when none is loaded."
	)

	_asset_library.save()


static func _queue_save():
	if is_instance_valid(_timer):
		_timer.time_left = time_to_save
		return

	var mainloop := Engine.get_main_loop()
	assert(mainloop is SceneTree)

	_timer = (mainloop as SceneTree).create_timer(time_to_save)
	_timer.timeout.connect(_save_asset_library)


static func _move_signal_connections(other: AssetLibrary):
	for _signal in _asset_library.get_signal_list():
		for connection in _asset_library.get_signal_connection_list(_signal["name"]):
			_asset_library.disconnect(_signal["name"], connection["callable"])
			if is_instance_valid(other):
				other.connect(_signal["name"], connection["callable"])


static func _connect_save():
	_asset_library.assets_changed.connect(_queue_save)
	_asset_library.folders_changed.connect(_queue_save)
	_asset_library.collections_changed.connect(_queue_save)


static func _disconnect_save():
	_asset_library.assets_changed.disconnect(_queue_save)
	_asset_library.folders_changed.disconnect(_queue_save)
	_asset_library.collections_changed.disconnect(_queue_save)
