class_name FolderPresenter
extends RefCounted

signal folders_loaded(folder: Array[AssetFolder])

var folder_repository: FolderRepository
var sync: Synchronize


func _init():
	self.folder_repository = FolderRepository.instance
	self.sync = Synchronize.new(self.folder_repository)


func _ready():
	folders_loaded.emit(folder_repository.get_all())

	folder_repository.folder_changed.connect(
		func():
			var folders = folder_repository.get_all()
			folders_loaded.emit(folders)
	)


func delete_folder(folder: AssetFolder):
	var lib := AssetLibraryManager.get_asset_library()
	folder_repository.delete(folder.path)
	for asset in lib.get_assets():
		if asset.folder_path == folder.path:
			lib.remove_asset_by_id(asset.id)


func sync_folder(folder: AssetFolder):
	sync.sync_folder(folder)


func include_subfolders(include: bool, folder: AssetFolder):
	folder.include_subfolders = include
	folder_repository.update(folder)


func add_folder(folder: String):
	if folder.get_extension().is_empty():
		folder_repository.add(folder)


func add_folders(folders: PackedStringArray):
	for folder in folders:
		add_folder(folder)


func is_file_supported(file: String) -> bool:
	return file.ends_with(".tscn") || file.ends_with(".glb") || file.ends_with(".fbx")
