
extends RefCounted
class_name AssetResource

@export var scene: PackedScene
@export var name: String
@export var id: String
@export var tags: Array[String]


func _init(scene: PackedScene, name: String, tags: Array[String] = []):
	self.scene = scene
	self.name = name
	self.id = ResourceUID.path_to_uid(scene.resource_path)
	self.tags = tags
