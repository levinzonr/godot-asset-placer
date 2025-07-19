extends Node
class_name FolderRepository

var _library: AssetLibrary

func _init(library: AssetLibrary):
	self._library = library
	

func get_all() -> Array[StringName]:
	return _library.folders
	

func add(folder: StringName):
	var duplicated_folders := _library.folders.duplicate()
	duplicated_folders.append(folder)
	_library.folders = duplicated_folders
	ResourceSaver.save(_library)	
		
