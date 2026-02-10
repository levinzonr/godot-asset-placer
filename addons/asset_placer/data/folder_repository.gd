class_name FolderRepository
extends RefCounted

signal folder_changed

static var instance: FolderRepository


func _init():
	instance = self


func get_all() -> Array[AssetFolder]:
	return AssetLibraryParser.load_library().get_folders()


func find(path: String) -> AssetFolder:
	var folders = get_all()
	var folder: int = -1
	for f in len(folders):
		if folders[f].path == path:
			folder = f
			break
	return folders[folder]


func update(folder: AssetFolder):
	var library := AssetLibraryParser.load_library()
	var folders = library.get_folders().duplicate()
	var to_update_index = folders.find_custom(func(f): return f.path == folder.path)
	if to_update_index != -1:
		folders[to_update_index] = folder
		library._folders = folders
		AssetLibraryParser.save_libray(library)


func add(folder: String, incldude_subfolders: bool = true):
	var library := AssetLibraryParser.load_library()
	var duplicated_folders := library.get_folders().duplicate()

	if exists(folder):
		push_warning("Folder with this path already exists")
		return

	var new_folder = AssetFolder.new(folder, incldude_subfolders)
	duplicated_folders.append(new_folder)
	library._folders = duplicated_folders
	AssetLibraryParser.save_libray(library)
	folder_changed.emit()


func exists(path: String) -> bool:
	for folder in get_all():
		if folder.path == path:
			return true
		if folder.include_subfolders && path.contains(folder.path):
			return true

	return false


func delete(folder: String):
	var library := AssetLibraryParser.load_library()
	library._folders = library.get_folders().filter(func(f): return f.path != folder)
	AssetLibraryParser.save_libray(library)
	folder_changed.emit()
