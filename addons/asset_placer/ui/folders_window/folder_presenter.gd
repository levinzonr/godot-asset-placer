class_name FolderPresenter
extends RefCounted

signal folders_loaded(folder: Array[AssetFolder])

var sync: Synchronize


func _init():
	self.sync = Synchronize.new()


func _ready():
	var lib := AssetLibraryManager.get_asset_library()
	folders_loaded.emit(lib.get_folders())

	lib.folders_changed.connect(
		func():
			# Safer to call get_asset_library, rather than bind the lib we have now
			folders_loaded.emit(AssetLibraryManager.get_asset_library().get_folders())
	)


func delete_folder(folder: AssetFolder):
	var lib := AssetLibraryManager.get_asset_library()
	lib.remove_folder_by_path(folder.path)
	for asset in lib.get_assets():
		if asset.folder_path == folder.path:
			lib.remove_asset_by_id(asset.id)


func sync_folder(folder: AssetFolder):
	sync.sync_folder(folder)


func include_subfolders(include: bool, folder: AssetFolder):
	folder.include_subfolders = include
	AssetLibraryManager.get_asset_library().update_folder(folder)


func add_folder(folder_path: String):
	if folder_path.get_extension().is_empty():
		AssetLibraryManager.get_asset_library().add_folder(folder_path)


func add_folders(folders: PackedStringArray):
	for folder in folders:
		add_folder(folder)


func is_file_supported(file: String) -> bool:
	return file.ends_with(".tscn") || file.ends_with(".glb") || file.ends_with(".fbx")
