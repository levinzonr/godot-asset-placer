extends RefCounted
class_name AssetCollection

var name: String
var backgroundColor: Color
var id: int


func _init(name: String, backgroundColor: Color, id: int):
	self.backgroundColor = backgroundColor
	self.name = name
	self.id = id
