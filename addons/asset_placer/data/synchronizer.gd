extends RefCounted
class_name Synchronize

var folder_repository: FolderRepository
var asset_repository: AssetsRepository

func _init(folders_repository: FolderRepository, assets_repository: AssetsRepository):
	self.asset_repository = assets_repository
	self.folder_repository = folders_repository
	

func sync_folder(folder: AssetFolder):
	sync_folder_path(folder.path, folder.include_subfolders)

func sync_all():
	for folder in folder_repository:
		sync_folder(folder)	

func sync_folder_path(folder_path: String, recursive: bool):
	var dir = DirAccess.open(folder_path)
	for file in dir.get_files():
		if is_file_supported(file):
			var path = folder_path + "/" + file
			asset_repository.add_asset(path)	
		
	if recursive:
		for sub_dir in dir.get_directories():
			var path: String = folder_path + "/" + sub_dir
			sync_folder_path(path, true)
	
func is_file_supported(file: String)	->  bool:
	return file.ends_with(".tscn") || file.ends_with(".glb") || file.ends_with(".fbx")
