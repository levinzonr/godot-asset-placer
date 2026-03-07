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
	add_assets_from_folder(folder.path, folder.include_subfolders, folder.get_rules())


func _sync_all():
	_clear_unreachable_assets()
	_clear_invalid_assets()
	for folder in AssetLibraryManager.get_asset_library().get_folders():
		_sync_folder(folder)


func add_assets_from_folder(
	folder_path: String, recursive: bool, rules: Array[AssetPlacerFolderRule]
):
	var lib := AssetLibraryManager.get_asset_library()
	var dir := DirAccess.open(folder_path)
	if not dir:
		push_warning("Could not open folder: %s" % folder_path)
		return

	var tags: Array[int] = []
	for file in dir.get_files():
		_scanned += 1
		var path := folder_path.path_join(file)
		var file_name = file.get_file()
		var passed_filter := true
		var uid = ResourceIdCompat.path_to_uid(path)

		if not AssetResource.is_file_supported(file):
			continue

		# Check if file passes all filters
		for rule in rules:
			if not rule.do_filter(file_name):
				passed_filter = false
				break

		if passed_filter:
			var asset := AssetResource.new(uid, file.get_file(), [], folder_path)
			var added = lib.add_asset(asset)

			if added:
				# New asset - apply after_added rules
				for rule in rules:
					asset = rule.do_after_asset_added(asset)
				lib.update_asset(asset)
				_added += 1
			elif rules.size() > 0:
				# Existing asset - apply after_added rules
				var existing = lib.get_asset(uid)
				if existing:
					for rule in rules:
						existing = rule.do_after_asset_added(existing)
					lib.update_asset(existing)
		else:
			# File doesn't pass filter - delete if exists
			var existing = lib.get_asset(uid)
			if existing:
				lib.remove_asset(existing)
				_removed += 1

	if recursive:
		for sub_dir in dir.get_directories():
			var path: String = folder_path.path_join(sub_dir)
			add_assets_from_folder(path, true, rules)


func _notify_scan_complete():
	if _added != 0 || _removed != 0:
		call_deferred("emit_signal", "sync_complete", _added, _removed, _scanned)
	_clear_data()


func _clear_unreachable_assets():
	var lib := AssetLibraryManager.get_asset_library()
	var assets: Array[AssetResource] = lib.get_assets().duplicate()
	for asset in assets:
		var path := asset.folder_path
		if path.is_empty():
			continue
		var folder := lib.get_folder(path)
		if folder == null or not _is_asset_reachable_from_folder(asset, folder):
			lib.remove_asset(asset)


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
	var assets: Array[AssetResource] = lib.get_assets().duplicate()
	for asset in assets:
		if not asset.has_resource():
			_removed += 1
			lib.remove_asset(asset)


func _clear_data():
	_removed = 0
	_added = 0
	_scanned = 0
