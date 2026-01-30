class_name AssetCollectionRepository
extends RefCounted

signal collections_changed

static var instance: AssetCollectionRepository

var _data_source: AssetLibraryDataSource
var _current_highest_id: int


func _init(source: AssetLibraryDataSource):
	_current_highest_id = source.get_library().get_highest_id()
	_data_source = source
	instance = self


func get_collections() -> Array[AssetCollection]:
	return _data_source.get_library().collections


func update_collection(collection: AssetCollection):
	var lib = _data_source.get_library()
	var collections = lib.collections
	for item in collections:
		if item.id == collection.id:
			item.name = collection.name
			item.background_color = collection.background_color
			break
	lib.collections = collections
	_data_source.save_libray(lib)
	collections_changed.emit()


func add_collection(name: String, color: Color):
	var lib = _data_source.get_library()
	_current_highest_id += 1
	assert(
		_current_highest_id > lib.get_highest_id(),
		"Cannot create collection with id %s as it already exists." % _current_highest_id
	)
	var collection := AssetCollection.new(name, color, _current_highest_id)
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
