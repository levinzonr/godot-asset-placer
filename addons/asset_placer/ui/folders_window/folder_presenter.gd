class_name FolderPresenter
extends RefCounted

signal folders_loaded(folders: Array[AssetFolder])

var collection_repository: AssetCollectionRepository


func _init():
	collection_repository = AssetCollectionRepository.instance


func _ready():
	var lib := AssetLibraryManager.get_asset_library()
	folders_loaded.emit(lib.get_folders())

	lib.folders_changed.connect(_reload_folders)
	collection_repository.collections_changed.connect(_reload_folders)


func _reload_folders():
	folders_loaded.emit(AssetLibraryManager.get_asset_library().get_folders())


func add_folder(path: String):
	if path.get_extension().is_empty():
		AssetLibraryManager.get_asset_library().add_folder(path)


func add_folders(paths: PackedStringArray):
	for path in paths:
		add_folder(path)
