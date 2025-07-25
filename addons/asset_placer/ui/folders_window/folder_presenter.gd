extends RefCounted
class_name FolderPresenter

signal folders_loaded(folder: Array[AssetFolder])

var folder_repository: FolderRepository
var asset_repository: AssetsRepository
var sync: Synchronize

func _init():
	self.folder_repository = FolderRepository.new()
	self.asset_repository = AssetsRepository.new()
	self.sync = Synchronize.new(self.folder_repository, self.asset_repository)


func _ready():
	folders_loaded.emit(folder_repository.get_all())
	
	folder_repository.folder_changed.connect(func():
		var folders = folder_repository.get_all()
		folders_loaded.emit(folders)
	)


func delete_folder(folder: AssetFolder):
	folder_repository.delete(folder.path)

func sync_folder(folder: AssetFolder):
	sync.sync_folder(folder)

func include_subfolders(include: bool, folder: AssetFolder):
	folder.include_subfolders = include
	folder_repository.update(folder)

func add_folder(folder: String):
	folder_repository.add(folder)	


func is_file_supported(file: String)	->  bool:
	return file.ends_with(".tscn") || file.ends_with(".glb") || file.ends_with(".fbx")
