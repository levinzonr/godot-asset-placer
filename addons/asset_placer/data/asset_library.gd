@tool
class_name AssetLibrary
extends RefCounted

signal assets_changed
signal folders_changed
signal collections_changed

var _assets: Array[AssetResource] = []
var _folders: Array[AssetFolder] = []
var _collections: Array[AssetCollection] = []

var _highest_collection_id: int

var _is_assets_changed_queued := false
var _is_folders_changed_queued := false
var _is_collections_changed_queued := false
var _is_signal_queued: bool:
	get:
		return _is_assets_changed_queued or _is_folders_changed_queued or _is_collections_changed_queued

func _init(
	assets: Array[AssetResource],
	folders: Array[AssetFolder],
	collections: Array[AssetCollection],
):
	_assets = assets
	_folders = folders
	_collections = collections
	_highest_collection_id = _get_highest_collection_id()


func get_assets() -> Array[AssetResource]:
	return _assets


func get_folders() -> Array[AssetFolder]:
	return _folders


func get_collections() -> Array[AssetCollection]:
	return _collections


## Assets

func has_asset_id(asset_id: String):
	return _assets.any(func(item: AssetResource): return item.id == asset_id)


func has_asset_path(asset_path: String):
	return _assets.any(func(item: AssetResource): return item.get_path() == asset_path)


# TODO change to accept AssetResource instead of its parameters
# TODO Also change init parameters of AssetResource to be more lenient
func add_asset(scene_path: String, tags: Array[int] = [], folder_path: String = "") -> bool:
	if not is_scene_file_supported(scene_path):
		return false

	var id = ResourceIdCompat.path_to_uid(scene_path)
	if has_asset_id(id):
		return false

	var asset := AssetResource.new(id, scene_path.get_file(), tags, folder_path)
	_assets.append(asset)
	_queue_emit_assets_changed()

	return true


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


func find_asset_by_uid(uid: String) -> AssetResource:
	for asset in _assets:
		if asset.id == uid:
			return asset
	return null


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


## Folders

func get_folder(path: String) -> AssetFolder:
	if _folders.is_empty():
		return null
	var folder: int = -1
	for f in len(_folders):
		if _folders[f].path == path:
			folder = f
			break
	return _folders[folder]


# TODO Should take in a AssetFolder
func add_folder(folder: String, incldude_subfolders: bool = true):
	if has_folder_path(folder):
		push_warning("Folder with this path already exists")
		return

	var new_folder := AssetFolder.new(folder, incldude_subfolders)
	_folders.append(new_folder)
	_queue_emit_folders_changed()


func remove_folder_by_path(folder_path: String):
	_folders = _folders.filter(func(f): return f.path != folder_path)
	_queue_emit_folders_changed()


# TODO find_custom is not supported in 4.3. Change to normal loop.
func update_folder(folder: AssetFolder):
	var to_update_index = _folders.find_custom(func(f): return f.path == folder.path)
	assert(
		to_update_index != -1,
		"Cannot update folder with path %s as it's not in the current AssetLibrary." % folder.path
	)
	_folders[to_update_index] = folder
	_queue_emit_folders_changed()


func has_folder_path(path: String) -> bool:
	for folder in _folders:
		if folder.path == path:
			return true
		if folder.include_subfolders && path.contains(folder.path):
			return true

	return false


## Collections

# TODO Should take in an AssetCollection
func add_collection(name: String, color: Color):
	_highest_collection_id += 1
	assert(
		_highest_collection_id > _get_highest_collection_id(),
		"Cannot create collection with id %s as it already exists." % _highest_collection_id
	)
	var collection := AssetCollection.new(name, color, _highest_collection_id)
	_collections.append(collection)
	_queue_emit_collections_changed()


func delete_collection(id: int):
	var new_collections: Array[AssetCollection] = _collections.filter(func(c): return c.id != id)
	_collections = new_collections

	for asset in _assets:
		var updated_tags: Array[int] = asset.tags.filter(func(f): return f != id)
		if updated_tags != asset.tags:
			asset.tags = updated_tags

	_queue_emit_collections_changed()


func update_collection(collection: AssetCollection):
	for i in _collections.size():
		if _collections[i].id == collection.id:
			_collections[i] = collection
	_queue_emit_collections_changed()


# TODO Make private since its not needed anywhere else.
func _get_highest_collection_id() -> int:
	var highest := 0
	for collection in _collections:
		if collection.id > highest:
			highest = collection.id
	return highest


## Signals


func _emit_queued_signals():
	print("Checking emit queue")
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
