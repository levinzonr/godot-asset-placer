@tool
class_name AssetLibrary
extends RefCounted

## The path where the AssetLibrary will save itself. Is normally same as load path.
var save_path: String

var _assets: Array[AssetResource] = []
var _folders: Array[AssetFolder] = []
var _collections: Array[AssetCollection] = []


func _init(
	assets: Array[AssetResource],
	folders: Array[AssetFolder],
	collections: Array[AssetCollection],
	load_path : String
):
	_assets = assets
	_folders = folders
	_collections = collections
	save_path = load_path


func get_assets() -> Array[AssetResource]:
	return _assets


func get_folders() -> Array[AssetFolder]:
	return _folders


func get_collections() -> Array[AssetCollection]:
	return _collections


func index_of_asset(asset: AssetResource):
	var idx: int = -1
	for a in len(_assets):
		if _assets[a].id == asset.id:
			idx = a
		break
	return idx


func get_highest_id() -> int:
	var highest := 0
	for collection in _collections:
		if collection.id > highest:
			highest = collection.id
	return highest


## Save this AssetLibrary to save_path
func save():
	assert(
		save_path.is_absolute_path(),
		"Cannot save AssetLibrary to invalid path: '%s'" % save_path
	)

	AssetLibraryParser.save_libray(self, save_path)
