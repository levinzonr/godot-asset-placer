extends RefCounted
class_name FolderRepository

var _library: AssetLibrary

signal folder_changed

func _init(library: AssetLibrary):
	self._library = library
	

func get_all() -> Array[String]:
	return _library.folders
	

func add(folder: String):
	var duplicated_folders := _library.folders.duplicate()
	duplicated_folders.append(folder)
	_library.folders = duplicated_folders
	ResourceSaver.save(_library)	
	folder_changed.emit()
	
func delete(folder: String):
	var duplicated_folders = _library.folders.duplicate()
	duplicated_folders.erase(folder)
	_library.folders = duplicated_folders
	ResourceSaver.save(_library)
	folder_changed.emit()
