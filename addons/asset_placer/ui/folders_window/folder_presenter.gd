class_name FolderPresenter
extends RefCounted

signal folders_loaded(folder: Array[AssetFolder])

var sync: Synchronize

var _asset_library : AssetLibrary:
	get:
		return AssetLibraryManager.get_asset_library()


func _init():
	self.sync = Synchronize.new()


func ready():
	folders_loaded.emit(_asset_library.get_folders())

	_asset_library.folders_changed.connect(
		func():
			# Safer to call get_asset_library, rather than bind the lib we have now
			folders_loaded.emit(AssetLibraryManager.get_asset_library().get_folders())
	)


func delete_folder(folder: AssetFolder):
	_asset_library.delete_folder_by_path(folder.path)
	for asset in _asset_library.get_assets():
		if asset.folder_path == folder.path:
			_asset_library.remove_asset_by_id(asset.id)


func sync_folder(folder: AssetFolder):
	sync.sync_folder(folder)


func include_subfolders(include: bool, folder: AssetFolder):
	folder.include_subfolders = include
	_asset_library.update_folder(folder)


func add_folder(folder_path: String):
	if folder_path.get_extension().is_empty():
		var new_folder := AssetFolder.new(folder_path)
		_asset_library.add_folder(new_folder)


func add_folders(folders: PackedStringArray):
	for folder in folders:
		add_folder(folder)
