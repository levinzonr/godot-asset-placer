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
	if ResourceLoader.exists(USER_DATA_SAVE_PATH, "AssetPlacerOptions"):
		_loaded_options = load(USER_DATA_SAVE_PATH)
	else:
		_loaded_options = AssetPlacerOptions.new()

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
