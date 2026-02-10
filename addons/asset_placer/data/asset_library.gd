@tool
class_name AssetLibrary
extends RefCounted

signal assets_changed
signal folders_changed
signal collections_changed

var _assets: Array[AssetResource] = []
var _folders: Array[AssetFolder] = []
var _collections: Array[AssetCollection] = []

var _is_assets_changed_queued := false
var _is_folders_changed_queued := false
var _is_collections_changed_queued := false
var _is_signal_queued: bool:
	get:
		return _is_assets_changed_queued or _is_folders_changed_queued or _is_collections_changed_queued

func _init(
	assets: Array[AssetResource], folders: Array[AssetFolder], collections: Array[AssetCollection]
):
	_assets = assets
	_folders = folders
	_collections = collections


func get_assets() -> Array[AssetResource]:
	return _assets


func get_folders() -> Array[AssetFolder]:
	return _folders


func get_collections() -> Array[AssetCollection]:
	return _collections


## Assets


func get_asset(uid: String) -> AssetResource:
	for asset in _assets:
		if asset.id == uid:
			return asset
	return null

# TODO change to accept AssetResource instead of its parameters
# TODO Also change init parameters of AssetResource to be more lenient
func add_asset(scene_path: String, tags: Array[int] = [], folder_path: String = "") -> AssetResource:
	if not is_scene_file_supported(scene_path):
		return null

	var id = ResourceIdCompat.path_to_uid(scene_path)
	if has_asset_id(id):
		return null

	var asset := AssetResource.new(id, scene_path.get_file(), tags, folder_path)
	_assets.append(asset)
	_queue_emit_assets_changed()

	return asset


func remove_asset(asset: AssetResource):
	remove_asset_by_id(asset.id)


# TODO find_custom is not supported in 4.3. Change to normal loop.
func remove_asset_by_id(asset_id: String):
	var index := _assets.find_custom((func(a: AssetResource): return a.id == asset_id))
	assert(index != -1, "Cannot remove asset with id %s as it doesn't exist" % asset_id)

	_assets.remove_at(index)
	_queue_emit_assets_changed()


# TODO find_custom is not supported in 4.3. Change to normal loop.
func update_asset(asset: AssetResource):
	var index = _assets.find_custom((func(a: AssetResource): return a.id == asset.id))
	assert(
		index != -1,
		"Cannot update asset with with id %s, as it doesn't exist" % asset.id
	)
	_assets[index] = asset
	_queue_emit_assets_changed()


func has_asset_id(asset_id: String):
	return _assets.any(func(item: AssetResource): return item.id == asset_id)


func has_asset_path(asset_path: String):
	return _assets.any(func(item: AssetResource): return item.get_path() == asset_path)


# TODO Should be in AssetResource,
func is_scene_file_supported(file: String) -> bool:
	var extension := file.get_extension()
	var supported_extensions := ["tscn", "glb", "fbx", "obj", "gltf", "blend"]
	return extension in supported_extensions


func index_of_asset(asset: AssetResource):
	var idx: int = -1
	for a in len(_assets):
		if _assets[a].id == asset.id:
			idx = a
			break
	return idx


func get_highest_id() -> int:
	var highest := 0
	for collection in _collections:
		if collection.id > highest:
			highest = collection.id
	return highest


## Signals


func _emit_queued_signals():
	if _is_assets_changed_queued:
		assets_changed.emit()
	if _is_folders_changed_queued:
		folders_changed.emit()
	if _is_collections_changed_queued:
		collections_changed.emit()

	_is_assets_changed_queued = false
	_is_folders_changed_queued = false
	_is_collections_changed_queued = false


func _queue_emit_assets_changed():
	if not _is_signal_queued:
		_emit_queued_signals.call_deferred()
	_is_assets_changed_queued = true


func _queue_emit_folders_changed():
	if not _is_signal_queued:
		_emit_queued_signals.call_deferred()
	_is_folders_changed_queued = true


func _queue_emit_collections_changed():
	if not _is_signal_queued:
		_emit_queued_signals.call_deferred()
	_is_collections_changed_queued = true


## Only used by AssetLibraryManager
func _emit_all_changed():
	assets_changed.emit()
	folders_changed.emit()
	collections_changed.emit()
