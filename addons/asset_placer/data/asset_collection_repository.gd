extends RefCounted
class_name AssetCollectionRepository

var _data_source: AssetLibraryDataSource
var _id_generator: AssetPlacerIdGenerator

signal collections_changed

func _init():
	self._id_generator = AssetPlacerIdGenerator.new()
	self._data_source = AssetLibraryDataSource.new()


func get_collections() -> Array[AssetCollection]:
	return _data_source.get_library().collections


func add_collection(name: String, color: Color):
	var lib = _data_source.get_library()
	var collection = AssetCollection.new(name, color, _id_generator.next_int())
	lib.collections.append(collection)
	_data_source.save_libray(lib)
	collections_changed.emit()
	
func delete_collection(id: int):
	var lib = _data_source.get_library()
	var new_collections = lib.collections.filter(func(c): return c.id != id)
	lib.collections = new_collections
	var assets = lib.items
	
	for asset in assets:
		var updated_tags = asset.tags.filter(func(f): return f != id)
		if updated_tags != asset.tags:
			asset.tags = updated_tags
		
	lib.items = assets
	
	_data_source.save_libray(lib)
	collections_changed.emit()
