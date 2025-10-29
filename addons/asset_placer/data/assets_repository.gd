extends RefCounted
class_name AssetsRepository

var data_source: AssetLibraryDataSource

static var instance: AssetsRepository

signal assets_changed

func _init(data_source: AssetLibraryDataSource):
	self.data_source = data_source
	instance = self
	
func get_all_assets() -> Array[AssetResource]:
	return data_source.get_library().items

func exists(assetId: String):
	return get_all_assets().any(func(item: AssetResource):
		return item.id == assetId
	)

func delete(assetId: String):
	var lib = data_source.get_library()
	var assets = lib.items.filter(func(a): return a.id != assetId)
	lib.items = assets
	data_source.save_libray(lib)
	call_deferred("emit_signal", "assets_changed")

func find_by_uid(uid: String) -> AssetResource:
	for asset in get_all_assets():
		if asset.id == uid:
			return asset
	return null	

func update(asset: AssetResource):
	var lib = data_source.get_library()
	var index = lib.index_of_asset(asset)
	if index != -1:
		lib.items[index] = asset
		data_source.save_libray(lib)
		call_deferred("emit_signal", "assets_changed")
	

func add_asset(scene_path: String, tags: Array[int] = [], folder_path: String = "") -> bool:
	if not is_file_supported(scene_path.get_file()):
		return false
	
	var library = data_source.get_library()
	var id = ResourceIdCompat.path_to_uid(scene_path)
	if exists(id):
		return false
	var asset = AssetResource.new(id, scene_path.get_file(), tags, folder_path)	
	var duplicated_items = library.items.duplicate()
	duplicated_items.append(asset)
	library.items = duplicated_items
	data_source.save_libray(library)
	call_deferred("emit_signal", "assets_changed")
	return true


func is_file_supported(file: String)	->  bool:
	var extension = file.get_extension()
	var supported_extensions = ["tscn", "glb", "fbx", "obj", "gltf"]
	return extension in supported_extensions
