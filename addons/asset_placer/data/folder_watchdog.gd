extends RefCounted
class_name FileSystemWatchDog

var folder_repository: FolderRepository
var file_system: EditorFileSystem

func _init(folder_repository: FolderRepository):
	self.folder_repository = folder_repository
	self.file_system = EditorInterface.get_resource_filesystem()
	file_system.resources_reload.connect(func(a): print("Loaded: " + str(a)))
	file_system.filesystem_changed.connect(react_to_files_change)
	file_system.resources_reimported.connect(func(a): print("Rein:" + str(a)))
	var a = folder_repository.get_all()[0]
	var dir = DirAccess.open(a.path)
	
	
	
func react_to_files_change():
	print("File system changed")
