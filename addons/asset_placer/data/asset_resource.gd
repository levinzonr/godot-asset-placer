
extends RefCounted
class_name AssetResource

@export var scene: PackedScene
@export var name: String
@export var id: String
@export var tags: Array[String]


var shallow_collections: Array[AssetCollection]:
	get():
		var shallow: Array[AssetCollection] = []
		for name in tags:
			shallow.push_back(AssetCollection.new(name, Color.TRANSPARENT))
		return shallow

func _init(scene: PackedScene, name: String, tags: Array[String] = []):
	self.scene = scene
	self.name = name
	self.id = ResourceUID.path_to_uid(scene.resource_path)
	self.tags = tags


func belongs_to_collection(collection : AssetCollection) -> bool:
	return tags.any(func(tag: String): return tag == collection.name)
	
	
func belongs_to_some_collection(collections: Array[AssetCollection]) -> bool:
	return collections.any(func(collection: AssetCollection):
		return self.belongs_to_collection(collection)
	)	
