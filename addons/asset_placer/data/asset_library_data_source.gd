extends RefCounted
class_name AssetLibraryDataSource

var _asset_lib_json: String

func _init(asset_lib_path: String = "user://asset_library.json"):
	_asset_lib_json = asset_lib_path

func get_library() -> AssetLibrary:
	var file = FileAccess.open(_asset_lib_json, FileAccess.READ)
	if file == null || file.get_as_text().is_empty():
		return AssetLibrary.new([], [], [])
	else:
		var data = JSON.parse_string(file.get_as_text())
		var folders_dicts: Array = data["folders"]
		var assets_dicts: Array = data["assets"]
		var collections_dict: Array = data["collections"]
		
		var folders: Array[AssetFolder]
		var assets: Array[AssetResource]
		var collections: Array[AssetCollection]
		
		for folder_dict in folders_dicts:
			var path = folder_dict["path"]
			var include_subfolders = folder_dict["include_subfolders"]
			var folder = AssetFolder.new(path, include_subfolders)
			folders.append(folder)
		
		for asset_dict in assets_dicts:
			var name = asset_dict["name"]
			var id = asset_dict["id"]
			var folder_path := ""
			if asset_dict.has("folder_path"): 
				folder_path = asset_dict["folder_path"]
			var dict = asset_dict as Dictionary
			var tags: Array[int] = []
			if dict.has("tags"):
				var raw_tags = dict["tags"]
				for tag in raw_tags:
					tags.append(int(tag))
			var asset = AssetResource.new(id, name, tags, folder_path)
			assets.append(asset)
		
		for collection_dict in collections_dict:
			var name = collection_dict["name"]
			var color_string: String = collection_dict["color"]
			var color = Color.from_string(color_string, Color.AQUA)
			var id: int = collection_dict["id"]
			collections.append(AssetCollection.new(name, color, id))
			
		file.close()
		return AssetLibrary.new(assets, folders, collections)
		
	
func save_libray(library: AssetLibrary):	
	if library:
		var assets_dict : Array[Dictionary] = []
		var folders_dict: Array[Dictionary] = []
		var collections_dict: Array[Dictionary] = []
		
		for folder in library.folders:
			folders_dict.append({
				"path": folder.path,
				"include_subfolders": folder.include_subfolders
			})
			
		for asset in library.items:
			assets_dict.append({
				"name": asset.name,
				"id": asset.id,
				"tags": asset.tags,
				"folder_path": asset.folder_path
			})
		
		for collection in library.collections:
			collections_dict.append({
				"name": collection.name,
				"color": collection.backgroundColor.to_html(),
				"id": collection.id
			})	
		
		var lib_dict = {
			"assets": assets_dict,
			"folders": folders_dict,
			"collections": collections_dict,
			"version": 2
		}
		
		var json = JSON.stringify(lib_dict)
		var file = FileAccess.open(_asset_lib_json, FileAccess.WRITE)
		file.store_string(json)
		file.close()
		
	else:
		push_error("AssetLibraryDataSource: Cannot save null library.")
