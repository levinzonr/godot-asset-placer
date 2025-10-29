extends RefCounted
class_name AssetCollectionRepository

var _data_source: AssetLibraryDataSource
var _id_generator: AssetPlacerIdGenerator

static var instance: AssetCollectionRepository

signal collections_changed

func _init(data_source: AssetLibraryDataSource):
	self._id_generator = AssetPlacerIdGenerator.new()
	self._data_source = data_source
	instance = self


func get_collections() -> Array[AssetCollection]:
	return _data_source.get_library().collections


func update_collection(collection: AssetCollection):
	var lib = _data_source.get_library()
	var collections = lib.collections
	for item in collections:
		if item.id == collection.id:
			item.name = collection.name
			item.backgroundColor = collection.backgroundColor
			break
	lib.collections = collections		
	_data_source.save_libray(lib)
	collections_changed.emit()

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
