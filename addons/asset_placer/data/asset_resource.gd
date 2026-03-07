class_name AssetResource
extends RefCounted

var name: String
var id: String
var tags: Array[int]
var folder_path: String
var primary_collection: int = -1

var _resource: Resource = null
## If _resource fails to load, don't try to load it anymore
var _failed_load := false


## Checks whether the given filename is supported as a resource.
static func is_file_supported(file: String) -> bool:
	return file.get_extension() in ["tscn", "glb", "fbx", "obj", "gltf", "blend"]


## Creates a new AssetResource tied to a given resource path.
static func from_path(
	p_path: String,
	p_tags: Array[int] = [],
	p_folder_path: String = "",
	p_primary_collection: int = -1
) -> AssetResource:

	assert(is_file_supported(p_path), "Given filepath %s is an unsupported resource type." % p_path)

	var asset := AssetResource.new(
		ResourceIdCompat.path_to_uid(p_path),
		p_path.get_file(),
		p_tags,
		p_folder_path,
		p_primary_collection
	)

	return asset


func _init(
	res_id: String,
	p_name: String,
	p_tags: Array[int] = [],
	p_folder_path: String = "",
	p_primary_collection: int = -1
):
	name = p_name
	id = res_id
	tags = p_tags
	folder_path = p_folder_path
	primary_collection = p_primary_collection


func get_primary_collection() -> int:
	if primary_collection >= 0:
		return primary_collection
	return -1


## Get the path to the resource if it exists
func get_path() -> String:
	if not has_resource():
		return ""
	# If id is already a path (not a UID), return it directly
	if not id.begins_with("uid://"):
		return id
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


## Adds a tag to this asset. Does nothing if it already has new_tag.
func add_tag(new_tag: int):
	if not new_tag in tags:
		tags.append(new_tag)


## Adds multiple new tags to this asset. Skips tags it already has.
func add_tags(new_tags: Array[int]):
	for new_tag in new_tags:
		add_tag(new_tag)


## Removes a tag from this asset. Does nothing if it doesn't have tag.
func remove_tag(tag: int):
	tags.erase(tag)
