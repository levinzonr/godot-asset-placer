extends RefCounted
class_name AssetsRepository

var library: AssetLibrary

func _init(library: AssetLibrary):
	self.library = library
	
	
func get_all_assets() -> Array[AssetResource]:
	return library.items

func exists(asset: AssetResource):
	return library.items.any(func(item: AssetResource):
		return item.scene == asset.scene
	)

func add_asset(scene_path: String):
	print("Adding asset " + scene_path)
	var asset = AssetResource.new()
	var loaded_scene: PackedScene = load(scene_path)
	loaded_scene.is_queued_for_deletion()
	var segments = scene_path.split("/")
	
	var file_name = segments.get(segments.size() - 1)
	asset.name = file_name
	asset.scene = loaded_scene
	
	if exists(asset):
		print("Asset already exists")
		return
	
	var duplicated_items = library.items.duplicate()
	duplicated_items.append(asset)
	library.items = duplicated_items
	library.changed.emit()
	ResourceSaver.save(library)
