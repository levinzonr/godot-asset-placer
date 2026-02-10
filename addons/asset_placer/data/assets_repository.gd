class_name AssetsRepository
extends RefCounted

signal assets_changed

static var instance: AssetsRepository


func _init():
	instance = self


func get_all_assets() -> Array[AssetResource]:
	return AssetLibraryParser.load_library().get_assets()


func exists(asset_id: String):
	return get_all_assets().any(func(item: AssetResource): return item.id == asset_id)


func delete(asset_id: String):
	var lib = AssetLibraryParser.load_library()
	var assets = lib.get_assets().filter(func(a): return a.id != asset_id)
	lib._assets = assets
	AssetLibraryParser.save_libray(lib)
	call_deferred("emit_signal", "assets_changed")


func find_by_uid(uid: String) -> AssetResource:
	for asset in get_all_assets():
		if asset.id == uid:
			return asset
	return null


func update(asset: AssetResource):
	var lib = AssetLibraryParser.load_library()
	var index = lib.index_of_asset(asset)
	if index != -1:
		lib._assets[index] = asset
		AssetLibraryParser.save_libray(lib)
		call_deferred("emit_signal", "assets_changed")


func add_asset(scene_path: String, tags: Array[int] = [], folder_path: String = "") -> bool:
	if not is_file_supported(scene_path.get_file()):
		return false

	var library = AssetLibraryParser.load_library()
	var id = ResourceIdCompat.path_to_uid(scene_path)
	if exists(id):
		return false
	var asset = AssetResource.new(id, scene_path.get_file(), tags, folder_path)
	var duplicated_items = library.get_assets().duplicate()
	duplicated_items.append(asset)
	library._assets = duplicated_items
	AssetLibraryParser.save_libray(library)
	call_deferred("emit_signal", "assets_changed")
	return true


func is_file_supported(file: String) -> bool:
	var extension = file.get_extension()
	var supported_extensions = ["tscn", "glb", "fbx", "obj", "gltf", "blend"]
	return extension in supported_extensions
