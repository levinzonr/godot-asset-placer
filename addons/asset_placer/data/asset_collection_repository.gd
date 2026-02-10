class_name AssetCollectionRepository
extends RefCounted

signal collections_changed

static var instance: AssetCollectionRepository

var _current_highest_id: int


func _init():
	_current_highest_id = AssetLibraryParser.load_library().get_highest_id()
	instance = self


func get_collections() -> Array[AssetCollection]:
	return AssetLibraryParser.load_library().get_collections()


func update_collection(collection: AssetCollection):
	var lib = AssetLibraryParser.load_library()
	var collections = lib.get_collections()
	for item in collections:
		if item.id == collection.id:
			item.name = collection.name
			item.background_color = collection.background_color
			break
	lib._collections = collections
	AssetLibraryParser.save_libray(lib)
	collections_changed.emit()


func add_collection(name: String, color: Color):
	var lib := AssetLibraryParser.load_library()
	_current_highest_id += 1
	assert(
		_current_highest_id > lib.get_highest_id(),
		"Cannot create collection with id %s as it already exists." % _current_highest_id
	)
	var collection := AssetCollection.new(name, color, _current_highest_id)
	lib._collections.append(collection)
	AssetLibraryParser.save_libray(lib)
	collections_changed.emit()


func delete_collection(id: int):
	var lib = AssetLibraryParser.load_library()
	var new_collections = lib.get_collections().filter(func(c): return c.id != id)
	lib._collections = new_collections
	var assets = lib.get_assets()

	for asset in assets:
		var updated_tags = asset.tags.filter(func(f): return f != id)
		if updated_tags != asset.tags:
			asset.tags = updated_tags

	lib._assets = assets

	AssetLibraryParser.save_libray(lib)
	collections_changed.emit()
