extends RefCounted
class_name AssetsRepository

var data_source: AssetLibraryDataSource

func _init():
	data_source = AssetLibraryDataSource.new()
	
func get_all_assets() -> Array[AssetResource]:
	return data_source.get_library().items

func exists(asset: AssetResource):
	return get_all_assets().any(func(item: AssetResource):
		return item.scene == asset.scene
	)
	

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

func add_asset(scene_path: String):
	print("Adding asset " + scene_path)
	var loaded_scene: PackedScene = load(scene_path)
	loaded_scene.is_queued_for_deletion()
	var segments = scene_path.split("/")
	
	var file_name = segments.get(segments.size() - 1)
	var asset = AssetResource.new(loaded_scene, file_name)
	
	if exists(asset):
		print("Asset already exists")
		return
	var library: AssetLibrary = data_source.get_library()
	var duplicated_items = library.items.duplicate()
	duplicated_items.append(asset)
	library.items = duplicated_items
	data_source.save_libray(library)
