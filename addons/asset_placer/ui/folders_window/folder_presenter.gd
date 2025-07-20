extends RefCounted
class_name FolderPresenter

signal folders_loaded(folder: Array[String])

var folder_repository: FolderRepository
var asset_repository: AssetsRepository

func _init():
	var lib = load("res://addons/asset_placer/data/asset_library.tres")
	self.folder_repository = FolderRepository.new(lib)
	self.asset_repository = AssetsRepository.new(lib)


func _ready():
	folders_loaded.emit(folder_repository.get_all())
	
	folder_repository.folder_changed.connect(func():
		var folders = folder_repository.get_all()
		folders_loaded.emit(folders)
	)


func delete_folder(folder: String):
	folder_repository.delete(folder)

func sync_folder(folder: String):
	var dir = DirAccess.open(folder)
	for file in dir.get_files():
		if is_file_supported(file):
			var path = folder + "/" + file
			asset_repository.add_asset(path)


func add_folder(folder: String):
	folder_repository.add(folder)	


func is_file_supported(file: String)	->  bool:
	return file.ends_with(".tscn") || file.ends_with(".glb") || file.ends_with(".fbx")
