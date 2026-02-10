class_name Synchronize
extends RefCounted

signal sync_state_change(running: bool)
signal sync_complete(added: int, removed: int, scanned: int)

static var instance: Synchronize

var sync_running = false:
	set(value):
		sync_running = value
		call_deferred("emit_signal", "sync_state_change", value)

var _added = 0
var _removed = 0
var _scanned = 0


func _init():
	instance = self


func sync_all():
	if sync_running:
		push_error("Sync is already running")
		return

	AssetPlacerAsync.instance.enqueue(
		func():
			sync_running = true
			_sync_all()
			_notify_scan_complete()
			sync_running = false
	)


func sync_folder(folder: AssetFolder):
	if sync_running:
		push_error("Sync is already running")
		return

	AssetPlacerAsync.instance.enqueue(
		func():
			sync_running = true
			_sync_folder(folder)
			_notify_scan_complete()
			sync_running = false
	)


func _sync_folder(folder: AssetFolder):
	_clear_invalid_assets()
	_clear_unreachable_assets()
	add_assets_from_folder(folder.path, folder.include_subfolders)


func _sync_all():
	_clear_unreachable_assets()
	_clear_invalid_assets()
	for folder in AssetLibraryManager.get_asset_library().get_folders():
		_sync_folder(folder)


func add_assets_from_folder(folder_path: String, recursive: bool):
	var lib := AssetLibraryManager.get_asset_library()
	var dir := DirAccess.open(folder_path)
	var tags: Array[int] = []
	for file in dir.get_files():
		_scanned += 1
		var path = folder_path.path_join(file)
		if lib.add_asset(path, tags, folder_path):
			_added += 1

	if recursive:
		for sub_dir in dir.get_directories():
			var path: String = folder_path.path_join(sub_dir)
			add_assets_from_folder(path, true)


func _notify_scan_complete():
	if _added != 0 || _removed != 0:
		call_deferred("emit_signal", "sync_complete", _added, _removed, _scanned)
	_clear_data()


func _clear_unreachable_assets():
	var lib := AssetLibraryManager.get_asset_library()
	for asset in lib.get_assets():
		var path := asset.folder_path
		if path.is_empty():
			continue
		var folder := lib.get_folder(path)
		if folder == null or not _is_asset_reachable_from_folder(asset, folder):
			lib.remove_asset_by_id(asset.id)


func _is_asset_reachable_from_folder(asset: AssetResource, folder: AssetFolder) -> bool:
	var asset_folder_path := asset.folder_path
	var folder_path := folder.path
	if folder_path == asset_folder_path:
		return true

	if folder.include_subfolders and asset_folder_path.begins_with(folder_path + "/"):
		return true

	return false


func _clear_invalid_assets():
	var lib := AssetLibraryManager.get_asset_library()
	for asset in lib.get_assets():
		if not asset.has_resource():
			_removed += 1
			lib.remove_asset_by_id(asset.id)


func _clear_data():
	_removed = 0
	_added = 0
	_scanned = 0
