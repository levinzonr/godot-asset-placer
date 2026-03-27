@tool
class_name AssetPlacerOptionsManager
extends RefCounted

const USER_DATA_SAVE_PATH := "user://asset_placer_options.tres"
## Time between AssetPlacerOptions change and save to disk in seconds.
const TIME_TO_SAVE: float = 1.0

static var _loaded_options: AssetPlacerOptions
static var _save_timer: SceneTreeTimer


static func get_options():
	return _loaded_options


static func load_options():
	var is_first_load := not is_instance_valid(_loaded_options)
	if not is_first_load and is_instance_valid(_save_timer):
		_save_options()

	var new_options := AssetPlacerOptions.new()
	if ResourceLoader.exists(USER_DATA_SAVE_PATH, "AssetPlacerOptions"):
		new_options = load(USER_DATA_SAVE_PATH)

	if is_first_load:
		_loaded_options = new_options
		_loaded_options.changed.connect(_queue_save)
	else:
		_loaded_options.changed.disconnect(_queue_save)
		_move_signal_connections(new_options)

		_loaded_options = new_options
		_loaded_options.emit_changed()

		_loaded_options.changed.connect(_queue_save)


static func _queue_save():
	if is_instance_valid(_save_timer):
		_save_timer.time_left = TIME_TO_SAVE
		return

	var mainloop := Engine.get_main_loop()
	assert(mainloop is SceneTree)

	_save_timer = (mainloop as SceneTree).create_timer(TIME_TO_SAVE)
	_save_timer.timeout.connect(_save_options)


static func _save_options():
	_save_timer.timeout.disconnect(_save_options)
	_save_timer = null

	ResourceSaver.save(_loaded_options, USER_DATA_SAVE_PATH)


static func _move_signal_connections(other: AssetPlacerOptions):
	for _signal in _loaded_options.get_signal_list():
		for connection in _loaded_options.get_signal_connection_list(_signal["name"]):
			_loaded_options.disconnect(_signal["name"], connection["callable"])
			if is_instance_valid(other):
				other.connect(_signal["name"], connection["callable"])
