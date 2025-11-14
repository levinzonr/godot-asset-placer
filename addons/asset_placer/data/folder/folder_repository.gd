extends RefCounted
class_name FolderRepository

var data_source: AssetLibraryDataSource

static var instance: FolderRepository

	
signal folder_changed

func _init(data_source: AssetLibraryDataSource):
	self.data_source = data_source
	instance = self

func get_all() -> Array[AssetFolder]:
	return data_source.get_library().folders

func find(path: String)  -> AssetFolder:
	var folders = get_all()
	var folder:int = -1; for f in len(folders): if folders[f].path == path: folder = f; break
	return folders[folder]
	

func update(folder: AssetFolder):
	var library = data_source.get_library()
	var folders = library.folders.duplicate()
	var to_update_index = folders.find_custom(func(f): return f.path == folder.path)
	if to_update_index != -1:
		folders[to_update_index] = folder
		library.folders = folders
		data_source.save_libray(library)

func add(folder: String, incldude_subfolders: bool = true):
	var library := data_source.get_library()
	var duplicated_folders := library.folders.duplicate()
	
	if exists(folder):
		push_warning("Folder with this path already exists")
		return
	
	var _folder = AssetFolder.new(folder, incldude_subfolders)
	duplicated_folders.append(_folder)
	library.folders = duplicated_folders
	data_source.save_libray(library)
	folder_changed.emit()

func exists(path: String) -> bool:
	for folder in get_all():
		if folder.path == path:
			return true
		if folder.include_subfolders && path.contains(folder.path):
			return true
		
	return false
func delete(folder: String):
	var library := data_source.get_library()
	library.folders = library.folders.filter(func(f): return f.path != folder)
	data_source.save_libray(library)
	folder_changed.emit()
