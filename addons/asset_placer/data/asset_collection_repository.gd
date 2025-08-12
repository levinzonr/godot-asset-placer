extends RefCounted
class_name AssetCollectionRepository

var _data_source: AssetLibraryDataSource

signal collections_changed

func _init():
	self._data_source = AssetLibraryDataSource.new()


func get_collections() -> Array[AssetCollection]:
	return _data_source.get_library().collections


func add_collection(collection: AssetCollection):
	var lib = _data_source.get_library()
	lib.collections.append(collection)
	_data_source.save_libray(lib)
	collections_changed.emit()
	
func delete_collection(name: String):
	var lib = _data_source.get_library()
	var new_collections = lib.collections.filter(func(c): return c.name != name)
	lib.collections = new_collections
	_data_source.save_libray(lib)
	collections_changed.emit()
