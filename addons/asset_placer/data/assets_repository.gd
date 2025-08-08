extends RefCounted
class_name AssetsRepository

var data_source: AssetLibraryDataSource

static var instance: AssetsRepository

signal assets_changed

func _init():
	data_source = AssetLibraryDataSource.new()
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
	assets_changed.emit()

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
		assets_changed.emit()
	

func add_asset(scene_path: String, tags: Array[String] = []) -> bool:
	var loaded_scene: PackedScene = load(scene_path)
	var id = ResourceUID.path_to_uid(loaded_scene.resource_path)
	var asset = AssetResource.new(id, scene_path.get_file())
	if exists(id):
		return false
		
	var library: AssetLibrary = data_source.get_library()
	var duplicated_items = library.items.duplicate()
	duplicated_items.append(asset)
	library.items = duplicated_items
	data_source.save_libray(library)
	assets_changed.emit()
	return true
