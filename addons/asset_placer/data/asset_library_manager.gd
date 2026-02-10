@tool
class_name AssetLibraryManager
extends RefCounted

## Singleton class to manage a single active AssetLibrary


static var _asset_library: AssetLibrary
static var _is_save_queued := false


static func get_asset_library() -> AssetLibrary:
	assert(
		is_instance_valid(_asset_library),
		"Cannot get AssetLibrary when none is loaded."
	)
	return _asset_library


static func load_asset_library(load_path: String) -> void:
	if _is_save_queued:
		_save_asset_library()

	var new_asset_library = AssetLibraryParser.load_library(load_path)
	_move_signal_connections(new_asset_library)
	_asset_library = new_asset_library

	# TODO Emit AssetLibrary signals to update UI

	# TODO Setup signal to watch when asset library needs to be saved.

	# TODO Emit library changed.


static func _save_asset_library():
	_is_save_queued = false

	assert(
		is_instance_valid(_asset_library),
		"Cannot save AssetLibrary when none is loaded."
	)

	_asset_library.save()


static func _move_signal_connections(new_asset_library: AssetLibrary) -> void:
	pass

