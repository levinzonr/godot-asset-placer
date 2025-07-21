extends RefCounted
class_name FolderRepository

var data_source: AssetLibraryDataSource

signal folder_changed

func _init():
	self.data_source = AssetLibraryDataSource.new()

func get_all() -> Array[AssetFolder]:
	return data_source.get_library().folders

func find(path: String)  -> AssetFolder:
	var folders = get_all()
	var folder = folders.find_custom(func(f: String): return f == path)
	return folders[folder]
	

func update(folder: AssetFolder):
	var library = data_source.get_library()
	var folders = library.folders.duplicate()
	var to_update_index = folders.find_custom(func(f): return f.path == folder.path)
	if to_update_index != -1:
		folders[to_update_index] = folder
		library.folders = folders
		data_source.save_libray(library)
	else:
		print("Did not find a folder to update")

func add(folder: String):
	var library := data_source.get_library()
	var duplicated_folders := library.folders.duplicate()
	var _folder = AssetFolder.new(folder)
	duplicated_folders.append(_folder)
	library.folders = duplicated_folders
	data_source.save_libray(library)
	folder_changed.emit()
	
func delete(folder: String):
	var folders = get_all()
	var to_delete = find(folder)
	if to_delete != null:
		var library := data_source.get_library()
		var duplicated_folders := library.folders.duplicate()
		duplicated_folders.erase(to_delete)
		library.folders = duplicated_folders
		data_source.save_libray(library)
		folder_changed.emit()
