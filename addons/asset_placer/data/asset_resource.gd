
extends RefCounted
class_name AssetResource

@export var scene: PackedScene
@export var name: String


func _init(scene: PackedScene, name: String):
	self.scene = scene
	self.name = name
