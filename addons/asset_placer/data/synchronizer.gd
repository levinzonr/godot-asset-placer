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
	_update_assets()
	add_assets_from_folder(folder)


func _sync_all():
	_update_assets()
	for folder in AssetLibraryManager.get_asset_library().get_folders():
		add_assets_from_folder(folder)


func add_assets_from_folder(folder: AssetFolder, override_path := ""):
	var folder_path := folder.path if override_path.is_empty() else override_path
	var lib := AssetLibraryManager.get_asset_library()
	var dir := DirAccess.open(folder_path)
	if not dir:
		push_warning("Could not open folder: %s" % folder_path)
		return

	for file in dir.get_files():
		_scanned += 1
		if not AssetResource.is_file_supported(file) or not folder.name_passes_filters(file):
			continue

		var uid = ResourceIdCompat.path_to_uid(folder_path.path_join(file))
		if not lib.has_asset_id(uid):
			var asset := AssetResource.new(
				uid, file, [], folder_path, -1, Time.get_unix_time_from_system()
			)
			for rule in folder.get_rules():
				asset = rule.do_after_asset_added(asset)
			if lib.add_asset(asset):
				_added += 1

	if folder.include_subfolders:
		for sub_dir in dir.get_directories():
			var path: String = folder_path.path_join(sub_dir)
			add_assets_from_folder(folder, path)


func _notify_scan_complete():
	if _added != 0 || _removed != 0:
		call_deferred("emit_signal", "sync_complete", _added, _removed, _scanned)
		# Since Synchronize can run on another thread we need to assure UI has latest updates.
		AssetLibraryManager.get_asset_library()._queue_emit_assets_changed.call_deferred()
	_clear_data()


func _update_assets():
	var lib := AssetLibraryManager.get_asset_library()
	var assets: Array[AssetResource] = lib.get_assets().duplicate()
	for asset in assets:
		if not _is_asset_valid(asset):
			_removed += 1
			lib.remove_asset(asset)
			continue

		for folder in lib.get_folders():
			if folder.has_asset(asset):
				for rule in folder.get_rules():
					asset = rule.do_after_asset_added(asset)
		lib.update_asset(asset)


func _is_asset_valid(asset: AssetResource):
	var lib := AssetLibraryManager.get_asset_library()
	return asset.has_resource() and lib.asset_has_folder(asset)


func _clear_data():
	_removed = 0
	_added = 0
	_scanned = 0
