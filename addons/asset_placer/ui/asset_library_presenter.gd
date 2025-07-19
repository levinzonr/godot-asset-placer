extends RefCounted
class_name AssetLibraryPresenter

var library: AssetLibrary
var folder_repository: FolderRepository
var assets_repository: AssetsRepository

signal assets_loaded(assets: Array[AssetResource])

func _init():
	self.library = load("res://addons/asset_placer/data/asset_library.tres")
	self.folder_repository = FolderRepository.new(library)
	self.assets_repository = AssetsRepository.new(library)
	library.changed.connect(func(): 
		print("Changes in library")
		self.assets_loaded.emit(self.assets_repository.get_all_assets())
	)

func on_ready():
	assets_loaded.emit(library.items)

func add_asset_folder(path: String):
	folder_repository.add(path)


func sync():
	for folder in folder_repository.get_all():
		var dir = DirAccess.open(folder)
		for file in dir.get_files():
			if is_file_supported(file):
				var path = folder + "/" + file
				assets_repository.add_asset(path)
				
			

func is_file_supported(file: String)	->  bool:
	return file.ends_with(".tscn") || file.ends_with(".glb")
