class_name FolderPresenter
extends RefCounted

signal folders_loaded(folders: Array[AssetFolder])

var folder_repository: FolderRepository
var collection_repository: AssetCollectionRepository


func _init():
	folder_repository = FolderRepository.instance
	collection_repository = AssetCollectionRepository.instance


func _ready():
	folders_loaded.emit(folder_repository.get_all())

	folder_repository.folder_changed.connect(_reload_folders)
	collection_repository.collections_changed.connect(_reload_folders)


func _reload_folders():
	folders_loaded.emit(folder_repository.get_all())


func add_folder(path: String):
	if path.get_extension().is_empty():
		folder_repository.add(path)


func add_folders(paths: PackedStringArray):
	for path in paths:
		add_folder(path)
