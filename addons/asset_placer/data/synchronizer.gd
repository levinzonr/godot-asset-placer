extends RefCounted
class_name Synchronize

var folder_repository: FolderRepository
var asset_repository: AssetsRepository

static var instance: Synchronize

signal sync_state_change(running: bool)
signal sync_complete(added: int, removed: int, scanned: int)

var _added = 0
var _removed = 0
var _scanned = 0

var sync_running = false:
	set(value):
		sync_running = value
		call_deferred("emit_signal", "sync_state_change", value)

func _init(folders_repository: FolderRepository, assets_repository: AssetsRepository):
	self.asset_repository = assets_repository
	self.folder_repository = folders_repository
	instance = self

func sync_all():
	
	if sync_running:
		push_error("Sync is already running")
		return
	
	AssetPlacerAsync.instance.enqueue(func():
		sync_running = true
		_sync_all()
		_notify_scan_complete()
		sync_running = false
	)

func sync_folder(folder: AssetFolder):
	
	if sync_running:
		push_error("Sync is already running")
		return
	
	AssetPlacerAsync.instance.enqueue(func():
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
	for folder in folder_repository.get_all():
		_sync_folder(folder)

func add_assets_from_folder(folder_path: String, recursive: bool):
	var dir = DirAccess.open(folder_path)
	var tags : Array[int] = []
	for file in dir.get_files():
		_scanned += 1
		var path = folder_path + "/" + file
		if asset_repository.add_asset(path, tags, folder_path):
			_added += 1
		
	if recursive:
		for sub_dir in dir.get_directories():
			var path: String = folder_path + "/" + sub_dir
			add_assets_from_folder(path, true)


func _notify_scan_complete():
	if _added != 0 || _removed != 0:
		call_deferred("emit_signal", "sync_complete", _added, _removed, _scanned)
	_clear_data()


func _clear_unreachable_assets():
	for asset in asset_repository.get_all_assets():
		var path = asset.folder_path
		if not path.is_empty():
			var folder = folder_repository.find(path)
			if folder == null:
				# remove asset if folder associated with that asset no longer exists
				asset_repository.delete(asset.id)
			elif not _is_asset_reachable_from_folder(asset, folder):
				asset_repository.delete(asset.id)
			
func _is_asset_reachable_from_folder(asset: AssetResource, folder: AssetFolder) -> bool:
	var asset_folder_path := asset.folder_path
	var folder_path := folder.path
	if folder_path == asset_folder_path:
		return true

	if folder.include_subfolders and asset_folder_path.begins_with(folder_path + "/"):
		return true
	
	return false
				
			
func _clear_invalid_assets():
	for asset in asset_repository.get_all_assets():
		if asset.scene == null:
			_removed += 1 
			asset_repository.delete(asset.id)

func _clear_data():
	_removed = 0
	_added = 0
	_scanned = 0		
			
