extends RefCounted
class_name AssetLibraryDataSource

var _asset_lib_json := "user://asset_library.json"

func get_library() -> AssetLibrary:
	var file = FileAccess.open(_asset_lib_json, FileAccess.READ)
	if file == null:
		return AssetLibrary.new([], [])
	else:
		var data = JSON.parse_string(file.get_as_text())
		var folders_dicts: Array = data["folders"]
		var assets_dicts: Array = data["assets"]
		
		var folders: Array[AssetFolder]
		var assets: Array[AssetResource]
		
		for folder_dict in folders_dicts:
			var path = folder_dict["path"]
			var include_subfolders = folder_dict["include_subfolders"]
			var folder = AssetFolder.new(path, include_subfolders)
			folders.append(folder)
		
		for asset_dict in assets_dicts:
			var name = asset_dict["name"]
			var id = asset_dict["id"]
			var scene = load(id)
			var asset = AssetResource.new(scene, name)
			assets.append(asset)
		file.close()
		return AssetLibrary.new(assets, folders)
		
	
func save_libray(library: AssetLibrary):	
	if library:
		var assets_dict : Array[Dictionary] = []
		var folders_dict: Array[Dictionary] = [] 
		
		for folder in library.folders:
			folders_dict.append({
				"path": folder.path,
				"include_subfolders": folder.include_subfolders
			})
			
		for asset in library.items:
			assets_dict.append({
				"name": asset.name,
				"id": ResourceUID.path_to_uid(asset.scene.resource_path)
			})
		
		var lib_dict = {
			"assets": assets_dict,
			"folders": folders_dict
		}
		
		var json = JSON.stringify(lib_dict)
		var file = FileAccess.open(_asset_lib_json, FileAccess.WRITE)
		file.store_string(json)
		file.close()
		
	else:
		print("AssetLibraryDataSource: Cannot save null library.")
