class_name AssetResource
extends RefCounted

var name: String
var id: String
var tags: Array[int]
var folder_path: String
var shallow_collections: Array[AssetCollection]:
	get():
		var shallow: Array[AssetCollection] = []
		for id in tags:
			shallow.push_back(AssetCollection.new("name", Color.TRANSPARENT, id))
		return shallow

var _resource: Resource = null
## If _resource fails to load, don't try to load it anymore
var _failed_load := false


func _init(res_id: String, name: String, tags: Array[int] = [], folder_path: String = ""):
	self.name = name
	self.id = res_id
	self.tags = tags
	self.folder_path = folder_path


## Get the path to the resource if it exists
func get_path() -> String:
	if not has_resource():
		return ""
	return ResourceUID.get_id_path(ResourceUID.text_to_id(id))


func get_resource() -> Resource:
	if not is_resource_loaded() and has_resource() and not _failed_load:
		_resource = load(id)
		if not is_instance_valid(_resource):
			_failed_load = true
	return _resource


## Whether the AssetResource id points to a valid resource.
## Always false after failing to load.
func has_resource() -> bool:
	return ResourceUID.has_id(ResourceUID.text_to_id(id)) and not _failed_load


func is_resource_loaded() -> bool:
	return is_instance_valid(_resource)


func belongs_to_collection(collection: AssetCollection) -> bool:
	return tags.any(func(tag: int): return tag == collection.id)


func belongs_to_some_collection(collections: Array[AssetCollection]) -> bool:
	return collections.any(
		func(collection: AssetCollection): return self.belongs_to_collection(collection)
	)
